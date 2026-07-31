import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/Screens/Widgets/custom_app_bar.dart';
import 'package:test/Screens/Enseignant/student_search_utils.dart';
import 'package:test/Screens/parent/home_Parent.dart';
import 'package:test/providers/Pd_Providers.dart';
import 'package:test/providers/auth_provider.dart';

class RdvPdParent extends StatefulWidget {
  const RdvPdParent({super.key});

  @override
  State<RdvPdParent> createState() => _RdvPdParentState();
}

class _RdvPdParentState extends State<RdvPdParent> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _loadingStudents = false;

  Map<String, dynamic>? _selectedStudent;
  int? _selectedParentId;

  bool _loadingDisponibilite = false;
  String? _disponibiliteError;

  final List<String> _availableDays = [];
  final List<Map<String, String>> _allSlots = [];
  final List<Map<String, String>> _allDateSlots = [];
  final List<Map<String, String>> _allDateOccurrences = [];

  final List<Map<String, String>> _availableDates = [];
  final List<Map<String, String>> _filteredSlots = [];

  int? _selectedDayIndex;
  int? _selectedSlotIndex;
  int _selectedWeekOffset = 0;
  final Color primary = const Color(0xff1F4B8F);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _filterStudents(_searchController.text);
    });
    _loadStudents();
    _fetchDisponibilite();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('students') ?? prefs.getString('classes') ?? prefs.getString('studentsList');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _students = List<Map<String, dynamic>>.from(decoded.map((e) => Map<String, dynamic>.from(e)));
        } else if (decoded is Map) {
          if (decoded.containsKey('students') && decoded['students'] is List) {
            _students = List<Map<String, dynamic>>.from((decoded['students'] as List).map((e) => Map<String, dynamic>.from(e)));
          } else if (decoded.containsKey('data') && decoded['data'] is List) {
            _students = List<Map<String, dynamic>>.from((decoded['data'] as List).map((e) => Map<String, dynamic>.from(e)));
          }
        }
      }
    } catch (_) {
      _students = [];
    }
    if (!mounted) return;
    setState(() {
      _filteredStudents = [];
      _loadingStudents = false;
    });
  }

  Future<void> _fetchDisponibilite() async {
    setState(() {
      _loadingDisponibilite = true;
      _disponibiliteError = null;
      _availableDays.clear();
      _allSlots.clear();
      _allDateOccurrences.clear();
      _allDateSlots.clear();
      _availableDates.clear();
      _filteredSlots.clear();
      _selectedDayIndex = null;
      _selectedSlotIndex = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      int idPedagogique = int.parse(prefs.getString('IdPd') ?? '0');
      debugPrint('Fetching disponibilites for idPedagogique: $idPedagogique');
      final disponibilites = await PdProvider().getAllDisponibilites(idPedagogique);
      final slotKeys = <String>{};

      for (final item in disponibilites) {
        final jour = item['jour']?.toString().trim() ?? '';
        final start = item['heuredebut']?.toString().trim() ?? '';
        final end = item['heurefin']?.toString().trim() ?? '';
        if (jour.isEmpty || start.isEmpty || end.isEmpty) {
          continue;
        }
        if (!_availableDays.contains(jour)) {
          _availableDays.add(jour);
        }
        final slots = _generateSlots(start, end);
        for (final slot in slots) {
          final key = '$jour-${slot['start']}-${slot['end']}';
          if (slotKeys.add(key)) {
            _allSlots.add({
              'jour': jour,
              'start': slot['start']!,
              'end': slot['end']!,
              'time': slot['time']!,
            });
          }
        }
      }

      _buildCalendarOccurrences();
    } catch (error) {
      _disponibiliteError = error.toString();
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingDisponibilite = false;
      });
    }
  }

  List<Map<String, String>> _generateSlots(String start, String end) {
    final slots = <Map<String, String>>[];
    final startParts = start.split(':');
    final endParts = end.split(':');
    if (startParts.length != 2 || endParts.length != 2) {
      return slots;
    }

    final startMinutes = int.tryParse(startParts[0]) ?? 0;
    final startSeconds = int.tryParse(startParts[1]) ?? 0;
    final endMinutes = int.tryParse(endParts[0]) ?? 0;
    final endSeconds = int.tryParse(endParts[1]) ?? 0;

    final startTotal = startMinutes * 60 + startSeconds;
    final endTotal = endMinutes * 60 + endSeconds;

    for (var current = startTotal; current + 15 * 60 <= endTotal; current += 15 * 60) {
      final finish = current + 15 * 60;
      final h1 = (current ~/ 3600).toString().padLeft(2, '0');
      final m1 = ((current % 3600) ~/ 60).toString().padLeft(2, '0');
      final h2 = (finish ~/ 3600).toString().padLeft(2, '0');
      final m2 = ((finish % 3600) ~/ 60).toString().padLeft(2, '0');

      slots.add({
        'start': '$h1:$m1',
        'end': '$h2:$m2',
        'time': '$h1:$m1 - $h2:$m2',
      });
    }

    return slots;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _startOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  DateTime _currentWeekStart() {
    return _startOfWeek(DateTime.now()).add(Duration(days: _selectedWeekOffset * 7));
  }

  String _formatWeekLabel(DateTime date) {
    final end = date.add(const Duration(days: 6));
    return 'Semaine du ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} au ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';
  }

  void _buildCalendarOccurrences() {
    _allDateOccurrences.clear();
    _allDateSlots.clear();

    final weekStart = _startOfWeek(DateTime.now());
    final horizon = weekStart.add(const Duration(days: 41));

    const weekdays = {
      'lundi': DateTime.monday,
      'mardi': DateTime.tuesday,
      'mercredi': DateTime.wednesday,
      'jeudi': DateTime.thursday,
      'vendredi': DateTime.friday,
      'samedi': DateTime.saturday,
      'dimanche': DateTime.sunday,
    };

    final slotKeys = <String>{};

    for (final day in _availableDays) {
      final target = weekdays[day.toLowerCase()];
      if (target == null) continue;

      for (var date = weekStart; !date.isAfter(horizon); date = date.add(const Duration(days: 1))) {
        if (date.weekday != target) continue;

        final apiDate = _formatDateKey(date);
        final label = '$day ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

        _allDateOccurrences.add({
          'label': label,
          'value': apiDate,
          'jour': day,
        });

        for (final slot in _allSlots) {
          if (slot['jour'] != day) continue;
          final key = '$apiDate-${slot['start']}-${slot['end']}';
          if (slotKeys.add(key)) {
            _allDateSlots.add({
              'label': label,
              'value': apiDate,
              'jour': day,
              'start': slot['start']!,
              'end': slot['end']!,
              'time': slot['time']!,
            });
          }
        }
      }
    }

    _allDateOccurrences.sort((a, b) => a['value']!.compareTo(b['value']!));
    _allDateSlots.sort((a, b) {
      final dateComparison = a['value']!.compareTo(b['value']!);
      if (dateComparison != 0) return dateComparison;
      return a['start']!.compareTo(b['start']!);
    });

    _applyWeekFilter();
  }

  void _applyWeekFilter() {
    _availableDates.clear();
    _filteredSlots.clear();
    _selectedDayIndex = null;
    _selectedSlotIndex = null;

    final start = _currentWeekStart();
    final end = start.add(const Duration(days: 6));
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (final date in _allDateOccurrences) {
      final parsed = DateTime.tryParse(date['value']!);
      if (parsed == null) continue;
      if (_selectedWeekOffset == 0 && parsed.isBefore(today)) continue;
      if (parsed.isBefore(start) || parsed.isAfter(end)) continue;
      _availableDates.add(date);
    }

    _availableDates.sort((a, b) => a['value']!.compareTo(b['value']!));

    if (_availableDates.isNotEmpty) {
      _selectedDayIndex = 0;
      final firstValue = _availableDates.first['value'];
      _filteredSlots.addAll(_allDateSlots.where((slot) => slot['value'] == firstValue));
    }
  }

  void _changeWeek(int increment) {
    if (_selectedWeekOffset + increment < 0) {
      return;
    }
    setState(() {
      _selectedWeekOffset += increment;
      _applyWeekFilter();
    });
  }

  void _selectDate(int index) {
    if (index < 0 || index >= _availableDates.length) return;
    final date = _availableDates[index];
    final slots = _allDateSlots.where((slot) => slot['value'] == date['value']).toList();
    setState(() {
      _selectedDayIndex = index;
      _selectedSlotIndex = null;
      _filteredSlots
        ..clear()
        ..addAll(slots);
    });
  }

  void _selectSlot(int index) {
    if (index < 0 || index >= _filteredSlots.length) return;
    setState(() {
      _selectedSlotIndex = index;
    });
  }

  void _filterStudents(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredStudents = [];
      });
      return;
    }

    final results = filterStudentsByQuery(_students, query);
    setState(() {
      _filteredStudents = results;
    });
  }

  Future<void> _selectStudent(Map<String, dynamic> student) async {
    final dynamic pid = student['parentId'] ?? student['idParent'] ?? student['id_parent'] ?? student['parent_id'] ?? student['parentID'] ?? student['id'] ?? student['parent'];
    int? parsed;
    if (pid is int) {
      parsed = pid;
    } else if (pid is String) {
      parsed = int.tryParse(pid);
    }

    if (parsed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de récupérer l\'ID du parent')));
      return;
    }

    final name = (student['fullName'] ?? student['name'] ?? student['prenomfr'] ?? student['nomfr'] ?? '').toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTeacherParentId', parsed.toString());
    await prefs.setString('selectedTeacherParentName', name);

    if (!mounted) return;
    setState(() {
      _selectedStudent = student;
      _selectedParentId = parsed;
      _searchController.text = name;
      _filteredStudents = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Parent sélectionné (ID: $parsed)')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xffF5F7FB),
      appBar: CustomAppBar(
        interfacePage: HomeParent(),
        title: 'Rendez-vous pédagogique',
        subtitle: 'Créer un rendez-vous pédagogique',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un élève...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xff1F4B8F), width: 1.5),
                  ),
                ),
                onChanged: _filterStudents,
              ),
              const SizedBox(height: 8),
              if (!_loadingStudents)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Text(
                    'Élèves chargés: ${_students.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              if (_loadingStudents) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(),
                ),
              ] else if (_searchController.text.isNotEmpty) ...[
                Container(
                  constraints: const BoxConstraints(maxHeight: 240),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _filteredStudents.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Aucun élève trouvé'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _filteredStudents.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            final displayName = (student['fullName'] ?? student['name'] ?? student['prenomfr'] ?? student['nomfr'] ?? '').toString();
                            final classLabel = (student['className'] ?? student['classe'] ?? student['nomclasse'] ?? '').toString();
                            return ListTile(
                              title: Text(displayName.isNotEmpty ? displayName : 'Nom non renseigné'),
                              subtitle: classLabel.isNotEmpty ? Text(classLabel) : null,
                              onTap: () => _selectStudent(student),
                            );
                          },
                        ),
                ),
              ],
              if (_selectedStudent != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Élève sélectionné',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedStudent = null;
                                _selectedParentId = null;
                                _searchController.clear();
                                _filteredStudents = [];
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (_selectedStudent!['fullName'] ?? _selectedStudent!['name'] ?? _selectedStudent!['prenomfr'] ?? _selectedStudent!['nomfr'] ?? 'Nom non renseigné').toString(),
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      if ((_selectedStudent!['className'] ?? _selectedStudent!['classe'] ?? _selectedStudent!['nomclasse']) != null)
                        Text(
                          'Classe: ${(_selectedStudent!['className'] ?? _selectedStudent!['classe'] ?? _selectedStudent!['nomclasse'] ?? '').toString()}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'CHOISIR UNE DATE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Filtrée par semaine',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),
              if (_loadingDisponibilite) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(),
                ),
              ] else if (_disponibiliteError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Erreur chargement disponibilités: $_disponibiliteError',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeWeek(-1),
                    ),
                    Expanded(
                      child: Text(
                        _formatWeekLabel(_currentWeekStart()),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeWeek(1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_availableDates.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Aucune date disponible pour cette semaine.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFFBE6F00)),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableDates.length,
                      itemBuilder: (context, index) {
                        final date = _availableDates[index];
                        final selected = _selectedDayIndex == index;
                        return GestureDetector(
                          onTap: () {
                            _selectDate(index);
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(
                              right: 10,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  date['label']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Créneaux disponibles",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
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
                ],
              
              ],
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'motif de la demande',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _motifController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Entrez le motif de votre demande...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color.fromARGB(255, 1, 9, 20), width: 1.5),
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
