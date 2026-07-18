import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DisponibiliteProvider extends ChangeNotifier {

  final _baseUrl = dotenv.env['BACKEND_URL'];
  

  bool isLoading = false;
  String? errorMessage;
  List<Map<String, dynamic>> disponibilites = [];

  Map<String, dynamic> _normalizeDisponibilite(Map<String, dynamic> item) {
    final normalized = Map<String, dynamic>.from(item);

    final start = item['disponibilite_debut'] ??
        item['heureDebut'] ??
        item['heure_debut'] ??
        item['heuredebut'] ??
        item['startTime'];
    final end = item['disponibilite_fin'] ??
        item['heureFin'] ??
        item['heure_fin'] ??
        item['heurefin'] ??
        item['endTime'];

    if (start != null) {
      normalized['disponibilite_debut'] = start;
      normalized['heureDebut'] = start;
      normalized['heure_debut'] = start;
      normalized['heuredebut'] = start;
    }

    if (end != null) {
      normalized['disponibilite_fin'] = end;
      normalized['heureFin'] = end;
      normalized['heure_fin'] = end;
      normalized['heurefin'] = end;
    }

    return normalized;
  }

  Future<void> loadDisponibilites(int idTeacher) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/enseignant/disponibilites/$idTeacher'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is List) {
          disponibilites = data
              .map((item) =>
                  _normalizeDisponibilite(Map<String, dynamic>.from(item as Map)))
              .toList();
        } else if (data is Map<String, dynamic>) {
          disponibilites = [_normalizeDisponibilite(data)];
        } else {
          disponibilites = [];
        }
      } else {
        errorMessage = 'Impossible de charger les disponibilités.';
        disponibilites = [];
      }
    } catch (e) {
      errorMessage = 'Erreur lors du chargement des disponibilités.';
      disponibilites = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDisponibilite(
    int idTeacher,
    Map<String, dynamic> disponibiliteData,
  ) async {
    try {
      final url = '$_baseUrl/api/enseignant/disponibilites/$idTeacher';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(disponibiliteData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadDisponibilites(idTeacher);
        return true;
      }

      errorMessage = 'Erreur API (${response.statusCode}): ${response.body}';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('EXCEPTION => $e');
      errorMessage = 'Erreur réseau lors de l\'ajout: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDisponibilite(
    int idTeacher,
    dynamic disponibiliteId,
    Map<String, dynamic> updatedDisponibilite,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/disponibilites/$disponibiliteId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedDisponibilite),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadDisponibilites(idTeacher);
        return true;
      }

      errorMessage = 'Erreur lors de la modification de la disponibilité.';
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Erreur réseau lors de la modification.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDisponibilite(
    int idTeacher,
    dynamic disponibiliteId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/disponibilites/$disponibiliteId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadDisponibilites(idTeacher);
        return true;
      }

      errorMessage = 'Erreur lors de la suppression de la disponibilité.';
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Erreur réseau lors de la suppression.';
      notifyListeners();
      return false;
    }
  }
}
