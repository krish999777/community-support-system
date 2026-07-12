import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiRoutes {
  // Use 10.0.2.2 for Android emulator to access local machine's localhost.
  // Use localhost for iOS simulator or web.
  static String get baseUrl {
    return "https://community-support-system-latest.onrender.com/api";
  }

  // Admin / Auth
  static String get loginPin => "$baseUrl/admin/login-pin";
  static String get pins => "$baseUrl/admin/pins";
  static String get stats => "$baseUrl/admin/stats";
  static String get export => "$baseUrl/admin/export";

  // Donors
  static String get addDonor => "$baseUrl/donor/add";
  static String searchDonor(String query) => "$baseUrl/donor/search/$query";
  static String get allDonors => "$baseUrl/donor/all";
  static String donorProfile(String mobile) => "$baseUrl/donor/profile/$mobile";

  // Receipts / Donations
  static String get donate => "$baseUrl/receipt/donate";
  static String donationHistory(String donorId) => "$baseUrl/receipt/history/$donorId";
  static String receiptDetails(String receiptNo) => "$baseUrl/receipt/receipt/$receiptNo";
  static String downloadReceipt(String receiptNo) => "$baseUrl/receipt/download/$receiptNo";

  // CSV Import
  static String get importCsv => "$baseUrl/import/csv";
}
