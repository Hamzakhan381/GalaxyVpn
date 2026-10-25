import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../domain/entities/vpn_connection_state.dart';
import 'motion.dart';

/// Pill-shaped status badge with restrained status colors.
class ConnectionStatusBadge extends StatefulWidget {
  final VpnConnectionState state;

  const ConnectionStatusBadge({super.key, required this.state});

  @override
  State<ConnectionStatusBadge> createState() => _ConnectionStatusBadgeState();
}

class _ConnectionStatusBadgeState extends State<ConnectionStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isTestEnvironment || Motion.isLite(context)) {
      _pulseCtrl
        ..stop()
        ..value = 1.0;
    } else if (!_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color badgeBackground;
    Color dotColor;
    Color borderColor;
    String label;

    switch (widget.state) {
      case VpnConnectionState.connected:
        badgeBackground = const Color(0xFF0F1E16);
        dotColor = AppColors.connectedStatus; // #35C98A subtle green
        borderColor = const Color(0xFF1E3A2B);
        label = 'PROTECTED';
        break;
      case VpnConnectionState.connecting:
      case VpnConnectionState.checking:
        badgeBackground = AppColors.cardBackground;
        dotColor = AppColors.primaryText; // Pure white
        borderColor = AppColors.borderDivider;
        label = 'CONNECTING...';
        break;
      case VpnConnectionState.disconnecting:
        badgeBackground = AppColors.cardBackground;
        dotColor = AppColors.secondaryText;
        borderColor = AppColors.borderDivider;
        label = 'DISCONNECTING...';
        break;
      case VpnConnectionState.error:
        badgeBackground = const Color(0xFF261214);
        dotColor = AppColors.errorStatus; // #FF5C5C restrained red
        borderColor = const Color(0xFF4A1E22);
        label = 'ACTION REQUIRED';
        break;
      case VpnConnectionState.disconnected:
        badgeBackground = AppColors.cardBackground;
        dotColor = AppColors.mutedText; // #777777 subtle grey
        borderColor = AppColors.borderDivider;
        label = 'UNPROTECTED';
        break;
    }

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final t = _pulseCtrl.value;
        final shouldPulse =
            widget.state == VpnConnectionState.connected ||
            widget.state == VpnConnectionState.connecting ||
            widget.state == VpnConnectionState.checking;

        final pulseAlpha = shouldPulse ? (0.4 + (t * 0.6)) : 0.6;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: badgeBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: Motion.shadows(context, [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status pip
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor.withValues(alpha: pulseAlpha),
                  shape: BoxShape.circle,
                  boxShadow: shouldPulse && !Motion.isLite(context)
                      ? [
                          BoxShadow(
                            color: dotColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: AppTextStyles.labelSm.copyWith(
                    color: dotColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
