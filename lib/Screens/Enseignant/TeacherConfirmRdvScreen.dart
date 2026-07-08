import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/Screens/parent/ChooseCreneauScreen.dart';
import 'package:test/Screens/parent/rendezvous_screen.dart';

class TeacherConfirmRdvScreen extends StatefulWidget {
  const TeacherConfirmRdvScreen({super.key});

  @override
  State<TeacherConfirmRdvScreen> createState() => _TeacherConfirmRdvScreenState();
}

class _TeacherConfirmRdvScreenState extends State<TeacherConfirmRdvScreen> {
  String className = '';
  String studentName = '';
  String parentName = '';
  String selectedDateDisplay = '';
  String selectedTimeValue = '';
  String selectedTimeStart = '';
  String selectedTimeEnd = '';
  String teacherName = '';
  String motif = '';
  int teacherId = 0;
  int parentId = 0;
  int studentId = 0;
  int classId = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      className = prefs.getString('selectedTeacherClassName') ?? '';
      studentName = prefs.getString('selectedTeacherStudentName') ?? '';
      parentName = prefs.getString('selectedTeacherParentName') ?? '';
      selectedDateDisplay = prefs.getString('selectedDayLabel') ??
          prefs.getString('selectedDateDisplay') ??
          '';
      selectedTimeValue = prefs.getString('selectedTimeValue') ?? '';
      selectedTimeStart = prefs.getString('selectedTimeStart') ?? '';
      selectedTimeEnd = prefs.getString('selectedTimeEnd') ?? '';
      teacherName = prefs.getString('enseignantFullname') ?? '';
      motif = prefs.getString('teacherRdvMotif') ?? '';
      teacherId = prefs.getInt('idE') ??
          prefs.getInt('idEnseignant') ??
          int.tryParse(prefs.getString('idE') ?? '') ??
          int.tryParse(prefs.getString('idEnseignant') ?? '') ??
          0;
      parentId = int.tryParse(prefs.getString('selectedTeacherParentId') ?? '') ?? 0;
      studentId = int.tryParse(prefs.getString('selectedTeacherStudentId') ?? '') ?? 0;
      classId = int.tryParse(prefs.getString('selectedTeacherClassId') ?? '') ?? 0;
      _loading = false;
    });
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Non renseigné' : value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF3F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChooseCreneauScreen(),
                          ),
                        );
                      },
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: Color(0xff1F4B8F),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.notifications_none,
                            color: Color(0xff1F4B8F),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          backgroundColor: const Color(0xff1F4B8F),
                          child: ClipOval(
                            child: Image.asset(
                              'lib/images/logoise.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Confirmer la demande',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RÉCAPITULATIF',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _row('Enseignant', teacherName),
                            _row('Classe', className),
                            _row('Élève', studentName),
                            _row('Parent', parentName),
                            _row('Date', selectedDateDisplay),
                            _row('Créneau', selectedTimeValue),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Motif',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    motif.isEmpty ? 'Non renseigné' : motif,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'La création de rendez-vous enseignant est prête côté interface, mais l\'API POST reste à brancher.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1F4B8F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text('Envoyer la demande'),
                    onPressed: () async {
                      // TODO: brancher l'API POST enseignant quand elle sera disponible.
                      // await rdvProvider.createTeacherRDV(
                      //   idTeacher: teacherId,
                      //   idParent: parentId,
                      //   date: selectedDateDisplay,
                      //   timeStart: selectedTimeStart,
                      //   timeEnd: selectedTimeEnd,
                      //   motif: motif,
                      //   studentId: studentId,
                      //   classId: classId,
                      //   parentName: parentName,
                      //   parentType: '',
                      // );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('API de création rendez-vous enseignant non encore disponible.'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RendezVousPage(isTeacher: true),
                        ),
                      );
                    },
                    child: const Text('Retour aux rendez-vous'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
