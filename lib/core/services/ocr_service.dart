import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> extractDrugName(File imageFile) async {
    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // Simple heuristic: Look for keywords or use regex to extract possible drug names
      // For a real app, this would be more complex or use a medical NER model
      String fullText = recognizedText.text;
      debugPrint('Recognized Text: $fullText');

      // Return the most prominent word that looks like a drug (mock logic for now)
      // In production, we'd match against our Firestore products collection
      return _parseDrugName(fullText);
    } catch (e) {
      debugPrint('Error recognizing text: $e');
      return null;
    }
  }

  String? _parseDrugName(String text) {
    if (text.isEmpty) return null;
    
    // Look for common drug patterns (e.g., words followed by mg/ml)
    final RegExp drugRegExp = RegExp(r'([A-Za-z]+)\s?\d+(\s?mg|ml|mcg)', caseSensitive: false);
    final match = drugRegExp.firstMatch(text);
    
    if (match != null) {
      return match.group(1);
    }

    // Fallback: first word longer than 3 chars (very basic)
    final words = text.split(RegExp(r'\s+'));
    for (var word in words) {
      if (word.length > 5) return word;
    }

    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
