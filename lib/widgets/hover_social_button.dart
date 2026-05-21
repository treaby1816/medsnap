import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

/// A premium, interactive social login button with beautiful hover and press animations.
/// Tailored for the VailMeds "Clinical Concierge" aesthetic.
class HoverSocialButton extends StatefulWidget {
  final Widget iconWidget;
  final String label;
  final VoidCallback? onTap;
  final String? tagText;
  final Color hoverColor;

  const HoverSocialButton({
    super.key,
    required this.iconWidget,
    required this.label,
    required this.onTap,
    this.tagText,
    this.hoverColor = const Color(0xFF4285F4), // Default to Google Blue, or custom per brand
  });

  @override
  State<HoverSocialButton> createState() => _HoverSocialButtonState();
}

class _HoverSocialButtonState extends State<HoverSocialButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onTap != null;
    
    // Determine the theme colors
    final Color borderGlowColor = isEnabled ? widget.hoverColor : AppTheme.borderColor;
    final Color baseBgColor = isEnabled ? Colors.white : AppTheme.backgroundColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        MouseRegion(
          onEnter: (_) {
            if (isEnabled) setState(() => _isHovered = true);
          },
          onExit: (_) {
            if (isEnabled) {
              setState(() {
                _isHovered = false;
                _isPressed = false;
              });
            }
          },
          cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTapDown: (_) {
              if (isEnabled) setState(() => _isPressed = true);
            },
            onTapUp: (_) {
              if (isEnabled) setState(() => _isPressed = false);
            },
            onTapCancel: () {
              if (isEnabled) setState(() => _isPressed = false);
            },
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 100,
              height: 90,
              transform: Matrix4.identity()
                ..setTranslationRaw(0.0, _isHovered ? (_isPressed ? -1.0 : -4.0) : 0.0, 0.0)
                ..scaleByDouble(
                  _isHovered ? (_isPressed ? 0.98 : 1.03) : 1.0,
                  _isHovered ? (_isPressed ? 0.98 : 1.03) : 1.0,
                  1.0,
                  1.0,
                ),
              decoration: BoxDecoration(
                color: baseBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? borderGlowColor.withValues(alpha: 0.6)
                      : AppTheme.borderColor.withValues(alpha: 0.8),
                  width: _isHovered ? 1.8 : 1.5,
                ),
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(
                      color: borderGlowColor.withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _isHovered ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: widget.iconWidget,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w600,
                      color: isEnabled ? AppTheme.textPrimaryColor : AppTheme.textTertiaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.tagText != null)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAB308),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEAB308).withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.tagText!,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
      ],
    );
  }
}
