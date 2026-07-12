import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../constants/colors.dart';
import '../../../models/donor.dart';
import '../../../providers/donor_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddDonorScreen extends StatefulWidget {
  final DonorModel? donorToEdit;

  const AddDonorScreen({super.key, this.donorToEdit});

  @override
  _AddDonorScreenState createState() => _AddDonorScreenState();
}

class _AddDonorScreenState extends State<AddDonorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _stationController;
  late TextEditingController _panController;
  late TextEditingController _aadhaarController;

  File? _panFile;
  File? _aadhaarFile;

  bool get _isEditing => widget.donorToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.donorToEdit?.fullName ?? "");
    _mobileController = TextEditingController(text: widget.donorToEdit?.mobile ?? "");
    _emailController = TextEditingController(text: widget.donorToEdit?.email ?? "");
    _addressController = TextEditingController(text: widget.donorToEdit?.address ?? "");
    _stationController = TextEditingController(text: widget.donorToEdit?.nearestRailwayStation ?? "");
    _panController = TextEditingController(text: widget.donorToEdit?.pan ?? "");
    _aadhaarController = TextEditingController(text: widget.donorToEdit?.aadhaar ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _stationController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isPan) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          if (isPan) {
            _panFile = File(result.files.single.path!);
          } else {
            _aadhaarFile = File(result.files.single.path!);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e"), backgroundColor: AppColors.error),
      );
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    bool success;

    if (_isEditing) {
      success = await donorProvider.updateDonor(
        originalMobile: widget.donorToEdit!.mobile,
        fullName: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        nearestRailwayStation: _stationController.text.trim(),
        pan: _panController.text.trim(),
        aadhaar: _aadhaarController.text.trim(),
        panFile: _panFile,
        aadhaarFile: _aadhaarFile,
      );
    } else {
      success = await donorProvider.addDonor(
        fullName: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        nearestRailwayStation: _stationController.text.trim(),
        pan: _panController.text.trim(),
        aadhaar: _aadhaarController.text.trim(),
        panFile: _panFile,
        aadhaarFile: _aadhaarFile,
      );
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? "Profile updated successfully!" : "Donor registered successfully!"),
            backgroundColor: AppColors.accent,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(donorProvider.errorMessage ?? "An error occurred."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorProvider = Provider.of<DonorProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          _isEditing ? "Edit Profile" : "Register Donor",
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _nameController,
                label: "Full Name *",
                prefixIcon: Icons.person_outline_rounded,
                validator: (val) => val == null || val.trim().isEmpty ? "Full Name is required" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _mobileController,
                label: "Mobile Number *",
                prefixIcon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().length != 10 ? "Enter a valid 10-digit mobile number" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: "Email Address",
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                label: "Address",
                prefixIcon: Icons.home_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _stationController,
                label: "Nearest Railway Station",
                prefixIcon: Icons.train_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _panController,
                label: "PAN Card Number",
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _aadhaarController,
                label: "Aadhaar Card Number",
                prefixIcon: Icons.fingerprint_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // File Pickers
              const Text(
                "Verification Documents",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildFileSelector("PAN Card Copy", _panFile, () => _pickFile(true)),
              const SizedBox(height: 12),
              _buildFileSelector("Aadhaar Card Copy", _aadhaarFile, () => _pickFile(false)),

              const SizedBox(height: 32),
              CustomButton(
                text: _isEditing ? "SAVE CHANGES" : "REGISTER DONOR",
                isLoading: donorProvider.isLoading,
                onPressed: _submitForm,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileSelector(String title, File? file, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  file != null ? file.path.split('/').last : "No file uploaded",
                  style: TextStyle(color: file != null ? AppColors.accent : AppColors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.upload_file_rounded, size: 18, color: Colors.white),
            label: const Text("Pick", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
