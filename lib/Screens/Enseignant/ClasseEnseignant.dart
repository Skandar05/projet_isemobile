import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/Screens/Enseignant/home_Enseignant.dart';
import 'package:test/Screens/Enseignant/student_search_utils.dart';
import 'package:test/Screens/Rdv/ChooseCreneauScreen.dart';
import 'package:test/Screens/Widgets/custom_app_bar.dart';
import 'package:test/providers/EnseignantProvider.dart';

class ClasseEnseignant extends StatefulWidget {
  const ClasseEnseignant({super.key});

  @override
  State<ClasseEnseignant> createState() => _ClasseEnseignantState();
}

class _ClasseEnseignantState extends State<ClasseEnseignant> {
  final TextEditingController _searchController = TextEditingController();

  int idEnseignant = 0;
  final List<Map<String, dynamic>> _students = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> initData() async {
    final provider = context.read<EnseignantProvider>();
    final prefs = await SharedPreferences.getInstance();

    int parsePossibleInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    idEnseignant = parsePossibleInt(prefs.get('idE'));
    if (idEnseignant == 0) {
      idEnseignant = parsePossibleInt(prefs.get('idEnseignant'));
    }

    if (idEnseignant == 0) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Identifiant enseignant introuvable.';
      });
      return;
    }

    final storedStudents = prefs.getString('teacherStudentsCache');
    final loadedStudents = <Map<String, dynamic>>[];

    if (storedStudents != null) {
      final decodedData = jsonDecode(storedStudents);
      if (decodedData is List) {
        for (final student in decodedData) {
          final studentMap = student is Map<String, dynamic>
              ? student
              : Map<String, dynamic>.from(student as Map);
          final studentId = studentMap['id']?.toString() ?? studentMap['studentId']?.toString() ?? '';
          final firstName = (studentMap['prenomfr'] ?? studentMap['Prenomfr'] ?? '').toString().trim();
          final lastName = (studentMap['nomfr'] ?? studentMap['Nomfr'] ?? '').toString().trim();
          final parents = (studentMap['parents'] as List<dynamic>? ?? [])
              .map<Map<String, dynamic>>((parent) => Map<String, dynamic>.from(parent as Map))
              .toList();

          loadedStudents.add({
            'studentId': studentId,
            'firstName': firstName,
            'lastName': lastName,
            'fullName': '$lastName $firstName'.trim(),
            'classId': studentMap['classId']?.toString() ?? studentMap['classe_id']?.toString() ?? '',
            'className': studentMap['className']?.toString() ?? studentMap['classe_nomfr']?.toString() ?? studentMap['nomClasse']?.toString() ?? studentMap['nomclasse']?.toString() ?? '',
            'parents': parents,
            'parentIds': parents
                .map((parent) => parent['idpersonne']?.toString() ?? parent['idPersonne']?.toString() ?? parent['id_personne']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .join(','),
            'parentNames': parents
                .map((parent) {
                  final parentFirstName = (parent['prenomfr'] ?? parent['Prenomfr'] ?? '').toString().trim();
                  final parentLastName = (parent['nomfr'] ?? parent['Nomfr'] ?? '').toString().trim();
                  return '$parentLastName $parentFirstName'.trim();
                })
                .where((name) => name.isNotEmpty)
                .join(' & '),
          });
        }
      }
    }

    if (loadedStudents.isEmpty) {
      final allStudents = await provider.GetAllStudents(idEnseignant);
      for (final student in allStudents) {
        final studentMap = student is Map<String, dynamic>
            ? student
            : Map<String, dynamic>.from(student as Map);
        final studentId = studentMap['id']?.toString() ?? studentMap['studentId']?.toString() ?? '';
        final firstName = (studentMap['prenomfr'] ?? studentMap['Prenomfr'] ?? '').toString().trim();
        final lastName = (studentMap['nomfr'] ?? studentMap['Nomfr'] ?? '').toString().trim();
        final parents = (studentMap['parents'] as List<dynamic>? ?? [])
            .map<Map<String, dynamic>>((parent) => Map<String, dynamic>.from(parent as Map))
            .toList();

        loadedStudents.add({
          'studentId': studentId,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': '$lastName $firstName'.trim(),
          'classId': studentMap['classId']?.toString() ?? studentMap['classe_id']?.toString() ?? '',
          'className': studentMap['className']?.toString() ?? studentMap['classe_nomfr']?.toString() ?? studentMap['nomClasse']?.toString() ?? studentMap['nomclasse']?.toString() ?? '',
          'parents': parents,
          'parentIds': parents
              .map((parent) => parent['idpersonne']?.toString() ?? parent['idPersonne']?.toString() ?? parent['id_personne']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .join(','),
          'parentNames': parents
              .map((parent) {
                final parentFirstName = (parent['prenomfr'] ?? parent['Prenomfr'] ?? '').toString().trim();
                final parentLastName = (parent['nomfr'] ?? parent['Nomfr'] ?? '').toString().trim();
                return '$parentLastName $parentFirstName'.trim();
              })
              .where((name) => name.isNotEmpty)
              .join(' & '),
        });
      }
    }

    if (!mounted) return;

    setState(() {
      _students.clear();
      _students.addAll(loadedStudents);
    });

    await prefs.setString('rdvFlow', 'teacher');

    if (!mounted) return;

    setState(() {
      isLoading = false;
      errorMessage = null;
    });
  }


  Future<void> _selectStudent(Map<String, dynamic> student) async {
    _dismissKeyboard();

    final prefs = await SharedPreferences.getInstance();
    String parentFirstName ="null" ;
    String parentLastName ="null" ;
    String parentNames = "null";
    final parentsList = student['parents'] as List<Map<String, dynamic>>? ?? [];
    int studentid = int.tryParse(student['studentId']?.toString() ?? '') ?? 0;
    
    int idresponsable = await EnseignantProvider().getResponsable(studentid);
    final parents = student['parents'] as List;
  final father = parents.where(
  (parent) => parent['type'] == 'Père'
  );

  if (father.isNotEmpty) {
    parentFirstName = father.first['prenomfr']?.toString() ?? '';
  }
  if (father.isNotEmpty) {
    parentLastName = father.first['nomfr']?.toString() ?? '';
  }
  parentNames = '$parentLastName $parentFirstName'.trim();
    
   
    await prefs.setString('rdvFlow', 'teacher'); 
    await prefs.setString('selectedTeacherClassId', student['classId']?.toString() ?? '');
    await prefs.setString('selectedTeacherClassName', student['className']?.toString() ?? '');
    await prefs.setString('selectedTeacherStudentId', student['studentId']?.toString() ?? '');
    await prefs.setString('selectedTeacherStudentName', student['fullName']?.toString() ?? '');
    await prefs.setString('selectedTeacherParentId', idresponsable.toString());
    await prefs.setString('selectedTeacherParentName', parentNames);
    

    if (!mounted) return;

    _dismissKeyboard();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChooseCreneauScreen(isTeacher: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final filteredStudents = query.isEmpty
        ? <Map<String, dynamic>>[]
        : filterStudentsByQuery(_students, query);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: const CustomAppBar(
          interfacePage: HomeEnseignant(),
          title: "Choisir un contact",
          subtitle: "selectionnez un eleve pour continuer",
          showBackButton: true,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher un élève',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
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
                        : query.isEmpty
                            ? Center(
                                child: Text(
                                  'Commencez à taper le nom d\'un élève',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              )
                            : filteredStudents.isEmpty
                                ? const Center(child: Text('Aucun élève trouvé'))
                                : ListView.separated(
                                    itemCount: filteredStudents.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final student = filteredStudents[index];
                                      final studentName = student['fullName']?.toString().trim().isNotEmpty == true
                                          ? student['fullName'].toString().trim()
                                          : 'Élève sans nom';

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => _selectStudent(student),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: const Color(0xffEAF3FF),
                                                child: Icon(Icons.person, color: Colors.blue.shade700),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      studentName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      student['className']?.toString() ?? '',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}