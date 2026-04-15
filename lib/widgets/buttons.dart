import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: (isLoading || onPressed == null) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: cs.onPrimary),
                    SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double width;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: cs.outline),
          foregroundColor: cs.onSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: cs.onSurfaceVariant),
              SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double width;

  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.error,
          disabledBackgroundColor: cs.error.withValues(alpha: 0.5),
          foregroundColor: cs.onError,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.onError),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: cs.onError,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
