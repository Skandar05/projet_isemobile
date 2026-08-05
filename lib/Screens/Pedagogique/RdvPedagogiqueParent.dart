import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/Screens/Pedagogique/HomePD.dart';
import 'package:test/Screens/Pedagogique/Pd_rendezvous_screen.dart';
import 'package:test/Screens/Widgets/custom_app_bar.dart';
import 'package:test/Screens/parent/home_Parent.dart';
import 'package:test/Screens/Enseignant/student_search_utils.dart';
import 'package:test/providers/Pd_Providers.dart';
import 'package:test/providers/Rdv_provider.dart';

class RdvPdParent extends StatefulWidget {
  const RdvPdParent({super.key});

  @override
  State<RdvPdParent> createState() => _RdvPdParentState();
}

class _RdvPdParentState extends State<RdvPdParent> {
  final Color primary = const Color(0xff1F4B8F);

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
  final List<Map<String, dynamic>> _allSlots = [];
  final List<Map<String, dynamic>> _filteredSlots = [];
  final List<Map<String, dynamic>> _availableDates = [];
  final List<Map<String, dynamic>> _allDateSlots = [];
  final List<Map<String, dynamic>> _allDateOccurrences = [];

  int parentId = 0;
  int? _selectedDayIndex;
  int? _selectedSlotIndex;
  int _selectedWeekOffset = 0;
  int idPd = 0;
  List<Map<String, dynamic>> data = [];

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      _filterStudents(_searchController.text);
    });

    _motifController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _initializePage();
  }

  Future<void> _initializePage() async {
    await _loadStoredIdPd();
    await _loadStudents();

    if (!mounted) {
      return;
    }

    await _fetchDisponibilite(idPd);
  }

  Future<List<Map<String, dynamic>>> fetchData(int id) async {
    data = await PdProvider().GetDispoV2(id);
    return data;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredIdPd() async {
    final prefs = await SharedPreferences.getInstance();
    idPd = prefs.getInt('idPd') ?? 0;
    debugPrint('Loaded IdPd from SharedPreferences: $idPd');
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loadingStudents = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('students') ?? prefs.getString('classes') ?? prefs.getString('studentsList');

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          _students = List<Map<String, dynamic>>.from(
            decoded.map((e) => Map<String, dynamic>.from(e)),
          );
        } else if (decoded is Map) {
          if (decoded['students'] is List) {
            _students = List<Map<String, dynamic>>.from(
              (decoded['students'] as List).map((e) => Map<String, dynamic>.from(e)),
            );
          } else if (decoded['data'] is List) {
            _students = List<Map<String, dynamic>>.from(
              (decoded['data'] as List).map((e) => Map<String, dynamic>.from(e)),
            );
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

  void _filterStudents(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredStudents = [];
      });
      return;
    }

    final result = filterStudentsByQuery(_students, query);

    setState(() {
      _filteredStudents = result;
    });
  }

  int? _extractParentIdFromStudent(Map<String, dynamic> student) {
    final int pid = student['parentId'] ?? 0;
    debugPrint('Extracted Parent ID from student: $pid');
    return pid;
  }

  Future<void> _selectStudent(Map<String, dynamic> student) async {
    parentId = _extractParentIdFromStudent(student) ?? 0;

    final name = (
      student['fullName'] ??
      student['name'] ??
      student['prenomfr'] ??
      student['nomfr'] ??
      ''
    ).toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTeacherParentId', parentId.toString());

    setState(() {
      _selectedStudent = student;
      _selectedParentId = parentId;
      _searchController.text = name;
      _filteredStudents = [];
    });
  }

  Future<void> _fetchDisponibilite(int idpd) async {
    setState(() {
      _loadingDisponibilite = true;
      _disponibiliteError = null;
      _availableDays.clear();
      _allSlots.clear();
      _filteredSlots.clear();
      _availableDates.clear();
      _allDateSlots.clear();
      _allDateOccurrences.clear();
      _selectedDayIndex = null;
      _selectedSlotIndex = null;
    });

    try {
      if (idpd <= 0) {
        throw Exception('IdPd introuvable');
      }

      debugPrint('Loading disponibilite for IdPd : $idpd');
      final disponibilites = await fetchData(idpd);
      debugPrint('Fetched disponibilites: $disponibilites');

      final slotKeys = <String>{};

      for (final item in disponibilites) {
        final jour = item['jour']?.toString().trim() ?? '';
        final start = item['start']?.toString().trim() ?? item['heuredebut']?.toString().trim() ?? '';
        final end = item['end']?.toString().trim() ?? item['heurefin']?.toString().trim() ?? '';
        final dateValue = item['date']?.toString().trim() ?? item['value']?.toString().trim() ?? '';
        final isAvailable = item['isAvailable'] is bool
            ? item['isAvailable'] as bool
            : item['available'] is bool
                ? item['available'] as bool
                : true;

        if (start.isEmpty || end.isEmpty) {
          continue;
        }

        if (jour.isNotEmpty && !_availableDays.contains(jour)) {
          _availableDays.add(jour);
        }

        final key = item['id']?.toString() ?? '$dateValue-$start-$end';

        if (slotKeys.add(key)) {
          _allSlots.add({
            'id': item['id'],
            'jour': jour,
            'date': dateValue,
            'start': start,
            'end': end,
            'time': item['time']?.toString().trim().isNotEmpty == true
                ? item['time']!.toString()
                : '$start - $end',
            'isAvailable': isAvailable,
            'disponibiliteId': item['disponibiliteId'] ?? item['iddisponibilites'],
            'intervalId': item['intervalId'] ?? item['id'],
          });
        }
      }

      _buildCalendarOccurrences();
    } catch (e) {
      _disponibiliteError = e.toString();
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingDisponibilite = false;
      });
    }
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

    final start = _startOfWeek(DateTime.now());
    final end = start.add(const Duration(days: 41));
    final groupedSlots = <String, List<Map<String, dynamic>>>{};

    for (final slot in _allSlots) {
      final rawDate = slot['date']?.toString().trim() ?? '';
      final jour = slot['jour']?.toString().trim() ?? '';

      if (rawDate.isNotEmpty) {
        groupedSlots.putIfAbsent(rawDate, () => []).add(slot);
        continue;
      }

      final weekday = _weekdayNumber(jour);
      if (weekday == null) {
        continue;
      }

      for (DateTime date = start; !date.isAfter(end); date = date.add(const Duration(days: 1))) {
        if (date.weekday != weekday) {
          continue;
        }

        final dateValue = _formatDateKey(date);
        groupedSlots.putIfAbsent(dateValue, () => []).add(slot);
      }
    }

    final sortedDates = groupedSlots.keys.toList()..sort();

    for (final dateValue in sortedDates) {
      final parsedDate = DateTime.tryParse(dateValue);
      final label = parsedDate == null
          ? dateValue
          : '${_weekdayLabel(parsedDate)} ${parsedDate.day}/${parsedDate.month}';

      _allDateOccurrences.add({
        'label': label,
        'value': dateValue,
        'jour': parsedDate == null ? 'Date' : _weekdayLabel(parsedDate),
      });
    }

    for (final occurrence in _allDateOccurrences) {
      final dateValue = occurrence['value']!.toString();
      final slotsForDate = groupedSlots[dateValue] ?? const [];
      final seenKeys = <String>{};

      for (final slot in slotsForDate) {
        final slotKey = '${dateValue}-${slot['start']}-${slot['end']}-${slot['intervalId'] ?? slot['id'] ?? ''}';
        if (!seenKeys.add(slotKey)) {
          continue;
        }

        _allDateSlots.add({
          'label': occurrence['label']!,
          'value': dateValue,
          'jour': occurrence['jour']!,
          'start': slot['start']!,
          'end': slot['end']!,
          'time': slot['time']!,
          'isAvailable': slot['isAvailable'] ?? true,
          'id': slot['id'],
          'disponibiliteId': slot['disponibiliteId'] ?? slot['iddisponibilites'],
          'intervalId': slot['intervalId'] ?? slot['id'],
        });
      }
    }

    _allDateOccurrences.sort((a, b) => a['value']!.compareTo(b['value']!));
    _allDateSlots.sort((a, b) {
      final d = a['value']!.compareTo(b['value']!);
      if (d != 0) return d;
      return a['start']!.compareTo(b['start']!);
    });

    _applyWeekFilter();
  }

  int? _weekdayNumber(String jour) {
    const days = {
      'lundi': DateTime.monday,
      'mardi': DateTime.tuesday,
      'mercredi': DateTime.wednesday,
      'jeudi': DateTime.thursday,
      'vendredi': DateTime.friday,
      'samedi': DateTime.saturday,
      'dimanche': DateTime.sunday,
    };

    return days[jour.toLowerCase()];
  }

  String _weekdayLabel(DateTime date) {
    const weekdays = <String>[
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];
    return weekdays[date.weekday - 1];
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

      if (parsed == null) {
        continue;
      }

      if (_selectedWeekOffset == 0 && parsed.isBefore(today)) {
        continue;
      }

      if (parsed.isBefore(start) || parsed.isAfter(end)) {
        continue;
      }

      _availableDates.add(date);
    }

    _availableDates.sort((a, b) => a['value']!.compareTo(b['value']!));
  }

  void _changeWeek(int value) {
    if (_selectedWeekOffset + value < 0) {
      return;
    }

    setState(() {
      _selectedWeekOffset += value;
      _applyWeekFilter();
    });
  }

  void _selectDate(int index) {
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
    setState(() {
      _selectedSlotIndex = index;
    });
  }

  bool get _isRdvFormComplete {
    final hasValidParent = (_selectedParentId ?? 0) > 0;
    return _selectedStudent != null &&
        hasValidParent &&
        _selectedDayIndex != null &&
        _selectedSlotIndex != null &&
        _motifController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xffF5F7FB),
      appBar: CustomAppBar(
        interfacePage: HomePD(),
        title: 'Créer un rendez-vous',
        subtitle: 'Remplissez les informations du rendez-vous.',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sélectionner un élève',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un élève par nom',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingStudents)
                const Center(child: CircularProgressIndicator())
              else if (_filteredStudents.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.separated(
                    itemCount: _filteredStudents.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final name = (student['fullName'] ?? student['name'] ?? '').toString();
                      final className = (student['className'] ?? student['classe'] ?? '').toString();
                      return ListTile(
                        title: Text(name.isNotEmpty ? name : 'Élève'),
                        subtitle: className.isNotEmpty ? Text(className) : null,
                        onTap: () => _selectStudent(student),
                      );
                    },
                  ),
                )
              else if (_searchController.text.trim().isNotEmpty)
                const SizedBox.shrink(),
              if (_selectedStudent != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xff1F4B8F)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Élève sélectionné : ${(_selectedStudent!['fullName'] ?? _selectedStudent!['name'] ?? '').toString()}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Choisir une date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: _selectedWeekOffset > 0 ? () => _changeWeek(-1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      _formatWeekLabel(_currentWeekStart()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeWeek(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loadingDisponibilite)
                const Center(child: CircularProgressIndicator())
              else if (_disponibiliteError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _disponibiliteError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (_availableDates.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text('Aucune disponibilité n\'a été trouvée pour ce profil.'),
                )
              else ...[
                SizedBox(
                  height: 92,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableDates.length,
                    itemBuilder: (context, index) {
                      final date = _availableDates[index];
                      final selected = _selectedDayIndex == index;
                      return GestureDetector(
                        onTap: () => _selectDate(index),
                        child: Container(
                          width: 132,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: selected ? primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? Colors.blue : Colors.grey.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                date['label']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Créneaux disponibles',
                                style: TextStyle(
                                  color: selected ? Colors.white70 : Colors.grey,
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
                const SizedBox(height: 18),
                const Text(
                  'Créneaux disponibles',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredSlots.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final slot = _filteredSlots[index];
                    final selected = _selectedSlotIndex == index;
                    final isAvailable = slot['isAvailable'] == true;
                    return GestureDetector(
                      onTap: (isAvailable && _selectedDayIndex != null) ? () => _selectSlot(index) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? primary
                              : isAvailable
                                  ? Colors.white
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? Colors.blue
                                : isAvailable
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade400,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${slot['start'] ?? ''} - ${slot['end'] ?? ''}',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : isAvailable
                                      ? Colors.black
                                      : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Motif du rendez-vous',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _motifController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Écrire le motif du rendez-vous...',
                    prefixIcon: Icon(Icons.edit),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Créer un rendez-vous', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRdvFormComplete ? primary : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _isRdvFormComplete ? _createRdv : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createRdv() async {
    final selectedStudentParentId = _selectedParentId ?? parentId;
    debugPrint('Selected Student Parent ID: $selectedStudentParentId');

    if (_selectedDayIndex == null || _selectedSlotIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date et un créneau.')),
      );
      return;
    }

    final motif = _motifController.text.trim();

    if (motif.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un motif.')),
      );
      return;
    }

    final date = _availableDates[_selectedDayIndex!]['value']!;
    final slot = _filteredSlots[_selectedSlotIndex!];

    if ((selectedStudentParentId ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un élève valide.')),
      );
      return;
    }

    if (idPd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Id pédagogique introuvable.')),
      );
      return;
    }

    debugPrint('''
CREATE RDV:
idPd=$idPd
parent=$_selectedParentId
date=$date
start=${slot['start']}
end=${slot['end']}
motif=$motif
''');

    final result = await RdvProvider().createPDRdv(
      idpd: idPd,
      idParent: selectedStudentParentId,
      date: date,
      timeStart: slot['start']!,
      timeEnd: slot['end']!,
      motif: motif,
      role: 'pedagogique',
      iddespo: slot['disponibiliteId'] ?? slot['iddisponibilites'] ?? slot['id'] ?? 0,
      idinterval: slot['intervalId'] ?? slot['id'] ?? 0,
    );

    if (!mounted) return;

    if (result == 200 || result == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous créé avec succès.')),
      );

      setState(() {
        _selectedDayIndex = null;
        _selectedSlotIndex = null;
        _filteredSlots.clear();
        _motifController.clear();
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Pd_rendezvous_screen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur création RDV : $result')),
      );
    }
  }
}
