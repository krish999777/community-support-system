import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../models/donor.dart';
import '../../../providers/donor_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddDonationScreen extends StatefulWidget {
  final DonorModel donor;

  const AddDonationScreen({super.key, required this.donor});

  @override
  _AddDonationScreenState createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _customPurposeController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _txnIdController;
  late TextEditingController _chequeNoController;
  late TextEditingController _accountNoController;
  late TextEditingController _ifscController;

  String _paymentMode = "Cash";
  final List<String> _modes = ["Cash", "UPI", "Bank Transfer", "Cheque"];

  String _selectedPurpose = "Education";
  final List<String> _purposes = ["Education", "Marriage", "Death", "Birth", "Other"];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _customPurposeController = TextEditingController();
    _phoneController = TextEditingController(text: widget.donor.mobile);
    _emailController = TextEditingController(text: widget.donor.email ?? "");
    _txnIdController = TextEditingController();
    _chequeNoController = TextEditingController();
    _accountNoController = TextEditingController();
    _ifscController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customPurposeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _txnIdController.dispose();
    _chequeNoController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  void _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    
    double? amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount greater than 0"), backgroundColor: AppColors.error),
      );
      return;
    }

    final purpose = _selectedPurpose == "Other" 
        ? _customPurposeController.text.trim() 
        : _selectedPurpose;

    bool success = await donorProvider.addDonation(
      donorId: widget.donor.id ?? '',
      fullName: widget.donor.fullName,
      amount: amt,
      mode: _paymentMode,
      purpose: purpose,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      transactionId: _txnIdController.text.trim(),
      chequeNumber: _chequeNoController.text.trim(),
      accountNumber: _accountNoController.text.trim(),
      ifsc: _ifscController.text.trim(),
    );

    if (success) {
      if (mounted) {
        Provider.of<DonorProvider>(context, listen: false).fetchDashboardStats();
        Provider.of<DonorProvider>(context, listen: false).fetchAllDonors();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Donation recorded successfully! Receipt generated."),
            backgroundColor: AppColors.accent,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(donorProvider.errorMessage ?? "Failed to save donation."),
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
        title: const Text("Record Donation", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Donor Info Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("DONOR", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      widget.donor.fullName,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "+91 ${widget.donor.mobile}",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Inputs
              CustomTextField(
                controller: _amountController,
                label: "Donation Amount (₹) *",
                prefixIcon: Icons.currency_rupee_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val == null || val.trim().isEmpty ? "Amount is required" : null,
              ),
              const SizedBox(height: 16),

              // Mode Selection Dropdown
              const Text("Payment Mode *", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.transparent),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _paymentMode,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    isExpanded: true,
                    items: _modes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _paymentMode = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Purpose of Donation Dropdown
              const Text(
                "Purpose of Donation *",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.transparent),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPurpose,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    isExpanded: true,
                    items: _purposes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedPurpose = newValue!;
                      });
                    },
                  ),
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

              // Conditional Fields based on mode
              if (_paymentMode == "UPI" || _paymentMode == "Bank Transfer") ...[
                CustomTextField(
                  controller: _txnIdController,
                  label: "Transaction ID / Reference Number *",
                  prefixIcon: Icons.receipt_long_rounded,
                  validator: (val) => val == null || val.trim().isEmpty ? "Transaction ID is required for digital payments" : null,
                ),
                const SizedBox(height: 16),
              ],

              if (_paymentMode == "Cheque") ...[
                CustomTextField(
                  controller: _chequeNoController,
                  label: "Cheque Number *",
                  prefixIcon: Icons.tag,
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.trim().isEmpty ? "Cheque Number is required" : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _accountNoController,
                  label: "Account Number",
                  prefixIcon: Icons.account_balance,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _ifscController,
                  label: "IFSC Code",
                  prefixIcon: Icons.domain,
                ),
                const SizedBox(height: 16),
              ],

              // Contact information for receipt notification
              const Text("Notification Details", style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _phoneController,
                label: "Receipt Mobile Number *",
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().length != 10 ? "10-digit mobile is required" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: "Receipt Email Address",
                prefixIcon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: "SUBMIT DONATION",
                isLoading: donorProvider.isLoading,
                onPressed: _submitDonation,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
