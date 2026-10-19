import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../data/models/vpn_server.dart';
import '../common/country_badge.dart';
import '../common/primary_button.dart';

class ServerDetailsSheet extends StatelessWidget {
  final VpnServer server;
  final VoidCallback onConnect;

  const ServerDetailsSheet({
    super.key,
    required this.server,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
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
          // Drag handle
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
            children: [
              CountryBadge(
                countryCode: server.countryCode,
                size: 48,
                darkMode: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.country,
                      style: AppTextStyles.headlineSm.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      server.city.isNotEmpty ? server.city : server.host,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDivider, width: 1),
                ),
                child: Text(
                  server.protocol,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderDivider),
          const SizedBox(height: 16),

          // Specs Grid
          _buildRow('Ping Latency', server.pingDisplay),
          const SizedBox(height: 12),
          _buildRow('Reported Speed', server.speedDisplay),
          const SizedBox(height: 12),
          _buildRow('Relay Hostname', server.host),
          const SizedBox(height: 12),
          _buildRow(
            'Relay Operator',
            server.operator.isNotEmpty
                ? server.operator
                : 'Community Volunteer',
          ),
          const SizedBox(height: 12),
          _buildRow('Active Sessions', '${server.numVpnSessions} users'),

          const SizedBox(height: 24),
          PrimaryButton(text: 'Connect to this Server', onPressed: onConnect),
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
