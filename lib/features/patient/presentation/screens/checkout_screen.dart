import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> cartData; // Simple mock cart
  const CheckoutScreen({super.key, required this.cartData});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _currentStep = 0;
  final _addressController = TextEditingController(text: '123 Lekki Phase 1, Lagos');
  
  // Field is now used to control UI loading states
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
        ),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          // Prevent interaction if already processing
          if (_isProcessing) return;

          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _handlePayment();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0 && !_isProcessing) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    // Disable button visually and functionally during processing
                    onPressed: _isProcessing ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.6),
                    ),
                    child: _isProcessing 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _currentStep == 2 ? 'Pay Now' : 'Continue',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                  ),
                ),
                if (_currentStep > 0 && !_isProcessing) ...[
                  const SizedBox(width: 16),
                  TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Address'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.floatingShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    enabled: !_isProcessing, // Disable input during processing
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      hintText: 'Enter your delivery address...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.floatingShadow,
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Items Total', '₦4,500'),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Delivery Fee', '₦1,000'),
                  const Divider(height: 32, thickness: 1.5),
                  _buildSummaryRow('Total', '₦5,500', isBold: true),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Payment'),
            isActive: _currentStep >= 2,
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.floatingShadow,
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                leading: const Icon(Icons.credit_card, color: AppTheme.primaryColor),
                title: Text('Paystack Gateway', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                subtitle: const Text('Secure payment via Card or Transfer'),
                trailing: const Icon(Icons.radio_button_checked, color: AppTheme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: GoogleFonts.inter(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
            color: isBold ? AppTheme.primaryColor : null
          )),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    
    // Simulate Paystack processing
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isProcessing = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 24),
            Text('Order Confirmed!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your order will be delivered to ${_addressController.text} within 45 mins.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close checkout
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Back to Home', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}