import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/colors.dart';
import '../../../constants/api_routes.dart';
import '../../../models/donor.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../services/api_service.dart';
import 'add_donor_screen.dart';
import 'add_donation_screen.dart';

class DonorDetailScreen extends StatefulWidget {
  final String mobile;

  const DonorDetailScreen({super.key, required this.mobile});

  @override
  _DonorDetailScreenState createState() => _DonorDetailScreenState();
}

class _DonorDetailScreenState extends State<DonorDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DonorProvider>(context, listen: false).fetchDonorProfile(widget.mobile);
    });
  }

  Future<void> _downloadReceipt(String receiptNo) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fetching receipt PDF: $receiptNo...")),
      );

      final dio = ApiService().client;
      final url = ApiRoutes.downloadReceipt(receiptNo);
      
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/receipt_$receiptNo.pdf";

      await dio.download(
        url, 
        filePath,
        options: Options(responseType: ResponseType.bytes),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Downloaded to: receipt_$receiptNo.pdf"),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to download PDF: $e"), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _shareReceiptWhatsApp(DonationModel donation, String donorName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preparing receipt PDF...")),
      );

      final dio = ApiService().client;
      final url = ApiRoutes.downloadReceipt(donation.receiptNo);
      
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/receipt_${donation.receiptNo}.pdf";

      await dio.download(
        url, 
        filePath,
        options: Options(responseType: ResponseType.bytes),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: "Samaj Receipt - ${donation.receiptNo}",
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to share PDF: $e"), backgroundColor: AppColors.error),
      );
    }
  }

  void _deleteDonor() async {
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Delete Profile", style: TextStyle(color: AppColors.textPrimary)),
        content: const Text("Are you sure you want to permanently delete this donor and all history?", style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await donorProvider.deleteDonor(widget.mobile);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Donor profile deleted successfully"), backgroundColor: AppColors.accent),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final donorProvider = Provider.of<DonorProvider>(context);
    final donor = donorProvider.selectedDonor;

    final isAdmin = authProvider.currentUser?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text("Donor Profile", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          if (isAdmin && donor != null) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddDonorScreen(donorToEdit: donor),
                  ),
                ).then((_) => donorProvider.fetchDonorProfile(widget.mobile));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: AppColors.error),
              onPressed: _deleteDonor,
            ),
          ]
        ],
      ),
      body: donorProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : donor == null
              ? const Center(child: Text("Donor profile not found.", style: TextStyle(color: AppColors.textSecondary)))
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      // Profile Header Info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        color: AppColors.surface,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                donor.fullName.isNotEmpty ? donor.fullName[0].toUpperCase() : 'D',
                                style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              donor.fullName,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "+91 ${donor.mobile}",
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tabs Header
                      const TabBar(
                        indicatorColor: AppColors.primary,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        tabs: [
                          Tab(text: "Details", icon: Icon(Icons.info_outline)),
                          Tab(text: "History", icon: Icon(Icons.history)),
                        ],
                      ),

                      // Tabs Views
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildDetailsTab(donor),
                            _buildHistoryTab(donor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: donor != null
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.payment_rounded, color: Colors.white),
              label: const Text("NEW DONATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddDonationScreen(donor: donor),
                  ),
                ).then((_) => donorProvider.fetchDonorProfile(widget.mobile));
              },
            )
          : null,
    );
  }

  Widget _buildDetailsTab(DonorModel donor) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard([
          _buildInfoRow(Icons.mail_outline, "Email Address", donor.email ?? "N/A"),
          _buildInfoRow(Icons.home_outlined, "Address", donor.address ?? "N/A"),
          _buildInfoRow(Icons.train_outlined, "Nearest Station", donor.nearestRailwayStation ?? "N/A"),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard([
          _buildInfoRow(Icons.badge_outlined, "PAN Number", donor.pan ?? "N/A"),
          _buildInfoRow(Icons.fingerprint, "Aadhaar Number", donor.aadhaar ?? "N/A"),
        ]),
        const SizedBox(height: 16),
        if (donor.panFileBase64 != null || donor.aadhaarFileBase64 != null) ...[
          const Text("Documents Preview", style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (donor.panFileBase64 != null)
                Expanded(child: _buildDocumentPreview("PAN Card Image", donor.panFileBase64!)),
              if (donor.panFileBase64 != null && donor.aadhaarFileBase64 != null) const SizedBox(width: 12),
              if (donor.aadhaarFileBase64 != null)
                Expanded(child: _buildDocumentPreview("Aadhaar Card Image", donor.aadhaarFileBase64!)),
            ],
          ),
          const SizedBox(height: 48),
        ]
      ],
    );
  }

  Widget _buildDocumentPreview(String title, String base64Data) {
    // Extract base64 part
    String base64String = base64Data.contains(',') ? base64Data.split(',')[1] : base64Data;
    ImageProvider imageProvider;
    try {
      imageProvider = MemoryImage(base64Decode(base64String));
    } catch (_) {
      imageProvider = const AssetImage('assets/placeholder.png'); // Fallback if decode fails
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: InteractiveViewer(
              child: Image(image: imageProvider),
            ),
          ),
        );
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          color: Colors.black54,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(DonorModel donor) {
    if (donor.donations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text("No donation records found.", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: donor.donations.length,
      itemBuilder: (context, index) {
        final donation = donor.donations[index];
        final formattedDate = DateFormat('MMM dd, yyyy').format(donation.date);
        
        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Receipt: ${donation.receiptNo}",
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Amount", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          "₹${donation.amount.toStringAsFixed(2)}",
                          style: const TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Mode / Purpose", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          "${donation.mode} / ${donation.purpose}",
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                if (donation.transactionId != null && donation.transactionId!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    "TXN ID: ${donation.transactionId}",
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 11),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _downloadReceipt(donation.receiptNo),
                      icon: const Icon(Icons.file_download, size: 16, color: AppColors.primary),
                      label: const Text("RECEIPT PDF", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _shareReceiptWhatsApp(donation, donor.fullName),
                      icon: const Icon(Icons.chat_outlined, size: 16, color: AppColors.accent),
                      label: const Text("WHATSAPP", style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
