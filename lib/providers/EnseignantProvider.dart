import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class EnseignantProvider extends ChangeNotifier {



  Future<void> getEnseignantsClasse(int idE) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://apiserv.ise-college-lycee.com:8415/GetClasseEnseignants/$idE/7',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Map<String, String> classMap = {};

        for (var item in data) {
          classMap[item['idclasse'].toString()] =
              item['nomclassefr'].toString();
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('classMap', jsonEncode(classMap));
      } else {
        debugPrint("API error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Exception: $e");
    }
  }



  Future<void> getEnseignantsMatier(int IdE) async{
    List<String> matieres = [];
    
    try {
      final response = await http.get(
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
    final response = await http.get(
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

Future<List<dynamic>> GetEleveParent(int IdEleve) async {


  List<dynamic> parents = [];
  final response = await http.get(
    Uri.parse("http://apiserv.ise-college-lycee.com:8415/api/parents/eleve/$IdEleve"),
    headers: {'Content-Type': 'application/json'},
  );

  try {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        parents = data;
      } else {
        print('Unexpected data format: $data');
      }
    } else {
      print('Failed to load parents. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching parents: $e');
  }
  return parents;
  }
}