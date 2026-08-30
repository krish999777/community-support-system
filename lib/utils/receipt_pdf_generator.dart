import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/donor.dart';

class ReceiptPdfGenerator {
  // Helper to load bundled asset font
  static Future<pw.Font?> _loadFont(String path) async {
    try {
      final fontData = await rootBundle.load(path);
      return pw.Font.ttf(fontData);
    } catch (e) {
      debugPrint("Failed to load font $path: $e");
      return null;
    }
  }

  // Calculate Indian Financial Year from date (starts Apr 1st, ends Mar 31st next year)
  static String _getFinancialYear(DateTime date) {
    int startYear = date.month >= 4 ? date.year : date.year - 1;
    int endYear = (startYear + 1) % 100;
    return "$startYear-${endYear.toString().padLeft(2, '0')}";
  }

  // Format Receipt No (e.g. 0010/2026-27)
  static String formatReceiptNo(String rawReceiptNo, DateTime date) {
    if (rawReceiptNo.contains('/')) return rawReceiptNo;
    return "$rawReceiptNo/${_getFinancialYear(date)}";
  }

  // English words conversion
  static String _convertToEnglishWords(int n) {
    const single = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"];
    const double = ["Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    const tens = ["", "Ten", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

    String formatTens(int num) {
      if (num < 10) return single[num];
      if (num < 20) return double[num - 10];
      return tens[num ~/ 10] + (num % 10 != 0 ? " ${single[num % 10]}" : "");
    }

    String convert(int num) {
      String str = "";
      if (num >= 100) {
        str += "${single[num ~/ 100]} Hundred ";
        num %= 100;
      }
      if (num > 0) {
        str += "${formatTens(num)} ";
      }
      return str.trim();
    }

    String words = "";
    int rem = n;
    if (rem >= 10000000) { words += "${convert(rem ~/ 10000000)} Crore "; rem %= 10000000; }
    if (rem >= 100000) { words += "${convert(rem ~/ 100000)} Lakh "; rem %= 100000; }
    if (rem >= 1000) { words += "${convert(rem ~/ 1000)} Thousand "; rem %= 1000; }
    if (rem > 0) { words += convert(rem); }
    return words.trim();
  }

  // Gujarati words conversion
  static String _convertToGujaratiWords(int n) {
    const ones = [
      "", "એક", "બે", "ત્રણ", "ચાર", "પાંચ", "છ", "સાત", "આઠ", "નવ",
      "દસ", "અગિયાર", "બાર", "તેર", "ચૌદ", "પંદર", "સોળ", "સત્તર", "અઢાર", "ઓગણીસ",
      "વીસ", "એકવીસ", "બાવીસ", "તેવીસ", "ચોવીસ", "પચ્ચીસ", "છવ્વીસ", "સત્તાવીસ", "અઠ્ઠાવીસ", "ઓગણત્રીસ",
      "ત્રીસ", "એકત્રીસ", "બત્રીસ", "તેત્રીસ", "ચોત્રીસ", "પાંત્રીસ", "છત્રીસ", "સાડત્રીસ", "ઓડત્રીસ", "ઓગણચાલીસ",
      "ચાલીસ", "એકતાલીસ", "બેતાલીસ", "તેતાલીસ", "ચુમ્માલીસ", "પિસ્તાલીસ", "છેતાલીસ", "સુડતાલીસ", "અડતાલીસ", "ઓગણપચાસ",
      "પચાસ", "એકાવન", "બાવન", "ત્રેપન", "ચોપન", "પંચાવન", "છપ્પન", "સત્તાવન", "અઠ્ઠાવન", "ઓગણસાઠ",
      "સાઠ", "એકસઠ", "બાસઠ", "ત્રેસઠ", "ચોસઠ", "પાંસઠ", "છાસઠ", "સડસઠ", "અડસઠ", "ઓગણસિત્તેર",
      "સિત્તેર", "એકોતેર", "બોતેર", "તોતેર", "ચૂમોતેર", "પંચોતેર", "છોતેર", "સંતોતેર", "અઠોતેર", "ઓગણાએંસી",
      "એંસી", "એક્યાસી", "બ્યાસી", "ત્યાસી", "ચોર્યાસી", "પંચાસી", "છ્યાસી", "સત્તયાસી", "અઠ્યાસી", "નેવ્યાસી",
      "નેવું", "એકાણું", "બાણું", "ત્રાણું", "ચોરાણું", "પંચાણું", "છન્નું", "સત્તાણું", "અઠ્ઠાણું", "નવ્વાણું"
    ];

    String convert(int num) {
      String str = "";
      if (num >= 100) {
        final h = num ~/ 100;
        if (h == 1) {
          str += "એકસો ";
        } else if (h < ones.length) {
          str += "${ones[h]}સો ";
        }
        num %= 100;
      }
      if (num > 0 && num < ones.length) {
        str += ones[num];
      }
      return str.trim();
    }

    String words = "";
    int rem = n;
    if (rem >= 10000000) { words += "${convert(rem ~/ 10000000)} કરોડ "; rem %= 10000000; }
    if (rem >= 100000) { words += "${convert(rem ~/ 100000)} લાખ "; rem %= 100000; }
    if (rem >= 1000) { words += "${convert(rem ~/ 1000)} હજાર "; rem %= 1000; }
    if (rem > 0) { words += convert(rem); }
    return words.trim();
  }

  // Hindi words conversion
  static String _convertToHindiWords(int n) {
    const ones = [
      "", "एक", "दो", "तीन", "चार", "पाँच", "छह", "सात", "आठ", "नौ",
      "दस", "ग्यारह", "बारह", "तेरह", "चौदह", "पंद्रह", "सोलह", "सत्रह", "अठारह", "उन्नीस",
      "बीस", "इक्कीस", "बाईस", "तेईस", "चौबीस", "पच्चीस", "छब्बीस", "सत्ताईस", "अट्ठाईस", "उनतीस",
      "तीस", "इकत्तीस", "बत्तीस", "तैंतीस", "चौंतीस", "पैंतीस", "छत्तीस", "सैंतीस", "अड़तीस", "उनतालीस",
      "चालीस", "इकतालीस", "बयालीस", "तैंतालीस", "चवालीस", "पैंतालीस", "छियालीस", "सैंतालीस", "अड़तालीस", "उनचास",
      "पचास", "इक्यावन", "बावन", "तिरेपन", "चौवन", "पचपन", "छप्पन", "सत्तावन", "अट्ठावन", "उनसठ",
      "साठ", "इकसठ", "बासठ", "तिरेसठ", "चौंसठ", "पैंसठ", "छियासठ", "सरसठ", "अड़सठ", "उनहत्तर",
      "सत्तर", "इकहत्तर", "बहत्तर", "तिहत्तर", "चौहत्तर", "पचहत्तर", "छिहत्तर", "सतहत्तर", "अठहत्तर", "उन्नासी",
      "अस्सी", "इक्यासी", "बयासी", "तिरासी", "चौरासी", "पचासी", "छियासी", "सत्तासी", "अट्ठासी", "नवासी",
      "नब्बे", "इक्यानवे", "बानवे", "तिरानवे", "चौरानवे", "पचानवे", "छियानवे", "सत्तानवे", "अट्ठानवे", "निन्यानवे"
    ];

    String convert(int num) {
      String str = "";
      if (num >= 100) {
        final h = num ~/ 100;
        if (h == 1) {
          str += "एक सौ ";
        } else if (h < ones.length) {
          str += "${ones[h]} सौ ";
        }
        num %= 100;
      }
      if (num > 0 && num < ones.length) {
        str += ones[num];
      }
      return str.trim();
    }

    String words = "";
    int rem = n;
    if (rem >= 10000000) { words += "${convert(rem ~/ 10000000)} करोड़ "; rem %= 10000000; }
    if (rem >= 100000) { words += "${convert(rem ~/ 100000)} लाख "; rem %= 100000; }
    if (rem >= 1000) { words += "${convert(rem ~/ 1000)} हज़ार "; rem %= 1000; }
    if (rem > 0) { words += convert(rem); }
    return words.trim();
  }

  // Translate amount to Gujarati/Hindi/English words
  static String _numberToWords(double amount, String lang) {
    int amt = amount.round();
    if (amt == 0) {
      if (lang == "gujarati") return "રૂ. શૂન્ય પૂરા";
      if (lang == "hindi") return "रु. शून्य मात्र";
      return "Rupees Zero Only";
    }

    if (lang == "gujarati") {
      final words = _convertToGujaratiWords(amt);
      return "રૂ. $words પૂરા";
    } else if (lang == "hindi") {
      final words = _convertToHindiWords(amt);
      return "रु. $words मात्र";
    } else {
      final words = _convertToEnglishWords(amt);
      return "Rupees $words Only";
    }
  }

  // Translate donor name initial on the fly
  static String getTranslatedInitial(String? initial, String lang) {
    if (initial == null || initial.trim().isEmpty) return "";
    final key = initial.toLowerCase().replaceAll('.', '').trim();
    if (lang == "gujarati") {
      switch (key) {
        case 'mr':
        case 'shriman':
        case 'mr (shriman)':
          return 'શ્રીમાન';
        case 'mrs':
        case 'shrimati':
        case 'mrs (shrimati)':
          return 'શ્રીમતી';
        case 'miss':
        case 'kumari':
        case 'miss (kumari)':
          return 'કુમારી';
        case 'dr':
        case 'doctor':
          return 'ડૉક્ટર';
        default:
          return initial;
      }
    } else if (lang == "hindi") {
      switch (key) {
        case 'mr':
        case 'shriman':
        case 'mr (shriman)':
          return 'श्रीमान';
        case 'mrs':
        case 'shrimati':
        case 'mrs (shrimati)':
          return 'श्रीमती';
        case 'miss':
        case 'kumari':
        case 'miss (kumari)':
          return 'कुमारी';
        case 'dr':
        case 'doctor':
          return 'डॉक्टर';
        default:
          return initial;
      }
    } else {
      // English
      switch (key) {
        case 'mr':
        case 'shriman':
        case 'mr (shriman)':
          return 'Mr.';
        case 'mrs':
        case 'shrimati':
        case 'mrs (shrimati)':
          return 'Mrs.';
        case 'miss':
        case 'kumari':
        case 'miss (kumari)':
          return 'Miss';
        case 'dr':
        case 'doctor':
          return 'Dr.';
        default:
          return initial;
      }
    }
  }

  static Future<Uint8List> generateReceiptPdf(DonationModel donation, DonorModel donor, String language) async {
    // Load bundled offline fonts
    final englishFont = await _loadFont("assets/fonts/NotoSans-Regular.ttf");
    final gujaratiFont = await _loadFont("assets/fonts/NotoSansGujarati-Regular.ttf");
    final hindiFont = await _loadFont("assets/fonts/NotoSansDevanagari-Regular.ttf");

    final primaryFont = language == "gujarati"
        ? (gujaratiFont ?? englishFont ?? pw.Font.helvetica())
        : (language == "hindi"
            ? (hindiFont ?? englishFont ?? pw.Font.helvetica())
            : (englishFont ?? pw.Font.helvetica()));

    final fallbackList = <pw.Font>[
      if (englishFont != null) englishFont,
      if (gujaratiFont != null) gujaratiFont,
      if (hindiFont != null) hindiFont,
      pw.Font.helvetica(),
    ];

    final theme = pw.ThemeData.withFont(
      base: primaryFont,
      bold: primaryFont,
      fontFallback: fallbackList,
    );

    final pdf = pw.Document(theme: theme);

    // Try loading logo image
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load("assets/images/logo.jpeg");
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // Dictionary of translations
    final translations = {
      "gujarati": {
        "slogan": "|| શ્રી ગણેશાય નમઃ ||",
        "title": "સમસ્ત દરજી સમાજ બાબરીયાવાડ, મુંબઈ",
        "regNo": "Regd. No. : F 29137",
        "cO": "C/o રૂમ નં. ૮, હિરવી ચાલ, ગુણકાભાકર કેન્દ્ર ની પાછળ, સાને ગુરૂજી રોડ, તારદેવ, મુંબઈ - ૪૦૦ ૦૩૪",
        "receiptNo": "રસીદ નંબર",
        "date": "તા.",
        "village": "ગામ",
        "railway": "હાલ",
        "voluntaryText": "આપના તરફથી સ્વેચ્છાએ દાન રૂપે",
        "rupeesInWords": "અંકે રૂ.",
        "modeNo": "UPI / Cash / Check",
        "bank": "બેન્ક",
        "detail": "વિગત",
        "coop": "સહકાર બદલ આભાર",
        "receiver": "પરાપ્તકર્તા :",
        "disclaimer": "આ કોમ્પ્યુટર જનરેટેડ દાન રસીદ છે, સહીની જરૂર નથી.",
        "genDate": "રસીદ બન્યા તા.:",
      },
      "hindi": {
        "slogan": "|| श्री गणेशाय नमः ||",
        "title": "સમસ્ત દરજી સમાજ બાબરીયાવાડ, મુંબઈ",
        "regNo": "Regd. No. : F 29137",
        "cO": "C/o रूम नं. ८, हिरवी चाल, गुणकाभाकर केंद्र के पीछे, साने गुरुजी रोड, ताड़देव, मुंबई - ४०० ०३૪",
        "receiptNo": "रसीद संख्या",
        "date": "दिनांक",
        "village": "ग्राम",
        "railway": "वर्तमान",
        "voluntaryText": "आपकी ओर से स्वेच्छा से दान स्वरूप",
        "rupeesInWords": "शब्दों में रु.",
        "modeNo": "UPI / Cash / Check",
        "bank": "बैंक",
        "detail": "विवरण",
        "coop": "सहयोग के लिए धन्यवाद",
        "receiver": "प्राप्तकर्ता :",
        "disclaimer": "यह कंप्यूटर जनित दान रसीद है, हस्ताक्षर की आवश्यकता नहीं है।",
        "genDate": "रसीद निर्माण तिथि:",
      },
      "english": {
        "slogan": "|| Shri Ganeshaya Namah ||",
        "title": "Samast Darji Samaj Babariyawad, Mumbai",
        "regNo": "Regd. No. : F 29137",
        "cO": "C/o Room No. 8, Hirvi Chawl, Behind Gunabhakar Center, Sane Guruji Road, Tardeo, Mumbai - 400034",
        "receiptNo": "Receipt No",
        "date": "Date",
        "village": "Native Village",
        "railway": "Nearest Station",
        "voluntaryText": "Voluntary donation received with thanks from",
        "rupeesInWords": "Amount in Words",
        "modeNo": "UPI / Cash / Check",
        "bank": "Bank Name",
        "detail": "Purpose / Description",
        "coop": "Thank you for cooperation",
        "receiver": "Receiver:",
        "disclaimer": "Disclaimer: This is Computer generated donation Receipt, Signature Not Required.",
        "genDate": "Generated on:",
      }
    };

    final labels = translations[language] ?? translations["english"]!;

    // Display formatted donation date and date of generation
    final dateStr = DateFormat('dd/MM/yyyy').format(donation.date);
    final generationDateStr = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    // Format receipt number
    final formattedRecNo = formatReceiptNo(donation.receiptNo, donation.date);

    // Custom receipt border decorations (Blue borders matching screenshot)
    final borderDecoration = pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.blue800, width: 2),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    );

    // Native Village is stored in address
    final nativeVillage = donor.address ?? "";
    final station = donor.nearestRailwayStation ?? "";

    // Parse bank name (stored in accountNumber)
    final bankName = (donation.mode != "Cash") ? (donation.accountNumber ?? "") : "-";

    // Receiver name
    final receiverName = (donation.receivedBy != null && donation.receivedBy!.isNotEmpty)
        ? donation.receivedBy!
        : ((donation.ifsc != null && donation.ifsc!.isNotEmpty) ? donation.ifsc! : "Person 1");

    // Transaction detail text
    String transactionDetails = donation.mode;
    if (donation.mode == "Cheque" && donation.chequeNumber != null && donation.chequeNumber!.isNotEmpty) {
      transactionDetails = "Cheque No: ${donation.chequeNumber}";
    } else if ((donation.mode == "UPI" || donation.mode == "Bank Transfer") && donation.transactionId != null && donation.transactionId!.isNotEmpty) {
      transactionDetails = "${donation.mode} Ref: ${donation.transactionId}";
    }

    // Dynamic translated initial prefix
    final translatedInit = getTranslatedInitial(donor.initial, language);
    final donorPrefixLabel = translatedInit.isNotEmpty
        ? translatedInit
        : (language == "gujarati" ? "શ્રીમાન" : language == "hindi" ? "श्रीमान" : "Mr.");

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(21 * PdfPageFormat.cm, 16 * PdfPageFormat.cm, marginAll: 0.8 * PdfPageFormat.cm),
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
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                  ),
                ),
                pw.SizedBox(height: 2),

                // Main Title row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Samaj Logo (matching screenshot)
                    if (logoImage != null)
                      pw.Container(
                        width: 50,
                        height: 50,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Container(
                        width: 50,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: PdfColors.red800, width: 2),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          "SEAL",
                          style: pw.TextStyle(fontSize: 8, color: PdfColors.red800, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),

                    // Header Info
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            labels["title"]!,
                            style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            labels["regNo"]!,
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            labels["cO"]!,
                            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
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
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Deduction u/s 80G",
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            "PAN : AAGTS1081B",
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Divider(color: PdfColors.blue800, thickness: 1.2),
                pw.SizedBox(height: 4),

                // Receipt No and Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          "${labels["receiptNo"]!}: ",
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          formattedRecNo,
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          "${labels["date"]!} ",
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          dateStr,
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Donor Name Row with initial
                pw.Row(
                  children: [
                    pw.Text(
                      "$donorPrefixLabel: ",
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          donor.fullName,
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
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
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          nativeVillage,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Text(
                      "${labels["railway"]!}: ",
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          station,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
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
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: pw.Row(
                        children: [
                          pw.Text(
                            "₹ ",
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                          ),
                          pw.Text(
                            donation.amount.toStringAsFixed(2),
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 10),

                    // Amount in Words
                    pw.Text(
                      "${labels["rupeesInWords"]!}: ",
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          _numberToWords(donation.amount, language),
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Payment mode / Ref No / Cheque No
                pw.Row(
                  children: [
                    pw.Text(
                      "${labels["modeNo"]!}: ",
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          transactionDetails,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),

                // Bank Name
                pw.Row(
                  children: [
                    pw.Text(
                      "${labels["bank"]!}: ",
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          bankName.isNotEmpty ? bankName : "-",
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),

                // Detail Description (વિગત)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${labels["detail"]!}: ",
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          donation.purpose,
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Bottom Section: cooperation text on left, single receiver dash on right (matching screenshot)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      labels["coop"]!,
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                    ),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          labels["receiver"]!,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey700, width: 1)),
                          ),
                          child: pw.Text(
                            receiverName,
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),

                // Disclaimer & Date of Generation line (centered)
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "${labels["disclaimer"]!} | ${labels["genDate"]!} $generationDateStr",
                    style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
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
