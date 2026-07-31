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

    final parentNames = _extractParentNames(student);

    return fullName.contains(normalizedQuery) ||
        className.contains(normalizedQuery) ||
        firstName.contains(normalizedQuery) ||
        lastName.contains(normalizedQuery) ||
        parentNames.contains(normalizedQuery);
  }).toList();
}

String _extractParentNames(Map<String, dynamic> student) {
  if (student['parentNames'] != null) {
    return student['parentNames'].toString().toLowerCase();
  }

  if (student['parents'] != null) {
    final parents = student['parents'];
    if (parents is List) {
      return parents
          .map((p) => p is Map ? '${p['nomfr'] ?? p['nom'] ?? ''} ${p['prenomfr'] ?? p['prenom'] ?? ''}' : p.toString())
          .join(' ')
          .toLowerCase();
    }
    return parents.toString().toLowerCase();
  }

  if (student['raw'] != null && student['raw'] is Map) {
    final raw = student['raw'] as Map;
    if (raw['parents'] is List) {
      return (raw['parents'] as List)
          .map((p) => p is Map ? '${p['nomfr'] ?? p['nom'] ?? ''} ${p['prenomfr'] ?? p['prenom'] ?? ''}' : p.toString())
          .join(' ')
          .toLowerCase();
    }
  }

  return '';
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

    // parent names may be a top-level string or inside raw.parents
    final parentNames = (classe['parentNames'] ?? classe['parent_names'] ?? '')
        .toString()
        .toLowerCase();

    String rawParentsConcat = '';
    try {
      final raw = classe['raw'];
      if (raw is Map && raw['parents'] is List) {
        final List parents = raw['parents'];
        rawParentsConcat = parents.map((p) {
          final nom = (p['nomfr'] ?? p['nom'] ?? '').toString();
          final prenom = (p['prenomfr'] ?? p['prenom'] ?? '').toString();
          return ('$nom $prenom').trim();
        }).where((s) => s.isNotEmpty).join(' ').toLowerCase();
      }
    } catch (_) {
      rawParentsConcat = '';
    }

    return label.contains(normalizedQuery) ||
      id.contains(normalizedQuery) ||
      idClasse.contains(normalizedQuery) ||
      idClass.contains(normalizedQuery) ||
      parentNames.contains(normalizedQuery) ||
      rawParentsConcat.contains(normalizedQuery);
  }).toList();
}
