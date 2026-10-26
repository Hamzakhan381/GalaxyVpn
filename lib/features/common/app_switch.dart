import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/platform/haptics.dart';

/// The app's on/off switch: theme colours and a haptic tick on each change.
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Switch(
      value: value,
      activeThumbColor: AppColors.pureWhite,
      activeTrackColor: AppColors.connectedStatus,
      onChanged: onChanged == null
          ? null
          : (on) {
              Haptics.tick();
              onChanged(on);
            },
    );
  }
}
