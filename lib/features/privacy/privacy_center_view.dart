import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../common/cyber_background.dart';

class PrivacyCenterView extends StatelessWidget {
  const PrivacyCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Privacy Center',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
      ),
      body: CyberBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              AnimatedFadeSlide(
                delayMs: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Data Philosophy',
                      style: AppTextStyles.headlineLg.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Galaxy VPN is designed with transparency and academic integrity. We explicitly disclose how network traffic and local metadata are handled.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AnimatedFadeSlide(
                delayMs: 60,
                child: _buildSection(
                  title: '1. Android VpnService & Routing',
                  content: 'We invoke the standard Android VpnService API to create a local virtual network interface (TUN). All outgoing packets are encapsulated into OpenVPN protocol datagrams and forwarded directly to the chosen public relay server.',
                ),
              ),
              const SizedBox(height: 16),
              AnimatedFadeSlide(
                delayMs: 120,
                child: _buildSection(
                  title: '2. What We DO NOT Inspect',
                  content: 'Galaxy VPN never performs Deep Packet Inspection (DPI), DNS sniffing, credential harvesting, or browsing history monitoring. We do not insert advertisements or inject third-party scripts into your traffic.',
                ),
              ),
              const SizedBox(height: 16),
              AnimatedFadeSlide(
                delayMs: 180,
                child: _buildSection(
                  title: '3. Local Device Storage',
                  content: 'Session duration, timestamp records, and server bookmarks are saved exclusively in your device\'s local storage (SharedPreferences). You can purge this data at any moment via the Settings screen.',
                ),
              ),
              const SizedBox(height: 16),
              AnimatedFadeSlide(
                delayMs: 240,
                child: _buildSection(
                  title: '4. Public Relay Infrastructure',
                  content: 'Galaxy VPN discovers community relays provided by university networks and research volunteers. While traffic between your device and the relay is encrypted, relay operators retain standard server connection logs according to their regional laws.',
                ),
              ),
              const SizedBox(height: 16),
              AnimatedFadeSlide(
                delayMs: 300,
                child: _buildSection(
                  title: '5. Academic Non-Monetization',
                  content: 'This application is an educational prototype developed for Mobile App Development. It does not sell user profiles, host telemetry trackers, or charge subscription fees.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.labelLg.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.secondaryText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
