import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../constants/colors.dart';
import '../../../models/donor.dart';
import '../../../providers/auth_provider.dart';
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
  late TextEditingController _detailedDescriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  
  // Conditional payment controllers
  late TextEditingController _bankNameController;
  late TextEditingController _txnIdController;
  late TextEditingController _chequeNoController;
  DateTime _transactionDate = DateTime.now();

  String _paymentMode = "Cash";
  final List<String> _modes = ["Cash", "UPI", "Bank Transfer", "Cheque"];

  String _purpose = "General";
  final List<String> _purposes = ["Marriage", "Death", "Birthday", "General", "Other"];

  String? _receivedBy;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _detailedDescriptionController = TextEditingController();
    _phoneController = TextEditingController(text: widget.donor.mobile);
    _emailController = TextEditingController(text: widget.donor.email ?? "");
    
    _bankNameController = TextEditingController();
    _txnIdController = TextEditingController();
    _chequeNoController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _detailedDescriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bankNameController.dispose();
    _txnIdController.dispose();
    _chequeNoController.dispose();
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

    // Combine purpose dropdown and detailed description
    final detailedDesc = _detailedDescriptionController.text.trim();
    final purposeVal = detailedDesc.isNotEmpty ? "$_purpose - $detailedDesc" : _purpose;

    bool success = await donorProvider.addDonation(
      donorId: widget.donor.id ?? '',
      fullName: widget.donor.fullName,
      amount: amt,
      mode: _paymentMode,
      purpose: purposeVal,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      transactionId: (_paymentMode == "UPI" || _paymentMode == "Bank Transfer") ? _txnIdController.text.trim() : null,
      chequeNumber: (_paymentMode == "Cheque") ? _chequeNoController.text.trim() : null,
      accountNumber: (_paymentMode != "Cash") ? _bankNameController.text.trim() : null, // Bank name in accountNumber
      ifsc: (_paymentMode != "Cash") ? _receivedBy : null, // Payment received by in ifsc
      date: _transactionDate,
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

              // Mode Selection Dropdown
              const Text("Payment Mode *", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
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
