import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_provider.dart';

class RdvProvider extends ChangeNotifier {
  int? idParent;
  int? idEnseignant;
  int? classId;

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
            'http://apiserv.ise-college-lycee.com:8415/GetEnseignantsParClasse/$classId/7',
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
      debugPrint("Role enseignant not implemented yet");
    }
  }



  Future<void> selectEnseignant(String fullName) async {
  final String name = fullName.trim();

  try {
    final response = await http.get(
      Uri.parse(
        'http://apiserv.ise-college-lycee.com:8415/GetIdEnseignants/',
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

Future<void> createRDV({
  required int idParent,
  required int idEnseignant,
  required String date,
  required String temp,
  required String motif,

}) async {


  final debutTemp = temp.split('-')[0];
  final finTemp = temp.split('-')[1];
  

  try{
    final response = await http.post(
      Uri.parse('http://apiserv.ise-college-lycee.com:8415/api/rendezvous/$idParent/7'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "id_enseignant": idEnseignant,
        "date": date,
        "heureDebut": debutTemp,
        "heureFin": finTemp,
        "motif": motif,
        
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('RDV created successfully');
    } else {
      debugPrint('Failed to create RDV: ${response.statusCode}');
    }
  }catch(e){
    debugPrint('Error creating RDV: $e');
  }

}

  Future<List<Map<String, dynamic>>> getParentRDV(int idParent) async {
  try {
    final response = await http.get(
      Uri.parse(
        'http://apiserv.ise-college-lycee.com:8415/api/rendezvous/personne/$idParent',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);

      if (data is List) {
        return data
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

}