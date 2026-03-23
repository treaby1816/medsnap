import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A glassmorphic app bar that uses [BackdropFilter] for a frosted-glass
/// translucent effect. Drop-in replacement for [AppBar] that embodies the
/// Antigravity "floating header" aesthetic.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final double blur;

  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.blur = 12.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + 1.0 + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppTheme.darkSurfaceColor.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.80);
    final borderBottom = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppTheme.primaryColor.withValues(alpha: 0.08);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(bottom: BorderSide(color: borderBottom, width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: NavigationToolbar(
                    leading: leading ??
                        (Navigator.canPop(context)
                            ? IconButton(
                                icon: const Icon(Icons.arrow_back, size: 22),
                                color: isDark
                                    ? Colors.white
                                    : AppTheme.textPrimaryColor,
                                onPressed: () => Navigator.pop(context),
                              )
                            : null),
                    middle: title,
                    trailing: actions != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!,
                          )
                        : null,
                    centerMiddle: centerTitle,
                    middleSpacing: NavigationToolbar.kMiddleSpacing,
                  ),
                ),
                if (bottom != null) bottom!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
