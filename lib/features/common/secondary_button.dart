import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// Secondary action button using charcoal surfaces with white text and subtle borders.
class SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? leading;
  final double? width;
  final Color? textColor;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.leading,
    this.width,
    this.textColor,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;

    return AnimatedScale(
      scale: _isPressed && isEnabled ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: 52,
        child: GestureDetector(
          onTapDown: isEnabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: () => setState(() => _isPressed = false),
          child: OutlinedButton(
            onPressed: isEnabled ? widget.onPressed : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.textColor ?? AppColors.primaryText,
              backgroundColor: _isPressed
                  ? AppColors.elevatedSurface
                  : AppColors.cardBackground,
              side: BorderSide(
                color: _isPressed
                    ? AppColors.primaryText.withValues(alpha: 0.3)
                    : AppColors.borderDivider,
                width: 1.1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLg.copyWith(
                      color:
                          widget.textColor ??
                          (isEnabled
                              ? AppColors.primaryText
                              : AppColors.mutedText),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
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
