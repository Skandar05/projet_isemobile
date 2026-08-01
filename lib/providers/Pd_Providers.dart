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
      
      'heuredebut': debut,
      'heurefin': fin,
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
  debugPrint('Fetched ${decoded} disponibilites for pedagogique $idPedagogique');
  if (decoded is! List) {
    throw Exception('Unexpected response format');
  }

  return List<Map<String, dynamic>>.from(decoded);



}




Future<List<Map<String, dynamic>>> getAllClasses() async {
  final List<Map<String, dynamic>> classes = [];
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

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load classes. Status code: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Expected a JSON array');
    }

    for (final item in decoded) {
      if (item is Map) {
        classes.add(Map<String, dynamic>.from(item));
      }
    }
  } catch (e) {
    debugPrint('Error fetching classes: $e');
    return [];
  }

  return classes;
}

Future<List<Map<String, dynamic>>> getAllStudentsForSearch() async {
  final List<Map<String, dynamic>> students = [];
  final baseUrl = _baseUrl;

  if (baseUrl == null || baseUrl.isEmpty) {
    throw Exception('BACKEND_URL is not configured');
  }

  try {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/eleves/classes/responsables'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      return [];
    }

    final payload = jsonDecode(response.body);

    if (payload is! List) {
      return [];
    }

    for (final entry in payload) {
      if (entry is! Map) continue;

      final studentMap = Map<String, dynamic>.from(entry);

      final parentName =
          studentMap['nomResponsable']?.toString() ?? '';

      final parentFirstName =
          studentMap['prenomResponsable']?.toString() ?? '';

      final parents =
          '$parentName $parentFirstName'.trim();

      final int parentId =
          int.tryParse(
            studentMap['idResponsable']?.toString() ?? ''
          ) ?? 0;

      final firstName =
          studentMap['prenomEleve']?.toString() ?? '';

      final lastName =
          studentMap['nomEleve']?.toString() ?? '';

      final className =
          studentMap['classe']?.toString() ?? '';

      final fullName = [
        firstName,
        lastName,
      ]
          .where((value) => value.isNotEmpty)
          .join(' ')
          .trim();
      debugPrint('Adding student: $fullName, Class: $className, Parent: $parentId');
      students.add({
        'id': studentMap['eleveId'],
        'fullName': fullName,
        'firstName': firstName,
        'lastName': lastName,
        'parentNames': parents,
        'parentId': parentId,
        'className': className,
        'raw': studentMap,
      });
    }

  } catch (e) {
    debugPrint('Error fetching students for search: $e');
    return [];
  }

  

  return students;
}
Future<void>updatedisponibility(int idDisponibilite, String debut, String fin, String jour) async {
  final baseUrl = _baseUrl;

  if (baseUrl == null || baseUrl.isEmpty) {
    throw Exception('BACKEND_URL is not configured');
  }

  final response = await _client.put(
    Uri.parse('$baseUrl/api/Pedagogique/disponibilites/$idDisponibilite'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'heuredebut': debut,
      'heurefin': fin,
      'jour': jour,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to update disponibilite (${response.statusCode})',
    );
  }
}

Future<void> deletedisponibility(int idDisponibilite) async {
  final baseUrl = _baseUrl;

  if (baseUrl == null || baseUrl.isEmpty) {
    throw Exception('BACKEND_URL is not configured');
  }

  final response = await _client.delete(
    Uri.parse('$baseUrl/api/Pedagogique/disponibilites/$idDisponibilite'),
    headers: {
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to delete disponibilite (${response.statusCode})',
    );
  }


}

}