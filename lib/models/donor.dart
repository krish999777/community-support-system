class DonationModel {
  final String? id;
  final double amount;
  final String mode;
  final DateTime date;
  final String receiptNo;
  final String purpose;
  final String? phone;
  final String? email;
  final String? transactionId;
  final String? chequeNumber;
  final String? accountNumber;
  final String? ifsc;

  DonationModel({
    this.id,
    required this.amount,
    required this.mode,
    required this.date,
    required this.receiptNo,
    required this.purpose,
    this.phone,
    this.email,
    this.transactionId,
    this.chequeNumber,
    this.accountNumber,
    this.ifsc,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['_id'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      mode: json['mode'] ?? 'Cash',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      receiptNo: json['receiptNo'] ?? '',
      purpose: json['purpose'] ?? 'General',
      phone: json['phone'],
      email: json['email'],
      transactionId: json['transactionId'],
      chequeNumber: json['chequeNumber'],
      accountNumber: json['accountNumber'],
      ifsc: json['ifsc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'mode': mode,
      'date': date.toIso8601String(),
      'receiptNo': receiptNo,
      'purpose': purpose,
      'phone': phone,
      'email': email,
      'transactionId': transactionId,
      'chequeNumber': chequeNumber,
      'accountNumber': accountNumber,
      'ifsc': ifsc,
    };
  }
}

class DonorModel {
  final String? id;
  final String fullName;
  final String mobile;
  final String? email;
  final String? address;
  final String? nearestRailwayStation;
  final String? pan;
  final String? aadhaar;
  final String? panFileBase64;
  final String? aadhaarFileBase64;
  final List<DonationModel> donations;

  DonorModel({
    this.id,
    required this.fullName,
    required this.mobile,
    this.email,
    this.address,
    this.nearestRailwayStation,
    this.pan,
    this.aadhaar,
    this.panFileBase64,
    this.aadhaarFileBase64,
    required this.donations,
  });

  factory DonorModel.fromJson(Map<String, dynamic> json) {
    var donationList = json['donations'] as List? ?? [];
    List<DonationModel> parsedDonations = donationList
        .map((d) => DonationModel.fromJson(d as Map<String, dynamic>))
        .toList();

    // The backend stores files inside panFile: { data, contentType } 
    // and when returning profiles it converts them to panFile.base64
    String? panBase64;
    if (json['panFile'] != null) {
      panBase64 = json['panFile']['base64'];
    }

    String? aadhaarBase64;
    if (json['aadhaarFile'] != null) {
      aadhaarBase64 = json['aadhaarFile']['base64'];
    }

    return DonorModel(
      id: json['_id'],
      fullName: json['fullName'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'],
      address: json['address'],
      nearestRailwayStation: json['nearestRailwayStation'],
      pan: json['pan'],
      aadhaar: json['aadhaar'],
      panFileBase64: panBase64,
      aadhaarFileBase64: aadhaarBase64,
      donations: parsedDonations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'mobile': mobile,
      'email': email,
      'address': address,
      'nearestRailwayStation': nearestRailwayStation,
      'pan': pan,
      'aadhaar': aadhaar,
    };
  }
}
