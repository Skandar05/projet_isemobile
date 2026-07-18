import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StudentProvider extends ChangeNotifier {

  String? idEleve;
  String? idClasse;
  final _baseUrl = dotenv.env['BACKEND_URL'];


  // SAVE
  Future<void> setStudent({
    required String eleve,
    required String classe,
  }) async {

    final prefs = await SharedPreferences.getInstance();


    await prefs.setString('idEleve', eleve);
    await prefs.setString('idClasse', classe);


    idEleve = eleve;
    idClasse = classe;


    notifyListeners();

  }



  // LOAD
  Future<void> loadStudent() async {

    final prefs = await SharedPreferences.getInstance();


    idEleve = prefs.getString('idEleve');
    idClasse = prefs.getString('idClasse');


    notifyListeners();

  }



  // CLEAR
  Future<void> clearStudent() async {

    final prefs = await SharedPreferences.getInstance();


    await prefs.remove('idEleve');
    await prefs.remove('idClasse');


    idEleve = null;
    idClasse = null;


    notifyListeners();

  }
}