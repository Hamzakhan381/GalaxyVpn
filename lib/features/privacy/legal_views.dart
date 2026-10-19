import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../common/cyber_background.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CyberBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms of Service',
                      style: AppTextStyles.headlineLg.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last Updated: Academic Semester 2026',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: _buildParagraph(
                  '1. Educational Nature',
                  'ShieldRoute VPN is developed strictly as a university Mobile App Development academic project for learning Android networking, Flutter state management, and OpenVPN encapsulation protocols.',
                ),
              ),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 160),
                child: _buildParagraph(
                  '2. Public Relay Disclaimer',
                  'Public relays are operated by voluntary academic and community hosts. ShieldRoute does not own or maintain external relay infrastructure and makes no guarantee of 100% uptime, specific bandwidth, or persistent endpoint availability.',
                ),
              ),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 220),
                child: _buildParagraph(
                  '3. Acceptable Use',
                  'Users agree not to utilize this software for unlawful activities, unauthorized penetration testing, spam transmission, or harassment. You remain accountable for compliance with local and international cyber legislation.',
                ),
              ),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 280),
                child: _buildParagraph(
                  '4. Limitation of Liability',
                  'This academic software is provided "AS-IS" without warranty of merchantability or fitness for a particular commercial purpose.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParagraph(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
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
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CyberBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: AppTextStyles.headlineLg.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transparency & Academic Standard',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: _buildParagraph(
                  'Information Collection',
                  'ShieldRoute collects zero personal browsing history, search queries, or transmitted content. When you run the application, local configurations (favorite servers, session history counters) are stored solely on your device.',
                ),
              ),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 160),
                child: _buildParagraph(
                  'Network Routing',
                  'Upon initiating a VPN connection, your IP packets are encapsulated into OpenVPN format and relayed directly through the target gateway. ShieldRoute servers do not intermediate or decrypt this connection.',
                ),
              ),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 220),
                child: _buildParagraph(
                  'Analytics & Third Parties',
                  'ShieldRoute incorporates zero third-party advertising SDKs, behavioral analytics trackers, or user profiling tools.',
                ),
              ),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 280),
                child: _buildParagraph(
                  'Data Retention & Deletion',
                  'You have full autonomy to erase all locally recorded session timestamps and favorite selections at any time through the "Clear Local History" or "Delete Account" buttons in the Settings menu.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParagraph(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
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
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
