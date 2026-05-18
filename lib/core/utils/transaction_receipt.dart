
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ─────────────────────────────────────────────────────────────────────
// TRANSACTION RECEIPT GENERATOR — VailMeds Digital Invoice
// ─────────────────────────────────────────────────────────────────────

class MedicationItem {
  final String name;
  final String dosage;
  final int quantity;
  final double unitPrice;

  const MedicationItem({
    required this.name,
    required this.dosage,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

class TransactionReceipt {
  final String orderId;
  final DateTime timestamp;
  final List<MedicationItem> items;
  final double totalAmount;
  final double taxRate;
  final String patientName;
  final String patientId;
  final String pharmacyName;
  final String pharmacyLicenseId;
  final String pharmacyId;

  TransactionReceipt({
    required this.orderId,
    required this.timestamp,
    required this.items,
    required this.totalAmount,
    this.taxRate = 0.075, // 7.5% VAT
    required this.patientName,
    required this.patientId,
    required this.pharmacyName,
    required this.pharmacyLicenseId,
    required this.pharmacyId,
  });

  static const _primaryColor = PdfColor.fromInt(0xFFEC5B13);
  static const _slateColor = PdfColor.fromInt(0xFF0F172A);
  static const _grayColor = PdfColor.fromInt(0xFF64748B);
  static const _surfaceColor = PdfColor.fromInt(0xFFF8F6F6);

  /// Generates the audit-grade PDF receipt.
  Future<Uint8List> generatePdf() async {
    final pdf = pw.Document(
      title: 'VailMeds Digital Invoice - $orderId',
      author: 'VailMeds Clinical Concierge',
    );

    final dateStr = DateFormat('MMMM dd, yyyy').format(timestamp);
    final timeStr = DateFormat('hh:mm a').format(timestamp);
    final taxAmount = totalAmount * taxRate;
    final grandTotal = totalAmount + taxAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('VAILMEDS', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
                    pw.Text('Digital Invoice', style: const pw.TextStyle(fontSize: 10, color: _grayColor)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: _slateColor)),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF0FDF4),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text('PAID', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF22C55E))),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Container(width: double.infinity, height: 2, color: _primaryColor),
            pw.SizedBox(height: 20),

            // ── Transaction Info ──
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _surfaceColor,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _infoBlock('Transaction ID', orderId),
                  _infoBlock('Date', dateStr),
                  _infoBlock('Time', timeStr),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Parties ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILLED TO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _grayColor)),
                        pw.SizedBox(height: 6),
                        pw.Text(patientName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _slateColor)),
                        pw.Text('Patient ID: $patientId', style: const pw.TextStyle(fontSize: 9, color: _grayColor)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DISPENSING PHARMACY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _grayColor)),
                        pw.SizedBox(height: 6),
                        pw.Text(pharmacyName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _slateColor)),
                        pw.Text('License: $pharmacyLicenseId', style: const pw.TextStyle(fontSize: 9, color: _grayColor)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── Itemization Table ──
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: _slateColor),
              headerHeight: 30,
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellHeight: 26,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              headers: ['#', 'Medication', 'Dosage', 'Qty', 'Unit Price', 'Total'],
              data: List.generate(items.length, (i) {
                final item = items[i];
                return [
                  (i + 1).toString(),
                  item.name,
                  item.dosage,
                  item.quantity.toString(),
                  _formatCurrency(item.unitPrice),
                  _formatCurrency(item.total),
                ];
              }),
            ),
            pw.SizedBox(height: 12),

            // ── Totals ──
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 200,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal', _formatCurrency(totalAmount)),
                    _totalRow('VAT (${(taxRate * 100).toStringAsFixed(1)}%)', _formatCurrency(taxAmount)),
                    pw.Divider(color: _grayColor, thickness: 0.5),
                    _totalRow('TOTAL', _formatCurrency(grandTotal), bold: true, color: _primaryColor),
                  ],
                ),
              ),
            ),
            pw.Spacer(),

            // ── Clinical Note ──
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _grayColor, width: 0.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 4,
                    height: 30,
                    color: _primaryColor,
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Electronically verified by VailMeds Concierge',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _slateColor),
                        ),
                        pw.Text(
                          'This receipt serves as proof of transaction processed through the VailMeds Clinical Concierge platform. '
                          'Transaction ID: $orderId — ${DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp)} UTC.',
                          style: const pw.TextStyle(fontSize: 7, color: _grayColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Generates the PDF and uploads to Supabase Storage.
  Future<String?> generateAndStore() async {
    try {
      final pdfBytes = await generatePdf();
      final path = '$orderId.pdf';
      await Supabase.instance.client.storage
          .from('receipts')
          .uploadBinary(path, pdfBytes, fileOptions: const FileOptions(upsert: true, contentType: 'application/pdf'));

      final url = Supabase.instance.client.storage.from('receipts').getPublicUrl(path);
      debugPrint('Receipt stored: $url');
      return url;
    } catch (e) {
      debugPrint('Failed to store receipt: $e');
      return null;
    }
  }

  /// Creates a TransactionReceipt from a Supabase order map.
  static Future<TransactionReceipt?> fromOrderDoc(Map<String, dynamic> data) async {
    try {
      if (data.isEmpty) return null;

      final itemsList = (data['items'] as List<dynamic>?)?.map((item) {
        final m = item as Map<String, dynamic>;
        return MedicationItem(
          name: m['name'] ?? 'Medication',
          dosage: m['dosage'] ?? 'N/A',
          quantity: m['quantity'] ?? 1,
          unitPrice: (m['price'] ?? 0).toDouble(),
        );
      }).toList() ?? [];

      return TransactionReceipt(
        orderId: data['id'].toString(),
        timestamp: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) ?? DateTime.now() : DateTime.now(),
        items: itemsList,
        totalAmount: (data['totalAmount'] ?? 0).toDouble(),
        patientName: data['patientName'] ?? 'Patient',
        patientId: data['patientId'] ?? 'N/A',
        pharmacyName: data['pharmacyName'] ?? 'Pharmacy',
        pharmacyLicenseId: data['pharmacyLicenseId'] ?? 'N/A',
        pharmacyId: data['pharmacyId'] ?? '',
      );
    } catch (e) {
      debugPrint('Error creating receipt from order: $e');
      return null;
    }
  }

  static pw.Widget _infoBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _grayColor)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _slateColor)),
      ],
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: _grayColor)),
          pw.Text(value, style: pw.TextStyle(fontSize: bold ? 12 : 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? _slateColor)),
        ],
      ),
    );
  }

  static String _formatCurrency(double amount) => '₦${NumberFormat('#,##0.00').format(amount)}';
}

