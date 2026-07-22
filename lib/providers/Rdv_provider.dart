import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_provider.dart';
import 'package:test/providers/EnseignantProvider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class RdvProvider extends ChangeNotifier {
  int? idParent;
  int? idEnseignant;
  int? classId;
  final _baseUrl = dotenv.env['BACKEND_URL'];
  List<Map<String, dynamic>> enseignants = [];


  Future<void> loadIds(BuildContext context) async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    idParent = int.tryParse(studentProvider.idEleve ?? '');
    classId = int.tryParse(studentProvider.idClasse ?? '');
  }

  Future<void> checkRole({
    required String role,
    required BuildContext context,
  }) async {
    await loadIds(context);

    if (role == 'parent') {
      if (classId == null) {
        debugPrint('classId is null');
        return;
      }

      try {
        final response = await http.get(
          Uri.parse(
            '$_baseUrl/GetEnseignantsParClasse/$classId/7',
          ),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
  final dynamic data = jsonDecode(response.body);

  List<Map<String, dynamic>> tempList = [];

  if (data is List) {
    tempList = List<Map<String, dynamic>>.from(data);
  } else if (data is Map<String, dynamic>) {
    tempList = [data];
  }

  // Remove duplicates
  final seen = <String>{};

  enseignants = tempList.where((element) {
    final key =
        "${element['Nomfr']}_${element['Prenomfr']}_${element['Nommatierefr']}_${element['nomclassefr']}";

    if (seen.contains(key)) {
      return false; // duplicate => remove
    }

    seen.add(key);
    return true; // keep first occurrence
  }).toList();

  notifyListeners();
} else {
  debugPrint('Error: ${response.statusCode}');
}
      } catch (e) {
        debugPrint('Exception: $e');
      }
    }

    else if (role == 'enseignant') {
      Future<void> getInfoParent(BuildContext context) async {
       final enseignantProvider =Provider.of<EnseignantProvider>(context, listen: false);
       await enseignantProvider.getEnseignantsClasse(idEnseignant ?? 0);
    }
    }
  }



  Future<int> selectEnseignant(String fullName) async {
  final String name = fullName.trim();
  int idfinalE= 0;
  try {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/GetIdEnseignants/',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      final enseignant = data.firstWhere(
        (element) =>
            "${element['Nomfr']} ${element['Prenomfr']}".trim().toLowerCase() ==
            name.toLowerCase(),
        orElse: () => null,
      );

      if (enseignant != null) {
        idEnseignant = enseignant['idenseignant'];
        idfinalE =idEnseignant ?? 0;

      if (idEnseignant != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("idEnseignant", idfinalE);
      }
      } else {
        debugPrint(
          'No enseignant found with name: $name',
        );
      }
    } else {
      debugPrint(
        'Error fetching enseignants: ${response.statusCode}',
      );
    }
  } catch (e) {
    debugPrint(
      'Error selecting enseignant: $e',
    );
  }

  notifyListeners();
  return idfinalE ;
  
}

Future<void> saveSelectedEnseignant({
  required String id,
  required String fullname,
  required String matiere,
}) async {

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    "idEnseignant",
    id,
  );

  await prefs.setString(
    "enseignantFullname",
    fullname,
  );

  await prefs.setString(
    "matiere",
    matiere,
  );

}

  Future<int> resolveParentId(int idPersonne) async {
    if (idPersonne <= 0) return 0;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/Getpersonnemobile/$idPersonne'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          final candidates = [
            data['id_parent'],
            data['idParent'],
            data['idparent'],
            data['idpersonne'],
          ];

          for (final value in candidates) {
            final parsed = int.tryParse(value?.toString() ?? '');
            if (parsed != null && parsed > 0) return parsed;
          }
        } else if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final candidates = [
                item['id_parent'],
                item['idParent'],
                item['idparent'],
                item['idpersonne'],
              ];

              for (final value in candidates) {
                final parsed = int.tryParse(value?.toString() ?? '');
                if (parsed != null && parsed > 0) 
                
                return parsed;
              }
            }
          }
        }
      } else {
        debugPrint('Failed to resolve parent id: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error resolving parent id: $e');
    }

    return 0;
  }

Future<void> createRDV({
  required int idParent,
  required int idEnseignant,
  required String date,
  required String temp,
  required String motif,
  String? heureDebut,
  String? heureFin,
}) async {
  final debutTemp = (heureDebut ?? temp.split('-')[0]).trim();
  final finTemp = (heureFin ?? temp.split('-')[1]).trim();
  final resolvedParentId = await resolveParentId(idParent);
  final effectiveParentId = resolvedParentId > 0 ? resolvedParentId : idParent;
  final String dmd = 'parent';
  
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/rendezvous/$effectiveParentId/7'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "id_enseignant": idEnseignant,
        "date": date,
        "heureDebut": debutTemp,
        "heureFin": finTemp,
        "motif": motif,
        "demandeur_role": dmd
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('RDV created successfully');
    } else {
      debugPrint('Failed to create RDV: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error creating RDV: $e');
  }
}

  Future<List<Map<String, dynamic>>> getParentRDV(int idParent) async {
  final int test = int.parse(idParent.toString());
  
  final resolvedParentId = await resolveParentId(idParent);
  final effectiveParentId = resolvedParentId > 0 ? resolvedParentId : idParent;
  

  try {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/getRendezVousParentTous/$effectiveParentId',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      debugPrint('Fetched parent RDVs: $data');

      if (data is List) {
        return data
            .where(
        (rdv) =>
            rdv['demandeur_role']
                ?.toString()
                .toLowerCase() ==
            'parent',
      )
            .map((rdv) => rdv as Map<String, dynamic>)
            .toList();
      }

      if (data is Map<String, dynamic>) {
        return [data];
      }

      return [];
    } else {
      debugPrint('Failed to fetch parent RDVs: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    debugPrint('Error fetching RDVs: $e');
    return [];
  }
}


  Future<List<Map<String, dynamic>>> getParentRDV2(int idParent) async {
  final resolvedParentId = await resolveParentId(idParent);
  final effectiveParentId = resolvedParentId > 0 ? resolvedParentId : idParent;

  try {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/getRendezVousParentTous/$effectiveParentId',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);


      if (data is List) {
        return data
            .where(
        (rdv) =>
            rdv['demandeur_role']
                ?.toString()
                .toLowerCase() ==
            'enseignant',
      )
            .map((rdv) => rdv as Map<String, dynamic>)
            .toList();
      }

      if (data is Map<String, dynamic>) {
        return [data];
      }

      return [];
    } else {
      debugPrint('Failed to fetch parent RDVs: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    debugPrint('Error fetching RDVs: $e');
    return [];
  }
}

// ===== TEACHER RDV METHODS =====

  Future<List<Map<String, dynamic>>> getTeacherRDV(int idTeacher) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/GetRendezVousEnseignantParent/$idTeacher',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is List) {
          return data
              .where(
        (rdv) =>
            rdv['demandeur_role']
                ?.toString()
                .toLowerCase() ==
            'enseignant',
            )
              .map((rdv) => rdv as Map<String, dynamic>)
              .toList();
        }

        if (data is Map<String, dynamic>) {
          return [data];
        }

        return [];
      } else {
        debugPrint('Failed to fetch teacher RDVs: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching teacher RDVs: $e');
      return [];
    }
  }

    Future<List<Map<String, dynamic>>> getTeacherRDV2(int idTeacher) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/GetRendezVousEnseignantParent/$idTeacher',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is List) {
          return data
              .where(
        (rdv) =>
            rdv['demandeur_role']
                ?.toString()
                .toLowerCase() ==
            'parent',
            )
              .map((rdv) => rdv as Map<String, dynamic>)
              .toList();
        }

        if (data is Map<String, dynamic>) {
          return [data];
        }

        return [];
      } else {
        debugPrint('Failed to fetch teacher RDVs: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching teacher RDVs: $e');
      return [];
    }
  }

  Future<void> acceptTeacherRDV(int rdvId) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$_baseUrl/api/rendezvous/$rdvId/statut',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'statuts': 'accepte'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('RDV accepted successfully');
      } else {
        debugPrint('Failed to accept RDV: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error accepting RDV: $e');
    }
    notifyListeners();
  }

  Future<void> rejectTeacherRDV(int rdvId) async {
    try {
            final response = await http.put(
        Uri.parse(
          '$_baseUrl/api/rendezvous/$rdvId/statut',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'statuts': 'refuse'}),
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('RDV rejected successfully');
      } else {
        debugPrint('Failed to reject RDV: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error rejecting RDV: $e');
    }
    notifyListeners();
  }

  Future<void> createTeacherRDV({
    required int idTeacher,
    required int idParent,
    required String date,
    required String timeStart,
    required String timeEnd,
    required String motif,
  }) async {
    final resolvedParentId = await resolveParentId(idParent);
    final effectiveParentId = resolvedParentId > 0 ? resolvedParentId : idParent;
  debugPrint('Creating RDV for teacher $idTeacher with parent $effectiveParentId on $date from $timeStart to $timeEnd for motif: $motif');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/rendezvous/enseignant/$idTeacher/7'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id_parent": effectiveParentId,
          "id_personne": idParent,
          "date": date,
          "heureDebut": timeStart,
          "heureFin": timeEnd,
          "motif": motif,
          "demandeur_role": "enseignant"
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('RDV created successfully by teacher');
      } else {
        debugPrint('Failed to create RDV by teacher: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating RDV by teacher: $e');
    }
  }


}