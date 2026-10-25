import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_vpn/core/storage/preferences_service.dart';
import 'package:galaxy_vpn/features/common/motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PreferencesService> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return PreferencesService.create();
  }

  test('level is unset on first launch so the device can pick one', () async {
    final prefs = await prefsWith({});
    expect(prefs.motionLevel, isNull);
    expect(MotionSettings(prefs).level, MotionLevel.full);
  });

  test('the old Reduce Motion switch carries over as off', () async {
    final prefs = await prefsWith({'setting_reduce_motion': true});
    expect(prefs.motionLevel, 'off');
    expect(MotionSettings(prefs).level, MotionLevel.off);
  });

  test('saving a level keeps Reduce Motion in step', () async {
    final prefs = await prefsWith({});
    final motion = MotionSettings(prefs);

    await motion.setLevel(MotionLevel.lite);
    expect(prefs.motionLevel, 'lite');
    expect(prefs.reduceMotion, isFalse);

    await motion.setLevel(MotionLevel.off);
    expect(prefs.reduceMotion, isTrue);
  });

  test('the device picks the level until the user chooses one', () async {
    final prefs = await prefsWith({});
    final motion = MotionSettings(prefs);

    await motion.applyDeviceDefault(lowEndDevice: true);
    expect(motion.level, MotionLevel.lite);
    await motion.applyDeviceDefault(lowEndDevice: false);
    expect(motion.level, MotionLevel.full);

    await motion.setLevel(MotionLevel.lite);
    await motion.applyDeviceDefault(lowEndDevice: false);
    expect(motion.level, MotionLevel.lite);
    expect(prefs.motionLevelChosen, isTrue);
  });

  test('the old Reduce Motion switch counts as a choice', () async {
    final prefs = await prefsWith({'setting_reduce_motion': true});
    final motion = MotionSettings(prefs);

    await motion.applyDeviceDefault(lowEndDevice: false);
    expect(motion.level, MotionLevel.off);
  });

  testWidgets('widgets follow a level change immediately', (tester) async {
    final prefs = await prefsWith({});
    final motion = MotionSettings(prefs);
    final seen = <(MotionLevel, bool, bool)>[];

    await tester.pumpWidget(
      MotionScope(
        settings: motion,
        child: Builder(
          builder: (context) {
            seen.add((
              Motion.levelOf(context),
              Motion.isLite(context),
              Motion.isReduced(context),
            ));
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen.last, (MotionLevel.full, false, false));

    await motion.setLevel(MotionLevel.lite);
    await tester.pump();
    expect(seen.last, (MotionLevel.lite, true, false));

    await motion.setLevel(MotionLevel.off);
    await tester.pump();
    expect(seen.last, (MotionLevel.off, true, true));
  });
}
