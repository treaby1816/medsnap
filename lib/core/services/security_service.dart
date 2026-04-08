import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:root_checker_plus/root_checker_plus.dart';
import 'package:screen_protector/screen_protector.dart';
import 'dart:developer' as developer;

class SecurityService {
  /// Returns true if the device is compromised (Rooted/Jailbroken).
  static bool isDeviceCompromised = false;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    // 1. Root/Jailbreak Detection
    await _checkRootStatus();

    // 2. Prevent Screenshots & Screen Recording
    await _enableScreenProtection();
  }

  static Future<void> _checkRootStatus() async {
    try {
      bool? compromised = false;
      
      if (Platform.isAndroid) {
        compromised = await RootCheckerPlus.isRootChecker();
      } else if (Platform.isIOS) {
        compromised = await RootCheckerPlus.isJailbreak();
      }

      if (compromised == true) {
        isDeviceCompromised = true;
        developer.log('🚨 SECURITY ALERT: Device integrity compromised!', name: 'SecurityService');
        // Implementation Note: You can use this flag in your main.dart to show 
        // a "Device Not Supported" screen instead of the login page.
      }
    } catch (e) {
      developer.log('Error checking root status: $e', name: 'SecurityService');
    }
  }

  static Future<void> _enableScreenProtection() async {
    try {
      if (kIsWeb) return;

      if (Platform.isAndroid) {
        // Prevents screenshots, screen recording, and content showing in App Switcher
        await ScreenProtector.protectDataLeakageWithColor(const Color(0xFF42A5F5));
        await ScreenProtector.preventScreenshotOn();
        developer.log('Android: FLAG_SECURE enabled.', name: 'SecurityService');
      } 
      
      // Note for iOS: 
      // ScreenProtector does not support iOS natively either. iOS handles screenshots differently.
      // To hide content in the App Switcher on iOS, you typically need to 
      // add a blurred overlay in the AppDelegate.swift.
    } catch (e) {
      developer.log('Error enabling screen protection: $e', name: 'SecurityService');
    }
  }

  static Future<void> disableScreenProtection() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await ScreenProtector.preventScreenshotOff();
        developer.log('Android: FLAG_SECURE disabled.', name: 'SecurityService');
      }
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