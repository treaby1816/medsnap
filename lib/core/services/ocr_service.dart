import 'package:flutter/foundation.dart';

class OCRService {
  // Safe mock for Web so dart.io and native MLKit don't violently crash JS compilation
  Future<String?> extractDrugName(dynamic imageFile) async {
    debugPrint('OCR Scanning not supported natively on Web platform.');
    return null;
  }

  void dispose() {
    // No-op
  }
}
