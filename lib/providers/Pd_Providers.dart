import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PdProvider extends ChangeNotifier {
  final http.Client _client = http.Client();

  String? get _baseUrl => dotenv.env['BACKEND_URL']?.trim();

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> getAllRdv(String demandeurRole) async {
  final baseUrl = _baseUrl;

  if (baseUrl == null || baseUrl.isEmpty) {
    throw Exception('BACKEND_URL is not configured');
  }

  final response = await _client.get(
    Uri.parse('$baseUrl/api/rendezvous/demandeurs/$demandeurRole'),
    headers: {
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to load rendezvous (${response.statusCode})',
    );
  }

  final decoded = jsonDecode(response.body);
  debugPrint('Fetched ${decoded.length} rendezvous for role $demandeurRole');

  if (decoded is! List) {
    throw Exception('Unexpected response format');
  }

  return List<Map<String, dynamic>>.from(decoded);
}

Future<Map<String, String>> getPvCount() async {
  final baseUrl = _baseUrl;
  final List<String> roles = [
    'enseignant',
    'parent',
    'Pedagogique',
  ];

  Map<String, String> counts = {};

  if (baseUrl == null || baseUrl.isEmpty) {
    throw Exception('BACKEND_URL is not configured');
  }

  for (final role in roles) {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/rendezvous/demandeurs/$role'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load rendezvous for role $role (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Unexpected response format for role $role');
    }

    counts[role] = decoded.length.toString();
  }
  debugPrint('Rendezvous counts: $counts');

  return counts;
}
Future<void> creationdiponibilite (int idPedagogique , String debut, String fin, String jour)async {
  final baseUrl = _baseUrl;

  if (baseUrl == null || baseUrl.isEmpty) {
    throw Exception('BACKEND_URL is not configured');
  }

  final response = await _client.post(
    Uri.parse('$baseUrl/api/Pedagogique/disponibilites/$idPedagogique'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      
      'disponibilite_debut': debut,
      'disponibilite_fin': fin,
      'jour': jour,
    }),
  );

  if (response.statusCode != 201) {
    throw Exception(
      'Failed to create disponibilite (${response.statusCode})',
    );
  }
}


Future<List<Map<String, dynamic>>> getAllDisponibilites(int idPedagogique) async {
  final baseUrl = _baseUrl;

  if (baseUrl == null || baseUrl.isEmpty) {
    throw Exception('BACKEND_URL is not configured');
  }

  final response = await _client.get(
    Uri.parse('$baseUrl/api/Pedagogique/disponibilites/$idPedagogique'),
    headers: {
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to load disponibilites (${response.statusCode})',
    );
  }

  final decoded = jsonDecode(response.body);

  if (decoded is! List) {
    throw Exception('Unexpected response format');
  }

  return List<Map<String, dynamic>>.from(decoded);



}




Future<List<dynamic>> getAllClasses() async {
  final baseUrl = _baseUrl;

  if (baseUrl == null || baseUrl.isEmpty) {
    throw Exception('BACKEND_URL is not configured');
  }

  try {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/getIClasseActifMobile'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        debugPrint('Fetched ${decoded.length} classes with response: ${response.body}');
        return List<dynamic>.from(decoded);
      } else {
        throw Exception('Expected a JSON array');
      }
    } else {
      throw Exception(
        'Failed to load classes. Status code: ${response.statusCode}',
      );
    }
  } catch (e) {
    debugPrint('Error fetching classes: $e');
    return [];
  }
}

}