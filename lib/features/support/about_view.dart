import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../common/app_logo.dart';
import '../common/cyber_background.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'About ${AppConstants.appName}',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
      ),
      body: CyberBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              AnimatedFadeSlide(
                delayMs: 0,
                child: Center(
                  child: Column(
                    children: [
                      const AppLogo(size: 80, showBadge: true),
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.appName,
                        style: AppTextStyles.headlineLg.copyWith(
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version ${AppConstants.appVersion} • Android Client',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedFadeSlide(
                delayMs: 60,
                child: _buildCard(
                  title: 'Academic Context',
                  content: 'Developed as a capstone project for Mobile App Development. The primary goal is exploring real-world Android network engineering, Flutter architecture, and OpenVPN packet encapsulation with a strict focus on privacy.',
                ),
              ),
              const SizedBox(height: 16),
              AnimatedFadeSlide(
                delayMs: 120,
                child: _buildCard(
                  title: 'Design Source of Truth',
                  content: 'Visual system and typography are anchored to a premium obsidian-black and charcoal cybersecurity design language with pure white typography, restrained status indicators, and smooth transitions.',
                ),
              ),
              const SizedBox(height: 16),
              AnimatedFadeSlide(
                delayMs: 180,
                child: _buildCard(
                  title: 'SSTP, OpenVPN & Network Core',
                  content: 'Tunnels run over SSTP, which travels inside a standard TLS connection so it works even on networks that block OpenVPN, with OpenVPN as a fallback. Both feed Android\'s VpnService TUN interface. Relays come from VPN Gate\'s university and community network and from VPNBook\'s free servers in Europe and North America; the app checks each from your network and lists the fastest working server in every country.',
                ),
              ),
              const SizedBox(height: 16),
              AnimatedFadeSlide(
                delayMs: 240,
                child: _buildCard(
                  title: 'License & Attribution',
                  content: 'Built with Flutter 3.47 and Dart 3.13. All third-party packages, licenses, and notices are cataloged in THIRD_PARTY_NOTICES.md.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(18),
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
