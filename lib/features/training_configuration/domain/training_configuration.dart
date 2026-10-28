import 'dart:convert';

Map<String, dynamic> configObject(Object? value) =>
    Map<String, dynamic>.from(value as Map);
const trainingConfigurationContract = 'trainforge.training-configuration/1';

class TrainingResourceRef {
  final String sourceId;
  final int equipmentId;
  const TrainingResourceRef(this.sourceId, this.equipmentId);
  factory TrainingResourceRef.fromJson(Map<String, dynamic> j) {
    final result = TrainingResourceRef(
      j['sourceId'] as String,
      j['equipmentId'] as int,
    );
    if (!RegExp(
          r'^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$',
        ).hasMatch(result.sourceId) ||
        result.equipmentId < 1 ||
        result.equipmentId > 2147483647) {
      throw const FormatException('Invalid resource reference');
    }
    return result;
  }
  String get key => '$sourceId/$equipmentId';
  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'equipmentId': equipmentId,
  };
}

class TrainingResourceOption {
  final TrainingResourceRef reference;
  final String name, source;
  TrainingResourceOption.fromJson(Map<String, dynamic> j)
    : reference = TrainingResourceRef.fromJson(j),
      name = j['nameOriginal'] as String,
      source = j['sourceName'] as String {
    if (name.trim().isEmpty ||
        name.runes.length > 360 ||
        source.trim().isEmpty ||
        RegExp(r'[\u0000-\u001f\u007f]').hasMatch(name)) {
      throw const FormatException('Invalid resource label');
    }
  }
}

class AvailabilityDraft {
  final int id;
  int? weekday;
  String minutes;
  String? start;
  AvailabilityDraft({
    required this.id,
    this.weekday,
    this.minutes = '',
    this.start,
  });
  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'startTime': start,
    'minutesAvailable': int.tryParse(minutes),
  };
}

class TrainingDraft {
  Set<String> environments = {};
  String? resourceStatus, context;
  Map<String, TrainingResourceRef> resources = {};
  String timezone;
  List<AvailabilityDraft> availability = [];
  int nextId = 1;
  TrainingDraft({required this.timezone}) {
    availability.add(AvailabilityDraft(id: nextId++));
  }
  factory TrainingDraft.fromJson(Map<String, dynamic> j) {
    final d = TrainingDraft(timezone: j['timezone'] as String);
    d.environments = Set.from(j['environments'] as List);
    d.context = j['context'] as String;
    final resources = configObject(j['resources']);
    d.resourceStatus = resources['status'] as String;
    for (final item in resources['items'] as List) {
      final ref = TrainingResourceRef.fromJson(configObject(item));
      if (d.resources.containsKey(ref.key)) {
        throw const FormatException('Duplicate resource');
      }
      d.resources[ref.key] = ref;
    }
    d.availability = [];
    for (final slot in j['availability'] as List) {
      final v = configObject(slot);
      d.availability.add(
        AvailabilityDraft(
          id: d.nextId++,
          weekday: v['weekday'] as int,
          minutes: (v['minutesAvailable'] as int).toString(),
          start: v['startTime'] as String?,
        ),
      );
    }
    if (d.validate().isNotEmpty) {
      throw const FormatException('Invalid configuration');
    }
    return d;
  }
  Map<String, dynamic> toJson() => {
    'environments': environments.toList(),
    'context': context,
    'timezone': timezone,
    'resources': {
      'status': resourceStatus,
      'items': resources.values.map((r) => r.toJson()).toList(),
    },
    'availability': availability.map((a) => a.toJson()).toList(),
  };
  String get fingerprint => jsonEncode(toJson());
  Map<String, String> validate() {
    final e = <String, String>{};
    if (environments.isEmpty ||
        environments.length > 3 ||
        environments.any((v) => !{'home', 'park', 'gym'}.contains(v))) {
      e['configuration.environments'] = 'choose_environment';
    }
    if (!{'personal', 'caregiver_break'}.contains(context)) {
      e['configuration.context'] = 'choose_context';
    }
    if (!{'declared', 'none', 'unknown'}.contains(resourceStatus)) {
      e['configuration.resources.status'] = 'choose_resource_status';
    }
    if (resourceStatus == 'declared' && resources.isEmpty) {
      e['configuration.resources.items'] = 'choose_resources';
    }
    if (resources.length > 32 ||
        (resourceStatus != 'declared' && resources.isNotEmpty)) {
      e['configuration.resources.items'] = 'invalid_resources';
    }
    if (timezone.isEmpty ||
        timezone.length > 80 ||
        timezone == 'Local' ||
        !(timezone == 'UTC' ||
            RegExp(r'^[+-](0[0-9]|1[0-3]):[0-5][0-9]$').hasMatch(timezone) ||
            {'+14:00', '-14:00'}.contains(timezone) ||
            RegExp(r'^[A-Za-z_]+(?:/[A-Za-z0-9_+-]+)+$').hasMatch(timezone))) {
      e['configuration.timezone'] = 'invalid_timezone';
    }
    if (availability.isEmpty || availability.length > 28) {
      e['configuration.availability'] = 'choose_availability';
    }
    final slots = <String>{};
    for (var i = 0; i < availability.length; i++) {
      final a = availability[i], key = 'configuration.availability.$i';
      if (a.weekday == null || a.weekday! < 1 || a.weekday! > 7) {
        e['$key.weekday'] = 'invalid_weekday';
      }
      final minutes = int.tryParse(a.minutes);
      if (!RegExp(r'^[0-9]{1,4}$').hasMatch(a.minutes) ||
          minutes == null ||
          minutes < 1 ||
          minutes > 1440) {
        e['$key.minutesAvailable'] = 'invalid_available_minutes';
      }
      if (a.start != null &&
          !RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$').hasMatch(a.start!)) {
        e['$key.startTime'] = 'invalid_start_time';
      }
      if (!slots.add('${a.weekday}|${a.start ?? ''}')) {
        e[key] = 'duplicate_availability';
      }
    }
    return e;
  }
}

class TrainingSnapshot {
  final int revision;
  final String confirmedAt;
  final Map<String, dynamic> _configuration;
  TrainingSnapshot.fromJson(Map<String, dynamic> j)
    : revision = j['revision'] as int,
      confirmedAt = j['confirmedAt'] as String,
      _configuration =
          jsonDecode(jsonEncode(j['configuration'])) as Map<String, dynamic> {
    if (j['contract'] != trainingConfigurationContract ||
        revision < 1 ||
        revision > 2147483647 ||
        DateTime.tryParse(confirmedAt) == null) {
      throw const FormatException('Invalid training snapshot');
    }
    TrainingDraft.fromJson(_configuration);
  }
  TrainingDraft draft() => TrainingDraft.fromJson(
    configObject(jsonDecode(jsonEncode(_configuration))),
  );
}

class TrainingCurrent {
  final TrainingSnapshot? snapshot;
  final List<TrainingResourceOption> labels;
  final List<TrainingResourceRef> unavailable;
  TrainingCurrent.fromJson(Map<String, dynamic> j)
    : snapshot = j['current'] == null
          ? null
          : TrainingSnapshot.fromJson(configObject(j['current'])),
      labels = (j['resourceLabels'] as List)
          .map((x) => TrainingResourceOption.fromJson(configObject(x)))
          .toList(),
      unavailable = (j['unavailableResources'] as List)
          .map((x) => TrainingResourceRef.fromJson(configObject(x)))
          .toList() {
    final selected = snapshot?.draft().resources ?? {};
    final seen = <String>{};
    for (final key in [
      ...labels.map((v) => v.reference.key),
      ...unavailable.map((v) => v.key),
    ]) {
      if (!selected.containsKey(key) || !seen.add(key)) {
        throw const FormatException('Unrelated resource projection');
      }
    }
    if (seen.length != selected.length) {
      throw const FormatException('Incomplete resource projection');
    }
  }
}

class TrainingResourcePage {
  final List<TrainingResourceOption> items;
  final String? cursor;
  TrainingResourcePage.fromJson(Map<String, dynamic> j)
    : items = (j['items'] as List)
          .map((x) => TrainingResourceOption.fromJson(configObject(x)))
          .toList(),
      cursor = j['nextCursor'] as String?;
}

class TrainingFailure implements Exception {
  final String code;
  final Map<String, String> fields;
  final bool uncertain;
  const TrainingFailure(
    this.code, {
    this.fields = const {},
    this.uncertain = false,
  });
}

abstract interface class TrainingConfigurationRepository {
  Future<TrainingCurrent> load();
  Future<TrainingCurrent> save(Map<String, dynamic> command, String key);
  Future<TrainingResourcePage> resources({String q = '', String? cursor});
}

String canonicalTrainingConfiguration(Map<String, dynamic> value) {
  final d = TrainingDraft.fromJson(value), j = d.toJson();
  (j['environments'] as List).sort();
  (j['resources']['items'] as List).sort((a, b) {
    final source = (a['sourceId'] as String).compareTo(b['sourceId'] as String);
    return source != 0
        ? source
        : (a['equipmentId'] as int).compareTo(b['equipmentId'] as int);
  });
  (j['availability'] as List).sort((a, b) {
    final day = (a['weekday'] as int).compareTo(b['weekday'] as int);
    return day != 0
        ? day
        : ((a['startTime'] as String?) ?? '').compareTo(
            (b['startTime'] as String?) ?? '',
          );
  });
  return jsonEncode(j);
}
