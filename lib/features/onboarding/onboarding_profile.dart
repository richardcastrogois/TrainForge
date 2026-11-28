import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// First-use answers that prepare the app. Every answer is optional and can be
/// changed later. Kept encrypted on this device only (never sent to the API).
/// Body measurements are asked only when the account granted health data.
class OnboardingProfile {
  /// 'woman', 'man', 'nonbinary', 'other' or 'undisclosed'.
  final String? gender;
  final int? heightCm, weightKg;

  /// Training places from the workout library: casa, praca, academia, pausa.
  final Set<String> places;

  /// How confident the person feels: sentado, iniciante, intermediario, avancado.
  final String? confidence;
  final DateTime? completedAt;

  /// Food goal id (`FoodGoal.id`), chosen on the food page.
  final String? foodGoal;

  const OnboardingProfile({
    this.gender,
    this.heightCm,
    this.weightKg,
    this.places = const {},
    this.confidence,
    this.completedAt,
    this.foodGoal,
  });

  static const genders = ['woman', 'man', 'nonbinary', 'other', 'undisclosed'];
  static const foodGoals = [
    'perder',
    'manter',
    'ganhar',
    'recompor',
    'desempenho',
    'saude',
  ];
  static const placeIds = ['casa', 'praca', 'academia', 'pausa'];
  static const confidences = [
    'sentado',
    'iniciante',
    'intermediario',
    'avancado',
  ];

  bool get completed => completedAt != null;

  /// Library cell for a place: "pausa" has only seated and standing breaks.
  String cellFor(String place) {
    final level = confidence ?? 'iniciante';
    if (place == 'pausa') {
      return level == 'sentado' ? 'pausa-sentado' : 'pausa-em-pe';
    }
    if (level == 'sentado') {
      return place == 'casa' ? 'casa-sentado' : '$place-iniciante';
    }
    return '$place-$level';
  }

  OnboardingProfile copyWith({
    String? gender,
    int? heightCm,
    int? weightKg,
    Set<String>? places,
    String? confidence,
    DateTime? completedAt,
    String? foodGoal,
    bool clearHeight = false,
    bool clearWeight = false,
  }) => OnboardingProfile(
    gender: gender ?? this.gender,
    heightCm: clearHeight ? null : heightCm ?? this.heightCm,
    weightKg: clearWeight ? null : weightKg ?? this.weightKg,
    places: places ?? this.places,
    confidence: confidence ?? this.confidence,
    completedAt: completedAt ?? this.completedAt,
    foodGoal: foodGoal ?? this.foodGoal,
  );

  Map<String, dynamic> toJson() => {
    'v': 1,
    if (gender != null) 'gender': gender,
    if (heightCm != null) 'heightCm': heightCm,
    if (weightKg != null) 'weightKg': weightKg,
    'places': places.toList()..sort(),
    if (confidence != null) 'confidence': confidence,
    if (completedAt != null)
      'completedAt': completedAt!.toUtc().toIso8601String(),
    if (foodGoal != null) 'foodGoal': foodGoal,
  };

  /// Unknown or out-of-range values are dropped instead of trusted.
  factory OnboardingProfile.fromJson(Map<String, dynamic> j) {
    int? range(Object? v, int min, int max) =>
        v is int && v >= min && v <= max ? v : null;
    final gender = j['gender'];
    final confidence = j['confidence'];
    return OnboardingProfile(
      gender: genders.contains(gender) ? gender as String : null,
      heightCm: range(j['heightCm'], 90, 230),
      weightKg: range(j['weightKg'], 25, 250),
      places: {
        for (final p in j['places'] as List? ?? const [])
          if (placeIds.contains(p)) p as String,
      },
      confidence: confidences.contains(confidence)
          ? confidence as String
          : null,
      completedAt: DateTime.tryParse(j['completedAt'] as String? ?? ''),
      foodGoal: foodGoals.contains(j['foodGoal'])
          ? j['foodGoal'] as String
          : null,
    );
  }
}

abstract interface class OnboardingStore {
  Future<OnboardingProfile?> read(String accountId);
  Future<void> write(String accountId, OnboardingProfile? profile);
}

class SecureOnboardingStore implements OnboardingStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
  );
  static const _prefix = 'trainforge.onboarding.v1.';

  @override
  Future<OnboardingProfile?> read(String accountId) async {
    final raw = await _storage.read(key: _prefix + accountId);
    if (raw == null) return null;
    try {
      return OnboardingProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String accountId, OnboardingProfile? profile) =>
      profile == null
      ? _storage.delete(key: _prefix + accountId)
      : _storage.write(
          key: _prefix + accountId,
          value: jsonEncode(profile.toJson()),
        );
}

class MemoryOnboardingStore implements OnboardingStore {
  final Map<String, OnboardingProfile?> values;
  MemoryOnboardingStore([Map<String, OnboardingProfile?>? values])
    : values = values ?? {};
  @override
  Future<OnboardingProfile?> read(String accountId) async => values[accountId];
  @override
  Future<void> write(String accountId, OnboardingProfile? profile) async =>
      values[accountId] = profile;
}

/// Answers per signed-in account, shared by the gate, the home and settings.
class OnboardingController extends ChangeNotifier {
  /// Tests replace the default device store (flutter_test_config.dart).
  static OnboardingStore Function() defaultStore = SecureOnboardingStore.new;

  final OnboardingStore store;
  final Map<String, OnboardingProfile?> _profiles = {};
  final Set<String> _loading = {};
  OnboardingController({OnboardingStore? store})
    : store = store ?? defaultStore();

  bool loaded(String accountId) => _profiles.containsKey(accountId);
  OnboardingProfile? profile(String accountId) => _profiles[accountId];

  Future<void> load(String accountId) async {
    if (loaded(accountId) || !_loading.add(accountId)) return;
    OnboardingProfile? value;
    try {
      value = await store.read(accountId);
    } catch (_) {
      // Unreadable storage: ask again rather than block the app.
    }
    _loading.remove(accountId);
    _profiles[accountId] = value;
    notifyListeners();
  }

  Future<void> save(String accountId, OnboardingProfile profile) async {
    _profiles[accountId] = profile;
    notifyListeners();
    try {
      await store.write(accountId, profile);
    } catch (_) {
      // Kept in memory for this session; asked again next time if not saved.
    }
  }

  /// "Redo the first questions": forget the answers on this device.
  Future<void> reset(String accountId) async {
    _profiles[accountId] = null;
    notifyListeners();
    try {
      await store.write(accountId, null);
    } catch (_) {}
  }
}

/// Gives the home, the workout card and settings access to the answers.
class OnboardingScope extends InheritedNotifier<OnboardingController> {
  final String accountId;
  const OnboardingScope({
    super.key,
    required OnboardingController controller,
    required this.accountId,
    required super.child,
  }) : super(notifier: controller);

  static OnboardingScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnboardingScope>();

  OnboardingProfile? get profile => notifier!.profile(accountId);

  /// Keeps the food goal with the other answers on this device.
  Future<void> saveFoodGoal(String id) => notifier!.save(
    accountId,
    (profile ?? const OnboardingProfile()).copyWith(foodGoal: id),
  );
}
