/* import 'package:flutter_test/flutter_test.dart';
import 'package:test/Screens/Enseignant/TeacherStudentsParentsScreen.dart';

void main() {
  group('Teacher parent selection', () {
    test('prefers idpersonne when available for teacher RDV payload', () {
      final parent = {
        'idparent': 3127,
        'idpersonne': 8523,
        'nomfr': 'TEST',
        'prenomfr': 'Me',
        'type': 'Mère',
      };

      expect(resolveParentPersonId(parent), '8523');
    });

    test('falls back to idparent when idpersonne is missing', () {
      final parent = {
        'idparent': 3126,
        'nomfr': 'TEST',
        'prenomfr': 'Pe',
        'type': 'Père',
      };

      expect(resolveParentPersonId(parent), '3126');
    });
  });
}
 */