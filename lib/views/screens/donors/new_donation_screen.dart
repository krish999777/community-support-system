import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/donor_provider.dart';
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

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _mobileController;
  late TextEditingController _amountController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _customPurposeController;

  String _paymentMode = "Cash";
  final List<String> _modes = ["Cash", "UPI", "Bank Transfer", "Cheque"];
  bool _isLoading = false;

  // Donor lookup state variables
  bool _isSearchingMobile = false;
  bool _isExistingDonor = false;
  String? _existingDonorId;
  String? _lookupStatusMessage;
  Color _lookupStatusColor = Colors.transparent;

  String _selectedPurpose = "Education";
  final List<String> _purposes = ["Education", "Marriage", "Death", "Birth", "Other"];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _mobileController = TextEditingController();
    _amountController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _customPurposeController = TextEditingController();

    // Start listening to mobile number changes for on-the-fly lookup
    _mobileController.addListener(_onMobileChanged);
  }

  @override
  void dispose() {
    _mobileController.removeListener(_onMobileChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _amountController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _customPurposeController.dispose();
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
          _firstNameController.clear();
          _lastNameController.clear();
          _emailController.clear();
          _addressController.clear();
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

          // Split full name into first and last names
          String fullName = donor.fullName;
          List<String> parts = fullName.split(' ');
          _firstNameController.text = parts.isNotEmpty ? parts[0] : '';
          _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';

          _emailController.text = donor.email ?? '';
          _addressController.text = donor.address ?? '';

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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final mobile = _mobileController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullNameInput = "$firstName $lastName";
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final purpose = _selectedPurpose == "Other"
        ? _customPurposeController.text.trim()
        : _selectedPurpose;

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
          // Register donor if not found (without needing PAN/Aadhaar)
          bool donorCreated = await donorProvider.addDonor(
            fullName: fullNameInput,
            mobile: mobile,
            email: email.isNotEmpty ? email : null,
            address: address.isNotEmpty ? address : null,
            pan: "",
            aadhaar: "",
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
        purpose: purpose,
        phone: mobile,
        email: email.isNotEmpty ? email : null,
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

              // First & Last Name
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _firstNameController,
                      label: "First Name *",
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? "First Name is required"
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _lastNameController,
                      label: "Last Name *",
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? "Last Name is required"
                          : null,
                    ),
                  ),
                ],
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
              ),
              const SizedBox(height: 16),

              // Address
              CustomTextField(
                controller: _addressController,
                label: "Address (Location of Living)",
                prefixIcon: Icons.home_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Purpose of Donation Dropdown
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
                  value: _selectedPurpose,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(border: InputBorder.none),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  items: _purposes.map((String purpose) {
                    return DropdownMenuItem<String>(
                      value: purpose,
                      child: Text(purpose),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPurpose = val;
                      });
                    }
                  },
                ),
              ),
              if (_selectedPurpose == "Other") ...[
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _customPurposeController,
                  label: "Describe custom purpose *",
                  prefixIcon: Icons.edit_note_rounded,
                  validator: (val) => _selectedPurpose == "Other" && (val == null || val.trim().isEmpty)
                      ? "Custom purpose description is required"
                      : null,
                ),
              ],
              const SizedBox(height: 16),

              // Payment Mode Dropdown
              const Text(
                "Payment Mode",
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
}
