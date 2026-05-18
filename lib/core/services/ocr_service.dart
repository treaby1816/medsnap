import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, String>> scanPrescription(File imageFile) async {
    // Step 1: Try on-device ML Kit (FREE)
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _textRecognizer.processImage(inputImage);
    final rawText = recognized.text;

    if (rawText.length > 20) {
      // ML Kit got something useful — parse it with regex
      return _extractDrugInfo(rawText);
    }

    // Step 2: ML Kit failed — fallback to Gemini API (costs money, use sparingly)
    return await _geminiFallback(imageFile);
  }

  Map<String, String> _extractDrugInfo(String text) {
    return {
      'drug_name': _extractDrugName(text),
      'dosage': _extractDosage(text),
      'duration': _extractDuration(text),
      'raw_text': text,
    };
  }

  Future<Map<String, String>> _geminiFallback(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) return _extractDrugInfo('');

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{
          'parts': [
            {
              'inlineData': {
                'mimeType': 'image/jpeg',
                'data': base64Image,
              }
            },
            {
              'text': 'Extract from this prescription: drug name, dosage, and duration. Return JSON only: {"drug_name": "", "dosage": "", "duration": ""}'
            }
          ]
        }]
      }),
    );

    try {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      final cleanedText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return Map<String, String>.from(jsonDecode(cleanedText));
    } catch (e) {
      return _extractDrugInfo('');
    }
  }

  String _extractDrugName(String text) {
    final patterns = [
      RegExp(r'(?:Rx|Tabs?|Cap|Syr|Inj)[:\s]+([A-Za-z\s]+\d*mg)', caseSensitive: false),
      RegExp(r'([A-Z][a-z]+(?:\s[A-Z][a-z]+)*)\s+(\d+\s*mg)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1)?.trim() ?? '';
    }
    return '';
  }

  String _extractDosage(String text) {
    final pattern = RegExp(r'(\d+\s*mg|\d+\s*ml|\d+\s*mcg)', caseSensitive: false);
    return pattern.firstMatch(text)?.group(0) ?? '';
  }

  String _extractDuration(String text) {
    final pattern = RegExp(r'(\d+\s*(?:days?|weeks?|months?))', caseSensitive: false);
    return pattern.firstMatch(text)?.group(0) ?? '';
  }

  void dispose() {
    _textRecognizer.close();
  }
}
