import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/providers/Rdv_provider.dart';
import 'ChooseCreneauScreen.dart';
import 'SuccessRdvScreen.dart';

class ConfirmAndSendScreen extends StatefulWidget {
  const ConfirmAndSendScreen({super.key});

  @override
  State<ConfirmAndSendScreen> createState() => _ConfirmAndSendScreenState();
}

class _ConfirmAndSendScreenState extends State<ConfirmAndSendScreen> {
  final TextEditingController _reasonController = TextEditingController();

  String enseignantFullname = '';
  String matiere = '';
  String selectedDateValue = '';
  String selectedTimeValue = '';
  int idParent = 0;
  int idEnseignant = 0;
  bool _canSend = false;

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
      selectedDateValue = prefs.getString('selectedDateValue') ?? '';
      selectedTimeValue = prefs.getString('selectedTimeValue') ?? '';
      idParent = prefs.getInt('idPersonne') ?? 0;
      idEnseignant =
          int.tryParse(prefs.getString('idEnseignant') ?? '') ?? 0;
    });
  }

  @override
  void dispose() {
    _reasonController.removeListener(_updateCanSend);
    _reasonController.dispose();
    super.dispose();
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

                // 🔙 Header
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ChooseCreneauScreen(),
                          ),
                        );
                      },
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.arrow_back),
                      ),
                    ),
                    const Spacer(),
                    Stack(
                      children: const [
                        CircleAvatar(
                          backgroundColor: Color(0xff1F4B8F),
                          child: Icon(Icons.notifications,
                              color: Colors.white),
                        ),
                        Positioned(
                          right: 0,
                          child: CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.red,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: const Color(0xff1F4B8F),
                      child: const Text("ISE",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  "Confirmer & envoyer",
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),

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

                      _row("Contact", enseignantFullname),
                      _row("Matière", matiere),
                      _row("Date", selectedDateValue),
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
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Notification envoyée à M. Ben Amor Karim et à l'administration",
                          style: TextStyle(color: Colors.orange),
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
                            final rdvProvider =
                                Provider.of<RdvProvider>(context,
                                    listen: false);

                            await rdvProvider.createRDV(
                              idParent: idParent,
                              idEnseignant: idEnseignant,
                              date: selectedDateValue,
                              temp: selectedTimeValue,
                              motif: _reasonController.text,
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SuccessRdvScreen(
                                  enseignantFullname:
                                      enseignantFullname,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}