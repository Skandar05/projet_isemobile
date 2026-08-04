import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/providers/Pd_Providers.dart';
import 'package:test/providers/disponibilite_provider.dart';

void main() {
  group('normalizeTeacherDisponibilitePayload', () {
    test('flattens nested intervals into usable slot entries', () {
      final payload = [
        {
          'jour': 'Lundi',
          'date': '2025-09-01',
          'intervals': [
            {'start': '09:00', 'end': '10:00', 'isAvailable': true},
            {'start': '10:30', 'end': '11:30', 'isAvailable': false},
          ],
        },
        {
          'jour': 'Mardi',
          'start': '08:00',
          'end': '09:00',
          'isAvailable': true,
        },
      ];

      final normalized = normalizeTeacherDisponibilitePayload(payload);

      expect(normalized.length, 3);
      expect(normalized[0]['jour'], 'Lundi');
      expect(normalized[0]['start'], '09:00');
      expect(normalized[0]['end'], '10:00');
      expect(normalized[0]['time'], '09:00 - 10:00');
      expect(normalized[0]['isAvailable'], isTrue);

      expect(normalized[1]['start'], '10:30');
      expect(normalized[1]['isAvailable'], isFalse);

      expect(normalized[2]['jour'], 'Mardi');
      expect(normalized[2]['start'], '08:00');
      expect(normalized[2]['end'], '09:00');
    });
  });

  group('availability deletion', () {
    test('uses the availability id for teacher delete requests', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'DELETE') {
          expect(request.url.toString(), 'http://example.com/api/enseignant/disponibilites/137');
          return http.Response('', 200);
        }

        if (request.method == 'GET') {
          return http.Response('[]', 200);
        }

        return http.Response('unexpected', 500);
      });

      final provider = DisponibiliteProvider(client: client, baseUrl: 'http://example.com');
      final success = await provider.deleteDisponibilite(191, '137');

      expect(success, isTrue);
      expect(requests.length, 2);
      expect(requests.first.method, 'DELETE');
    });

    test('uses the availability id for pedagogique delete requests', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'DELETE') {
          expect(request.url.toString(), 'http://example.com/api/Pedagogique/disponibilites/125');
          return http.Response('', 200);
        }

        return http.Response('unexpected', 500);
      });

      final provider = PdProvider(client: client, baseUrl: 'http://example.com');
      await provider.deletedisponibility('125');

      expect(requests.length, 1);
      expect(requests.first.method, 'DELETE');
    });
  });
}
