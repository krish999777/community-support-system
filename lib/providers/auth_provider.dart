import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../constants/api_routes.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  UserModel? _currentUser;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  final _storage = StorageService();
  final _api = ApiService();

  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.getToken();
      final userInfo = await _storage.getUserInfo();
      if (token != null && userInfo['username'] != null && userInfo['role'] != null) {
        _currentUser = UserModel(
          username: userInfo['username']!,
          role: userInfo['role']!,
          token: token,
        );
      }
    } catch (e) {
      print("Auto login error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.client.post(
        ApiRoutes.loginPin,
        data: {'pin': pin},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        _currentUser = UserModel.fromJson(data);
        
        await _storage.saveToken(_currentUser!.token);
        await _storage.saveUserInfo(_currentUser!.username, _currentUser!.role);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Authentication failed';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _storage.clearAll();
    notifyListeners();
  }
}
