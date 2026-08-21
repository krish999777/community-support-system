import 'dart:typed_data';
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

  // Convert Gujarati number to words with exact 1-99 words mapping
  static String _convertGujaratiNumberToWords(int number) {
    if (number == 0) return "શૂન્ય";

    final onesAndTeens = [
      "", "એક", "બે", "ત્રણ", "ચાર", "પાંચ", "છ", "સાત", "આઠ", "નવ", "દસ",
      "અગિયાર", "બાર", "તેર", "ચૌદ", "પંદર", "સોળ", "સત્તર", "અઢાર", "ઓગણીસ", "વીસ",
      "એકવીસ", "બાવીસ", "તેવીસ", "ચોવીસ", "પચાસ", "છવીસ", "સત્તાવીસ", "અઠ્ઠાવીસ", "ઓગણત્રીસ", "ત્રીસ",
      "એકત્રીસ", "બત્રીસ", "તેત્રીસ", "ચોત્રીસ", "પાંત્રીસ", "છત્રીસ", "સડત્રીસ", "અડત્રીસ", "ઓગણચાલીસ", "ચાલીસ",
      "એકતાલીસ", "બેતાલીસ", "તાલીસ", "ચોતાલીસ", "પિસ્તાલીસ", "છેતાલીસ", "સુડતાલીસ", "અડતાલીસ", "ઓગણપચાસ", "પચાસ",
      "એકાવન", "બાવન", "ત્રેપન", "ચોપન", "પંચાવન", "છપ્પન", "સત્તાવન", "અઠ્ઠાવન", "ઓગણસાઠ", "સાઠ",
      "એકસઠ", "બાસઠ", "ત્રેસઠ", "ચોસઠ", "પાંસઠ", "છાસઠ", "સડસઠ", "અડસઠ", "ઓગણસિત્તેર", "સિત્તેર",
      "એકોતેર", "બોતેર", "તોતેર", "ચુમ્મોતેર", "પંચોતેર", "છોતેર", "સત્તોતેર", "અઠ્ઠોતેર", "ઓગણએંસી", "એંસી",
      "એક્યાસી", "બ્યાસી", "ત્યાસી", "ચોર્યાસી", "પંચાસી", "છ્યાસી", "સત્ત્યાસી", "અઠ્ઠ્યાસી", "નેવ્યાસી", "નેવુ",
      "એકમાણુ", "બ્રાણુ", "ત્રાણુ", "ચોર્માણુ", "પંચાણુ", "છન્નુ", "સત્તાણુ", "અઠ્ઠાળુ", "નવ્વાણુ"
    ];

    String convertLessThanHundred(int n) {
      if (n < onesAndTeens.length) return onesAndTeens[n];
      return "$n";
    }

    String convertLessThanThousand(int n) {
      if (n == 0) return "";
      if (n < 100) return convertLessThanHundred(n);
      int h = n ~/ 100;
      int rem = n % 100;
      String hundredStr = "${onesAndTeens[h]} સો";
      if (rem == 0) return hundredStr;
      return "$hundredStr ${convertLessThanHundred(rem)}";
    }

    String result = "";
    int crores = number ~/ 10000000;
    number %= 10000000;

    int lakhs = number ~/ 100000;
    number %= 100000;

    int thousands = number ~/ 1000;
    number %= 1000;

    if (crores > 0) {
      result += "${convertLessThanThousand(crores)} કરોડ ";
    }
    if (lakhs > 0) {
      result += "${convertLessThanThousand(lakhs)} લાખ ";
    }
    if (thousands > 0) {
      result += "${convertLessThanThousand(thousands)} હજાર ";
    }
    if (number > 0) {
      result += convertLessThanThousand(number);
    }

    return result.trim();
  }

  // Translate amount to words
  static String _numberToWords(double amount, String lang) {
    int amt = amount.round();
    if (lang == "gujarati") {
      String words = _convertGujaratiNumberToWords(amt);
      return "રૂ. $words પૂરા";
    } else {
      String words = _convertEnglishNumberToWords(amt);
      return "Rupees $words Only";
    }
  }

  // Load image asset as pw.MemoryImage
  static Future<pw.MemoryImage?> _loadAssetImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      print("Failed to load asset image $path: $e");
      return null;
    }
  }

  static Future<Uint8List> generateReceiptPdf(DonationModel donation, DonorModel donor, String language) async {
    final pdf = pw.Document();
    final font = await _loadFont(language);
    final englishFont = await _loadFont("english");
    final bool isGuj = (language == "gujarati");

    // Load logo image from assets
    pw.ImageProvider? logoImageProvider;
    try {
      final logoData = await rootBundle.load("assets/logo.jpg");
      logoImageProvider = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      print("Failed to load logo image: $e");
    }

    // Load pre-rendered Gujarati header image assets
    final sloganImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/slogan.png") : null;
    final titleImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/title.png") : null;
    final addressImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/address.png") : null;
    final shrimanImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/shriman.png") : null;
    final vigatImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/vigat.png") : null;
    final praptkartaImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/praptkarta.png") : null;
    final ankeImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/anke.png") : null;
    final rasidNoImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/rasid_no.png") : null;
    final taImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/ta.png") : null;
    final gamImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/gam.png") : null;
    final halImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/hal.png") : null;
    final coopImg = isGuj ? await _loadAssetImage("assets/gujarati_headers/coop.png") : null;
    // Header Widgets
    final pw.Widget sloganWidget = sloganImg != null
        ? pw.Image(sloganImg, height: 14, fit: pw.BoxFit.contain)
        : pw.Text("|| Shri Ganeshaya Namah ||", style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900));

    final pw.Widget titleWidget = titleImg != null
        ? pw.Image(titleImg, height: 22, fit: pw.BoxFit.contain)
        : pw.Text("Samast Darji Samaj Babariyawad, Mumbai", style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red900));

    final pw.Widget addressWidget = addressImg != null
        ? pw.Image(addressImg, height: 10, fit: pw.BoxFit.contain)
        : pw.Text("C/o Room No. 8, Hirvi Chawl, Behind Gunakar Kendra, Sane Guruji Road, Tardeo, Mumbai - 400034", style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey800));

    final pw.Widget receiptNoLabelWidget = rasidNoImg != null
        ? pw.Image(rasidNoImg, height: 14, fit: pw.BoxFit.contain)
        : pw.Text("Receipt No:", style: pw.TextStyle(font: font, fontSize: 11, fontWeight: pw.FontWeight.bold));

    final pw.Widget dateLabelWidget = taImg != null
        ? pw.Image(taImg, height: 14, fit: pw.BoxFit.contain)
        : pw.Text("Date", style: pw.TextStyle(font: font, fontSize: 11, fontWeight: pw.FontWeight.bold));

    final pw.Widget donorNameLabelWidget = shrimanImg != null
        ? pw.Image(shrimanImg, height: 14, fit: pw.BoxFit.contain)
        : pw.Text("Mr / Mrs:", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.blueGrey800));

    final pw.Widget villageLabelWidget = gamImg != null
        ? pw.Image(gamImg, height: 13, fit: pw.BoxFit.contain)
        : pw.Text("Native Village:", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.blueGrey800));

    final pw.Widget stationLabelWidget = halImg != null
        ? pw.Image(halImg, height: 13, fit: pw.BoxFit.contain)
        : pw.Text("Nearest Station:", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.blueGrey800));

    final pw.Widget rupeesWordsLabelWidget = ankeImg != null
        ? pw.Image(ankeImg, height: 14, fit: pw.BoxFit.contain)
        : pw.Text("Amount in Words:", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.blueGrey800));

    final pw.Widget modeLabelWidget = pw.Text(
      "UPI / Cash / Check:",
      style: pw.TextStyle(font: englishFont, fontSize: 10, color: PdfColors.blueGrey800),
    );

    final pw.Widget bankLabelWidget = pw.Text(
      isGuj ? "બેન્ક:" : "Bank Name:",
      style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, color: PdfColors.blueGrey800),
    );

    final pw.Widget detailLabelWidget = vigatImg != null
        ? pw.Image(vigatImg, height: 14, fit: pw.BoxFit.contain)
        : pw.Text("Purpose / Description:", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.blueGrey800));

    final pw.Widget coopWidget = coopImg != null
        ? pw.Image(coopImg, height: 14, fit: pw.BoxFit.contain)
        : pw.Text("Thank you for cooperation", style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900));

    final pw.Widget receiverWidget = praptkartaImg != null
        ? pw.Row(children: [pw.Image(praptkartaImg, height: 14, fit: pw.BoxFit.contain), pw.Text(": ________________", style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold))])
        : pw.Text("Receiver: ________________", style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900));

    // Format date and receipt number
    final dateStr = DateFormat('dd/MM/yyyy').format(donation.date);
    final formattedRecNo = formatReceiptNo(donation.receiptNo, donation.date);

    // Custom receipt border decorations (Blue borders matching photo)
    final borderDecoration = pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.blue800, width: 3),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    );

    // Clean donor full name
    String cleanDonorName = donor.fullName
        .replaceAll(RegExp(r'^(Mr\s*\(Shriman\)|Mrs\s*\(Shrimati\)|Miss\s*\(Kumari\)|Shriman|Srimati|Mr\.|Mrs\.|Mr|Mrs|Shri)\s*', caseSensitive: false), '')
        .trim();

    String displayName = cleanDonorName;
    if (language == "english") {
      displayName = "Mr. $cleanDonorName";
    }

    final nativeVillage = donor.address ?? "";
    final station = donor.nearestRailwayStation ?? "";
    final bankName = (donation.mode != "Cash") ? (donation.accountNumber ?? "") : "";

    String transactionDetails = donation.mode;
    if (donation.mode == "Cheque") {
      transactionDetails = "Cheque No: ${donation.chequeNumber ?? ''}";
    } else if (donation.mode == "UPI" || donation.mode == "Bank Transfer") {
      transactionDetails = "UPI/Ref: ${donation.transactionId ?? ''}";
    }

    final amountInWordsText = _numberToWords(donation.amount, language);

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
                  child: sloganWidget,
                ),
                pw.SizedBox(height: 4),

                // Main Title row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Circular Stamp / Samaj Logo
                    logoImageProvider != null
                        ? pw.Image(logoImageProvider, width: 50, height: 50)
                        : pw.Container(width: 50, height: 50),

                    // Header Info
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          titleWidget,
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Regd. No. : F 29137",
                            style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 2),
                          addressWidget,
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
                        receiptNoLabelWidget,
                        pw.SizedBox(width: 4),
                        pw.Text(
                          formattedRecNo,
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        dateLabelWidget,
                        pw.SizedBox(width: 4),
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
                    donorNameLabelWidget,
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          displayName,
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
                    villageLabelWidget,
                    pw.SizedBox(width: 4),
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
                    stationLabelWidget,
                    pw.SizedBox(width: 4),
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
                    rupeesWordsLabelWidget,
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          amountInWordsText,
                          style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Payment mode & Bank Name
                pw.Row(
                  children: [
                    modeLabelWidget,
                    pw.SizedBox(width: 4),
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
                    bankLabelWidget,
                    pw.SizedBox(width: 4),
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
                    detailLabelWidget,
                    pw.SizedBox(width: 4),
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
                    coopWidget,
                    receiverWidget,
                  ],
                ),
                pw.SizedBox(height: 8),

                // Disclaimer at bottom center
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "Disclaimer: This is Computer generated donation Receipt, Signature Not Required.",
                    style: pw.TextStyle(font: font, fontFallback: [englishFont], fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
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
