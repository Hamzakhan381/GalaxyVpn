import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../data/models/vpn_session.dart';
import '../../presentation/controllers/vpn_controller.dart';
import '../common/cyber_background.dart';
import '../common/empty_state.dart';
import '../common/metric_card.dart';
import '../common/motion.dart';
import 'session_details_sheet.dart';

class ActivityView extends StatelessWidget {
  const ActivityView({super.key});

  void _confirmClearHistory(BuildContext context, VpnController vpnRepo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDivider),
        ),
        title: Text(
          'Clear Session History?',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
        content: Text(
          'This will delete all local activity and duration logs from this device. This action cannot be undone.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              vpnRepo.clearHistory();
            },
            child: Text(
              'Clear History',
              style: AppTextStyles.labelLg.copyWith(
                color: AppColors.errorStatus,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d • HH:mm');

    return Consumer<VpnController>(
      builder: (context, vpnRepo, _) {
        final sessions = vpnRepo.sessions;

        return Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Activity History',
              style: AppTextStyles.headlineSm.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            actions: [
              if (sessions.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.secondaryText,
                  ),
                  tooltip: 'Clear History',
                  onPressed: () => _confirmClearHistory(context, vpnRepo),
                ),
            ],
          ),
          body: CyberBackground(
            child: sessions.isEmpty
                ? const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No Session Records',
                    message: 'Encrypted tunnel connections and usage statistics will appear here.',
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    children: [
                      // Overview Metric Cards
                      AnimatedFadeSlide(
                        child: Row(
                          children: [
                            Expanded(
                              child: MetricCard(
                                label: 'Sessions',
                                value: '${vpnRepo.totalSessionsCount}',
                                icon: Icons.repeat_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MetricCard(
                                label: 'Protected',
                                value: vpnRepo.formattedTotalProtectedTime,
                                icon: Icons.shield_outlined,
                                accentColor: AppColors.connectedStatus,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedFadeSlide(
                        delayMs: Motion.staggerStepMs,
                        child: MetricCard(
                          label: 'Total Encrypted Traffic',
                          value: vpnRepo.formattedTotalDataTransferred,
                          icon: Icons.data_usage_rounded,
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryText,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PAST SESSIONS',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.secondaryText,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Session Tiles
                      for (final (index, session) in sessions.indexed)
                        AnimatedFadeSlide(
                          key: ValueKey(session.id),
                          delayMs:
                              Motion.staggerStepMs * (2 + index.clamp(0, 8)),
                          offset: const Offset(0, 0.2),
                          child: _buildSessionCard(
                            context,
                            session,
                            dateFormat,
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    VpnSession session,
    DateFormat dateFormat,
  ) {
    final isFailed = session.status == 'failed';
    final isConnected = session.status == 'connected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFailed
              ? AppColors.errorStatus.withValues(alpha: 0.35)
              : AppColors.borderDivider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => SessionDetailsSheet(session: session),
            );
          },
          splashColor: AppColors.primaryText.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryText.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isFailed
                        ? AppColors.errorContainer
                        : AppColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFailed
                          ? AppColors.errorStatus.withValues(alpha: 0.4)
                          : AppColors.borderDivider,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isFailed
                        ? Icons.error_outline_rounded
                        : (isConnected
                              ? Icons.shield_rounded
                              : Icons.lock_outline_rounded),
                    color: isFailed
                        ? AppColors.errorStatus
                        : (isConnected
                              ? AppColors.connectedStatus
                              : AppColors.primaryText),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              session.serverName,
                              style: AppTextStyles.labelLg.copyWith(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isFailed
                                  ? AppColors.errorContainer
                                  : (isConnected
                                        ? const Color(0xFF14241B)
                                        : AppColors.elevatedSurface),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isFailed ? 'FAILED' : session.durationFormatted,
                              style: AppTextStyles.labelSm.copyWith(
                                color: isFailed
                                    ? AppColors.errorStatus
                                    : (isConnected
                                          ? AppColors.connectedStatus
                                          : AppColors.secondaryText),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            dateFormat.format(session.startedAt),
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.mutedText,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            session.bytesTransferredFormatted,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
