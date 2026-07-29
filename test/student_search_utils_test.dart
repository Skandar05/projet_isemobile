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

  group('filterClassesByQuery', () {
    final classes = [
      {'id': 1, 'nomclassefr': 'Mathématiques'},
      {'id': 2, 'nomclassefr': 'Physique Chimie'},
    ];

    test('returns all classes when query is empty', () {
      expect(filterClassesByQuery(classes, ''), hasLength(2));
    });

    test('matches by class name in a case-insensitive way', () {
      final result = filterClassesByQuery(classes, 'phys');
      expect(result, hasLength(1));
      expect(result.first['id'], 2);
    });

    test('matches by numeric id', () {
      final result = filterClassesByQuery(classes, '1');
      expect(result, hasLength(1));
      expect(result.first['nomclassefr'], 'Mathématiques');
    });

    test('matches flattened student records by full name and parent names', () {
      final students = [
        {
          'fullName': 'Sami Ben Ali',
          'className': '1S3',
          'parentNames': 'Ahmed Ben Ali',
        },
      ];

      expect(filterClassesByQuery(students, 'sami'), hasLength(1));
      expect(filterClassesByQuery(students, 'ahmed'), hasLength(1));
    });
  });
}
