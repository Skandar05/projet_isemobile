import 'package:flutter_test/flutter_test.dart';
import 'package:test/providers/Pd_Providers.dart';

void main() {
  test('normalizes nested intervals payload into individual slots', () {
    final payload = [
      {
        'idpedagogique': 8525,
        'jour': 'Lundi',
        'idenseignant': null,
        'intervals': [
          {'id': 97, 'start': '08:00', 'end': '08:15', 'isAvailable': true},
          {'id': 98, 'start': '08:15', 'end': '08:30', 'isAvailable': true},
        ],
        'heuredebut': '08:00',
        'heurefin': '09:00',
        'start': '08:00',
        'end': '09:00',
        'time': '08:00 - 09:00',
        'isAvailable': true,
      },
    ];

    final result = normalizeDisponibilitePayload(payload);

    expect(result, hasLength(2));
    expect(result[0]['jour'], 'Lundi');
    expect(result[0]['start'], '08:00');
    expect(result[0]['end'], '08:15');
    expect(result[0]['id'], 97);
    expect(result[1]['start'], '08:15');
    expect(result[1]['end'], '08:30');
  });
}
