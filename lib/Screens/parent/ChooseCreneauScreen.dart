import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  int? selectedDayIndex;
  int? selectedSlotIndex;
  bool isLoading = true;
  String? errorMessage;

  final List<String> availableDays = [];
  final List<Map<String, String>> allSlots = [];
  final List<Map<String, String>> filteredSlots = [];

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString("idEnseignant") ?? '';

    setState(() {
      id = savedId;
      fullname = prefs.getString("enseignantFullname") ?? '';
      matiere = prefs.getString("matiere") ?? '';
    });

    if (id.isNotEmpty) {
      await fetchDisponibilites();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Identifiant de l\'enseignant introuvable.';
      });
    }
  }

  Future<void> fetchDisponibilites() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      availableDays.clear();
      allSlots.clear();
      filteredSlots.clear();
      selectedDayIndex = null;
      selectedSlotIndex = null;
    });

    final teacherId = int.tryParse(id);
    if (teacherId == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'ID enseignant invalide.';
      });
      return;
    }

    try {
      final url = 'http://apiserv.ise-college-lycee.com:8415/api/enseignant/$teacherId/disponibilite';
      debugPrint('fetchDisponibilites: GET $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('fetchDisponibilites: status=${response.statusCode}');
      debugPrint('fetchDisponibilites: body=${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slotKeys = <String>{};

        if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final day = item['jour']?.toString() ?? '';
              if (day.isEmpty) continue;

              if (!availableDays.contains(day)) {
                availableDays.add(day);
              }

              final disponibiliteBegin = item['disponibilite_debut']?.toString() ?? '';
              final disponibiliteEnd = item['disponibilite_fin']?.toString() ?? '';

              if (disponibiliteBegin.isNotEmpty && disponibiliteEnd.isNotEmpty) {
                final slotKey = '$day|$disponibiliteBegin|$disponibiliteEnd';
                if (!slotKeys.contains(slotKey)) {
                  slotKeys.add(slotKey);
                  allSlots.add({
                    'jour': day,
                    'time': '$disponibiliteBegin - $disponibiliteEnd',
                  });
                }
              }
            }
          }
        }

        debugPrint('fetchDisponibilites: days=$availableDays');
        debugPrint('fetchDisponibilites: slots=$allSlots');

        if (availableDays.isEmpty) {
          errorMessage = 'Aucun jour disponible trouvé.';
        }
      } else {
        errorMessage = 'Erreur serveur : ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'Erreur réseau : $e';
    }

    setState(() {
      isLoading = false;
    });
  }

  bool get isFormValid =>
      selectedDayIndex != null && selectedSlotIndex != null;

  void _selectDay(int index) {
    final day = availableDays[index];
    final slotsForDay = allSlots.where((slot) => slot['jour'] == day).toList();

    setState(() {
      selectedDayIndex = index;
      selectedSlotIndex = null;
      filteredSlots
        ..clear()
        ..addAll(slotsForDay);
    });
  }

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

              const SizedBox(height: 10),

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
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
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              if (isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ] else if (errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableDays.length,
                    itemBuilder: (context, index) {
                      final dayName = availableDays[index];
                      final isSelected = selectedDayIndex == index;

                      return GestureDetector(
                        onTap: () => _selectDay(index),
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xff1F4B8F) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Disponible',
                                style: TextStyle(
                                  color: isSelected ? Colors.white70 : Colors.grey,
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
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: filteredSlots.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              selectedDayIndex == null
                                  ? 'Sélectionnez un jour pour voir les créneaux disponibles.'
                                  : 'Aucun créneau disponible pour ce jour.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : GridView.builder(
                          itemCount: filteredSlots.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            final slot = filteredSlots[index];
                            final isSelected = selectedSlotIndex == index;

                            return GestureDetector(
                              onTap: selectedDayIndex != null
                                  ? () {
                                      setState(() {
                                        selectedSlotIndex = index;
                                      });
                                    }
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xff1F4B8F) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    slot['time'] ?? '',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFormValid
                        ? const Color(0xff1F4B8F)
                        : Colors.grey,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isFormValid
                      ? () async {
                          final selectedDay = availableDays[selectedDayIndex!];
                          final selectedTime = filteredSlots[selectedSlotIndex!]['time'] ?? '';

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('selectedDateValue', selectedDay);
                          await prefs.setString('selectedTimeValue', selectedTime);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConfirmAndSendScreen(),
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