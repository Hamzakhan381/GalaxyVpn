import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../common/cyber_background.dart';
import '../common/primary_button.dart';

class ReportProblemView extends StatefulWidget {
  const ReportProblemView({super.key});

  @override
  State<ReportProblemView> createState() => _ReportProblemViewState();
}

class _ReportProblemViewState extends State<ReportProblemView> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  String _problemType = 'Connection Dropped';
  bool _includeLogs = true;
  bool _isSubmitting = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Report a Problem',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
      ),
      body: CyberBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _isSuccess ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          AnimatedFadeSlide(
            delayMs: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnostic Feedback',
                  style: AppTextStyles.headlineLg.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Help improve Shark VPN by reporting protocol failures, unreachable nodes, or UI bugs.',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Issue Category',
                  style: AppTextStyles.labelLg.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _problemType,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceElevated,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (val) {
                        if (val != null) setState(() => _problemType = val);
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'Connection Dropped',
                          child: Text('Connection Dropped'),
                        ),
                        DropdownMenuItem(
                          value: 'Handshake Timeout',
                          child: Text('Handshake Timeout'),
                        ),
                        DropdownMenuItem(
                          value: 'Server Unreachable',
                          child: Text('Server Unreachable'),
                        ),
                        DropdownMenuItem(
                          value: 'VPN Permission Issue',
                          child: Text('VPN Permission Issue'),
                        ),
                        DropdownMenuItem(
                          value: 'Other Bug',
                          child: Text('Other UI/App Bug'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AnimatedFadeSlide(
            delayMs: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: AppTextStyles.labelLg.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    fillColor: AppColors.cardBackground,
                    hintText: 'Describe what occurred, node selected, and behavior...',
                    hintStyle: TextStyle(color: AppColors.mutedText),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please describe the problem.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AnimatedFadeSlide(
            delayMs: 180,
            child: Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Include Anonymous Diagnostics',
                        style: AppTextStyles.labelMd.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'App version & last error code only',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _includeLogs,
                    activeThumbColor: AppColors.pureWhite,
                    activeTrackColor: AppColors.connectedStatus,
                    onChanged: (v) => setState(() => _includeLogs = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          AnimatedFadeSlide(
            delayMs: 240,
            child: PrimaryButton(
              text: 'Submit Report',
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.connectedStatus.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.connectedStatus.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.connectedStatus.withValues(alpha: 0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.connectedStatus,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Report Submitted',
            style: AppTextStyles.headlineMd.copyWith(
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for assisting the academic testing team with feedback.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            text: 'Return',
            onPressed: () => Navigator.of(context).pop(),
            width: 160,
          ),
        ],
      ),
    );
  }
}
