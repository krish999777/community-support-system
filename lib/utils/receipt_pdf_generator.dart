import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/donor.dart';

class ReceiptPdfGenerator {
  // Helper to load font file from local assets
  static Future<pw.Font> _loadFont(String lang) async {
    try {
      String fontPath = "assets/fonts/NotoSans-Regular.ttf";
      if (lang == "gujarati") {
        fontPath = "assets/fonts/NotoSansGujarati-Regular.ttf";
      } else if (lang == "hindi") {
        fontPath = "assets/fonts/NotoSansDevanagari-Regular.ttf";
      }
      
      final fontData = await rootBundle.load(fontPath);
      return pw.Font.ttf(fontData);
    } catch (e) {
      print("Failed to load custom font $lang: $e. Falling back to Helvetica.");
      return pw.Font.helvetica();
    }
  }

  // Calculate Indian Financial Year from date (starts Apr 1st, ends Mar 31st next year)
  static String _getFinancialYear(DateTime date) {
    int startYear = date.month >= 4 ? date.year : date.year - 1;
    int endYear = (startYear + 1) % 100;
    return "$startYear-${endYear.toString().padLeft(2, '0')}";
  }

  // Format Receipt No (e.g. 0001/2026-27)
  static String formatReceiptNo(String rawReceiptNo, DateTime date) {
    if (rawReceiptNo.contains('/')) return rawReceiptNo;
    String cleanNum = rawReceiptNo.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNum.isEmpty) cleanNum = "1";
    String padded = cleanNum.length >= 4 ? cleanNum : cleanNum.padLeft(4, '0');
    return "$padded/${_getFinancialYear(date)}";
  }

  // Convert English number to words (crores, lakhs, thousands, hundreds)
  static String _convertEnglishNumberToWords(int number) {
    if (number == 0) return "Zero";

    final units = [
      "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
      "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
      "Seventeen", "Eighteen", "Nineteen"
    ];

    final tens = [
      "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
    ];

    String convertLessThanThousand(int n) {
      if (n == 0) return "";
      if (n < 20) return units[n];
      if (n < 100) {
        return "${tens[n ~/ 10]}${n % 10 != 0 ? " ${units[n % 10]}" : ""}";
      }
      return "${units[n ~/ 100]} Hundred${n % 100 != 0 ? " ${convertLessThanThousand(n % 100)}" : ""}";
    }

    String result = "";
    int crores = number ~/ 10000000;
    number %= 10000000;

    int lakhs = number ~/ 100000;
    number %= 100000;

    int thousands = number ~/ 1000;
    number %= 1000;

    if (crores > 0) {
      result += "${convertLessThanThousand(crores)} Crore ";
    }
    if (lakhs > 0) {
      result += "${convertLessThanThousand(lakhs)} Lakh ";
    }
    if (thousands > 0) {
      result += "${convertLessThanThousand(thousands)} Thousand ";
    }
    if (number > 0) {
      result += convertLessThanThousand(number);
    }

    return result.trim();
  }

  // Translate amount to words
  static String _numberToWords(double amount, String lang) {
    int amt = amount.round();
    String words = _convertEnglishNumberToWords(amt);
    return "$words Only";
  }

  static Future<Uint8List> generateReceiptPdf(DonationModel donation, DonorModel donor, String language) async {
    final pdf = pw.Document();
    final font = await _loadFont(language);
    final englishFont = await _loadFont("english");

    // Load logo image from assets
    pw.ImageProvider? logoImageProvider;
    try {
      final logoData = await rootBundle.load("assets/logo.jpg");
      logoImageProvider = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      print("Failed to load logo image: $e");
    }

    // Dictionary of translations
    final translations = {
      "gujarati": {
        "slogan": "।। શ્રી ગણેશાય નમઃ ।।",
        "title": "સમસ્ત દરજી સમાજ બાબરીયાવાડ, મુંબઈ",
        "regNo": "Regd. No. : F 29137",
        "cO": "C/o. રૂમ નં. ૮, હિરવી ચાલ, ગુણાકર કેન્દ્રની પાછળ, સાને ગુરુજી રોડ, તારદેવ, મુંબઈ - ૪૦૦ ૦૩૪",
        "receiptNo": "રસીદ નંબર",
        "date": "તા.",
        "donorName": "શ્રીમાન / શ્રીમતી",
        "village": "ગામ",
        "railway": "હાલ",
        "voluntaryText": "આપના તરફથી સ્વેચ્છાએ દાન રૂપે",
        "rupeesInWords": "અંકે રૂ.",
        "modeNo": "UPI / Cash / Check",
        "bank": "બેન્ક",
        "detail": "વિગત",
        "coop": "સહકાર બદલ આભાર",
        "receiver": "પ્રાપ્તકર્તા",
        "disclaimer": "This is a computer generated donation receipt. Signature not required.",
      },
      "hindi": {
        "slogan": "।। श्री गणेशाय नमः ।।",
        "title": "સમસ્ત દરજી સમાજ બાબરીયાવાડ, મુંબઈ",
        "regNo": "Regd. No. : F 29137",
        "cO": "C/o. रूम नं. ८, हिरवी चाल, गुणकाभाकर केंद्र के पीछे, साने गुरुजी रोड, ताड़देव, मुंबई - ४०० ०३४",
        "receiptNo": "रसीद संख्या",
        "date": "दिनांक",
        "donorName": "श्रीमान / श्रीमती",
        "village": "ग्राम",
        "railway": "वर्तमान",
        "voluntaryText": "आपकी ओर से स्वेच्छा से दान स्वरूप",
        "rupeesInWords": "शब्दों में रु.",
        "modeNo": "UPI / Cash / Check",
        "bank": "बैंक",
        "detail": "विवरण",
        "coop": "सहयोग के लिए धन्यवाद",
        "receiver": "प्राप्तकर्ता",
        "disclaimer": "This is a computer generated donation receipt. Signature not required.",
      },
      "english": {
        "slogan": "|| Shri Ganeshaya Namah ||",
        "title": "Samast Darji Samaj Babariyawad, Mumbai",
        "regNo": "Regd. No. : F 29137",
        "cO": "C/o Room No. 8, Hirvi Chawl, Behind Gunakar Kendra, Sane Guruji Road, Tardeo, Mumbai - 400034",
        "receiptNo": "Receipt No",
        "date": "Date",
        "donorName": "Mr / Mrs",
        "village": "Native Village",
        "railway": "Nearest Station",
        "voluntaryText": "Voluntary donation received with thanks from",
        "rupeesInWords": "Amount in Words",
        "modeNo": "UPI / Cash / Check",
        "bank": "Bank Name",
        "detail": "Purpose / Description",
        "coop": "Thank you for cooperation",
        "receiver": "Receiver",
        "disclaimer": "This is a computer generated donation receipt. Signature not required.",
      }
    };

    final labels = translations[language] ?? translations["english"]!;

    // Display formatted date
    final dateStr = DateFormat('dd/MM/yyyy').format(donation.date);

    // Format receipt number
    final formattedRecNo = formatReceiptNo(donation.receiptNo, donation.date);

    // Custom receipt border decorations (Blue borders matching photo)
    final borderDecoration = pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.blue800, width: 3),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    );

    // Clean donor full name (remove old Mr(Shriman) / Shriman / Mr. prefixes)
    String cleanDonorName = donor.fullName
        .replaceAll(RegExp(r'^(Mr\(Shriman\)|Shriman|Srimati|Mr\.|Mrs\.|Shri)\s*', caseSensitive: false), '')
        .trim();

    // Native Village is stored in address
    final nativeVillage = donor.address ?? "";
    final station = donor.nearestRailwayStation ?? "";

    // Parse bank name (stored in accountNumber)
    final bankName = (donation.mode != "Cash") ? (donation.accountNumber ?? "") : "";

    // Transaction detail text
    String transactionDetails = donation.mode;
    if (donation.mode == "Cheque") {
      transactionDetails = "Cheque No: ${donation.chequeNumber ?? ''}";
    } else if (donation.mode == "UPI" || donation.mode == "Bank Transfer") {
      transactionDetails = "UPI/Ref: ${donation.transactionId ?? ''}";
    }

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(21 * PdfPageFormat.cm, 16 * PdfPageFormat.cm, marginAll: 1 * PdfPageFormat.cm),
        build: (pw.Context ctx) {
          return pw.Container(
            decoration: borderDecoration,
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Slogan
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    labels["slogan"]!,
                    style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                  ),
                ),
                pw.SizedBox(height: 4),

                // Main Title row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Circular Stamp replaced with Samaj Logo
                    logoImageProvider != null
                        ? pw.Image(logoImageProvider, width: 50, height: 50)
                        : pw.Container(width: 50, height: 50),

                    // Header Info
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            labels["title"]!,
                            style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text(
                            labels["regNo"]!,
                            style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text(
                            labels["cO"]!,
                            style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 7, color: PdfColors.grey800),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Section 80G / PAN Box
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey700, width: 1),
                      ),
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Deduction u/s 80G",
                            style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 7, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            "PAN : AAGTS1081B",
                            style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 7, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Divider(color: PdfColors.blue900, thickness: 1.5),

                // Receipt No and Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          "${labels["receiptNo"]!}: ",
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          formattedRecNo,
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          "${labels["date"]!} ",
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          dateStr,
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Donor Name Row
                pw.Row(
                  children: [
                    pw.Text(
                      "${labels["donorName"]!}: ",
                      style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          cleanDonorName,
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),

                // Native Village & Current Station
                pw.Row(
                  children: [
                    pw.Text(
                      "${labels["village"]!}: ",
                      style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          nativeVillage,
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Text(
                      "${labels["railway"]!}: ",
                      style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          station,
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Donation Amount Box and Amount in Words
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Amount Box
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: pw.Row(
                        children: [
                          pw.Text(
                            "₹ ",
                            style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                          ),
                          pw.Text(
                            donation.amount.toStringAsFixed(2),
                            style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),

                    // Amount in Words
                    pw.Text(
                      "${labels["rupeesInWords"]!}: ",
                      style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          _numberToWords(donation.amount, language),
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Payment mode / Ref No / Cheque No & Bank Name
                pw.Row(
                  children: [
                    pw.Text(
                      "${labels["modeNo"]!}: ",
                      style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          transactionDetails,
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),

                pw.Row(
                  children: [
                    pw.Text(
                      "${labels["bank"]!}: ",
                      style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          bankName.isNotEmpty ? bankName : "-",
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Detail Description (વિગત)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${labels["detail"]!}: ",
                      style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          donation.purpose,
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),

                // Bottom Row: Left Thank You / Right Receiver Signature Field
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      labels["coop"]!,
                      style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                    ),
                    pw.Text(
                      "${labels["receiver"]!}: ________________",
                      style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Disclaimer at bottom center
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    labels["disclaimer"]!,
                    style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 7, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
