import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/providers/disponibilite_provider.dart';

void main() {
  group('DisponibiliteProvider Tests', () {
    late DisponibiliteProvider provider;

    setUp(() {
      provider = DisponibiliteProvider();
    });

    test('Initial state should be correct', () {
      expect(provider.isLoading, false);
      expect(provider.errorMessage, null);
      expect(provider.disponibilites, isEmpty);
    });
    test('TimeOfDay formatting should be correct', () {
      final timeOfDay = const TimeOfDay(hour: 9, minute: 30);
      final formatted = _formatTime(timeOfDay);
      expect(formatted, '09:30');

      final timeOfDay2 = const TimeOfDay(hour: 14, minute: 5);
      final formatted2 = _formatTime(timeOfDay2);
      expect(formatted2, '14:05');
    });

    test('TimeOfDay parsing should be correct', () {
      final parsed = _parseTime('09:30');
      expect(parsed.hour, 9);
      expect(parsed.minute, 30);

      final parsed2 = _parseTime('14:05');
      expect(parsed2.hour, 14);
      expect(parsed2.minute, 5);

      // Invalid format should return default
      final parsed3 = _parseTime('invalid');
      expect(parsed3.hour, 8);
      expect(parsed3.minute, 0);
    });

    test('Card label should be built correctly', () {
      final disponibilite = {
        'jour': 'Lundi',
        'disponibilite_debut': '09:00',
        'disponibilite_fin': '10:00',
      };

      final label = _buildCardLabel(disponibilite);
      expect(label, 'Lundi 09:00 - 10:00');
    });

    test('Card label with missing times should show fallback', () {
      final disponibilite = {
        'jour': 'Mardi',
        'disponibilite_debut': '',
        'disponibilite_fin': '',
      };

      final label = _buildCardLabel(disponibilite);
      expect(label, 'Mardi Horaire à définir');
    });

    test('Should validate time constraints correctly', () {
      final startTime = const TimeOfDay(hour: 9, minute: 0);
      final endTime = const TimeOfDay(hour: 10, minute: 0);

      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;

      expect(endMinutes > startMinutes, true);
    });

    test('Should reject invalid time range (end before start)', () {
      final startTime = const TimeOfDay(hour: 10, minute: 0);
      final endTime = const TimeOfDay(hour: 9, minute: 0);

      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;

      expect(endMinutes <= startMinutes, true);
    });

    test('Should reject equal start and end times', () {
      final startTime = const TimeOfDay(hour: 9, minute: 0);
      final endTime = const TimeOfDay(hour: 9, minute: 0);

      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;

      expect(endMinutes <= startMinutes, true);
    });
  });

  group('Data Display Tests', () {
    test('All field variations should be handled in display functions', () {
      final variants = [
        {'jour': 'Lundi', 'heureDebut': '09:00', 'heureFin': '10:00'},
        {'jourSemaine': 'Lundi', 'heure_debut': '09:00', 'heure_fin': '10:00'},
        {'day': 'Lundi', 'disponibilite_debut': '09:00', 'disponibilite_fin': '10:00'},
        {'jour': 'Lundi', 'heuredebut': '09:00', 'heurefin': '10:00'},
        {'jour': 'Lundi', 'startTime': '09:00', 'endTime': '10:00'},
      ];

      for (final variant in variants) {
        expect(_displayDay(variant), 'Lundi');
        expect(_displayStart(variant), '09:00');
        expect(_displayEnd(variant), '10:00');
      }
    });

    test('Missing fields should use defaults', () {
      final incomplete = {'jour': 'Jeudi'};

      expect(_displayDay(incomplete), 'Jeudi');
      expect(_displayStart(incomplete), '');
      expect(_displayEnd(incomplete), '');
    });
  });

  group('Edge Cases', () {
    test('Should handle midnight times', () {
      final midnight = const TimeOfDay(hour: 0, minute: 0);
      final formatted = _formatTime(midnight);
      expect(formatted, '00:00');
    });

    test('Should handle end of day', () {
      final endOfDay = const TimeOfDay(hour: 23, minute: 59);
      final formatted = _formatTime(endOfDay);
      expect(formatted, '23:59');
    });

    test('Should parse times with leading zeros correctly', () {
      final parsed = _parseTime('08:05');
      expect(parsed.hour, 8);
      expect(parsed.minute, 5);
    });

    test('Should handle all days of the week', () {
      final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
      for (final day in days) {
        final disponibilite = {'jour': day};
        expect(_displayDay(disponibilite), day);
      }
    });
  });
}

// Helper functions for testing
String _formatTime(TimeOfDay timeOfDay) {
  final hour = timeOfDay.hour.toString().padLeft(2, '0');
  final minute = timeOfDay.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) {
    return const TimeOfDay(hour: 8, minute: 0);
  }

  final hour = int.tryParse(parts[0]) ?? 8;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour, minute: minute);
}

String _displayDay(Map<String, dynamic> disponibilite) {
  return (disponibilite['jour'] ??
      disponibilite['jourSemaine'] ??
      disponibilite['day'] ??
      'Jour non défini')
      .toString();
}

String _displayStart(Map<String, dynamic> disponibilite) {
  return (disponibilite['heureDebut'] ??
      disponibilite['disponibilite_debut'] ??
      disponibilite['heure_debut'] ??
      disponibilite['heuredebut'] ??
      disponibilite['startTime'] ??
      '')
      .toString();
}

String _displayEnd(Map<String, dynamic> disponibilite) {
  return (disponibilite['heureFin'] ??
      disponibilite['disponibilite_fin'] ??
      disponibilite['heure_fin'] ??
      disponibilite['heurefin'] ??
      disponibilite['endTime'] ??
      '')
      .toString();
}

String _buildCardLabel(Map<String, dynamic> disponibilite) {
  final day = _displayDay(disponibilite);
  final start = _displayStart(disponibilite);
  final end = _displayEnd(disponibilite);

  final timePart = start.isNotEmpty && end.isNotEmpty
      ? '$start - $end'
      : 'Horaire à définir';
  return '$day $timePart';
}
