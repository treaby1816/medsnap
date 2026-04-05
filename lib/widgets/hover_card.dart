import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A premium, high-fidelity card wrapper that provides standard 
/// interact-on-hover effects (Lift + Glow + Scale).
/// 
/// Optimized for the VailMeds "Clinical Concierge" aesthetic.
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double liftAmount;
  final double scaleAmount;
  final Color? glowColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.liftAmount = -6.0,
    this.scaleAmount = 1.01,
    this.glowColor,
    this.borderRadius,
    this.padding,
    this.backgroundColor,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(AppTheme.cardRadius);
    final glowColor = widget.glowColor ?? AppTheme.primaryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..setTranslationRaw(0.0, _isHovered ? widget.liftAmount : 0.0, 0.0)
            ..scaleByDouble(_isHovered ? widget.scaleAmount : 1.0, _isHovered ? widget.scaleAmount : 1.0, 1.0, 1.0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            borderRadius: borderRadius,
            border: Border.all(
              color: _isHovered 
                  ? glowColor.withValues(alpha: 0.5) 
                  : AppTheme.borderColor.withValues(alpha: 0.4),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
