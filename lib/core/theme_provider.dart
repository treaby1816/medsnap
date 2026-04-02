import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the current theme mode (Light/Dark/System)
final themeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);
