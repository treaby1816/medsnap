import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:developer' as developer;

class ChatbotMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatbotMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatbotService extends StateNotifier<List<ChatbotMessage>> {
  ChatbotService() : super([
    ChatbotMessage(
      text: "Hello! I'm VailBot, your AI health assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  GenerativeModel? _model;
  ChatSession? _chat;

  // SYSTEM PROMPT: This "trains" the bot on VailMeds logic
  final String _systemPrompt = """
You are VailBot, the official AI Support Assistant for VailMeds, a premium pharmacy and health platform. 

CORE KNOWLEDGE:
- VailMeds provides door-step medication delivery, health record management, and pharmacy verification.
- Users can be either Patients or Pharmacies.
- Pharmacies must be verified (Name, Brand, License) before they can list inventory.
- Patients can upload prescriptions for verification.

TONE:
- Clinical, professional, yet empathetic.
- Concise and efficient.
- If a user asks for human support, tell them you'll connect them and show the "Talk to a Human" option.

CONSTRAINTS:
- Do NOT provide specific medical prescriptions or diagnoses. 
- Refer serious health concerns to a doctor or emergency services.
- If you don't know something about VailMeds, offer to connect them to a human agent.
""";

  void initialize(String apiKey) {
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
      developer.log('ChatbotService: No API key provided (GEMINI_API_KEY environment variable is empty). Running in Mock mode.', name: 'VailBot');
      return;
    }
    
    developer.log('ChatbotService: Gemini API key detected. Initializing AI...', name: 'VailBot');
    
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt),
      );
      _chat = _model!.startChat();
    } catch (e) {
      developer.log('ChatbotService Initialization Error: $e', name: 'VailBot');
    }
  }

  Future<void> sendMessage(String text) async {
    // 1. Add user message
    final userMsg = ChatbotMessage(text: text, isUser: true, timestamp: DateTime.now());
    state = [...state, userMsg];

    // 2. Get AI Response
    if (_chat != null) {
      try {
        final response = await _chat!.sendMessage(Content.text(text));
        final aiText = response.text ?? "I'm sorry, I couldn't process that. Would you like to speak with a human?";
        _addAiMessage(aiText);
      } catch (e) {
        developer.log('Chatbot AI Error: $e', name: 'VailBot');
        _addAiMockResponse(text);
      }
    } else {
      // Mock mode for local testing or missing key
      _addAiMockResponse(text);
    }
  }

  void _addAiMessage(String text) {
    state = [...state, ChatbotMessage(text: text, isUser: false, timestamp: DateTime.now())];
  }

  void _addAiMockResponse(String text) {
    // Intelligent Mock responses based on keywords to simulate "training"
    String response = "I'm currently optimizing my intelligence. For high-fidelity answers, please ensure the Gemini API key is configured. How else can I help?";
    
    final lower = text.toLowerCase();
    if (lower.contains('human') || lower.contains('support') || lower.contains('call')) {
      response = "I understand you'd like to reach our human team. You can use the 'Contact Human Support' button at the top of this window or call +234 801 234 5678.";
    } else if (lower.contains('pharmacy') || lower.contains('verify')) {
      response = "VailMeds requires all pharmacies to be verified with a valid license and store name for security standards.";
    } else if (lower.contains('order') || lower.contains('delivery')) {
      response = "Our delivery team is hardware-accelerated! Most orders are delivered within 2-4 hours after pharmacy confirmation.";
    }

    Future.delayed(const Duration(seconds: 1), () {
      _addAiMessage(response);
    });
  }

  void clearChat() {
    state = [state.first];
    _chat = _model?.startChat();
  }
}

final chatbotProvider = StateNotifierProvider<ChatbotService, List<ChatbotMessage>>((ref) {
  final service = ChatbotService();
  // HARDCODED: Initializing with the verified production key
  service.initialize('AIzaSyB9K07Jcwfe4_3aJoAggdo_XQdal5pJZu0'); 
  return service;
});
