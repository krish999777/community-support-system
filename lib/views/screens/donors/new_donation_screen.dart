import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../constants/colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'donor_detail_screen.dart';

class NewDonationScreen extends StatefulWidget {
  const NewDonationScreen({super.key});

  @override
  _NewDonationScreenState createState() => _NewDonationScreenState();
}

class _NewDonationScreenState extends State<NewDonationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _mobileController;
  late TextEditingController _amountController;
  late TextEditingController _emailController;
  late TextEditingController _nativeVillageController;
  late TextEditingController _stationController;
  late TextEditingController _detailedDescriptionController;
  late TextEditingController _panController;
  late TextEditingController _aadhaarController;

  // Conditional payment controllers
  late TextEditingController _bankNameController;
  late TextEditingController _txnIdController;
  late TextEditingController _chequeNoController;
  DateTime _transactionDate = DateTime.now();

  File? _panFile;
  File? _aadhaarFile;

  String _namePrefix = "Mr.";
  final List<String> _prefixes = ["Mr.", "Mrs.", "Miss", "Dr."];

  String _paymentMode = "Cash";
  final List<String> _modes = ["Cash", "UPI", "Bank Transfer", "Cheque"];

  String _purpose = "General";
  final List<String> _purposes = ["Marriage", "Death", "Birthday", "General", "Other"];

  String? _receivedBy;
  bool _isLoading = false;

  // Donor lookup state variables
  bool _isSearchingMobile = false;
  bool _isExistingDonor = false;
  String? _existingDonorId;
  String? _lookupStatusMessage;
  Color _lookupStatusColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _mobileController = TextEditingController();
    _amountController = TextEditingController();
    _emailController = TextEditingController();
    _nativeVillageController = TextEditingController();
    _stationController = TextEditingController();
    _detailedDescriptionController = TextEditingController();
    _panController = TextEditingController();
    _aadhaarController = TextEditingController();

    _bankNameController = TextEditingController();
    _txnIdController = TextEditingController();
    _chequeNoController = TextEditingController();

    // Start listening to mobile number changes for on-the-fly lookup
    _mobileController.addListener(_onMobileChanged);
  }

  @override
  void dispose() {
    _mobileController.removeListener(_onMobileChanged);
    _fullNameController.dispose();
    _mobileController.dispose();
    _amountController.dispose();
    _emailController.dispose();
    _nativeVillageController.dispose();
    _stationController.dispose();
    _detailedDescriptionController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();

    _bankNameController.dispose();
    _txnIdController.dispose();
    _chequeNoController.dispose();
    super.dispose();
  }

  void _onMobileChanged() {
    final mobile = _mobileController.text.trim();
    if (mobile.length == 10) {
      _lookupDonor(mobile);
    } else {
      if (_isExistingDonor || _lookupStatusMessage != null) {
        setState(() {
          _isExistingDonor = false;
          _existingDonorId = null;
          _lookupStatusMessage = null;
          _lookupStatusColor = Colors.transparent;
          _fullNameController.clear();
          _namePrefix = "Mr.";
          _emailController.clear();
          _nativeVillageController.clear();
          _stationController.clear();
          _panController.clear();
          _aadhaarController.clear();
        });
      }
    }
  }

  Future<void> _lookupDonor(String mobile) async {
    setState(() {
      _isSearchingMobile = true;
      _lookupStatusMessage = "Checking if donor exists...";
      _lookupStatusColor = AppColors.primary;
    });

    try {
      final donorProvider = Provider.of<DonorProvider>(context, listen: false);
      final donor = await donorProvider.searchDonor(mobile);
      if (donor != null) {
        setState(() {
          _isExistingDonor = true;
          _existingDonorId = donor.id;

          // Parse prefix from fullName if present
          String rawFullName = donor.fullName;
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
          _fullNameController.text = nameWithoutPrefix;

          _emailController.text = donor.email ?? '';
          _nativeVillageController.text = donor.address ?? ''; // Native village stored in address
          _stationController.text = donor.nearestRailwayStation ?? '';
          _panController.text = donor.pan ?? '';
          _aadhaarController.text = donor.aadhaar ?? '';

          _lookupStatusMessage = "Existing donor found: ${donor.fullName}";
          _lookupStatusColor = Colors.green;
        });
      } else {
        setState(() {
          _isExistingDonor = false;
          _existingDonorId = null;
          _lookupStatusMessage = "New donor. They will be registered on the fly.";
          _lookupStatusColor = Colors.orange;
        });
      }
    } catch (e) {
      setState(() {
        _isExistingDonor = false;
        _existingDonorId = null;
        _lookupStatusMessage = "Lookup failed. Creating as new donor.";
        _lookupStatusColor = Colors.orange;
      });
    } finally {
      setState(() {
        _isSearchingMobile = false;
      });
    }
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

    setState(() {
      _isLoading = true;
    });

    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final mobile = _mobileController.text.trim();
    
    // Combine name prefix and full name
    final nameInput = _fullNameController.text.trim();
    final fullNameInput = "$_namePrefix $nameInput";
    
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final email = _emailController.text.trim();
    final village = _nativeVillageController.text.trim();
    final stationVal = _stationController.text.trim();

    // Combine purpose dropdown and detailed description
    final detailedDesc = _detailedDescriptionController.text.trim();
    final purposeVal = detailedDesc.isNotEmpty ? "$_purpose - $detailedDesc" : _purpose;

    final panVal = _panController.text.trim().toUpperCase();
    final aadhaarVal = _aadhaarController.text.trim().replaceAll(RegExp(r'\s+|-'), '');

    try {
      String? donorId = _existingDonorId;
      String fullName = fullNameInput;

      if (donorId == null || donorId.isEmpty) {
        // Fallback check: Search if donor already exists
        var donor = await donorProvider.searchDonor(mobile);
        if (donor != null) {
          donorId = donor.id;
          fullName = donor.fullName;
        } else {
          // Register donor if not found (with optional PAN/Aadhaar)
          bool donorCreated = await donorProvider.addDonor(
            fullName: fullNameInput,
            mobile: mobile,
            email: email.isNotEmpty ? email : null,
            address: village.isNotEmpty ? village : null, // Native Village in address field
            nearestRailwayStation: stationVal.isNotEmpty ? stationVal : null,
            pan: panVal.isNotEmpty ? panVal : null,
            aadhaar: aadhaarVal.isNotEmpty ? aadhaarVal : null,
            panFile: _panFile,
            aadhaarFile: _aadhaarFile,
          );

          if (!donorCreated) {
            throw Exception(donorProvider.errorMessage ?? "Failed to register new donor.");
          }

          // Fetch newly registered donor profile to get database ID
          final newDonor = await donorProvider.searchDonor(mobile);
          if (newDonor == null) {
            throw Exception("Registered successfully, but failed to retrieve profile ID.");
          }
          donorId = newDonor.id;
          fullName = newDonor.fullName;
        }
      }

      if (donorId == null || donorId.isEmpty) {
        throw Exception("Invalid Donor ID resolved.");
      }

      // Record donation
      bool donationSuccess = await donorProvider.addDonation(
        donorId: donorId,
        fullName: fullName,
        amount: amount,
        mode: _paymentMode,
        purpose: purposeVal,
        phone: mobile,
        email: email.isNotEmpty ? email : null,
        transactionId: (_paymentMode == "UPI" || _paymentMode == "Bank Transfer") ? _txnIdController.text.trim() : null,
        chequeNumber: (_paymentMode == "Cheque") ? _chequeNoController.text.trim() : null,
        accountNumber: (_paymentMode != "Cash") ? _bankNameController.text.trim() : null, // Bank name in accountNumber
        ifsc: (_paymentMode != "Cash") ? _receivedBy : null, // Payment received by in ifsc
        date: _transactionDate,
      );

      if (donationSuccess) {
        if (mounted) {
          // Re-fetch stats and donors immediately!
          Provider.of<DonorProvider>(context, listen: false).fetchDashboardStats();
          Provider.of<DonorProvider>(context, listen: false).fetchAllDonors();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Donation recorded successfully!"),
              backgroundColor: AppColors.accent,
            ),
          );
          // Redirect to donor profile details
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DonorDetailScreen(mobile: mobile),
            ),
          );
        }
      } else {
        throw Exception(donorProvider.errorMessage ?? "Failed to save donation.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Prepare dynamic received-by list containing standard names + current logged in user
    final List<String> receivers = ["K. A. Vaghela", "Nimeshbhai Parmar", "Rameshbhai Patel"];
    final currentUsername = authProvider.currentUser?.username;
    if (currentUsername != null && !receivers.contains(currentUsername)) {
      receivers.add(currentUsername);
    }
    
    if (_receivedBy == null && receivers.isNotEmpty) {
      _receivedBy = receivers[0];
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "New Donation",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Donation Form (No Documents Required)",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Submit quick donation details. Enter mobile number to auto-populate donor.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Mobile Number (On Top)
              CustomTextField(
                controller: _mobileController,
                label: "Mobile Number *",
                prefixIcon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                suffixIcon: _isSearchingMobile
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : _isExistingDonor
                        ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                        : null,
                validator: (val) => val == null || val.trim().length != 10
                    ? "Enter a valid 10-digit mobile number"
                    : null,
              ),
              if (_lookupStatusMessage != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _lookupStatusMessage!,
                    style: TextStyle(
                      color: _lookupStatusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Donor Name Prefix Dropdown
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
                  onChanged: _isExistingDonor
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _namePrefix = val;
                            });
                          }
                        },
                ),
              ),
              const SizedBox(height: 16),

              // Full Name Textbox
              CustomTextField(
                controller: _fullNameController,
                label: "Donor Full Name *",
                prefixIcon: Icons.person_outline_rounded,
                readOnly: _isExistingDonor,
                validator: (val) => val == null || val.trim().isEmpty
                    ? "Full Name is required"
                    : null,
              ),
              const SizedBox(height: 16),

              // Donation Amount
              CustomTextField(
                controller: _amountController,
                label: "Donation Amount (₹) *",
                prefixIcon: Icons.currency_rupee_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Donation Amount is required";
                  }
                  final amt = double.tryParse(val.trim());
                  if (amt == null || amt <= 0) {
                    return "Enter a valid amount greater than 0";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Address
              CustomTextField(
                controller: _emailController,
                label: "Email Address",
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                readOnly: _isExistingDonor,
              ),
              const SizedBox(height: 16),

              // Native Village Textbox
              CustomTextField(
                controller: _nativeVillageController,
                label: "Native Village",
                prefixIcon: Icons.holiday_village_outlined,
                readOnly: _isExistingDonor,
              ),
              const SizedBox(height: 16),

              // Nearest Railway Station
              CustomTextField(
                controller: _stationController,
                label: "Nearest Railway Station (Optional)",
                prefixIcon: Icons.train_outlined,
                readOnly: _isExistingDonor,
              ),
              const SizedBox(height: 16),

              // PAN Card Number
              CustomTextField(
                controller: _panController,
                label: "PAN Card Number (Optional)",
                prefixIcon: Icons.badge_outlined,
                readOnly: _isExistingDonor,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  if (!Validators.validatePAN(val)) {
                    return "Enter a valid 10-digit PAN (e.g. ABCDE1234F)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Aadhaar Card Number
              CustomTextField(
                controller: _aadhaarController,
                label: "Aadhaar Card Number (Optional)",
                prefixIcon: Icons.fingerprint_outlined,
                keyboardType: TextInputType.number,
                readOnly: _isExistingDonor,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  if (!Validators.validateAadhaar(val)) {
                    return "Enter a valid 12-digit Aadhaar number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Verification Documents (Optional)
              if (!_isExistingDonor) ...[
                const Text(
                  "Verification Documents (Optional)",
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildFileSelector("PAN Card Copy", _panFile, () => _pickFile(true)),
                const SizedBox(height: 12),
                _buildFileSelector("Aadhaar Card Copy", _aadhaarFile, () => _pickFile(false)),
                const SizedBox(height: 16),
              ],

              // Purpose Dropdown
              const Text(
                "Purpose of Donation *",
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
                  value: _purpose,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(border: InputBorder.none),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  items: _purposes.map((String pur) {
                    return DropdownMenuItem<String>(
                      value: pur,
                      child: Text(pur),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _purpose = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Detailed Description (500 char limit)
              CustomTextField(
                controller: _detailedDescriptionController,
                label: "Detailed Description (Max 500 characters) *",
                prefixIcon: Icons.description_rounded,
                maxLines: 3,
                maxLength: 500,
                validator: (val) => val == null || val.trim().isEmpty
                    ? "Detailed Description is required"
                    : null,
              ),
              const SizedBox(height: 16),

              // Payment Mode Dropdown
              const Text(
                "Payment Mode *",
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
                  value: _paymentMode,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(border: InputBorder.none),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  items: _modes.map((String mode) {
                    return DropdownMenuItem<String>(
                      value: mode,
                      child: Text(mode),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _paymentMode = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Conditional Payment Fields
              if (_paymentMode == "UPI" || _paymentMode == "Bank Transfer") ...[
                CustomTextField(
                  controller: _bankNameController,
                  label: "Bank Name *",
                  prefixIcon: Icons.account_balance_rounded,
                  validator: (val) => val == null || val.trim().isEmpty ? "Bank Name is required" : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _txnIdController,
                  label: "Transaction ID / Reference Number *",
                  prefixIcon: Icons.receipt_long_rounded,
                  validator: (val) => val == null || val.trim().isEmpty ? "Transaction ID is required" : null,
                ),
                const SizedBox(height: 16),
              ],

              if (_paymentMode == "Cheque") ...[
                CustomTextField(
                  controller: _bankNameController,
                  label: "Bank Name *",
                  prefixIcon: Icons.account_balance_rounded,
                  validator: (val) => val == null || val.trim().isEmpty ? "Bank Name is required" : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _chequeNoController,
                  label: "Cheque Number *",
                  prefixIcon: Icons.tag,
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.trim().isEmpty ? "Cheque Number is required" : null,
                ),
                const SizedBox(height: 16),
              ],

              if (_paymentMode != "Cash") ...[
                // Transaction Date selector
                const Text("Transaction Date *", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    backgroundColor: AppColors.surface,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _transactionDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (selected != null) {
                      setState(() {
                        _transactionDate = selected;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(DateFormat('dd-MMM-yyyy').format(_transactionDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // Received By Dropdown
                const Text("Payment Received By *", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _receivedBy,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(border: InputBorder.none),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    items: receivers.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _receivedBy = val;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 32),

              CustomButton(
                text: "SUBMIT DONATION",
                isLoading: _isLoading,
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
