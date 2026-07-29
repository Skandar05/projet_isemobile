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

List<Map<String, dynamic>> filterClassesByQuery(
  List<Map<String, dynamic>> classes,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();

  if (normalizedQuery.isEmpty) {
    return List<Map<String, dynamic>>.from(classes);
  }

  return classes.where((classe) {
    final label = [
      classe['nomclassefr'],
      classe['nomClasseFr'],
      classe['nomclasse'],
      classe['nom_classe'],
      classe['name'],
      classe['Nomfr'],
      classe['Prenomfr'],
      classe['fullName'],
      classe['full_name'],
      classe['firstName'],
      classe['lastName'],
      classe['className'],
      classe['class_name'],
      classe['parentNames'],
    ]
        .whereType<String>()
        .map((value) => value.toLowerCase())
        .join(' ');

    final id = classe['id']?.toString().toLowerCase() ?? '';
    final idClasse = classe['idclasse']?.toString().toLowerCase() ?? '';
    final idClass = classe['idClasse']?.toString().toLowerCase() ?? '';

    return label.contains(normalizedQuery) ||
        id.contains(normalizedQuery) ||
        idClasse.contains(normalizedQuery) ||
        idClass.contains(normalizedQuery);
  }).toList();
}
