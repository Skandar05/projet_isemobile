import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../screens/Parent/home_Parent.dart';
import '../Screens/Enseignant/home_Enseignant.dart';
import '../Screens/Pedagogique/home_Pedagogique.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  int? idPersonne;
  String? token;
  String? role;

  // Informations de la personne connectée
  String? nomFr;
  String? prenomFr;
  int? civilite;
  String? matiere;

  final   _baseUrl = dotenv.env['BACKEND_URL'];

  Future<String?> login({
    required String identifier,
    required String password,
  }) async {
    errorMessage = null;

    if (identifier.isEmpty || password.isEmpty) {
      errorMessage = 'Veuillez remplir les deux champs.';
      notifyListeners();
      return null;
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/login'),
        headers: const {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'username': identifier,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        errorMessage =
            'Identifiant ou mot de passe incorrect (${response.statusCode}).';
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
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('idE', idPersonne ?? 0);
      
      role = extractedRole;

      // Récupérer le nom/prénom depuis l'API Getpersonne
      if (idPersonne != null) {
        await _fetchPersonneInfo(idPersonne!);
      }

      return extractedRole;
    } catch (error) {
      errorMessage = 'Erreur réseau : $error';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Appel API Getpersonne pour récupérer le nom et prénom
  Future<void> _fetchPersonneInfo(int idPers) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/Getpersonne/$idPers'),
      );
      

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // The API may return a map with name fields or a list with subject info.
        if (data is Map<String, dynamic>) {
          nomFr = data['Nomfr'] as String?;
          prenomFr = data['Prenomfr'] as String?;
          civilite = data['Civilite'] as int?;
        } else if (data is List && data.isNotEmpty) {
          final first = data[0];
          if (first is Map<String, dynamic>) {
            // Example: [{"id":8465,"Nommatierefr":"arabe"}]
            matiere = (first['Nommatierefr'] ?? first['nomMatiere'] ?? first['matiere']) as String?;

            // Persist the subject so other screens can read it from SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            if (matiere != null && matiere!.isNotEmpty) {
              await prefs.setString('matiere', matiere!);
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur Getpersonne : $e');
    }
  }

  /// Renvoie le nom complet formaté (Prénom NOM)
  String get fullName {
    final p = prenomFr ?? '';
    final n = nomFr ?? '';
    if (p.isEmpty && n.isEmpty) return 'Utilisateur';
    if (p.isEmpty) return n;
    if (n.isEmpty) return p;
    return '$p $n';
  }

  /// Renvoie la civilité sous forme de texte
  String get civiliteLabel {
    switch (civilite) {
      case 1:
        return 'M.';
      case 2:
        return 'Mme';
      default:
        return '';
    }
  }

  Future<void> openRoleHome(BuildContext context, String role) async {
    final normalizedRole = role.trim().toUpperCase();

    Widget page;
    if (normalizedRole.contains('PARENT')) {
      page = const HomeParent();
    } else if (normalizedRole.contains('ENSEIGNANT') ||
        normalizedRole.contains('ENG')) {
      page = const HomeEnseignant();
    } else if (normalizedRole.contains('ADMIN') ||
        normalizedRole.contains('PD') ||
        normalizedRole.contains('PEDAGOGIQUE')) {
      page = const HomeCScreen();
    } else {
      page = const HomeCScreen();
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Map<String, dynamic> _parseJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Format de jeton invalide');
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      return json.decode(resp);
    } catch (e) {
      debugPrint('Erreur parsing JWT: $e');
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