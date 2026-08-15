import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../constants/colors.dart';
import '../../../models/donor.dart';
import '../../../providers/donor_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedYear = "All";
  String _selectedPurpose = "All";
  DateTime? _fromDate;
  DateTime? _toDate;

  final List<String> _years = ["All", "2025-26", "2026-27", "2027-28", "2028-29"];
  final List<String> _purposes = ["All", "Marriage", "Death", "Birthday", "General", "Other"];

  // Helper to calculate Indian Financial Year
  String _getFinancialYear(DateTime date) {
    int startYear = date.month >= 4 ? date.year : date.year - 1;
    int endYear = (startYear + 1) % 100;
    return "$startYear-${endYear.toString().padLeft(2, '0')}";
  }

  // Formatting receipt number helper
  String _formatReceiptNo(String rawReceiptNo, DateTime date) {
    if (rawReceiptNo.contains('/')) return rawReceiptNo;
    return "$rawReceiptNo/${_getFinancialYear(date)}";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DonorProvider>(context, listen: false).fetchAllDonors();
    });
  }

  List<Map<String, dynamic>> _getFilteredDonations(List<DonorModel> donors) {
    List<Map<String, dynamic>> results = [];

    for (var donor in donors) {
      for (var donation in donor.donations) {
        // 1. Financial Year Filter
        if (_selectedYear != "All") {
          final donationFY = _getFinancialYear(donation.date);
          if (donationFY != _selectedYear) continue;
        }

        // 2. Date Filtering
        if (_fromDate != null) {
          final startOfDay = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
          if (donation.date.isBefore(startOfDay)) continue;
        }
        if (_toDate != null) {
          final endOfDay = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
          if (donation.date.isAfter(endOfDay)) continue;
        }

        // 3. Purpose Filter
        if (_selectedPurpose != "All") {
          final cleanPurpose = donation.purpose.toLowerCase();
          final target = _selectedPurpose.toLowerCase();
          if (!cleanPurpose.startsWith(target) && !cleanPurpose.contains(target)) continue;
        }

        results.add({
          'donor': donor,
          'donation': donation,
        });
      }
    }

    // Sort by date descending
    results.sort((a, b) => b['donation'].date.compareTo(a['donation'].date));
    return results;
  }

  String _escapeCsv(String? val) {
    if (val == null) return '';
    String clean = val.replaceAll('"', '""');
    if (clean.contains(',') || clean.contains('\n') || clean.contains('"')) {
      return '"$clean"';
    }
    return clean;
  }

  String _generateCsvData(List<Map<String, dynamic>> filteredList) {
    final buffer = StringBuffer();
    // Headers matching all fields requested
    buffer.writeln(
      "Date,Receipt No,Financial Year,Donor Name,Mobile,Email,Native Village,Nearest Station,PAN,Aadhaar,Amount,Payment Mode,Bank Name,Transaction ID / Ref No,Transaction Date,Payment Received By,Purpose & Details"
    );

    for (var item in filteredList) {
      final DonorModel donor = item['donor'];
      final DonationModel donation = item['donation'];
      
      final dateStr = DateFormat('dd-MMM-yyyy').format(donation.date);
      final receiptNo = _formatReceiptNo(donation.receiptNo, donation.date);
      final fy = _getFinancialYear(donation.date);
      final donorName = donor.fullName;
      final mobile = donor.mobile;
      final email = donor.email ?? '';
      final village = donor.address ?? ''; // Native Village stored in address
      final station = donor.nearestRailwayStation ?? '';
      final pan = donor.pan ?? '';
      final aadhaar = donor.aadhaar ?? '';
      final amount = donation.amount.toStringAsFixed(2);
      final mode = donation.mode;
      final bankName = (donation.mode != "Cash") ? (donation.accountNumber ?? "") : '';
      
      String txnId = '';
      if (donation.mode == "Cheque") {
        txnId = donation.chequeNumber ?? '';
      } else {
        txnId = donation.transactionId ?? '';
      }
      
      final txnDate = DateFormat('dd-MMM-yyyy').format(donation.date);
      final receivedBy = donation.ifsc ?? 'K. A. Vaghela';
      final purpose = donation.purpose;

      buffer.writeln(
        "${_escapeCsv(dateStr)},"
        "${_escapeCsv(receiptNo)},"
        "${_escapeCsv(fy)},"
        "${_escapeCsv(donorName)},"
        "${_escapeCsv(mobile)},"
        "${_escapeCsv(email)},"
        "${_escapeCsv(village)},"
        "${_escapeCsv(station)},"
        "${_escapeCsv(pan)},"
        "${_escapeCsv(aadhaar)},"
        "$amount,"
        "${_escapeCsv(mode)},"
        "${_escapeCsv(bankName)},"
        "${_escapeCsv(txnId)},"
        "${_escapeCsv(txnDate)},"
        "${_escapeCsv(receivedBy)},"
        "${_escapeCsv(purpose)}"
      );
    }

    return buffer.toString();
  }

  Future<void> _exportCsv({required bool share}) async {
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final filtered = _getFilteredDonations(donorProvider.donors);

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No records found to export."), backgroundColor: AppColors.error),
      );
      return;
    }

    try {
      final csvString = _generateCsvData(filtered);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = "${dir.path}/samaj_report_$timestamp.csv";
      
      final file = File(filePath);
      await file.writeAsString(csvString);

      if (share) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: "Samaj Donation Report $timestamp",
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Downloaded to: samaj_report_$timestamp.csv"),
            backgroundColor: AppColors.accent,
            action: SnackBarAction(
              label: "OPEN",
              textColor: Colors.white,
              onPressed: () {
                OpenFilex.open(filePath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to export report: $e"), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorProvider = Provider.of<DonorProvider>(context);
    final filtered = _getFilteredDonations(donorProvider.donors);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text("Reports Generator", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Cards
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Financial Year Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Financial Year", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedYear,
                            dropdownColor: AppColors.surface,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                            style: const TextStyle(color: AppColors.textPrimary),
                            items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedYear = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Description/Purpose Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Purpose", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedPurpose,
                            dropdownColor: AppColors.surface,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                            style: const TextStyle(color: AppColors.textPrimary),
                            items: _purposes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPurpose = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Date pickers row
                Row(
                  children: [
                    // From date picker
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: AppColors.background,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: _fromDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (selected != null) {
                            setState(() => _fromDate = selected);
                          }
                        },
                        icon: const Icon(Icons.date_range, color: AppColors.primary, size: 18),
                        label: Text(
                          _fromDate == null ? "From Date" : DateFormat('dd-MMM-yyyy').format(_fromDate!),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    if (_fromDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.error, size: 18),
                        onPressed: () => setState(() => _fromDate = null),
                      ),
                    const SizedBox(width: 8),
                    // To date picker
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: AppColors.background,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: _toDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (selected != null) {
                            setState(() => _toDate = selected);
                          }
                        },
                        icon: const Icon(Icons.date_range, color: AppColors.accent, size: 18),
                        label: Text(
                          _toDate == null ? "To Date" : DateFormat('dd-MMM-yyyy').format(_toDate!),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    if (_toDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.error, size: 18),
                        onPressed: () => setState(() => _toDate = null),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Export buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _exportCsv(share: false),
                        icon: const Icon(Icons.download, color: Colors.white, size: 18),
                        label: const Text("Download CSV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _exportCsv(share: true),
                        icon: const Icon(Icons.share, color: Colors.white, size: 18),
                        label: const Text("Share CSV (WA/Mail)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Results Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Found ${filtered.length} Donations",
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_selectedYear != "All" || _selectedPurpose != "All" || _fromDate != null || _toDate != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedYear = "All";
                        _selectedPurpose = "All";
                        _fromDate = null;
                        _toDate = null;
                      });
                    },
                    child: const Text("Reset Filters", style: TextStyle(color: AppColors.error)),
                  ),
              ],
            ),
          ),

          // Directory List preview
          Expanded(
            child: donorProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text("No matching donations found.", style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final DonorModel donor = item['donor'];
                          final DonationModel donation = item['donation'];
                          final dateStr = DateFormat('MMM dd, yyyy').format(donation.date);
                          final receiptFormatted = _formatReceiptNo(donation.receiptNo, donation.date);

                          return Card(
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        donor.fullName,
                                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        "₹${donation.amount.toStringAsFixed(2)}",
                                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Receipt: $receiptFormatted",
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: AppColors.border, height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Mode: ${donation.mode}",
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                      Expanded(
                                        child: Text(
                                          donation.purpose,
                                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                          textAlign: TextAlign.end,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
