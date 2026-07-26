List<Map<String, dynamic>> filterStudentsByQuery(
  List<Map<String, dynamic>> students,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();

  if (normalizedQuery.isEmpty) {
    return List<Map<String, dynamic>>.from(students);
  }

  return students.where((student) {
    final fullName = (student['fullName'] ?? student['full_name'] ?? '')
        .toString()
        .toLowerCase();
    final className = (student['className'] ?? student['class_name'] ?? '')
        .toString()
        .toLowerCase();
    final firstName = (student['firstName'] ?? student['prenomfr'] ?? '')
        .toString()
        .toLowerCase();
    final lastName = (student['lastName'] ?? student['nomfr'] ?? '')
        .toString()
        .toLowerCase();

    return fullName.contains(normalizedQuery) ||
        className.contains(normalizedQuery) ||
        firstName.contains(normalizedQuery) ||
        lastName.contains(normalizedQuery);
  }).toList();
}
