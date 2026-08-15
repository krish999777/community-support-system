import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/donor.dart';
import '../services/api_service.dart';
import '../constants/api_routes.dart';

class DonorProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isStatsLoading = false;
  bool _isDonorsLoading = false;
  bool _isAnalyticsLoading = false;
  List<DonorModel> _donors = [];
  DonorModel? _selectedDonor;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _analyticsStats = {};
  String? _errorMessage;

  bool get isLoading => _isLoading || _isStatsLoading || _isDonorsLoading || _isAnalyticsLoading;
  bool get isStatsLoading => _isStatsLoading;
  bool get isDonorsLoading => _isDonorsLoading;
  bool get isAnalyticsLoading => _isAnalyticsLoading;
  List<DonorModel> get donors => _donors;
  DonorModel? get selectedDonor => _selectedDonor;
  Map<String, dynamic> get stats => _stats;
  Map<String, dynamic> get analyticsStats => _analyticsStats;
  String? get errorMessage => _errorMessage;

  final _api = ApiService();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchAllDonors() async {
    _isDonorsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.client.get(ApiRoutes.allDonors);
      if (response.statusCode == 200) {
        final List list = response.data;
        _donors = list.map((item) => DonorModel.fromJson(item)).toList();
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to load donors';
    } catch (e) {
      _errorMessage = 'Failed to load donors';
    } finally {
      _isDonorsLoading = false;
      notifyListeners();
    }
  }

  Future<DonorModel?> searchDonor(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.client.get(ApiRoutes.searchDonor(query));
      if (response.statusCode == 200 && response.data != null) {
        final donor = DonorModel.fromJson(response.data);
        _selectedDonor = donor;
        _isLoading = false;
        notifyListeners();
        return donor;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Donor not found';
    } catch (e) {
      _errorMessage = 'Search failed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> fetchDonorProfile(String mobile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.client.get(ApiRoutes.donorProfile(mobile));
      if (response.statusCode == 200) {
        _selectedDonor = DonorModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to load donor profile';
    } catch (e) {
      _errorMessage = 'Failed to load profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDonor({
    required String fullName,
    required String mobile,
    String? email,
    String? address,
    String? nearestRailwayStation,
    String? pan,
    String? aadhaar,
    File? panFile,
    File? aadhaarFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> dataMap = {
        'fullName': fullName,
        'mobile': mobile,
        'email': email ?? '',
        'address': address ?? '',
        'nearestRailwayStation': nearestRailwayStation ?? '',
        'pan': pan ?? '',
        'aadhaar': aadhaar ?? '',
      };

      FormData formData = FormData.fromMap(dataMap);

      if (panFile != null) {
        formData.files.add(MapEntry(
          'panFile',
          await MultipartFile.fromFile(panFile.path, filename: 'panFile_$mobile.jpg'),
        ));
      }

      if (aadhaarFile != null) {
        formData.files.add(MapEntry(
          'aadhaarFile',
          await MultipartFile.fromFile(aadhaarFile.path, filename: 'aadhaarFile_$mobile.jpg'),
        ));
      }

      final response = await _api.client.post(
        ApiRoutes.addDonor,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to add donor';
    } catch (e) {
      _errorMessage = 'Error adding donor';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> updateDonor({
    required String originalMobile,
    required String fullName,
    required String mobile,
    String? email,
    String? address,
    String? nearestRailwayStation,
    String? pan,
    String? aadhaar,
    File? panFile,
    File? aadhaarFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> dataMap = {
        'fullName': fullName,
        'mobile': mobile,
        'email': email ?? '',
        'address': address ?? '',
        'nearestRailwayStation': nearestRailwayStation ?? '',
        'pan': pan ?? '',
        'aadhaar': aadhaar ?? '',
      };

      FormData formData = FormData.fromMap(dataMap);

      if (panFile != null) {
        formData.files.add(MapEntry(
          'panFile',
          await MultipartFile.fromFile(panFile.path, filename: 'panFile_$mobile.jpg'),
        ));
      }

      if (aadhaarFile != null) {
        formData.files.add(MapEntry(
          'aadhaarFile',
          await MultipartFile.fromFile(aadhaarFile.path, filename: 'aadhaarFile_$mobile.jpg'),
        ));
      }

      final response = await _api.client.put(
        ApiRoutes.donorProfile(originalMobile),
        data: formData,
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to update donor';
    } catch (e) {
      _errorMessage = 'Error updating donor';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteDonor(String mobile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.client.delete(ApiRoutes.donorProfile(mobile));
      if (response.statusCode == 200) {
        _donors.removeWhere((d) => d.mobile == mobile);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to delete donor';
    } catch (e) {
      _errorMessage = 'Error deleting donor';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> addDonation({
    required String donorId,
    required String fullName,
    required double amount,
    required String mode,
    required String purpose,
    String? phone,
    String? email,
    String? transactionId,
    String? chequeNumber,
    String? accountNumber,
    String? ifsc,
    DateTime? date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.client.post(
        ApiRoutes.donate,
        data: {
          'donorId': donorId,
          'fullName': fullName,
          'amount': amount,
          'mode': mode,
          'purpose': purpose,
          'phone': phone,
          'email': email,
          'transactionId': transactionId,
          'chequeNumber': chequeNumber,
          'accountNumber': accountNumber,
          'ifsc': ifsc,
          'date': date?.toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to record donation';
    } catch (e) {
      _errorMessage = 'Error recording donation';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> fetchDashboardStats() async {
    _isStatsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.client.get(ApiRoutes.stats);
      if (response.statusCode == 200) {
        _stats = response.data;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to fetch dashboard stats';
    } catch (e) {
      _errorMessage = 'Error loading dashboard data';
    } finally {
      _isStatsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnalyticsStats({String? year, String? month, String? purpose}) async {
    _isAnalyticsLoading = true;
    _errorMessage = null;
    _analyticsStats = {}; // Reset previous stats
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};
      if (year != null && year != "All Time" && year != "all") {
        final regex = RegExp(r'\d+');
        final match = regex.firstMatch(year);
        if (match != null) {
          queryParams['year'] = match.group(0);
        } else {
          queryParams['year'] = year;
        }
      }
      if (month != null && month != "All" && month != "all") {
        queryParams['month'] = month.toLowerCase();
      }
      if (purpose != null && purpose != "All" && purpose != "all") {
        queryParams['purpose'] = purpose;
      }

      final response = await _api.client.get(
        ApiRoutes.stats,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        _analyticsStats = response.data;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to fetch analytics stats';
    } catch (e) {
      _errorMessage = 'Error loading analytics data';
    } finally {
      _isAnalyticsLoading = false;
      notifyListeners();
    }
  }
}
