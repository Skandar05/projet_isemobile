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
      final classId = item['id'];
      if (classId == null) {
        continue;
      }

      final response2 = await _client.get(
        Uri.parse('$baseUrl/api/parents-eleves-classe/$classId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response2.statusCode != 200) {
        continue;
      }

      final payload = jsonDecode(response2.body);
      if (payload is! List) {
        continue;
      }

      final className = item['nomclassefr']?.toString() ?? '';

      for (final entry in payload) {
        if (entry is! Map) {
          continue;
        }

        final studentMap = Map<String, dynamic>.from(entry);
        final parents = studentMap['parents'];
        final parentNames = <String>[];

        if (parents is List) {
          for (final parent in parents) {
            if (parent is Map) {
              final firstName = parent['prenomfr']?.toString() ?? '';
              final lastName = parent['nomfr']?.toString() ?? '';
              final name = [firstName, lastName]
                  .where((value) => value.isNotEmpty)
                  .join(' ')
                  .trim();
              if (name.isNotEmpty) {
                parentNames.add(name);
              }
            }
          }
        }

        final firstName = studentMap['eleve_prenomfr']?.toString() ?? '';
        final lastName = studentMap['eleve_nomfr']?.toString() ?? '';
        final fullName = [firstName, lastName]
            .where((value) => value.isNotEmpty)
            .join(' ')
            .trim();

        students.add({
          'id': studentMap['eleve_id'],
          'fullName': fullName,
          'firstName': firstName,
          'lastName': lastName,
          'className': className,
          'classId': classId.toString(),
          'parentNames': parentNames.join(' '),
          'raw': studentMap,
        });
      }
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