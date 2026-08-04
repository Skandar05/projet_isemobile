import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/providers/EnseignantProvider.dart';
import 'package:test/providers/Rdv_provider.dart';
import 'package:test/providers/disponibilite_provider.dart';
import 'package:test/Screens/Widgets/custom_app_bar.dart';
import '../parent/home_Parent.dart';
import '../Enseignant/home_Enseignant.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'SuccessRdvScreen.dart';

class ChooseCreneauScreen extends StatefulWidget {
  
  const ChooseCreneauScreen({super.key,required this.isTeacher});
  final bool isTeacher;

  @override
  State<ChooseCreneauScreen> createState() => _ChooseCreneauScreenState();
  
}

class _ChooseCreneauScreenState extends State<ChooseCreneauScreen> with WidgetsBindingObserver {
  String id = '';
  String fullname = '';
  String matiere = '';
  
  final _baseUrl = dotenv.env['BACKEND_URL'];
  

  int selectedWeekOffset = 0;
  int? selectedDayIndex;
  int? selectedSlotIndex;
  bool isLoading = true;
  String? errorMessage;
  // Debug helpers
  String debugRawResponse = '';
  int debugResolvedTeacherId = 0;

  final List<String> availableDays = [];
  final List<Map<String, String>> allSlots = [];
  final List<Map<String, String>> filteredSlots = [];
  final List<Map<String, String>> allDateOccurrences = [];
  final List<Map<String, String>> availableDates = [];
  final List<Map<String, String>> allDateSlots = [];
  final List<Map<String, String>> filteredDateSlots = [];
  String nomparent = '';
  final TextEditingController _motifController = TextEditingController();
  bool _canSend = false;
  bool _isSubmitting = false;
  String selectedDateDisplay = '';
  String selectedDateValue = '';
  String selectedTimeValue = '';
  int idParent = 0;
  int idEnseignant = 0;
  String parentName = '';
  final TextEditingController _teacherSearchController = TextEditingController();
  final List<Map<String, dynamic>> _teacherStudents = [];
  bool _teacherStudentsLoading = false;
  String? _teacherStudentsError;
  String _selectedTeacherStudentId = '';
  String _selectedTeacherStudentName = '';
  String _selectedTeacherClassName = '';
  String _selectedTeacherParentName = '';
  String _selectedTeacherParentId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motifController.addListener(_updateCanSend);
    _teacherSearchController.addListener(_updateCanSend);
    loadPrefs();
    if (widget.isTeacher) {
      _loadTeacherStudents();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motifController.removeListener(_updateCanSend);
    _motifController.dispose();
    _teacherSearchController.removeListener(_updateCanSend);
    _teacherSearchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (widget.isTeacher && state == AppLifecycleState.resumed) {
      _clearTeacherSelection(clearPrefs: true);
    }
  }
  Future<void>loadstudent()async{
    final prefs = await SharedPreferences.getInstance();
    final storedStudents = prefs.getString('teacherStudentsCache');

  }

  void _updateCanSend() {
    final hasTeacherStudent = !widget.isTeacher || _selectedTeacherStudentId.isNotEmpty;
    final canSend = !_isSubmitting &&
        selectedDayIndex != null &&
        selectedSlotIndex != null &&
        _motifController.text.trim().isNotEmpty &&
        hasTeacherStudent;

    if (_canSend != canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Map<String, dynamic> _normalizeTeacherStudent(Map<String, dynamic> studentMap) {
    final firstName = (studentMap['prenomfr'] ?? studentMap['Prenomfr'] ?? '').toString().trim();
    final lastName = (studentMap['nomfr'] ?? studentMap['Nomfr'] ?? '').toString().trim();
    final parents = (studentMap['parents'] as List<dynamic>? ?? [])
        .map<Map<String, dynamic>>((parent) => Map<String, dynamic>.from(parent as Map))
        .toList();

    return {
      ...studentMap,
      'studentId': studentMap['id']?.toString() ?? studentMap['studentId']?.toString() ?? '',
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
    };
  }

  Future<void> _loadTeacherStudents() async {
    if (!widget.isTeacher) return;

    final prefs = await SharedPreferences.getInstance();
    final teacherId = prefs.getInt('idE') ?? prefs.getInt('idEnseignant') ?? 0;

    if (teacherId <= 0) {
      if (!mounted) return;
      setState(() {
        _teacherStudentsLoading = false;
        _teacherStudentsError = 'Identifiant enseignant introuvable.';
      });
      return;
    }

    setState(() {
      _teacherStudentsLoading = true;
      _teacherStudentsError = null;
    });

    try {
      final provider = Provider.of<EnseignantProvider>(context, listen: false);
      final normalizedStudents = <Map<String, dynamic>>[];
      final cachedStudents = prefs.getString('teacherStudentsCache');

      if (cachedStudents != null && cachedStudents.isNotEmpty) {
        final decodedData = jsonDecode(cachedStudents);
        if (decodedData is List) {
          for (final item in decodedData) {
            final student = item is Map<String, dynamic>
                ? Map<String, dynamic>.from(item)
                : Map<String, dynamic>.from(item as Map);
            normalizedStudents.add(_normalizeTeacherStudent(student));
          }
        }
      }

      if (normalizedStudents.isEmpty) {
        final students = await provider.GetAllStudents(teacherId);
        for (final item in students) {
          final student = item is Map<String, dynamic>
              ? Map<String, dynamic>.from(item)
              : Map<String, dynamic>.from(item as Map);
          normalizedStudents.add(_normalizeTeacherStudent(student));
        }
      }

      if (!mounted) return;

      setState(() {
        _teacherStudents.clear();
        _teacherStudents.addAll(normalizedStudents);
      });

      await prefs.setString('teacherStudentsCache', jsonEncode(_teacherStudents));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _teacherStudentsError = 'Impossible de charger les élèves.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _teacherStudentsLoading = false;
        });
      }
    }
  }

  Future<void> _selectTeacherStudent(Map<String, dynamic> student) async {
    FocusScope.of(context).unfocus();

    final studentId = student['studentId']?.toString() ?? '';
    final firstName = (student['prenomfr'] ?? student['Prenomfr'] ?? '').toString().trim();
    final lastName = (student['nomfr'] ?? student['Nomfr'] ?? '').toString().trim();
    final fullName = '$lastName $firstName'.trim();
    final className = student['className']?.toString() ?? '';
    final parents = (student['parents'] as List<dynamic>? ?? []);

    String resolvedParentId = '';
    String resolvedParentName = '';
    for (final parent in parents) {
      final parentMap = parent is Map<String, dynamic>
          ? parent
          : Map<String, dynamic>.from(parent as Map);
      final parentFirstName = (parentMap['prenomfr'] ?? parentMap['Prenomfr'] ?? '').toString().trim();
      final parentLastName = (parentMap['nomfr'] ?? parentMap['Nomfr'] ?? '').toString().trim();
      final name = '$parentLastName $parentFirstName'.trim();
      final parentId = parentMap['idpersonne']?.toString() ?? parentMap['idPersonne']?.toString() ?? parentMap['id_personne']?.toString() ?? '';
      if (resolvedParentId.isEmpty && parentId.isNotEmpty) {
        resolvedParentId = parentId;
      }
      if (resolvedParentName.isEmpty && name.isNotEmpty) {
        resolvedParentName = name;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final provider = Provider.of<EnseignantProvider>(context, listen: false);
    final responsableId = await provider.getResponsable(int.tryParse(studentId) ?? 0);

    final selectedParentName = (student['parentNames']?.toString().trim().isNotEmpty == true)
        ? student['parentNames'].toString().trim()
        : (resolvedParentName.isNotEmpty ? resolvedParentName : (fullName.isNotEmpty ? fullName : 'Responsable'));
    final selectedParentId = responsableId > 0 ? responsableId.toString() : (resolvedParentId.isNotEmpty ? resolvedParentId : '');

    if (!mounted) return;

    setState(() {
      _selectedTeacherStudentId = studentId;
      _selectedTeacherStudentName = fullName;
      _selectedTeacherClassName = className;
      _selectedTeacherParentName = selectedParentName;
      _selectedTeacherParentId = selectedParentId;
      _teacherSearchController.text = fullName;
    });

    if (!mounted) return;

    await prefs.setString('rdvFlow', 'teacher');
    await prefs.setString('selectedTeacherStudentId', studentId);
    await prefs.setString('selectedTeacherStudentName', fullName);
    await prefs.setString('selectedTeacherClassId', student['classId']?.toString() ?? '');
    await prefs.setString('selectedTeacherClassName', className);
    await prefs.setString('selectedTeacherParentId', _selectedTeacherParentId);
    await prefs.setString('selectedTeacherParentName', _selectedTeacherParentName);

    _updateCanSend();
  }

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.isTeacher) {
      await _clearPersistedTeacherSelection(prefs);
    }

    nomparent = prefs.getString('selectedTeacherParentName') ?? '';
    parentName = nomparent;

    // Try multiple keys: handle int or string stored values
    String savedId = '';
    final dynamic rawIdEnseignant = prefs.get('idEnseignant');
    if (rawIdEnseignant != null) {
      if (rawIdEnseignant is int) savedId = rawIdEnseignant.toString();
      else if (rawIdEnseignant is String) savedId = rawIdEnseignant;
      else savedId = rawIdEnseignant.toString();
    }

    if (savedId.isEmpty) {
      final dynamic rawIdE = prefs.get('idE');
      if (rawIdE != null) {
        if (rawIdE is int) savedId = rawIdE.toString();
        else if (rawIdE is String) savedId = rawIdE;
      }
    }

    if (savedId.isEmpty) {
      final dynamic rawIdPersonne = prefs.get('idPersonne');
      if (rawIdPersonne != null) {
        if (rawIdPersonne is int) savedId = rawIdPersonne.toString();
        else if (rawIdPersonne is String) savedId = rawIdPersonne;
      }
    }

    setState(() {
      id = savedId;
      fullname = prefs.getString('enseignantFullname') ?? '';
      matiere = prefs.getString('matiere') ?? prefs.getString('Nommatierefr') ?? '';
      selectedDateDisplay = prefs.getString('selectedDayLabel') ?? '';
      selectedDateValue = prefs.getString('selectedDateValue') ?? '';
      selectedTimeValue = prefs.getString('selectedTimeValue') ?? '';
      idParent = prefs.getInt('idPersonne') ?? 0;
      final dynamic rawIdEns = prefs.get('idEnseignant');
      if (rawIdEns is int) {
        idEnseignant = rawIdEns;
      } else {
        idEnseignant = int.tryParse(rawIdEns?.toString() ?? '') ?? 0;
      }
    });

    _updateCanSend();

    if (id.isNotEmpty) {
      await fetchDisponibilites();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Identifiant de l\'enseignant introuvable.';
      });
    }
  }

  Future<void> _clearPersistedTeacherSelection(SharedPreferences prefs) async {
    await prefs.remove('selectedTeacherStudentId');
    await prefs.remove('selectedTeacherStudentName');
    await prefs.remove('selectedTeacherClassId');
    await prefs.remove('selectedTeacherClassName');
    await prefs.remove('selectedTeacherParentId');
    await prefs.remove('selectedTeacherParentName');
  }

  void _clearTeacherSelection({bool clearPrefs = false}) async {
    if (clearPrefs) {
      final prefs = await SharedPreferences.getInstance();
      await _clearPersistedTeacherSelection(prefs);
    }

    if (!mounted) return;

    setState(() {
      _selectedTeacherStudentId = '';
      _selectedTeacherStudentName = '';
      _selectedTeacherClassName = '';
      _selectedTeacherParentName = '';
      _selectedTeacherParentId = '';
      _teacherSearchController.clear();
    });

    _updateCanSend();
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
      debugPrint('fetchDisponibilites teacherId=$teacherId');
      final url = '$_baseUrl/api/enseignant/disponibilites/$teacherId';

      // add a timeout to avoid hanging the UI indefinitely
        final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

        // expose debug info
        debugRawResponse = response.body;
        debugResolvedTeacherId = teacherId;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slotKeys = <String>{};
        final normalizedSlots = normalizeTeacherDisponibilitePayload(data);

        for (final slot in normalizedSlots) {
          final day = slot['jour']?.toString() ?? '';
          if (day.isEmpty) continue;

          if (!availableDays.contains(day)) {
            availableDays.add(day);
          }

          final startTime = slot['start']?.toString() ?? '';
          final endTime = slot['end']?.toString() ?? '';

          if (startTime.isNotEmpty && endTime.isNotEmpty) {
            final slotKey = '$day|$startTime|$endTime';
            if (!slotKeys.contains(slotKey)) {
              slotKeys.add(slotKey);
              allSlots.add({
                'jour': day,
                'start': startTime,
                'end': endTime,
                'time': slot['time']?.toString() ?? '$startTime - $endTime',
              });
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
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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

  bool _isTodayDate(String? value) {
    final parsedDate = DateTime.tryParse(value ?? '');
    if (parsedDate == null) return false;

    final now = DateTime.now();
    return parsedDate.year == now.year &&
        parsedDate.month == now.month &&
        parsedDate.day == now.day;
  }

  bool _isFutureSlot(Map<String, String> slot, String? dateValue) {
    if (!_isTodayDate(dateValue)) return true;

    final slotStart = slot['start'] ?? '';
    final parts = slotStart.split(':');
    if (parts.length != 2) return true;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    final slotDateTime = DateTime(now.year, now.month, now.day, hour, minute);

    return slotDateTime.isAfter(now);
  }

  List<Map<String, String>> _slotsForDateEntry(Map<String, String> dateEntry) {
    final label = dateEntry['label'] ?? '';

    return allDateSlots.where((slot) {
      final slotLabel = slot['label'] ?? '';
      return slot['jour'] == dateEntry['jour'] &&
          slotLabel == label &&
          _isFutureSlot(slot, dateEntry['value']);
    }).toList();
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

      final dateSlots = _slotsForDateEntry(date);
      if (dateSlots.isEmpty) {
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
    final slotsForDate = _slotsForDateEntry(dateEntry);

    setState(() {
      selectedDayIndex = index;
      selectedSlotIndex = null;
      filteredSlots
        ..clear()
        ..addAll(slotsForDate);
    });

    _updateCanSend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: CustomAppBar(
          interfacePage: widget.isTeacher ? const HomeEnseignant() : const HomeParent(),
          title:  "Choisir un créneau",
          subtitle: "selectionnez un créneau pour continuer",
          showBackButton: true,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
              const SizedBox(height: 20),
              if (!widget.isTeacher)
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
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullname,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            matiere,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RECHERCHER UN ÉLÈVE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _teacherSearchController,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Nom de l’élève',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _teacherSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _teacherSearchController.clear();
                                      if (_selectedTeacherStudentId.isNotEmpty) {
                                        _selectedTeacherStudentId = '';
                                        _selectedTeacherStudentName = '';
                                        _selectedTeacherClassName = '';
                                        _selectedTeacherParentName = '';
                                        _selectedTeacherParentId = '';
                                      }
                                    });
                                    _updateCanSend();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xffF5F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_teacherStudentsLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_teacherStudentsError != null)
                        Text(
                          _teacherStudentsError!,
                          style: const TextStyle(color: Colors.red),
                        )
                      else if (_selectedTeacherStudentId.isEmpty)
                        Builder(
                          builder: (_) {
                            final query = _teacherSearchController.text.trim().toLowerCase();
                            if (query.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _teacherStudents.isEmpty
                                      ? 'Chargement des élèves en cours...'
                                      : 'Commencez à taper le nom d’un élève pour démarrer la recherche.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              );
                            }

                            final filteredStudents = _teacherStudents.where((student) {
                              final fullName = (student['fullName'] ?? '').toString().toLowerCase();
                              final className = (student['className'] ?? '').toString().toLowerCase();
                              return fullName.contains(query) || className.contains(query);
                            }).take(10).toList();

                            if (filteredStudents.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Aucun élève trouvé',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              );
                            }

                            return Column(
                              children: filteredStudents.map((student) {
                                final fullName = (student['fullName'] ?? '').toString();
                                final className = (student['className'] ?? '').toString();
                                return InkWell(
                                  onTap: () => _selectTeacherStudent(student),
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF5F7FB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Color(0xff1F4B8F),
                                          child: Icon(Icons.person, size: 16, color: Colors.white),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              if (className.isNotEmpty)
                                                Text(className, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xffF5F7FB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedTeacherStudentName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (_selectedTeacherClassName.isNotEmpty)
                                Text(
                                  _selectedTeacherClassName,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              const SizedBox(height: 4),
                              if (_selectedTeacherParentName.isNotEmpty)
                                Text(
                                  'Responsable : $_selectedTeacherParentName',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
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
                                label,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Créneaux disponibles',
                                style: TextStyle(
                                  color: isSelected ? Colors.white70 : Colors.grey,
                                  fontSize: 10,
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

                SizedBox(
                  height: 150,
                  
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
                            childAspectRatio: 3,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
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
                                      _updateCanSend();
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

              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MOTIF DU RENDEZ-VOUS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _motifController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Résultats, comportement, orientation, réclamation...',
                        filled: true,
                        fillColor: const Color(0xffF5F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.isTeacher
                                  ? 'La demande sera envoyée au parent sélectionné et à l\'administration.'
                                  : 'La demande sera envoyée à l\'enseignant et à l\'administration.',
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSend ? const Color(0xff1F4B8F) : Colors.grey,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _canSend && !_isSubmitting
                      ? () async {
                          _dismissKeyboard();

                          setState(() {
                            _isSubmitting = true;
                          });
                          _updateCanSend();

                          final prefs = await SharedPreferences.getInstance();
                          final selectedDate = availableDates[selectedDayIndex!];
                          final selectedSlot = filteredSlots[selectedSlotIndex!];

                          await prefs.setString('selectedDateValue', selectedDate['value'] ?? '');
                          await prefs.setString('selectedDayLabel', selectedDate['label'] ?? '');
                          await prefs.setString('selectedTimeValue', selectedSlot['time'] ?? '');
                          await prefs.setString('selectedTimeStart', selectedSlot['start'] ?? '');
                          await prefs.setString('selectedTimeEnd', selectedSlot['end'] ?? '');

                          if (!context.mounted) {
                            return;
                          }

                          final rdvProvider = Provider.of<RdvProvider>(context, listen: false);
                          bool created = false;

                          if (widget.isTeacher) {
                            final idTeacher = prefs.getInt('IdteacherInfo') ??
                                prefs.getInt('idEnseignant') ??
                                prefs.getInt('idE') ??
                                int.tryParse(prefs.getString('idEnseignant') ?? '') ??
                                0;
                            final parentIdStr = prefs.getString('selectedTeacherParentId') ?? '';
                            final pid = int.tryParse(parentIdStr) ?? 0;

                            if (pid > 0) {
                              created = await rdvProvider.createTeacherRDV(
                                idTeacher: idTeacher,
                                idParent: pid,
                                date: selectedDate['value'] ?? '',
                                timeStart: selectedSlot['start'] ?? '',
                                timeEnd: selectedSlot['end'] ?? '',
                                motif: _motifController.text.trim(),
                              );
                            } else {
                              final fallback = prefs.getInt('idPersonne') ?? 0;
                              if (fallback > 0) {
                                created = await rdvProvider.createTeacherRDV(
                                  idTeacher: idTeacher,
                                  idParent: fallback,
                                  date: selectedDate['value'] ?? '',
                                  timeStart: selectedSlot['start'] ?? '',
                                  timeEnd: selectedSlot['end'] ?? '',
                                  motif: _motifController.text.trim(),
                                );
                              }
                            }
                          } else {
                            created = await rdvProvider.createRDV(
                              idParent: idParent,
                              idEnseignant: idEnseignant,
                              date: selectedDate['value'] ?? '',
                              temp: selectedSlot['time'] ?? '',
                              motif: _motifController.text.trim(),
                              heureDebut: selectedSlot['start'] ?? '',
                              heureFin: selectedSlot['end'] ?? '',
                            );
                          }

                          if (!context.mounted) {
                            return;
                          }

                          if (created) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SuccessRdvScreen(
                                  enseignantFullname: fullname.isNotEmpty ? fullname : (widget.isTeacher ? parentName : 'L\'enseignant'),
                                  isTeacher: widget.isTeacher,
                                ),
                              ),
                            );
                          } else {
                            setState(() {
                              _isSubmitting = false;
                            });
                            _updateCanSend();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('La demande n\'a pas pu être envoyée. Veuillez réessayer.'),
                              ),
                            );
                          }
                        }
                      : null,
                  child: Text(
                    _isSubmitting ? 'Envoi en cours...' : 'Envoyer la demande',
                    style: const TextStyle(
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
      ),
    );
  }
}