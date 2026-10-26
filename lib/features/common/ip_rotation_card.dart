import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/platform/haptics.dart';
import '../../presentation/controllers/vpn_controller.dart';
import 'app_switch.dart';

/// Lets the user pick how often IP rotation switches relays.
Future<void> showIpRotationIntervalPicker(
  BuildContext context,
  VpnController vpn,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.elevatedSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderDivider),
      ),
      title: Text(
        'Change IP Every',
        style: AppTextStyles.headlineSm.copyWith(color: AppColors.primaryText),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final minutes in VpnController.ipRotationIntervals)
            ListTile(
              title: Text(
                _intervalLabel(minutes),
                style: TextStyle(
                  color: vpn.ipRotationMinutes == minutes
                      ? AppColors.primaryText
                      : AppColors.secondaryText,
                ),
              ),
              trailing: Icon(
                vpn.ipRotationMinutes == minutes
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: vpn.ipRotationMinutes == minutes
                    ? AppColors.primaryText
                    : AppColors.mutedText,
              ),
              onTap: () async {
                Haptics.tick();
                await vpn.setIpRotationMinutes(minutes);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
        ],
      ),
    ),
  );
}

String _intervalLabel(int minutes) =>
    minutes == 1 ? '1 minute' : '$minutes minutes';

/// Home-screen control for automatic IP rotation while connected: on/off,
/// a countdown to the next change, the interval, and "Rotate now".
class IpRotationCard extends StatefulWidget {
  const IpRotationCard({super.key});

  @override
  State<IpRotationCard> createState() => _IpRotationCardState();
}

class _IpRotationCardState extends State<IpRotationCard> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Ticks once a second only while a countdown is on screen.
  void _syncTicker(bool counting) {
    if (counting && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!counting && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  static String _countdown(Duration left) {
    final seconds = left.isNegative ? 0 : left.inSeconds;
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnController>();
    final enabled = vpn.ipRotationEnabled;
    final next = vpn.nextRotationAt;
    _syncTicker(enabled && next != null);

    final subtitle = !enabled
        ? 'Fastest server, new IP every ${_intervalLabel(vpn.ipRotationMinutes)}'
        : vpn.isRotatingIp
        ? 'Switching to a new IP…'
        : next != null
        ? 'New IP in ${_countdown(next.difference(DateTime.now()))}'
        : 'Starts once connected';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled
              ? AppColors.connectedStatus.withValues(alpha: 0.45)
              : AppColors.borderDivider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderDivider),
                ),
                child: Icon(
                  Icons.autorenew_rounded,
                  size: 18,
                  color: enabled
                      ? AppColors.connectedStatus
                      : AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUTO IP ROTATION',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.mutedText,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: enabled
                            ? AppColors.primaryText
                            : AppColors.secondaryText,
                        fontSize: 13,
                        fontWeight: enabled ? FontWeight.w600 : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              AppSwitch(value: enabled, onChanged: vpn.setIpRotationEnabled),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 48),
                _Chip(
                  icon: Icons.timer_outlined,
                  label: 'Every ${_intervalLabel(vpn.ipRotationMinutes)}',
                  onTap: () => showIpRotationIntervalPicker(context, vpn),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: vpn.isRotatingIp
                      ? null
                      : () {
                          Haptics.click();
                          vpn.rotateIpNow();
                        },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Rotate now'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryText,
                    disabledForegroundColor: AppColors.mutedText,
                    textStyle: AppTextStyles.labelLg.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Chip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.elevatedSurface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderDivider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.secondaryText),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.expand_more_rounded,
                size: 14,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
