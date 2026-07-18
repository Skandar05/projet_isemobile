import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/Screens/Rdv/ChooseCreneauScreen.dart';
import 'package:test/providers/EnseignantProvider.dart';

class TeacherStudentsParentsScreen extends StatefulWidget {
  final int classId;
  final String className;

  const TeacherStudentsParentsScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TeacherStudentsParentsScreen> createState() => _TeacherStudentsParentsScreenState();
}

String resolveParentPersonId(Map<String, dynamic> parent) {
  final candidates = [
    parent['idpersonne'],
    parent['idPersonne'],
    parent['id_personne'],
    parent['idparent'],
    parent['idParent'],
    parent['id_parent'],
    parent['id'],
  ];

  for (final candidate in candidates) {
    final parsed = int.tryParse(candidate?.toString() ?? '');
    if (parsed != null && parsed > 0) {
      return parsed.toString();
    }
  }

  return '';
}

class _TeacherStudentsParentsScreenState extends State<TeacherStudentsParentsScreen> {
  bool isLoading = false;
  String? errorMessage;
  final List<Map<String, dynamic>> _students = [];
  final Map<String, List<dynamic>> _parentsByStudentId = {};

  @override
  void initState() {
    super.initState();
    _loadStudentsAndParents();
  }

Future<void> _loadStudentsAndParents() async {
  setState(() {
    isLoading = true;
    errorMessage = null;
    _students.clear();
    _parentsByStudentId.clear();
  });

  try {
    final provider = context.read<EnseignantProvider>();

    final result = await provider.getElevesEtParentsClasse(widget.classId);

    if (!mounted) return;

    final eleves = (result['eleves'] as List<dynamic>? ?? [])
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    final parentsByEleve =
        (result['parentsByEleve'] as Map<String, dynamic>? ?? {});

    setState(() {
      _students.addAll(eleves);
      for (final entry in parentsByEleve.entries) {
        _parentsByStudentId[entry.key] =
            (entry.value as List<dynamic>)
                .map<Map<String, dynamic>>(
                  (p) => Map<String, dynamic>.from(p),
                )
                .toList();
      }
      isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
      errorMessage = 'Erreur lors du chargement des eleves.';
    });

    debugPrint('Error: ' + e.toString());
  }
}

  String _studentName(Map<String, dynamic> student) {
    final firstName = (student['Prenomfr'] ?? student['prenomfr'] ?? '').toString().trim();
    final lastName = (student['Nomfr'] ?? student['nomfr'] ?? '').toString().trim();
    return '$lastName $firstName'.trim();
  }

  String _parentName(Map<String, dynamic> parent) {
    final firstName = (parent['Prenomfr'] ?? parent['prenomfr'] ?? '').toString().trim();
    final lastName = (parent['Nomfr'] ?? parent['nomfr'] ?? '').toString().trim();
    final fullName = '$lastName $firstName'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return (parent['Type'] ?? parent['type'] ?? 'Parent').toString();
  }

  String _parentIdValue(Map<String, dynamic> parent) {
    return resolveParentPersonId(parent);
  }

  Future<void> _selectParent({
    required Map<String, dynamic> student,
    required Map<String, dynamic> parent,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = student['id']?.toString() ?? '';
    final parentId = _parentIdValue(parent);

    await prefs.setString('rdvFlow', 'teacher');
    await prefs.setString('selectedTeacherClassId', widget.classId.toString());
    await prefs.setString('selectedTeacherClassName', widget.className);
    await prefs.setString('selectedTeacherStudentId', studentId);
    await prefs.setString('selectedTeacherStudentName', _studentName(student));
    await prefs.setString('selectedTeacherParentId', parentId);
    await prefs.setString('selectedTeacherParentName', _parentName(parent));

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChooseCreneauScreen(isTeacher: true),
      ),
    );
  }

  Future<void> _selectBothParents({
    required Map<String, dynamic> student,
    required List<Map<String, dynamic>> parents,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = student['id']?.toString() ?? '';

    final parentIds = parents
        .map((p) => _parentIdValue(p))
        .where((id) => id.isNotEmpty)
        .join(',');
    final parentNames = parents.map((p) => _parentName(p)).join(' & ');

    await prefs.setString('rdvFlow', 'teacher');
    await prefs.setString('selectedTeacherClassId', widget.classId.toString());
    await prefs.setString('selectedTeacherClassName', widget.className);
    await prefs.setString('selectedTeacherStudentId', studentId);
    await prefs.setString('selectedTeacherStudentName', _studentName(student));
    await prefs.setString('selectedTeacherParentId', parentIds);
    await prefs.setString('selectedTeacherParentName', parentNames);

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChooseCreneauScreen(isTeacher: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xff253858),
        title: Text(
          widget.className,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisir un élève et son parent',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sélectionnez un parent pour préparer la demande de rendez-vous.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(
                            child: Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade400),
                            ),
                          )
                        : _students.isEmpty
                            ? const Center(child: Text('Aucun élève trouvé pour cette classe'))
                            : RefreshIndicator(
                                onRefresh: _loadStudentsAndParents,
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: _students.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final student = _students[index];
                                    final studentId = student['id']?.toString() ?? '';
                                    final studentName = _studentName(student);
                                    final parents = _parentsByStudentId[studentId];

                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: const Color(0xffEAF3FF),
                                                child: Icon(
                                                  Icons.person,
                                                  color: Colors.blue.shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      studentName.isEmpty ? 'Élève sans nom' : studentName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Élève',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'Parents',
                                            style: TextStyle(
                                              color: Colors.grey.shade800,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (parents == null)
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: SizedBox(
                                                height: 16,
                                                width: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            )
                                          else if (parents.isEmpty)
                                            Text(
                                              'Aucun parent trouvé',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 13,
                                              ),
                                            )
                                          else
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                ...parents.map((parent) {
                                                  final parentName = _parentName(parent);
                                                  return ActionChip(
                                                    backgroundColor: const Color(0xffEEF4FF),
                                                    label: Text(parentName),
                                                    onPressed: () => _selectParent(
                                                      student: student,
                                                      parent: Map<String, dynamic>.from(parent as Map),
                                                    ),
                                                  );
                                                }),
                                                if (parents.length > 1)
                                                  ActionChip(
                                                    backgroundColor: const Color(0xff1F4B8F),
                                                    label: const Text(
                                                      'Les deux parents',
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                    onPressed: () => _selectBothParents(
                                                      student: student,
                                                      parents: parents.map((p) => Map<String, dynamic>.from(p as Map)).toList(),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
