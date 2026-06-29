import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ChooseCreneauScreen.dart';


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

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      enseignantFullname = prefs.getString('enseignantFullname') ?? '';
      matiere = prefs.getString('matiere') ?? '';
      selectedDateValue = prefs.getString('selectedDateValue') ?? '';
      selectedTimeValue = prefs.getString('selectedTimeValue') ?? '';
    });
  }

  Future<void> _saveReason() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reason', _reasonController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demande envoyée')),
    );
    Navigator.pop(context);
  }
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF3F8),
      body: SafeArea(
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
                  
                  Spacer(),
                  Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xff1F4B8F),
                        child: Icon(Icons.notifications, color: Colors.white),
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
                  SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: Color(0xff1F4B8F),
                    child: Text("ISE",
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
                  Expanded(
                    child: Container(height: 2, color: Colors.blue),
                  ),
                  const Icon(Icons.check_circle, color: Colors.blue),
                  Expanded(
                    child: Container(height: 2, color: Colors.blue),
                  ),
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue,
                    child: Text("3",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 📋 Summary Card
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

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Contact"),
          Text(
            enseignantFullname,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),

      const SizedBox(height: 8),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Matière"),
          Text(
            matiere,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),

      const SizedBox(height: 8),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Date"),
          Text(
            selectedDateValue,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),

      const SizedBox(height: 8),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Créneau"),
          Text(
            selectedTimeValue,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ],
  ),
),
              const SizedBox(height: 20),

              const Text(
                "MOTIF DU RENDEZ-VOUS",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // ✍️ Text Field
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

              // ⚠️ Warning
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

              const Spacer(),

              // 🚀 Send button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1F4B8F),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text("Envoyer la demande"),
                  
                  onPressed: () {
                    // TODO: send request API
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