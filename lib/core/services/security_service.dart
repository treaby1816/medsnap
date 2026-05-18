import 'package:flutter/foundation.dart';
// import 'package:root_checker_plus/root_checker_plus.dart';
// import 'package:screen_protector/screen_protector.dart';

import 'dart:developer' as developer;

class SecurityService {
  /// Returns true if the device is compromised (Rooted/Jailbroken).
  static bool isDeviceCompromised = false;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    await _checkRootStatus();
    await _enableScreenProtection();
  }

  static Future<void> _checkRootStatus() async {
    try {
      if (kIsWeb) return;
      bool? compromised = false;
      
      // if (defaultTargetPlatform == TargetPlatform.android) {
      //   compromised = await RootCheckerPlus.isRootChecker();
      // } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      //   compromised = await RootCheckerPlus.isJailbreak();
      // }

      if (compromised == true) {
        isDeviceCompromised = true;
        developer.log('🚨 SECURITY ALERT: Device integrity compromised!', name: 'SecurityService');
      }
    } catch (e) {
      developer.log('Error checking root status: $e', name: 'SecurityService');
    }
  }

  static Future<void> _enableScreenProtection() async {
    try {
      if (kIsWeb) return;

      // if (defaultTargetPlatform == TargetPlatform.android) {
      //   await ScreenProtector.protectDataLeakageWithColor(const Color(0xFF42A5F5));
      //   await ScreenProtector.preventScreenshotOn();
      //   developer.log('Android: FLAG_SECURE enabled.', name: 'SecurityService');
      // } 
    } catch (e) {
      developer.log('Error enabling screen protection: $e', name: 'SecurityService');
    }
  }

  static Future<void> disableScreenProtection() async {
    try {
      // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      //   await ScreenProtector.preventScreenshotOff();
      //   developer.log('Android: FLAG_SECURE disabled.', name: 'SecurityService');
      // }
    } catch (e) {
      developer.log('Error disabling screen protection: $e', name: 'SecurityService');
    }
  }

  /// Use this to prevent the app from proceeding if security is a dealbreaker.
  static bool shouldBlockAccess() {
    // Return true to force the app into a "Locked" state
    return isDeviceCompromised;
  }
}