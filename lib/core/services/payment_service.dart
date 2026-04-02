import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import '../constants/api_keys.dart';

class PaymentService {
  Future<bool> processPaystackPayment({
    required BuildContext context,
    required String email,
    required double amount,
    required String reference,
  }) async {
    try {
      bool paymentSuccessful = false;

      await FlutterPaystackPlus.openPaystackPopup(
        context: context,
        publicKey: ApiKeys.paystackPublicKey,
        customerEmail: email,
        amount: (amount * 100).toInt().toString(), // Amount in kobo
        reference: reference,
        onClosed: () {
          debugPrint('Paystack closed');
        },
        onSuccess: () {
          paymentSuccessful = true;
          debugPrint('Paystack success');
        },
      );

      return paymentSuccessful;
    } catch (e) {
      debugPrint('Paystack Error: $e');
      rethrow;
    }
  }
}
