import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/Screens/Rdv/rendezvous_screen.dart';
import 'package:test/Screens/Widgets/custom_app_bar.dart';
import 'package:test/Screens/parent/home_Parent.dart';
import 'package:test/providers/Pd_Providers.dart';
import 'package:test/providers/rdv_provider.dart';

class RdvParentPd extends StatefulWidget {
  const RdvParentPd({super.key});

  @override
  State<RdvParentPd> createState() => _RdvParentPdState();
}

class _RdvParentPdState extends State<RdvParentPd> {
  final Color primary = const Color(0xff1F4B8F);

  List<dynamic> pedagogiques = [];
  Map<String, dynamic>? selectedPedagogique;
  int? selectedPedagogiqueId;

  int selectedWeekOffset = 0;
  int? selectedDayIndex;
  int? selectedSlotIndex;

  bool isLoading = false;
  String? errorMessage;

  final List<String> availableDays = [];
  final List<Map<String, dynamic>> allSlots = [];
  final List<Map<String, dynamic>> filteredSlots = [];
  final List<Map<String, dynamic>> availableDates = [];
  final List<Map<String, dynamic>> allDateSlots = [];
  final List<Map<String, dynamic>> allDateOccurrences = [];

  final TextEditingController motifController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPd();
  }

  @override
  void dispose() {
    motifController.dispose();
    super.dispose();
  }

  int idParent = 0;

  Future<void> _fetchPd() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      idParent = prefs.getInt('idPersonne') ?? 0;
      final result = await RdvProvider().loadpd();
      final parentIdStr = prefs.getString('selectedTeacherParentId') ?? '';
      debugPrint('Selected Teacher Parent ID: $parentIdStr');

      for (final item in result) {
        item['nom'] = '${item['Nomfr'] ?? ''} ${item['Prenomfr'] ?? ''}';
      }

      setState(() {
        pedagogiques = result;
      });

      if (pedagogiques.length == 1) {
        final onlyPd = pedagogiques.first;
        final idValue = int.tryParse(onlyPd['idpersonne']?.toString() ?? '');
        if (idValue != null) {
          await _onSelectPedagogique(idValue);
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Future<int> creationrdv(
    int idParent,
    int idPedagogique,
    String date,
    String motif,
    String role,
    String timeStart,
    String timeEnd,
    int iddespo,
    int idinterval,
  ) async {
    try {
      final result = await RdvProvider().createPDRdv(
        idpd: idPedagogique,
        idParent: idParent,
        date: date,
        motif: motif,
        role: 'parent',
        timeStart: timeStart,
        timeEnd: timeEnd,
        iddespo: iddespo,
        idinterval: idinterval,
      );
      return result;
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
      return -1;
    }
  }

  List<Map<String, dynamic>> data = [];

  Future<List<Map<String, dynamic>>> fetchData(int id) async {
    data = await PdProvider().GetDispoV2(id);
    return data;
  }

  Future<void> _onSelectPedagogique(int idPedagogique) async {
    final pd = pedagogiques.firstWhere(
      (item) => item['idpersonne']?.toString() == idPedagogique.toString(),
      orElse: () => {},
    );

    setState(() {
      selectedPedagogique = pd is Map<String, dynamic> && pd.isNotEmpty ? pd : null;
      selectedPedagogiqueId = idPedagogique;
    });

    await _fetchDisponibilite(idPedagogique);
  }

  Future<void> _fetchDisponibilite(int idPedagogique) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      availableDays.clear();
      allSlots.clear();
      filteredSlots.clear();
      availableDates.clear();
      allDateSlots.clear();
      allDateOccurrences.clear();
      selectedDayIndex = null;
      selectedSlotIndex = null;
    });

    try {
      if (idPedagogique <= 0) {
        throw Exception('Id pédagogique introuvable');
      }

      debugPrint('Loading disponibilite for IdPd : $idPedagogique');
      final disponibilites = await fetchData(idPedagogique);
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

        if (jour.isNotEmpty && !availableDays.contains(jour)) {
          availableDays.add(jour);
        }

        final key = item['id']?.toString() ?? '$dateValue-$start-$end';

        if (slotKeys.add(key)) {
          allSlots.add({
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
      errorMessage = e.toString();
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  DateTime _startOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  DateTime _currentWeekStart() {
    return _startOfWeek(DateTime.now()).add(Duration(days: selectedWeekOffset * 7));
  }

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatWeekLabel(DateTime date) {
    final end = date.add(const Duration(days: 6));
    return 'Semaine du ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} au ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';
  }

  void _buildCalendarOccurrences() {
    allDateOccurrences.clear();
    allDateSlots.clear();

    final start = _startOfWeek(DateTime.now());
    final end = start.add(const Duration(days: 41));
    final groupedSlots = <String, List<Map<String, dynamic>>>{};

    for (final slot in allSlots) {
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

      allDateOccurrences.add({
        'label': label,
        'value': dateValue,
        'jour': parsedDate == null ? 'Date' : _weekdayLabel(parsedDate),
      });
    }

    for (final occurrence in allDateOccurrences) {
      final dateValue = occurrence['value']!.toString();
      final slotsForDate = groupedSlots[dateValue] ?? const [];
      final seenKeys = <String>{};

      for (final slot in slotsForDate) {
        final slotKey = '${dateValue}-${slot['start']}-${slot['end']}-${slot['intervalId'] ?? slot['id'] ?? ''}';
        if (!seenKeys.add(slotKey)) {
          continue;
        }

        allDateSlots.add({
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

    allDateOccurrences.sort((a, b) => a['value']!.compareTo(b['value']!));
    allDateSlots.sort((a, b) {
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
    availableDates.clear();
    filteredSlots.clear();
    selectedDayIndex = null;
    selectedSlotIndex = null;

    final start = _currentWeekStart();
    final end = start.add(const Duration(days: 6));
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (final date in allDateOccurrences) {
      final parsed = DateTime.tryParse(date['value']!);

      if (parsed == null) {
        continue;
      }

      if (selectedWeekOffset == 0 && parsed.isBefore(today)) {
        continue;
      }

      if (parsed.isBefore(start) || parsed.isAfter(end)) {
        continue;
      }

      availableDates.add(date);
    }

    availableDates.sort((a, b) => a['value']!.compareTo(b['value']!));
  }

  void _changeWeek(int value) {
    if (selectedWeekOffset + value < 0) {
      return;
    }

    setState(() {
      selectedWeekOffset += value;
      _applyWeekFilter();
    });
  }

  void _selectDate(int index) {
    final date = availableDates[index];
    final slots = allDateSlots.where((slot) => slot['value'] == date['value']).toList();

    setState(() {
      selectedDayIndex = index;
      selectedSlotIndex = null;
      filteredSlots
        ..clear()
        ..addAll(slots);
    });
  }

  void _selectSlot(int index) {
    setState(() {
      selectedSlotIndex = index;
    });
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choisir un pédagogique', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selectedPedagogiqueId,
                    hint: const Text('Sélectionnez un pédagogique'),
                    items: pedagogiques.map((pd) {
                      final idValue = int.tryParse(pd['idpersonne']?.toString() ?? '') ?? pd['idpersonne'] as int?;
                      return DropdownMenuItem<int>(
                        value: idValue,
                        child: Text('${pd['Nomfr']} ${pd['Prenomfr']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _onSelectPedagogique(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text('CHOISIR UNE DATE', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(onPressed: selectedWeekOffset > 0 ? () => _changeWeek(-1) : null, icon: const Icon(Icons.chevron_left)),
                  Expanded(child: Text(_formatWeekLabel(_currentWeekStart()), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () => _changeWeek(1), icon: const Icon(Icons.chevron_right)),
                ],
              ),
              const SizedBox(height: 15),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                )
              else if (availableDates.isEmpty)
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
                    itemCount: availableDates.length,
                    itemBuilder: (context, index) {
                      final date = availableDates[index];
                      final selected = selectedDayIndex == index;
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
                  itemCount: filteredSlots.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final slot = filteredSlots[index];
                    final selected = selectedSlotIndex == index;
                    final isAvailable = slot['isAvailable'] == true;
                    return GestureDetector(
                      onTap: (isAvailable && selectedDayIndex != null) ? () => _selectSlot(index) : null,
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
              const SizedBox(height: 30),
              const Text('Motif du rendez-vous', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: motifController,
                  onChanged: (_) => setState(() {}),
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
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Créer un rendez-vous', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedDayIndex != null && selectedSlotIndex != null && motifController.text.trim().isNotEmpty ? primary : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: selectedDayIndex != null && selectedSlotIndex != null && motifController.text.trim().isNotEmpty
                      ? () async {
                          final dateValue = availableDates[selectedDayIndex!]['value'] ?? '';
                          final slot = filteredSlots[selectedSlotIndex!];
                          final motif = motifController.text.trim();

                          if (selectedPedagogiqueId == null || dateValue.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez sélectionner un pédagogique et une date valides.')),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          final result = await creationrdv(
                            idParent,
                            selectedPedagogiqueId!,
                            dateValue,
                            motif,
                            'parent',
                            slot['start']!,
                            slot['end']!,
                            slot['disponibiliteId'] ?? slot['iddisponibilites'] ?? slot['id'] ?? 0,
                            slot['intervalId'] ?? slot['id'] ?? 0,
                          );

                          if (!mounted) return;

                          if (result == 200 || result == 201) {
                            messenger.showSnackBar(const SnackBar(content: Text('Rendez-vous créé avec succès.')));
                            setState(() {
                              selectedDayIndex = null;
                              selectedSlotIndex = null;
                              motifController.clear();
                              filteredSlots.clear();
                            });
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RendezVousPage()));
                          } else {
                            messenger.showSnackBar(SnackBar(content: Text('Échec de la création du rendez-vous. Code: $result')));
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
