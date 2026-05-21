import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static String get paystackPublicKey => dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';
  static String get paystackSecretKey => dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';
  static String get flutterwavePublicKey => dotenv.env['FLUTTERWAVE_PUBLIC_KEY'] ?? '';

  // Add other keys here as needed for future integrations (e.g., Google Maps, etc.)
}
