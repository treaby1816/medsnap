import 'package:flutter/material.dart';

class VailLoader extends StatelessWidget {
  const VailLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        // Using withValues (modern) instead of withOpacity (deprecated)
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC5B13)),
        backgroundColor: const Color(0xFFEC5B13).withValues(alpha: 0.1),
        strokeWidth: 3,
      ),
    );
  }
}