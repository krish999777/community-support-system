import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/donor_provider.dart';
import 'add_donor_screen.dart';
import 'donor_detail_screen.dart';

class DonorListScreen extends StatefulWidget {
  const DonorListScreen({super.key});

  @override
  _DonorListScreenState createState() => _DonorListScreenState();
}

class _DonorListScreenState extends State<DonorListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DonorProvider>(context, listen: false).fetchAllDonors();
    });
  }

  void _onSearchSubmit(String query) {
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final donorProvider = Provider.of<DonorProvider>(context);

    final query = _searchController.text.trim().toLowerCase();
    final displayedDonors = query.isNotEmpty
        ? donorProvider.donors.where((donor) {
            return donor.fullName.toLowerCase().contains(query) ||
                donor.mobile.contains(query);
          }).toList()
        : donorProvider.donors;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Donor Directory",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearchSubmit,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "Search by Name or Mobile...",
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: AppColors.background,
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: _clearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),

          // Directory List
          Expanded(
            child: donorProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : displayedDonors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              "No Donors Registered Yet",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: displayedDonors.length,
                        itemBuilder: (context, index) {
                          final donor = displayedDonors[index];
                          return Card(
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border, width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  donor.fullName.isNotEmpty ? donor.fullName[0].toUpperCase() : 'D',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                donor.fullName,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      donor.mobile,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DonorDetailScreen(mobile: donor.mobile),
                                  ),
                                ).then((_) {
                                  // Refresh list when returning
                                  if (!_isSearching) {
                                    donorProvider.fetchAllDonors();
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDonorScreen()),
          ).then((_) {
            if (!_isSearching) {
              donorProvider.fetchAllDonors();
            }
          });
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
