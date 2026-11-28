import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/body/domain/body.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';

void main() {
  test('BMI follows weight / height² and the WHO adult bands', () {
    expect(bmi(78.4, 178), 24.7);
    expect(bmi(78.4, null), isNull);
    expect(BmiBand.of(18.4), BmiBand.under);
    expect(BmiBand.of(18.5), BmiBand.normal);
    expect(BmiBand.of(24.9), BmiBand.normal);
    expect(BmiBand.of(25), BmiBand.over);
    expect(BmiBand.of(30), BmiBand.obese);
  });

  test('one weigh-in per day, weekly averages from Monday', () {
    var all = <WeighIn>[];
    all = addWeighIn(all, WeighIn(DateTime(2026, 11, 24), 79));
    all = addWeighIn(all, WeighIn(DateTime(2026, 11, 26), 78));
    all = addWeighIn(all, WeighIn(DateTime(2026, 11, 26, 20), 77.8));
    all = addWeighIn(all, WeighIn(DateTime(2026, 11, 17), 79.6));
    expect(all.map((w) => w.kg), [79.6, 79, 77.8]);
    final weeks = weeklyAverages(all);
    expect(weeks.map((w) => w.monday), [
      // 28/11/2026 is a Saturday: the Mondays are 16 and 23.
      DateTime(2026, 11, 16),
      DateTime(2026, 11, 23),
    ]);
    expect(weeks.last.kg, closeTo(78.4, .001));
    expect(weeks.last.count, 2);
  });

  test('a weigh-in is suggested after 7 days', () {
    final all = [WeighIn(DateTime(2026, 11, 21), 78)];
    expect(weighInDue(all, DateTime(2026, 11, 27, 23)), isFalse);
    expect(weighInDue(all, DateTime(2026, 11, 28, 7)), isTrue);
    expect(weighInDue(const [], DateTime(2026, 11, 28)), isTrue);
  });

  test('weigh-ins are kept on the device and invalid ones dropped', () {
    final saved = OnboardingProfile(
      weighIns: [WeighIn(DateTime(2026, 11, 24), 78.4)],
      weighReminder: false,
    ).toJson();
    final back = OnboardingProfile.fromJson({
      ...saved,
      'weighIns': [
        ...saved['weighIns'] as List,
        {'d': 'x', 'w': 700},
        {'d': '2026-11-20', 'w': 9000},
      ],
    });
    expect(back.weighIns.single.kg, 78.4);
    expect(back.weighReminder, isFalse);
    expect(const OnboardingProfile().weighReminder, isTrue);
  });
}
