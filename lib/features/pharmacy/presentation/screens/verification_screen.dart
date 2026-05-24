import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/enums.dart';
import '../../../../widgets/glass_app_bar.dart';
import '../../../auth/presentation/screens/success_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _licenseController = TextEditingController();
  final List<TextEditingController> _tokenControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _tokenFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _uploadedFile;

  @override
  void dispose() {
    _licenseController.dispose();
    for (var c in _tokenControllers) { c.dispose(); }
    for (var f in _tokenFocusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        title: Text('Verification', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Upload Section
              Text('Upload License', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _uploadedFile = 'license_doc.pdf'),
                child: CustomPaint(
                  painter: _DashedBorderPainter(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 36, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(_uploadedFile ?? 'Tap to upload license file',
                          style: GoogleFonts.inter(color: AppTheme.textSecondaryColor, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // License Number
              Text('License Number', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 8),
              TextFormField(controller: _licenseController, decoration: const InputDecoration(hintText: 'Enter license number')),
              const SizedBox(height: 32),
              // Token Input
              Text('Verification Token', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: SizedBox(
                    width: 48, height: 56,
                    child: TextField(
                      controller: _tokenControllers[i], focusNode: _tokenFocusNodes[i],
                      textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textPrimaryColor),
                      decoration: const InputDecoration(counterText: '', contentPadding: EdgeInsets.symmetric(vertical: 12)),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 5) {
                          _tokenFocusNodes[i + 1].requestFocus();
                        } else if (v.isEmpty && i > 0) {
                          _tokenFocusNodes[i - 1].requestFocus();
                        }
                      },
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Verify Account', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleVerify() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SuccessScreen(userType: UserType.patient)));
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, end > metric.length ? metric.length : end), paint);
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
