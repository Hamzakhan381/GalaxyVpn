import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../domain/repositories/auth_repository.dart';
import '../common/cyber_background.dart';
import '../common/primary_button.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthRepository>();
      await auth.requestPasswordReset(_emailController.text.trim());
      setState(() => _submitted = true);
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CyberBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: _submitted ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forgot Your Password?',
                  style: AppTextStyles.headlineLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the email address registered with your Galaxy VPN profile and we will generate recovery instructions.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (_errorMessage != null) ...[
            AnimatedFadeSlide(
              delay: Duration.zero,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorStatus.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.errorStatus.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.errorStatus,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.errorStatus,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Address',
                  style: AppTextStyles.labelLg.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'student@university.edu',
                    hintStyle: const TextStyle(color: AppColors.mutedText),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.secondaryText,
                    ),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.pureWhite,
                        width: 1.2,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!val.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 180),
            child: PrimaryButton(
              text: 'Send Reset Instructions',
              isLoading: _isLoading,
              onPressed: _handleReset,
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
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 50),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.connectedStatus.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.connectedStatus.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.connectedStatus.withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: AppColors.connectedStatus,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 120),
            child: Text(
              'Check Your Inbox',
              style: AppTextStyles.headlineMd.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 180),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'If an account matches ${_emailController.text.trim()}, recovery steps have been dispatched.',
                style: AppTextStyles.bodyMd.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 240),
            child: PrimaryButton(
              text: 'Return to Sign In',
              onPressed: () => Navigator.of(context).pop(),
              width: 200,
            ),
          ),
        ],
      ),
    );
  }
}
