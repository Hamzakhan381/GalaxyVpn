import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../data/models/vpn_session.dart';

class SessionDetailsSheet extends StatelessWidget {
  final VpnSession session;

  const SessionDetailsSheet({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • HH:mm:ss');
    final isFailed = session.status == 'failed';
    final isConnected = session.status == 'connected';

    final Color badgeBg = isFailed
        ? AppColors.errorContainer
        : (isConnected ? const Color(0xFF14241B) : AppColors.elevatedSurface);
    final Color badgeColor = isFailed
        ? AppColors.errorStatus
        : (isConnected ? AppColors.connectedStatus : AppColors.secondaryText);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.borderDivider, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black, blurRadius: 24, offset: Offset(0, -8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session Details',
                style: AppTextStyles.headlineSm.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  session.status.toUpperCase(),
                  style: AppTextStyles.labelSm.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderDivider),
          const SizedBox(height: 16),
          _buildRow('Relay Node', session.serverName),
          const SizedBox(height: 12),
          _buildRow('Started At', dateFormat.format(session.startedAt)),
          const SizedBox(height: 12),
          _buildRow(
            'Ended At',
            session.endedAt != null
                ? dateFormat.format(session.endedAt!)
                : 'Still Active',
          ),
          const SizedBox(height: 12),
          _buildRow('Total Duration', session.durationFormatted),
          const SizedBox(height: 12),
          _buildRow('Traffic Transferred', session.bytesTransferredFormatted),
          if (session.errorMessage != null &&
              session.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.errorStatus.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Error: ${session.errorMessage}',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.errorStatus,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.secondaryText),
        ),
        Text(
          value,
          style: AppTextStyles.labelLg.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
