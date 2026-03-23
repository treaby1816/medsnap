import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A glassmorphic Floating Action Button using [BackdropFilter] to create
/// the Antigravity "floating element" aesthetic — translucent surface,
/// subtle shadow, and a primary-colored icon.
class AntigravityFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;
  final double blur;

  const AntigravityFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 56.0,
    this.blur = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurfaceColor.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: size * 0.45,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
