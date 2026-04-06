import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:root_checker_plus/root_checker_plus.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'dart:developer' as developer;

class SecurityService {
  static Future<void> initialize() async {
    if (kIsWeb) return;

    // 1. Root/Jailbreak Detection
    await _checkRootStatus();

    // 2. Prevent Screenshots & Screen Recording
    await _enableScreenProtection();
  }

  static Future<void> _checkRootStatus() async {
    try {
      if (Platform.isAndroid) {
        bool? isRooted = await RootCheckerPlus.isRootChecker();
        if (isRooted == true) {
          developer.log('SECURITY WARNING: Device is Rooted!', name: 'SecurityService');
          // In a real medical app, we might force-close or limit features here.
        }
      } else if (Platform.isIOS) {
        bool? isJailbroken = await RootCheckerPlus.isJailbreak();
        if (isJailbroken == true) {
          developer.log('SECURITY WARNING: Device is Jailbroken!', name: 'SecurityService');
        }
      }
    } catch (e) {
      developer.log('Error checking root status: $e', name: 'SecurityService');
    }
  }

  static Future<void> _enableScreenProtection() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        developer.log('Screen protection (FLAG_SECURE) enabled.', name: 'SecurityService');
      }
    } catch (e) {
      developer.log('Error enabling screen protection: $e', name: 'SecurityService');
    }
  }

  static Future<void> disableScreenProtection() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
        developer.log('Screen protection (FLAG_SECURE) disabled.', name: 'SecurityService');
      }
    } catch (e) {
      developer.log('Error disabling screen protection: $e', name: 'SecurityService');
    }
  }
}
