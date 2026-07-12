import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> saveUserInfo(String username, String role) async {
    await _storage.write(key: 'username', value: username);
    await _storage.write(key: 'role', value: role);
  }

  Future<Map<String, String?>> getUserInfo() async {
    final username = await _storage.read(key: 'username');
    final role = await _storage.read(key: 'role');
    return {'username': username, 'role': role};
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
