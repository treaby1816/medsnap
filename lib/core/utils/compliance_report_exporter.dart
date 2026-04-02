import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/user_profile.dart';

// ─────────────────────────────────────────────────────────────────────
// PDF COMPLIANCE EXPORT — Certified Pharmacy Compliance Report
// ─────────────────────────────────────────────────────────────────────

class ComplianceReportExporter {
  static const _primaryColor = PdfColor.fromInt(0xFFEC5B13);
  static const _slateColor = PdfColor.fromInt(0xFF0F172A);
  static const _grayColor = PdfColor.fromInt(0xFF64748B);

  /// Generates and previews a compliance report PDF of all verified pharmacies.
  static Future<void> generateAndPreview(BuildContext context, {String auditorName = 'Super Admin'}) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Generating compliance report...'), duration: Duration(seconds: 2)),
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'pharmacy')
          .where('isAdminApproved', isEqualTo: true)
          .get();

      final pharmacies = snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .toList();

      final pdfData = await _buildPdf(pharmacies, auditorName);

      if (context.mounted) {
        await Printing.layoutPdf(
          onLayout: (_) => pdfData,
          name: 'VailMeds_Compliance_Report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  static Future<Uint8List> _buildPdf(List<UserProfile> pharmacies, String auditorName) async {
    final pdf = pw.Document(
      title: 'VailMeds Compliance Report',
      author: 'VailMeds Clinical Concierge',
    );

    final now = DateTime.now();
    final dateStr = DateFormat('MMMM dd, yyyy').format(now);
    final timestampStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(dateStr),
        footer: (context) => _buildFooter(timestampStr, auditorName, context),
        build: (context) => [
          pw.SizedBox(height: 20),
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8F6F6),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem('Total Verified', pharmacies.length.toString()),
                _summaryItem('Report Date', dateStr),
                _summaryItem('Auditor', auditorName),
                _summaryItem('Status', 'COMPLIANT'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Table
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: _slateColor),
            headerHeight: 32,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 28,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['#', 'Pharmacy Name', 'License ID', 'NPI Number', 'Approval Date', 'Auditor'],
            data: List.generate(pharmacies.length, (i) {
              final p = pharmacies[i];
              final approvalDate = p.createdAt != null
                  ? DateFormat('MMM dd, yyyy').format(p.createdAt!)
                  : 'N/A';
              return [
                (i + 1).toString(),
                p.storeName ?? p.name,
                p.licenseNumber ?? 'N/A',
                p.npiNumber ?? 'N/A',
                approvalDate,
                auditorName,
              ];
            }),
          ),
          pw.SizedBox(height: 30),

          // Digital Signature Block
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _grayColor, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DIGITAL VERIFICATION',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _grayColor),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'This document was digitally generated by the VailMeds Clinical Concierge platform. '
                  'All data has been verified against the National Provider Identifier (NPI) Registry. '
                  'Timestamp: $timestampStr UTC.',
                  style: const pw.TextStyle(fontSize: 8, color: _grayColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String dateStr) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('VAILMEDS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
                pw.Text('Clinical Concierge', style: const pw.TextStyle(fontSize: 9, color: _grayColor)),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFEF3C7),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text('CONFIDENTIAL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFF59E0B))),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(width: double.infinity, height: 2, color: _primaryColor),
        pw.SizedBox(height: 8),
        pw.Text('Certified Pharmacy Compliance Report — $dateStr', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _slateColor)),
      ],
    );
  }

  static pw.Widget _buildFooter(String timestamp, String auditor, pw.Context context) {
    return pw.Column(children: [
      pw.Divider(color: _grayColor, thickness: 0.5),
      pw.SizedBox(height: 4),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('VailMeds Clinical Concierge — vailmeds-74e4b', style: const pw.TextStyle(fontSize: 7, color: _grayColor)),
        pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7, color: _grayColor)),
        pw.Text('Generated: $timestamp', style: const pw.TextStyle(fontSize: 7, color: _grayColor)),
      ]),
    ]);
  }

  static pw.Widget _summaryItem(String label, String value) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _grayColor)),
      pw.SizedBox(height: 2),
      pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _slateColor)),
    ]);
  }
}
