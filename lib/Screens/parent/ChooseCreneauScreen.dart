import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'creationRDV.dart';
import 'ConfirmAndSendScreen.dart';

class ChooseCreneauScreen extends StatefulWidget {
  const ChooseCreneauScreen({super.key});

  @override
  State<ChooseCreneauScreen> createState() => _ChooseCreneauScreenState();
}

class _ChooseCreneauScreenState extends State<ChooseCreneauScreen> {

  String id = '';
  String fullname = '';
  String matiere = '';

  int? selectedDate;
  int? selectedTime;

  final dates = [
    {"day": "SAM", "date": "14"},
    {"day": "SAM", "date": "21"},
    {"day": "SAM", "date": "28"},
  ];

  final times = [
    {"time": "14:00 - 14:30"},
    {"time": "14:30 - 15:00"},
    {"time": "15:00 - 15:30"},
    {"time": "15:30 - 16:00"},
  ];

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      id = prefs.getString("idEnseignant") ?? '';
      fullname = prefs.getString("enseignantFullname") ?? '';
      matiere = prefs.getString("matiere") ?? '';
    });
  }

  bool get isFormValid =>
      selectedDate != null && selectedTime != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 20),

              // HEADER
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ChooseContactScreen(),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_back),
                    ),
                  ),
                  const Spacer(),
                  const CircleAvatar(
                    backgroundColor: Color(0xff1F4B8F),
                    child: Icon(Icons.notifications,
                        color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "Nouveau rendez-vous",
                style: TextStyle(color: Colors.grey),
              ),

              const Text(
                "Choisir un créneau",
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
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue,
                    child: Text("2",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  Expanded(
                    child: Container(height: 2, color: Colors.grey),
                  ),
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey,
                    child: Text("3",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TEACHER CARD
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xff1F4B8F),
                      child: Icon(Icons.person,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullname,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          matiere,
                          style: const TextStyle(
                              color: Colors.grey),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "CHOISIR UNE DATE",
                style:
                    TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // DATES
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final d = dates[index];
                    final isSelected =
                        selectedDate == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = index;
                          selectedTime = null; // reset time
                        });
                      },
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xff1F4B8F)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              d["day"]!,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              d["date"]!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "CRÉNEAUX DISPONIBLES",
                style:
                    TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // TIMES
              Expanded(
                child: GridView.builder(
                  itemCount: times.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final t = times[index];
                    final isSelected =
                        selectedTime == index;

                    return GestureDetector(
                      onTap: selectedDate != null
                          ? () {
                              setState(() {
                                selectedTime = index;
                              });
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xff1F4B8F)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            t["time"]!,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // CONTINUE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFormValid
                        ? const Color(0xff1F4B8F)
                        : Colors.grey,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                    onPressed: isFormValid
                      ? () async {
                        final d = dates[selectedDate!];
                        final t = times[selectedTime!];

                        final selectedDateValue = '${d['day']} ${d['date']}';
                        final selectedTimeValue = t['time']!;

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('selectedDateValue', selectedDateValue);
                        await prefs.setString('selectedTimeValue', selectedTimeValue);

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfirmAndSendScreen(
                              ),
                            ),
                          ); 
                      }
                      : null,
                  child: const Text(
                    'Continuer →',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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