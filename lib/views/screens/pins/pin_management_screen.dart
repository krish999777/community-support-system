import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/pin_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class PinManagementScreen extends StatefulWidget {
  const PinManagementScreen({super.key});

  @override
  _PinManagementScreenState createState() => _PinManagementScreenState();
}

class _PinManagementScreenState extends State<PinManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  
  String _selectedRole = "admin";
  final List<String> _roles = ["admin", "operator"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PinProvider>(context, listen: false).fetchPins();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _createPin() async {
    if (!_formKey.currentState!.validate()) return;

    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    bool success = await pinProvider.createPin(
      _pinController.text.trim(),
      _labelController.text.trim(),
      _selectedRole,
    );

    if (success) {
      _pinController.clear();
      _labelController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Access PIN created successfully!"), backgroundColor: AppColors.accent),
        );
      }
      pinProvider.fetchPins();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pinProvider.errorMessage ?? "Failed to create PIN"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _deletePin(String id, String label) async {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Delete PIN", style: TextStyle(color: AppColors.textPrimary)),
        content: Text("Revoke access for '$label'?", style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Revoke", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await pinProvider.deletePin(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Access PIN deleted successfully"), backgroundColor: AppColors.accent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinProvider = Provider.of<PinProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text("Access Control", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // PIN Creator Form
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Generate Access Key", style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          controller: _pinController,
                          label: "PIN *",
                          hint: "4 digits",
                          prefixIcon: Icons.pin,
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.trim().length != 4 ? "4 digits" : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          controller: _labelController,
                          label: "Label / Name *",
                          hint: "e.g. Staff User",
                          prefixIcon: Icons.label_outline,
                          validator: (val) => val == null || val.trim().isEmpty ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: "Access Level",
                            labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase()))).toList(),
                          onChanged: (val) => setState(() => _selectedRole = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        height: 48,
                        child: CustomButton(
                          text: "CREATE",
                          height: 48,
                          isLoading: pinProvider.isLoading,
                          onPressed: _createPin,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // PIN list
          Expanded(
            child: pinProvider.isLoading && pinProvider.pins.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: pinProvider.pins.length,
                    itemBuilder: (context, index) {
                      final item = pinProvider.pins[index];
                      return Card(
                        color: AppColors.surface,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.key, color: AppColors.primary),
                          ),
                          title: Text(item['label'] ?? 'Unknown User', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                          subtitle: Text("Level: ${(item['role'] ?? 'staff').toString().toUpperCase()}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () => _deletePin(item['_id'], item['label'] ?? ''),
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
