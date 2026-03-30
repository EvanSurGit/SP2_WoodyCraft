import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // ⚠️ Sur émulateur Edge/Chrome on utilise localhost
  // Sur vrai téléphone Android remplace par ton IP locale ex: http://192.168.1.XX:8000
  static const String baseUrl = 'http://groupe2.lycee.local';

  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Stockage sécurisé du token et du rôle
      await _storage.write(key: 'access_token', value: data['access_token']);
      await _storage.write(key: 'user_role', value: data['user']['role']);
      return {'success': true, 'user': data['user']};
    } else if (response.statusCode == 403) {
      return {'success': false, 'message': 'Accès refusé. Réservé aux administrateurs.'};
    } else {
      return {'success': false, 'message': 'Identifiants incorrects.'};
    }
  }

  Future<void> logout() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    }
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}