import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_vpn/core/platform/haptics.dart';
import 'package:galaxy_vpn/core/storage/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final played = <String?>[];

  setUp(() {
    played.clear();
    Haptics.enabled = true;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          played.add(call.arguments as String?);
        }
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  // Haptics closer together than its minimum gap are merged into one.
  Future<void> gap() => Future<void>.delayed(const Duration(milliseconds: 60));

  test('each kind plays its own feedback', () async {
    Haptics.tick();
    await gap();
    Haptics.click();
    await gap();
    Haptics.error();
    await gap();

    expect(played, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      null,
    ]);
  });

  test('nothing plays when turned off in Settings', () async {
    Haptics.enabled = false;
    Haptics.click();
    await gap();
    expect(played, isEmpty);
  });

  test('nothing plays while the app is in the background', () async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    Haptics.success();
    await gap();
    expect(played, isEmpty);
  });

  test('a burst of taps plays once', () async {
    Haptics.tick();
    Haptics.tick();
    Haptics.tick();
    await gap();
    expect(played, hasLength(1));
  });

  test('the setting is on by default and remembered', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PreferencesService.create();
    expect(prefs.hapticsEnabled, isTrue);

    await prefs.setHapticsEnabled(false);
    expect((await PreferencesService.create()).hapticsEnabled, isFalse);
  });
}
