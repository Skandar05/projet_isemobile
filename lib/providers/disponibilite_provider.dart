import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

List<Map<String, dynamic>> normalizeTeacherDisponibilitePayload(dynamic decoded) {
  List<dynamic> items = [];

  if (decoded is Map) {
    items = decoded['slots'] ??
        decoded['data'] ??
        decoded['disponibilites'] ??
        decoded['items'] ??
        decoded['intervals'] ??
        [];
  } else if (decoded is List) {
    items = decoded;
  }

  if (items is! List) {
    return [];
  }

  final flattened = <Map<String, dynamic>>[];

  for (final item in items) {
    if (item is! Map) {
      continue;
    }

    final day = Map<String, dynamic>.from(item);
    final intervals = day['intervals'];

    if (intervals is List && intervals.isNotEmpty) {
      for (final interval in intervals) {
        if (interval is! Map) {
          continue;
        }

        final intervalMap = Map<String, dynamic>.from(interval);
        final start = intervalMap['start']?.toString() ??
            intervalMap['heuredebut']?.toString() ??
            intervalMap['heureDebut']?.toString() ??
            intervalMap['debut']?.toString() ??
            '';
        final end = intervalMap['end']?.toString() ??
            intervalMap['heurefin']?.toString() ??
            intervalMap['heureFin']?.toString() ??
            intervalMap['fin']?.toString() ??
            '';
        final isAvailable = intervalMap['isAvailable'] is bool
            ? intervalMap['isAvailable'] as bool
            : intervalMap['available'] is bool
                ? intervalMap['available'] as bool
                : day['isAvailable'] is bool
                    ? day['isAvailable'] as bool
                    : true;

        flattened.add({
          ...day,
          ...intervalMap,
          'jour': day['jour']?.toString() ?? day['day']?.toString() ?? '',
          'date': day['date']?.toString() ?? day['value']?.toString() ?? '',
          'start': start,
          'end': end,
          'time': start.isNotEmpty && end.isNotEmpty ? '$start - $end' : '',
          'isAvailable': isAvailable,
        });
      }
      continue;
    }

    final start = day['start']?.toString() ??
        day['heuredebut']?.toString() ??
        day['heureDebut']?.toString() ??
        day['debut']?.toString() ??
        '';
    final end = day['end']?.toString() ??
        day['heurefin']?.toString() ??
        day['heureFin']?.toString() ??
        day['fin']?.toString() ??
        '';
    final isAvailable = day['isAvailable'] is bool
        ? day['isAvailable'] as bool
        : day['available'] is bool
            ? day['available'] as bool
            : true;

    flattened.add({
      ...day,
      'jour': day['jour']?.toString() ?? day['day']?.toString() ?? '',
      'date': day['date']?.toString() ?? day['value']?.toString() ?? '',
      'start': start,
      'end': end,
      'time': start.isNotEmpty && end.isNotEmpty ? '$start - $end' : '',
      'isAvailable': isAvailable,
    });
  }

  return flattened;
}

class DisponibiliteProvider extends ChangeNotifier {
  DisponibiliteProvider({http.Client? client, String? baseUrl}) {
    _client = client ?? http.Client();
    _baseUrl = baseUrl ?? dotenv.env['BACKEND_URL'];
  }

  late final http.Client _client;
  late final String? _baseUrl;

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

  List<Map<String, dynamic>> _normalizeTeacherDisponibiliteForConfig(
      dynamic decoded) {
    List<dynamic> items = [];

    if (decoded is Map) {
      items = decoded['slots'] ??
          decoded['data'] ??
          decoded['disponibilites'] ??
          decoded['items'] ??
          [];
    } else if (decoded is List) {
      items = decoded;
    }

    if (items is! List) {
      return [];
    }

    final normalized = <String, Map<String, dynamic>>{};

    for (final item in items) {
      if (item is! Map) {
        continue;
      }

      final day = item['jour']?.toString() ?? item['day']?.toString() ?? '';
      if (day.trim().isEmpty) {
        continue;
      }

      var start = item['heuredebut']?.toString() ??
          item['start']?.toString() ??
          item['debut']?.toString() ??
          '';
      var end = item['heurefin']?.toString() ??
          item['end']?.toString() ??
          item['fin']?.toString() ??
          '';

      if ((start.isEmpty || end.isEmpty) && item['intervals'] is List) {
        final intervals = List.of(item['intervals']);
        if (intervals.isNotEmpty) {
          final firstInterval = intervals.first;
          final lastInterval = intervals.last;

          if (firstInterval is Map) {
            start = start.isNotEmpty
                ? start
                : firstInterval['start']?.toString() ??
                    firstInterval['heuredebut']?.toString() ??
                    start;
          }

          if (lastInterval is Map) {
            end = end.isNotEmpty
                ? end
                : lastInterval['end']?.toString() ??
                    lastInterval['heurefin']?.toString() ??
                    end;
          }
        }
      }

      final key = '$day|$start|$end';
      if (normalized.containsKey(key)) {
        continue;
      }

      normalized[key] = {
        ...Map<String, dynamic>.from(item),
        'jour': day,
        'start': start,
        'end': end,
        'time': start.isNotEmpty && end.isNotEmpty ? '$start - $end' : '',
        'id': item['iddisponibilites'] ?? item['id'],
      };
    }

    return normalized.values.toList();
  }

  Future<void> loadDisponibilites(int idTeacher) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final baseUrl = _baseUrl?.trim();
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception('BACKEND_URL is not configured');
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/api/enseignant/disponibilites/$idTeacher'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        disponibilites = _normalizeTeacherDisponibiliteForConfig(data);
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
      final baseUrl = _baseUrl?.trim();
      if (baseUrl == null || baseUrl.isEmpty) {
        errorMessage = 'BACKEND_URL is not configured';
        notifyListeners();
        return false;
      }

      final url = '$baseUrl/api/enseignant/disponibilites/$idTeacher';

      final response = await _client.post(
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

/*   Future<bool> updateDisponibilite(
    int idTeacher,
    dynamic disponibiliteId,
    Map<String, dynamic> updatedDisponibilite,
  ) async {
    try {
      final baseUrl = _baseUrl?.trim();
      if (baseUrl == null || baseUrl.isEmpty) {
        errorMessage = 'BACKEND_URL is not configured';
        notifyListeners();
        return false;
      }

      final response = await _client.put(
        Uri.parse('$baseUrl/api/disponibilites/$disponibiliteId'),
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
  } */

  Future<bool> deleteDisponibilite(
    int idTeacher,
    dynamic iddisponibilites,
  ) async {
    try {
      final deleteId = iddisponibilites?.toString().trim();
      if (deleteId == null || deleteId.isEmpty) {
        errorMessage = 'Identifiant de disponibilité introuvable.';
        notifyListeners();
        return false;
      }

      final baseUrl = _baseUrl?.trim();
      if (baseUrl == null || baseUrl.isEmpty) {
        errorMessage = 'BACKEND_URL is not configured';
        notifyListeners();
        return false;
      }

      final response = await _client.delete(
        Uri.parse('$baseUrl/api/enseignant/disponibilites/$deleteId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
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
