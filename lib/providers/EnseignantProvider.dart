import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnseignantProvider extends ChangeNotifier {

  final _baseUrl = dotenv.env['BACKEND_URL'];
  final http.Client _client = http.Client();
  String? _parentEndpoint;
  Future<String?>? _parentEndpointFuture;
  Future<int?>? _teacherInfoFuture;
  int? _teacherId;
  int? _teacherPersonneId;

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<Map<dynamic, String>> getEnseignantsClasse(int idE) async {
    Map<dynamic, String> classes = {};
    try {
      final response = await _client.get(
        Uri.parse(
          '$_baseUrl/GetClasseEnseignants/$idE/7',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        

        for (var item in data) {
          classes[item['idclasse']] =
              item['nomclassefr'].toString();
        }

        final prefs = await SharedPreferences.getInstance();
        final encoded = <String, String>{}; classes.forEach((key, value) { encoded[key.toString()] = value; }); await prefs.setString('classMap', jsonEncode(encoded));
      } else {
        debugPrint("API error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Exception: $e");
    }
    return classes;
  }

  Future<void> getEnseignantsMatier(int IdE) async {
    List<String> matieres = [];

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/GetMatiereEnseignant/$IdE/'),
        headers: {'Content-Type': 'application/json'},
      );
      final perf = await SharedPreferences.getInstance();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        for (var item in data) {
          matieres.add(item['Nommatierefr']);
        }
        await perf.setStringList('matieres', matieres);
      } else {
        print('Failed to load enseignants. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching enseignants: $e');
    }
  }

  Future<List<dynamic>> GetEleveClass(int IdC) async {
    List<dynamic> eleves = [];

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/eleves/classe/$IdC'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          eleves = data;
        } else {
          print('Unexpected data format: $data');
        }
      } else {
        print('Failed to load eleves. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching eleves: $e');
    }
    return eleves;
  }


  Future<Map<String, dynamic>> getElevesEtParentsClasse(int idClasse) async {
    final Map<String, dynamic> result = {
      'eleves': <Map<String, dynamic>>[],
      'parentsByEleve': <String, List<dynamic>>{},
    };

    try {
      final response = await _client.get(
        Uri.parse(
          '$_baseUrl/api/parents-eleves-classe/' + idClasse.toString(),
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          final eleves = <Map<String, dynamic>>[];
          final parentsByEleve = <String, List<dynamic>>{};

          for (final item in data) {
            final eleveId = item['eleve_id'];
            final eleve = {
              'id': eleveId,
              'nomfr': item['eleve_nomfr'] ?? '',
              'prenomfr': item['eleve_prenomfr'] ?? '',
              'classe_id': item['classe_id'],
              'classe_nomfr': item['classe_nomfr'] ?? '',
            };
            eleves.add(eleve);

            final rawParents = item['parents'] as List<dynamic>? ?? [];
            parentsByEleve[eleveId.toString()] = rawParents.map((p) {
              return {
                'id': p['idparent'] ?? 0,
                'nomfr': p['nomfr'] ?? '',
                'prenomfr': p['prenomfr'] ?? '',
                'type': p['type'] ?? '',
              };
            }).toList();
          }

          result['eleves'] = eleves;
          result['parentsByEleve'] = parentsByEleve;
        }
      } else {
        print('Failed to load eleves/parents. Status code: ' + response.statusCode.toString());
      }
    } catch (e) {
      print('Error fetching eleves/parents: ' + e.toString());
    }

    return result;
  }


Future<List<dynamic>> GetParentEleve(List<dynamic> eleves) async {
  List<dynamic> parents = [];

  final futures = eleves.map((eleve) async {

    int id = eleve['id'];

    try {
      http.Response response = await _client.get(
        Uri.parse(
          '$_baseUrl/api/parents-eleve/$id',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {

        List<dynamic> data = jsonDecode(response.body);

        return data.map((item) {

          return {
            "nomfr": item["Nomfr"],
            "prenomfr": item["Prenomfr"],

            // student information
            "eleve_id": eleve["id"],
            "eleve_nomfr": eleve["Nomfr"],
            "eleve_prenomfr": eleve["Prenomfr"],
          };

        }).toList();

      } else {
        print(
          "Failed for student $id : ${response.statusCode}"
        );
      }

    } catch(e) {
      print("Error fetching parent for $id : $e");
    }

    return [];
  });


  // Execute all API calls at the same time
  final results = await Future.wait(futures);


  // Merge all lists
  for (var result in results) {
    parents.addAll(result);
  }


  return parents;
}
Future<int?> getTeacherinfo(int idPersonne) async {
  if (_teacherPersonneId == idPersonne && _teacherId != null) {
    return _teacherId;
  }

  if (_teacherInfoFuture != null && _teacherPersonneId == idPersonne) {
    return _teacherInfoFuture;
  }

  final prefs = await SharedPreferences.getInstance();
  final cachedTeacherId = prefs.getInt('IdteacherInfo');
  if (cachedTeacherId != null && cachedTeacherId != 0) {
    _teacherPersonneId = idPersonne;
    _teacherId = cachedTeacherId;
    return cachedTeacherId;
  }

  debugPrint('Fetching teacher info for ID: $idPersonne');

  _teacherInfoFuture = _fetchTeacherInfo(idPersonne);
  final result = await _teacherInfoFuture;
  _teacherInfoFuture = null;
  return result;
}

Future<int?> _fetchTeacherInfo(int idPersonne) async {
  try {
    final response = await _client.get(
      Uri.parse('$_baseUrl/GetEnseignants/$idPersonne'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      if (data.isNotEmpty) {
        final int idTeacher = data.first['idenseignant'];

        debugPrint('Teacher ID = $idTeacher');

        _teacherPersonneId = idPersonne;
        _teacherId = idTeacher;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('IdteacherInfo', idTeacher);
        return idTeacher;
      }
    } else {
      debugPrint('Status : ${response.statusCode}');
    }
  } catch (e) {
    debugPrint(e.toString());
  }

  return null;
}
}
