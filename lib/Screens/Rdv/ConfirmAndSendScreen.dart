import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/providers/Rdv_provider.dart';
import 'ChooseCreneauScreen.dart';
import 'SuccessRdvScreen.dart';
import 'package:test/Screens/Widgets/custom_app_bar.dart';
import 'package:test/Screens/parent/home_Parent.dart';
import 'package:test/Screens/Enseignant/home_Enseignant.dart';

class ConfirmAndSendScreen extends StatefulWidget {
  const ConfirmAndSendScreen({super.key, required this.isTeacher});
  final bool isTeacher;
  @override
  State<ConfirmAndSendScreen> createState() => _ConfirmAndSendScreenState();
}

class _ConfirmAndSendScreenState extends State<ConfirmAndSendScreen> {
  final TextEditingController _reasonController = TextEditingController();

  String enseignantFullname = '';
  String matiere = '';
  String selectedDateDisplay = '';
  String selectedDateValue = '';
  String selectedTimeValue = '';
  String _selectedTimeStart = '';
  String _selectedTimeEnd = '';
  int idParent = 0;
  int idEnseignant = 0;
  bool _canSend = false;
  String parentName = '';
  String studentName = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(_updateCanSend);
    _loadPrefs();
    _updateCanSend();
  }

  void _updateCanSend() {
    final canSend = _reasonController.text.trim().isNotEmpty;
    if (_canSend != canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      enseignantFullname = prefs.getString('enseignantFullname') ?? '';
      matiere = prefs.getString('matiere') ?? '';
      selectedDateDisplay = prefs.getString('selectedDayLabel') ??
          prefs.getString('selectedDateDisplay') ??
          '';
      selectedDateValue = prefs.getString('selectedDateValue') ?? '';
      selectedTimeValue = prefs.getString('selectedTimeValue') ?? '';
      idParent = prefs.getInt('idPersonne') ?? 0;
      final dynamic rawIdEns = prefs.get('idEnseignant');
      if (rawIdEns is int) idEnseignant = rawIdEns; else idEnseignant = int.tryParse(rawIdEns?.toString() ?? '') ?? 0;
      _selectedTimeStart = prefs.getString('selectedTimeStart') ?? '';
      _selectedTimeEnd = prefs.getString('selectedTimeEnd') ?? '';
      // Load parent and student names from teacher flow
      parentName = prefs.getString('selectedTeacherParentName') ?? '';
      studentName = prefs.getString('selectedTeacherStudentName') ?? '';
    });
  }

  @override
  void dispose() {
    _reasonController.removeListener(_updateCanSend);
    _reasonController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF3F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: CustomAppBar(
          interfacePage: widget.isTeacher ? const HomeEnseignant() : const HomeParent(),
          title: "Confirmer & envoyer",
          subtitle: "",
          showBackButton: true,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 20),

                // 📊 Stepper
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.blue),
                    Expanded(child: Container(height: 2, color: Colors.blue)),
                    const Icon(Icons.check_circle, color: Colors.blue),
                    Expanded(child: Container(height: 2, color: Colors.blue)),
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue,
                      child: Text("3",
                          style: TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 📋 Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "RÉCAPITULATIF",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),

                      _row("Contact", parentName.isNotEmpty ? parentName : enseignantFullname),
                      if (widget.isTeacher ==false ) _row("Matière", matiere)else
  const SizedBox.shrink(),
                      _row("Date", selectedDateDisplay),
                      _row("Créneau", selectedTimeValue),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "MOTIF DU RENDEZ-VOUS",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        "Résultats, comportement, orientation, réclamation...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Notification envoyée à ${parentName.isNotEmpty ? parentName : 'le responsable'} et à l'administration",
                          style: const TextStyle(color: Colors.orange),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSend
                          ? const Color(0xff1F4B8F)
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text("Envoyer la demande"),
                     onPressed: _canSend
                        ? () async {
                            _dismissKeyboard();

                            final rdvProvider =
                                Provider.of<RdvProvider>(context,
                                    listen: false);

                            if (widget.isTeacher) {
                              // Teacher flow: support single or multiple parent IDs
                              final prefs = await SharedPreferences.getInstance();
                              final idTeacher = prefs.getInt('IdteacherInfo') ??
                                  prefs.getInt('idEnseignant') ??
                                  prefs.getInt('idE') ??
                                  int.tryParse(prefs.getString('idEnseignant') ?? '') ?? 0;
                              final parentIdStr = prefs.getString('selectedTeacherParentId') ?? '';
                              final parentNameStr = prefs.getString('selectedTeacherParentName') ?? '';
                              final studentId = int.tryParse(prefs.getString('selectedTeacherStudentId') ?? '') ?? 0;
                              final classId = int.tryParse(prefs.getString('selectedTeacherClassId') ?? '') ?? 0;

                              // Send only to the first (main) parent
                              final pid = int.tryParse(parentIdStr) ?? 0;
                              if (pid > 0) {
                                await rdvProvider.createTeacherRDV(
                                  idTeacher: idTeacher,
                                  idParent: pid,
                                  date: selectedDateValue,
                                  timeStart: _selectedTimeStart,
                                  timeEnd: _selectedTimeEnd,
                                  motif: _reasonController.text,
                                );
                              } else {
                                // fallback to current user idPersonne if no parent ID available
                                final fallback = prefs.getInt('idPersonne') ?? 0;
                                if (fallback > 0) {
                                  await rdvProvider.createTeacherRDV(
                                    idTeacher: idTeacher,
                                    idParent: fallback,
                                    date: selectedDateValue,
                                    timeStart: _selectedTimeStart,
                                    timeEnd: _selectedTimeEnd,
                                    motif: _reasonController.text,
                                  );
                                }
                              }
                            } else {
                              // Parent flow: call createRDV
                              await rdvProvider.createRDV(
                                idParent: idParent,
                                idEnseignant: idEnseignant,
                                date: selectedDateValue,
                                temp: selectedTimeValue,
                                motif: _reasonController.text,
                                heureDebut: _selectedTimeStart,
                                heureFin: _selectedTimeEnd,
                              );
                            }

                            _dismissKeyboard();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SuccessRdvScreen(
                                  enseignantFullname: enseignantFullname,
                                  isTeacher: widget.isTeacher,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}