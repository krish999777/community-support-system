import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../constants/api_routes.dart';

class PinProvider with ChangeNotifier {
  bool _isLoading = false;
  List<dynamic> _pins = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<dynamic> get pins => _pins;
  String? get errorMessage => _errorMessage;

  final _api = ApiService();

  Future<void> fetchPins() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.client.get(ApiRoutes.pins);
      if (response.statusCode == 200) {
        _pins = response.data as List;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to load access PINs';
    } catch (e) {
      _errorMessage = 'Failed to load PINs';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPin(String pin, String label, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.client.post(
        ApiRoutes.pins,
        data: {
          'pin': pin,
          'label': label,
          'role': role,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to create access PIN';
    } catch (e) {
      _errorMessage = 'Failed to create PIN';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deletePin(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.client.delete("${ApiRoutes.pins}/$id");
      if (response.statusCode == 200) {
        _pins.removeWhere((p) => p['_id'] == id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to delete access PIN';
    } catch (e) {
      _errorMessage = 'Failed to delete PIN';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
