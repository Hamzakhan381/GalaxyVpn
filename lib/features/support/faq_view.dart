import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../common/cyber_background.dart';

class FaqView extends StatelessWidget {
  const FaqView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Help & FAQ',
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
                      'Frequently Asked Questions',
                      style: AppTextStyles.headlineLg.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Answers to common operational and architectural questions.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AnimatedFadeSlide(
                delayMs: 60,
                child: _buildFaqItem(
                  'How does ShieldRoute protect my traffic?',
                  'ShieldRoute utilizes standard OpenVPN cryptographic encapsulation. Your network packets are wrapped in encrypted datagrams (typically AES-256 or AES-128 with SHA digests) and sent to the relay endpoint before accessing the broader internet.',
                ),
              ),
              AnimatedFadeSlide(
                delayMs: 120,
                child: _buildFaqItem(
                  'Why is the VPN permission requested?',
                  'Android requires explicit user approval before an application can bind to the Android VpnService subsystem. This ensures only trusted applications can route device traffic.',
                ),
              ),
              AnimatedFadeSlide(
                delayMs: 180,
                child: _buildFaqItem(
                  'Why does latency or ping vary between relays?',
                  'Relay nodes are situated across various global geographical locations (such as Japan, Frankfurt, London, or Singapore). Latency depends on the physical distance between your mobile device and the relay server.',
                ),
              ),
              AnimatedFadeSlide(
                delayMs: 240,
                child: _buildFaqItem(
                  'What does the green "Protected" indicator mean?',
                  'The subtle green indicator confirms that the OpenVPN engine has successfully negotiated the SSL/TLS handshake and that traffic routing through the tunnel is actively operational.',
                ),
              ),
              AnimatedFadeSlide(
                delayMs: 300,
                child: _buildFaqItem(
                  'Can I use the app without creating an account?',
                  'Yes! Guest mode provides 100% full VPN functionality, server discovery, and metric tracking without submitting an email or creating a password.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTextStyles.labelLg.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: AppColors.primaryAccent,
        collapsedIconColor: AppColors.secondaryText,
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
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
