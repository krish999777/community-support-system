import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/colors.dart';
import '../../../models/donor.dart';
import '../../../providers/donor_provider.dart';
import '../../../utils/validators.dart';
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
  late TextEditingController _nativeVillageController;
  late TextEditingController _stationController;
  late TextEditingController _panController;
  late TextEditingController _aadhaarController;

  File? _panFile;
  File? _aadhaarFile;

  String _namePrefix = "Mr.";
  final List<String> _prefixes = ["Mr.", "Mrs.", "Miss", "Dr."];

  bool get _isEditing => widget.donorToEdit != null;

  @override
  void initState() {
    super.initState();
    
    // Parse prefix if editing
    String initialName = "";
    if (_isEditing && widget.donorToEdit != null) {
      String rawFullName = widget.donorToEdit!.fullName;
      String matchedPrefix = "Mr.";
      String nameWithoutPrefix = rawFullName;
      for (var prefix in _prefixes) {
        if (rawFullName.startsWith("$prefix ")) {
          matchedPrefix = prefix;
          nameWithoutPrefix = rawFullName.substring(prefix.length + 1);
          break;
        }
      }
      _namePrefix = matchedPrefix;
      initialName = nameWithoutPrefix;
    }

    _nameController = TextEditingController(text: initialName);
    _mobileController = TextEditingController(text: widget.donorToEdit?.mobile ?? "");
    _emailController = TextEditingController(text: widget.donorToEdit?.email ?? "");
    _nativeVillageController = TextEditingController(text: widget.donorToEdit?.address ?? ""); // Native Village in address field
    _stationController = TextEditingController(text: widget.donorToEdit?.nearestRailwayStation ?? "");
    _panController = TextEditingController(text: widget.donorToEdit?.pan ?? "");
    _aadhaarController = TextEditingController(text: widget.donorToEdit?.aadhaar ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _nativeVillageController.dispose();
    _stationController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isPan) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                "Select Document Source",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text("Take Photo (Camera)", style: TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const Divider(color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
                title: const Text("Choose from Gallery", style: TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          if (isPan) {
            _panFile = File(photo.path);
          } else {
            _aadhaarFile = File(photo.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking document: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    bool success;

    // Combine prefix and name
    final nameInput = _nameController.text.trim();
    final fullNameInput = "$_namePrefix $nameInput";
    
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final village = _nativeVillageController.text.trim();
    final station = _stationController.text.trim();
    final panVal = _panController.text.trim().toUpperCase();
    final aadhaarVal = _aadhaarController.text.trim().replaceAll(RegExp(r'\s+|-'), '');

    if (_isEditing) {
      success = await donorProvider.updateDonor(
        originalMobile: widget.donorToEdit!.mobile,
        fullName: fullNameInput,
        mobile: mobile,
        email: email.isNotEmpty ? email : null,
        address: village.isNotEmpty ? village : null, // Native Village mapped to address
        nearestRailwayStation: station.isNotEmpty ? station : null,
        pan: panVal.isNotEmpty ? panVal : null,
        aadhaar: aadhaarVal.isNotEmpty ? aadhaarVal : null,
        panFile: _panFile,
        aadhaarFile: _aadhaarFile,
      );
    } else {
      success = await donorProvider.addDonor(
        fullName: fullNameInput,
        mobile: mobile,
        email: email.isNotEmpty ? email : null,
        address: village.isNotEmpty ? village : null, // Native Village mapped to address
        nearestRailwayStation: station.isNotEmpty ? station : null,
        pan: panVal.isNotEmpty ? panVal : null,
        aadhaar: aadhaarVal.isNotEmpty ? aadhaarVal : null,
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
              // Name Prefix dropdown
              const Text(
                "Name Prefix *",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  value: _namePrefix,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(border: InputBorder.none),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  items: _prefixes.map((String p) {
                    return DropdownMenuItem<String>(
                      value: p,
                      child: Text(p),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _namePrefix = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

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
                validator: Validators.emailValidator,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nativeVillageController,
                label: "Native Village",
                prefixIcon: Icons.holiday_village_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _stationController,
                label: "Nearest Railway Station (Optional)",
                prefixIcon: Icons.train_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _panController,
                label: "PAN Card Number",
                prefixIcon: Icons.badge_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  if (!Validators.validatePAN(val)) {
                    return "Enter a valid 10-digit PAN (e.g. ABCDE1234F)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _aadhaarController,
                label: "Aadhaar Card Number",
                prefixIcon: Icons.fingerprint_outlined,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  if (!Validators.validateAadhaar(val)) {
                    return "Enter a valid 12-digit Aadhaar number";
                  }
                  return null;
                },
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
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 18, color: Colors.white),
            label: const Text("Upload", style: TextStyle(color: Colors.white)),
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
