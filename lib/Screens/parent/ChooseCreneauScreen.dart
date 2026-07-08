import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'creationRDV.dart';
import 'ConfirmAndSendScreen.dart';
import 'package:test/Screens/Enseignant/TeacherConfirmRdvScreen.dart';

class ChooseCreneauScreen extends StatefulWidget {
  const ChooseCreneauScreen({super.key});

  @override
  State<ChooseCreneauScreen> createState() => _ChooseCreneauScreenState();
}

class _ChooseCreneauScreenState extends State<ChooseCreneauScreen> {
  String id = '';
  String fullname = '';
  String matiere = '';

  int selectedWeekOffset = 0;
  int? selectedDayIndex;
  int? selectedSlotIndex;
  bool isLoading = true;
  String? errorMessage;

  final List<String> availableDays = [];
  final List<Map<String, String>> allSlots = [];
  final List<Map<String, String>> filteredSlots = [];
  final List<Map<String, String>> allDateOccurrences = [];
  final List<Map<String, String>> availableDates = [];
  final List<Map<String, String>> allDateSlots = [];
  final List<Map<String, String>> filteredDateSlots = [];

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

  List<Map<String, String>> _generateSlots(String start, String end, {int slotMinutes = 15}) {
    final slots = <Map<String, String>>[];
    final startParts = start.split(':');
    final endParts = end.split(':');

    if (startParts.length != 2 || endParts.length != 2) return slots;

    final startH = int.tryParse(startParts[0]) ?? 0;
    final startM = int.tryParse(startParts[1]) ?? 0;
    final endH = int.tryParse(endParts[0]) ?? 0;
    final endM = int.tryParse(endParts[1]) ?? 0;

    final totalStart = startH * 60 + startM;
    final totalEnd = endH * 60 + endM;

    if (totalEnd <= totalStart) return slots;

    for (var current = totalStart; current + slotMinutes <= totalEnd; current += slotMinutes) {
      final slotEnd = current + slotMinutes;
      final slotStartStr = '${(current ~/ 60).toString().padLeft(2, '0')}:${(current % 60).toString().padLeft(2, '0')}';
      final slotEndStr = '${(slotEnd ~/ 60).toString().padLeft(2, '0')}:${(slotEnd % 60).toString().padLeft(2, '0')}';
      slots.add({
        'start': slotStartStr,
        'end': slotEndStr,
        'time': '$slotStartStr - $slotEndStr',
      });
    }

    return slots;
  }

  Future<void> fetchDisponibilites() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      availableDays.clear();
      allSlots.clear();
      filteredSlots.clear();
      allDateOccurrences.clear();
      selectedDayIndex = null;
      selectedSlotIndex = null;
      selectedWeekOffset = 0;
      availableDates.clear();
      allDateSlots.clear();
      filteredDateSlots.clear();
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
      debugPrint('$teacherId');
      final url = 'http://apiserv.ise-college-lycee.com:8415/api/enseignant/disponibilites/$teacherId';
      

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

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

              final heureDebut = (item['heure_debut']?.toString() ?? item['heuredebut']?.toString() ?? '').trim();
              final heureFin = (item['heure_fin']?.toString() ?? item['heurefin']?.toString() ?? '').trim();
              final dispoDebut = (item['disponibilite_debut']?.toString() ?? '').trim();
              final dispoFin = (item['disponibilite_fin']?.toString() ?? '').trim();

              final startTime = heureDebut.isNotEmpty ? heureDebut : dispoDebut;
              final endTime = heureFin.isNotEmpty ? heureFin : dispoFin;

              if (startTime.isNotEmpty && endTime.isNotEmpty) {
                final subSlots = _generateSlots(startTime, endTime);
                for (final slot in subSlots) {
                  final slotKey = '$day|${slot['start']}|${slot['end']}';
                  if (!slotKeys.contains(slotKey)) {
                    slotKeys.add(slotKey);
                    allSlots.add({
                      'jour': day,
                      'start': slot['start']!,
                      'end': slot['end']!,
                      'time': slot['time']!,
                    });
                  }
                }
              }
            }
          }
        }

        _buildCalendarOccurrences();

        debugPrint('fetchDisponibilites: days=$availableDays');
        debugPrint('fetchDisponibilites: slots=$allSlots');
        debugPrint('fetchDisponibilites: dateSlots=$allDateSlots');

        if (availableDays.isEmpty) {
          errorMessage = 'Aucun jour disponible trouvé.';
        }
      } else if (response.statusCode == 404) {
        errorMessage = 'Aucune disponibilité trouvée pour cet enseignant.';
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

  DateTime _startOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatWeekLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    final startLabel = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}';
    final endLabel = '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';
    return 'Semaine du $startLabel au $endLabel';
  }

  DateTime _currentWeekStart() {
    return _startOfWeek(DateTime.now()).add(Duration(days: selectedWeekOffset * 7));
  }

  void _applyWeekFilter() {
    availableDates.clear();
    filteredSlots.clear();
    selectedDayIndex = null;
    selectedSlotIndex = null;

    final weekStart = _currentWeekStart();
    final weekEnd = weekStart.add(const Duration(days: 6));
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (final date in allDateOccurrences) {
      final value = date['value'];
      if (value == null) continue;

      final parsedDate = DateTime.tryParse(value);
      if (parsedDate == null) continue;

      if (selectedWeekOffset == 0 && parsedDate.isBefore(today)) {
        continue;
      }

      if (parsedDate.isBefore(weekStart) || parsedDate.isAfter(weekEnd)) {
        continue;
      }

      availableDates.add(date);
    }

    availableDates.sort((a, b) => (a['value'] ?? '').compareTo(b['value'] ?? ''));
  }

  void _changeWeek(int delta) {
    if (selectedWeekOffset + delta < 0) {
      return;
    }

    setState(() {
      selectedWeekOffset += delta;
      _applyWeekFilter();
    });
  }

  void _buildCalendarOccurrences() {
    allDateOccurrences.clear();
    allDateSlots.clear();

    final dateSlotKeys = <String>{};
    final weekStart = _startOfWeek(DateTime.now());
    final horizonEnd = weekStart.add(const Duration(days: 41));
    final weekdays = {
      'lundi': DateTime.monday,
      'mardi': DateTime.tuesday,
      'mercredi': DateTime.wednesday,
      'jeudi': DateTime.thursday,
      'vendredi': DateTime.friday,
      'samedi': DateTime.saturday,
      'dimanche': DateTime.sunday,
    };

    for (final day in availableDays) {
      final normalized = day.toLowerCase();
      final target = weekdays[normalized];
      if (target == null) continue;

      for (var candidate = weekStart;
          !candidate.isAfter(horizonEnd);
          candidate = candidate.add(const Duration(days: 1))) {
        if (candidate.weekday != target) {
          continue;
        }

        final dateStrApi = _formatDateKey(candidate);
        final dateStrDisplay =
            '${candidate.day.toString().padLeft(2, '0')}/${candidate.month.toString().padLeft(2, '0')}/${candidate.year}';
        final label =
            '$day ${candidate.day.toString().padLeft(2, '0')}/${candidate.month.toString().padLeft(2, '0')}';

        if (!allDateOccurrences.any((d) => d['label'] == label && d['value'] == dateStrApi)) {
          allDateOccurrences.add({
            'label': label,
            'value': dateStrApi,
            'display': dateStrDisplay,
            'jour': day,
          });
        }

        for (final slot in allSlots) {
          if (slot['jour'] != day) continue;
          final key = '$dateStrApi|${slot['start']}|${slot['end']}';
          if (!dateSlotKeys.contains(key)) {
            dateSlotKeys.add(key);
            allDateSlots.add({
              'label': label,
              'value': dateStrApi,
              'display': dateStrDisplay,
              'jour': day,
              'start': slot['start']!,
              'end': slot['end']!,
              'time': slot['time']!,
            });
          }
        }
      }
    }

    allDateOccurrences.sort((a, b) => (a['value'] ?? '').compareTo(b['value'] ?? ''));
    allDateSlots.sort((a, b) {
      final valueCompare = (a['value'] ?? '').compareTo(b['value'] ?? '');
      if (valueCompare != 0) return valueCompare;
      return (a['start'] ?? '').compareTo(b['start'] ?? '');
    });

    _applyWeekFilter();
  }

  bool get isFormValid =>
      selectedDayIndex != null && selectedSlotIndex != null;

  void _selectDate(int index) {
    final dateEntry = availableDates[index];
    final label = dateEntry['label'] ?? '';
    final slotsForDate = allDateSlots.where((slot) {
      final slotLabel = slot['label'] ?? '';
      return slot['jour'] == dateEntry['jour'] && slotLabel == label;
    }).toList();

    setState(() {
      selectedDayIndex = index;
      selectedSlotIndex = null;
      filteredSlots
        ..clear()
        ..addAll(slotsForDate);
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

              Row(
                children: [
                  IconButton(
                    onPressed: selectedWeekOffset > 0 ? () => _changeWeek(-1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatWeekLabel(_currentWeekStart()),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Filtrée par semaine',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeWeek(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),

              const SizedBox(height: 12),

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
              ] else if (availableDates.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Aucune date disponible pour cette semaine.',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableDates.length,
                    itemBuilder: (context, index) {
                      final date = availableDates[index];
                      final label = date['label'] ?? '';
                      final isSelected = selectedDayIndex == index;

                      return GestureDetector(
                        onTap: () => _selectDate(index),
                        child: Container(
                          width: 130,
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
                                label,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Créneaux disponibles',
                                style: TextStyle(
                                  color: isSelected ? Colors.white70 : Colors.grey,
                                  fontSize: 12,
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
                                  ? 'Sélectionnez une date pour voir les créneaux disponibles.'
                                  : 'Aucun créneau disponible pour cette date.',
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
                    backgroundColor: selectedDayIndex != null && selectedSlotIndex != null
                        ? const Color(0xff1F4B8F)
                        : Colors.grey,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: selectedDayIndex != null && selectedSlotIndex != null
                      ? () async {
                          final prefs = await SharedPreferences.getInstance();
                          final selectedDate = availableDates[selectedDayIndex!];
                          final selectedSlot = filteredSlots[selectedSlotIndex!];

                          await prefs.setString('selectedDateValue', selectedDate['value'] ?? '');
                          await prefs.setString('selectedDayLabel', selectedDate['label'] ?? '');
                          await prefs.setString('selectedTimeValue', selectedSlot['time'] ?? '');
                          await prefs.setString('selectedTimeStart', selectedSlot['start'] ?? '');
                          await prefs.setString('selectedTimeEnd', selectedSlot['end'] ?? '');
                          final flow = prefs.getString('rdvFlow') ?? 'parent';

                          if (!context.mounted) {
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => flow == 'teacher'
                                  ? const TeacherConfirmRdvScreen()
                                  : const ConfirmAndSendScreen(),
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