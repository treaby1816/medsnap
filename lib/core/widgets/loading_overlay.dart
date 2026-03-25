import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vail_meds_v2/core/providers/loading_provider.dart';
import 'package:vail_meds_v2/core/theme.dart';

class GlobalLoadingOverlay extends ConsumerWidget {
  final Widget child;

  const GlobalLoadingOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the global loading state
    final isLoading = ref.watch(loadingProvider);

    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                // Flutter 3.x Compliance: using .withValues
                color: Colors.black.withValues(alpha: 0.2), 
                child: const Center(
                  child: Card(
                    elevation: 8,
                    shape: CircleBorder(),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}