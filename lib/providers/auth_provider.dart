import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../screens/home_ Parent.dart';
import '../screens/home_Enseignant.dart';
import '../screens/home_Pedagogique.dart';
import '../screens/home_Eleve.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  int? idPersonne;
  String? token;
  String? role;

  static const String _authUrl = 'http://apiserv.ise-college-lycee.com:8415/api/login';

  Future<String?> login({
    required String identifier,
    required String password,
  }) async {
    errorMessage = null;

    if (identifier.isEmpty || password.isEmpty) {
      errorMessage = 'Please fill in both fields.';
      notifyListeners();
      return null;
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(_authUrl),
        headers: const {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'username': identifier,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        errorMessage = 'Identifiant ou mot de passe incorrect (${response.statusCode}).';
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded['token'] == null) {
        errorMessage = 'Identifiant ou mot de passe incorrect';
        return null;
      }

      final jwtToken = decoded['token'] as String;
      final payload = _parseJwt(jwtToken);
      final extractedRole = _extractRole(payload);

      if (extractedRole == null) {
        errorMessage = 'Rôle non trouvé dans le jeton API.';
        return null;
      }

      token = jwtToken;
      idPersonne = payload['idpersonne'] as int?;
      role = extractedRole;

      return extractedRole;
    } catch (error) {
      errorMessage = 'Erreur réseau : $error';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openRoleHome(BuildContext context, String role) async {
    final normalizedRole = role.trim().toUpperCase();

    Widget page;
    if (normalizedRole.contains('PARENT')) {
      page = const HomeAScreen();
    } else if (normalizedRole.contains('ENSEIGNANT') || normalizedRole.contains('ENG')) {
      page = const HomeBScreen();
    } else if (normalizedRole.contains('USER') || normalizedRole.contains('ELEVE') || normalizedRole.contains('STUDENT')) {
      page = const HomeDScreen();
    } else if (normalizedRole.contains('ADMIN') || normalizedRole.contains('PD') || normalizedRole.contains('PEDAGOGIQUE')) {
      page = const HomeCScreen();
    } else {
      // Default fallback
      page = const HomeCScreen();
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Map<String, dynamic> _parseJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token format');
      }
      final payload = parts[1];
      var normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      return json.decode(resp);
    } catch (e) {
      debugPrint('Error parsing JWT: $e');
      return {};
    }
  }

  String? _extractRole(Map<String, dynamic> payload) {
    final roles = payload['roles'];
    if (roles is List) {
      return roles.join(',');
    } else if (roles != null) {
      return roles.toString();
    }
    return null;
  }
}