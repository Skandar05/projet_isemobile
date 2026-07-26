import 'package:flutter_test/flutter_test.dart';
import 'package:test/Screens/Enseignant/student_search_utils.dart';

void main() {
  group('filterStudentsByQuery', () {
    final students = [
      {
        'fullName': 'TEST Test',
        'className': 'Classe A',
      },
      {
        'fullName': 'Alice Martin',
        'className': 'Classe B',
      },
    ];

    test('returns all students when query is empty', () {
      expect(filterStudentsByQuery(students, ''), hasLength(2));
    });

    test('matches by student name in a case-insensitive way', () {
      final result = filterStudentsByQuery(students, 'test');
      expect(result, hasLength(1));
      expect(result.first['fullName'], 'TEST Test');
    });

    test('matches by class name', () {
      final result = filterStudentsByQuery(students, 'classe b');
      expect(result, hasLength(1));
      expect(result.first['fullName'], 'Alice Martin');
    });
  });
}
