import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EnseignantProvider extends ChangeNotifier {
  final http.Client _client = http.Client();
  String? _parentEndpoint;
  Future<String?>? _parentEndpointFuture;

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<List<dynamic>> getEnseignantsClasse(int idE) async {
    List<dynamic> classes = [];
    try {
      final response = await _client.get(
        Uri.parse(
          'http://apiserv.ise-college-lycee.com:8415/GetClasseEnseignants/$idE/7',
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
        await prefs.setString('classMap', jsonEncode(classes));
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
        Uri.parse('http://apiserv.ise-college-lycee.com:8415/GetMatiereEnseignant/$IdE/'),
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
        Uri.parse("http://apiserv.ise-college-lycee.com:8415/api/eleves/classe/$IdC"),
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
          'http://apiserv.ise-college-lycee.com:8415/api/parents-eleves-classe/' + idClasse.toString(),
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
                'id': p['idparent'],
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

  /* Future<String?> _resolveParentEndpoint(int sampleId) async {
    if (_parentEndpoint != null) return _parentEndpoint;
    _parentEndpointFuture ??= _doResolveParentEndpoint(sampleId);
    return _parentEndpointFuture!;
  }

  Future<String?> _doResolveParentEndpoint(int sampleId) async {
    const endpoints = [
      'http://apiserv.ise-college-lycee.com:8415/api/parents-eleve',
      'http://apiserv.ise-college-lycee.com:8415/api/parents/eleve',
    ];

    final completer = Completer<String?>();
    var remaining = endpoints.length;

    for (final base in endpoints) {
      _client.get(Uri.parse('$base/$sampleId')).then((response) {
        if (!completer.isCompleted && response.statusCode == 200) {
          completer.complete(base);
        }
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      }).catchError((_) {
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    final result = await completer.future;
    if (result != null) {
      _parentEndpoint = result;
    }
    return result;
  }

  Future<List<dynamic>> _fetchParentsFromEndpoint(String base, int idEleve) async {
    try {
      final response = await _client.get(
        Uri.parse('$base/$idEleve'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        }
        if (data is Map<String, dynamic>) {
          return [data];
        }
        print('Unexpected data format: $data');
      } else {
        print('Failed to load parents from $base. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching parents from $base: $e');
    }
    return [];
  }

  Future<List<dynamic>> GetEleveParent(int IdEleve) async {
    final endpoint = await _resolveParentEndpoint(IdEleve);
    if (endpoint != null) {
      return _fetchParentsFromEndpoint(endpoint, IdEleve);
    }

    List<dynamic> parents = [];
    const endpoints = [
      'http://apiserv.ise-college-lycee.com:8415/api/parents-eleve',
      'http://apiserv.ise-college-lycee.com:8415/api/parents/eleve',
    ];

    for (final base in endpoints) {
      parents = await _fetchParentsFromEndpoint(base, IdEleve);
      if (parents.isNotEmpty) {
        _parentEndpoint = base;
        break;
      }
    }
    return parents;
  } */



Future<List<dynamic>> GetParentEleve(List<dynamic> eleves) async {
  List<dynamic> parents = [];

  final futures = eleves.map((eleve) async {

    int id = eleve['id'];

    try {
      http.Response response = await _client.get(
        Uri.parse(
          'http://apiserv.ise-college-lycee.com:8415/api/parents-eleve/$id',
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
}