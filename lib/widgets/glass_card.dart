import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A glassmorphic card with [BackdropFilter] blur, translucent surface,
/// and subtle floating shadow. Automatically adapts to light/dark mode.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color? color;
  final bool showBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(24.0),
    this.blur = 10.0,
    this.color,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ??
        (isDark
            ? AppTheme.darkSurfaceColor.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.85));
    final borderColorValue = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: showBorder
                ? Border.all(color: borderColorValue, width: 1.5)
                : null,
            boxShadow: AppTheme.floatingShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
