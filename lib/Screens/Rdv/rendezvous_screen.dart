import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/Screens/DashboardPage.dart';
import 'package:test/Screens/Enseignant/ClasseEnseignant.dart';
import 'package:test/Screens/Enseignant/disponibilite_configuration_screen.dart';
import 'package:test/Screens/Widgets/appointment_card.dart';
import 'package:test/Screens/Rdv/creationRDV.dart';
import 'package:test/providers/EnseignantProvider.dart';
import 'package:test/providers/Rdv_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RendezVousPage extends StatefulWidget {
  final bool isTeacher;

  const RendezVousPage({super.key, this.isTeacher = false});

  @override
  State<RendezVousPage> createState() => _RendezVousPageState();
}

class _RendezVousPageState extends State<RendezVousPage> {
  List<Map<String, dynamic>> _rdvs = [];
  bool _isLoading = false;
  String _selectedFilter = 'Tous';
  final TextEditingController _pvController = TextEditingController();
  static const List<String> _statusFilters = [
    'Tous',
    'En attente',
    'Acceptés',
    'Rejetés',
  ];

  String _selectedType = 'Mes rendez-vous';
  static const List<String> _typeFilters = [
    'Mes rendez-vous',
    'Rendez-vous reçus',
  ];

  bool get _isTeacher => widget.isTeacher;

  bool _matchesFilter(Map<String, dynamic> rdv) {
    if (_selectedFilter == 'Tous') return true;
    final status = (rdv['statuts'] ?? rdv['status'] ?? '').toString();
    return _statusLabel(status) == _selectedFilter;
  }

  @override
  void initState() {
    super.initState();
    _fetchRdv();
  }

  @override
  void dispose() {
    _pvController.dispose();
    super.dispose();
  }

  Future<void> _fetchRdv() async {
    setState(() {
      _isLoading = true;
    });

    final rdvProvider = Provider.of<RdvProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final int currentUserId = prefs.getInt('idPersonne') ?? 0;

    final int idTeacher = prefs.getInt('IdteacherInfo') ??0;
    debugPrint('Current user ID: $currentUserId, Teacher ID: $idTeacher');

    final bool showReceived = _selectedType == 'Rendez-vous reçus';
    final List<Map<String, dynamic>> rdvs = _isTeacher
        ? (showReceived
            ? await rdvProvider.getTeacherRDV2(idTeacher)
            : await rdvProvider.getTeacherRDV(idTeacher))
        : (showReceived
            ? await rdvProvider.getParentRDV2(currentUserId)
            : await rdvProvider.getParentRDV(currentUserId));

    if (mounted) {
      setState(() {
        final sortedRdvs = List<Map<String, dynamic>>.from(rdvs);
        sortedRdvs.sort((a, b) {
          int parseId(dynamic value) {
            if (value is int) return value;
            if (value is String) return int.tryParse(value) ?? 0;
            if (value is num) return value.toInt();
            return 0;
          }

          final aId = parseId(a['id']);
          final bId = parseId(b['id']);
          return bId.compareTo(aId);
        });
        _rdvs = sortedRdvs;
        _isLoading = false;
      });
    }
  }

  String _formatDuration(String start, String end) {
    start = start.trim();
    end = end.trim();

    if (start.isEmpty || end.isEmpty) {
      return '30 min';
    }

    final startTime = DateTime.tryParse('2024-01-01 $start');
    final endTime = DateTime.tryParse('2024-01-01 $end');

    if (startTime == null || endTime == null) {
      return '30 min';
    }

    final duration = endTime.difference(startTime).inMinutes;
    return duration > 0 ? '$duration min' : '30 min';
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (value.contains('accept') || value.contains('accepte')) {
      return Colors.green;
    }
    if (value.contains('refus') || value.contains('rej')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  String _statusLabel(String status) {
    final value = status.toLowerCase();
    if (value.contains('accept') || value.contains('accepte')) {
      return 'Acceptés';
    }
    if (value.contains('refus') || value.contains('rej')) {
      return 'Rejetés';
    }
    return 'En attente';
  }

  bool _isPendingStatus(String status) {
    return _statusLabel(status) == 'En attente';
  }

  String _contactName(Map<String, dynamic> rdv) {
    final teacherName =
        ('${rdv['nomEnseignant'] ?? rdv['enseignant'] ?? ''}'
                ' ${rdv['prenomEnseignant'] ?? ''}')
            .trim();
    final parentName =
        ('${rdv['nomParent'] ?? rdv['parent'] ?? ''}'
                ' ${rdv['prenomParent'] ?? ''}')
            .trim();

    if (_isTeacher) {
      return parentName.isEmpty ? 'Parent' : parentName;
    }

    return teacherName.isEmpty ? 'Enseignant' : teacherName;
  }

  void _openNewRdvFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _isTeacher ? const ClasseEnseignant() : const ChooseContactScreen(),
      ),
    );
  }

  void _openDisponibiliteConfiguration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClasseEnseignant(),
      ),
    );
  }

  Future<void> _showRdvDetails(BuildContext context, Map<String, dynamic> rdv) async {
    final status = (rdv['statuts'] ?? rdv['status'] ?? '').toString();
    final contactName = _contactName(rdv);
    final subject = (rdv['nomMatiere'] ?? rdv['matiere'] ?? rdv['sujet'] ?? '')
        .toString();
    final date = (rdv['date'] ?? '').toString().trim();
    final heureDebut = (rdv['heureDebut'] ?? '').toString().trim();
    final heureFin = (rdv['heureFin'] ?? '').toString().trim();
    final motif = (rdv['motif'] ?? '').toString().trim();
    final eleveName = ('${rdv['prenomEleve'] ?? ''} ${rdv['nomEleve'] ?? ''}')
        .trim();
    final classe = (rdv['classeEleve'] ?? '').toString().trim();
    final eleveLine = eleveName.isEmpty
        ? 'Élève non renseigné'
        : '$eleveName${classe.isEmpty ? '' : ' • $classe'}';
    final time = heureDebut.isEmpty && heureFin.isEmpty
        ? 'Heure à confirmer'
        : '$heureDebut - $heureFin';
    final bool shouldShowPvSection = _isTeacher && _statusLabel(status) == 'Acceptés';
    final String initialPv = (rdv['commentaire'] ?? rdv['pv'] ?? rdv['note'] ?? '')
        .toString();

    final int rdvId = rdv['id'] ?? rdv['idRdv'] ?? 0;
    final int enseignantId =
        rdv['idEnseignant'] ?? rdv['idenseignant'] ?? 0;
    final Map<String, dynamic>? pvData = await context.read<EnseignantProvider>().getPv(
          rdvId,
          enseignantId,
        );

    if (pvData != null) {
      _pvController.text = pvData['message']?.toString() ?? '';
    } else if (_pvController.text != initialPv) {
      _pvController.text = initialPv;
    }

    _pvController.selection = TextSelection.fromPosition(
      TextPosition(offset: _pvController.text.length),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        final bottomInset = MediaQuery.of(bottomSheetContext).viewInsets.bottom;
        final screenHeight = MediaQuery.of(bottomSheetContext).size.height;
        final maxHeight = (screenHeight - bottomInset) * 0.9;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: const Text(
                          'Détail du rendez-vous',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _statusColor(status).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _statusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(
                              color: _statusColor(status).withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _detailRow(
                    icon: Icons.person,
                    title: 'Contact',
                    value: subject.isEmpty
                        ? contactName
                        : '$contactName • $subject',
                  ),
                  const SizedBox(height: 14),
                  _detailRow(
                    icon: Icons.calendar_today,
                    title: 'Date',
                    value: date.isEmpty ? 'Date à confirmer' : date,
                  ),
                  const SizedBox(height: 14),
                  _detailRow(
                    icon: Icons.access_time,
                    title: 'Créneau',
                    value: time,
                  ),
                  const SizedBox(height: 14),
                  _detailRow(icon: Icons.school, title: 'Élève', value: eleveLine),
                  if (motif.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _detailRow(
                      icon: Icons.notes,
                      title: 'Motif',
                      value: motif,
                      valueStyle: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (shouldShowPvSection) ...[
                    Text(
                      'PV du rendez-vous',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff253858),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pvController,
                      maxLines: 4,
                      minLines: 3,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: 'Ajouter un PV',
                        hintText: 'Renseignez les remarques ou observations...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xff1F4B8F), width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.description_outlined, color: Color(0xff1F4B8F)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Builder(builder: (context) {
                      final bool alreadyExists = pvData != null;
                      final int existingPvId = alreadyExists
                          ? (pvData!['id'] ?? pvData!['idPv'] ?? pvData!['id_pv'] ?? 0)
                          : 0;
                      final String buttonLabel =
                          alreadyExists ? 'Mettre à jour le PV' : 'Enregistrer le PV';

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _pvController.text.trim().isNotEmpty
                              ? () async {
                                  rdv['commentaire'] = _pvController.text.trim();
                                  rdv['pv'] = _pvController.text.trim();

                                  if (alreadyExists && existingPvId != 0) {
                                    await context.read<EnseignantProvider>().UpdatePv(
                                          existingPvId,
                                          _pvController.text.trim(),
                                        );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('PV mis à jour avec succès'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                    return;
                                  }

                                  await context.read<EnseignantProvider>().createPv(
                                        rdv['id'] ?? rdv['idRdv'],
                                        _pvController.text.trim(),
                                        rdv['idEnseignant'] ?? rdv['idenseignant'] ?? 0,
                                      );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('PV créé avec succès'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1F4B8F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded),
                          label: Text(buttonLabel),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xff1F4B8F)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    valueStyle ??
                    const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff253858),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Color primary = const Color(0xff1F4B8F);
    final actionLabel = _isTeacher
        ? 'Créer un rendez-vous'
        : 'Demander un rendez-vous';

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
     floatingActionButton: _isTeacher
    ? Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff1F4B8F), Color(0xff3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisponibiliteConfigurationScreen(isPedagogique: false),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      )
    : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DashboardPage(isTeacher: _isTeacher),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.notifications_none, color: primary),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: primary,
                        child: ClipOval(
                          child: Image.asset(
                            'lib/images/logoise.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Center(
                                child: Icon(Icons.image_outlined),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Mes Rendez-vous",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff253858),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (!_isTeacher)
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: primary.withOpacity(.3), blurRadius: 10),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: _openNewRdvFlow,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.add, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Text(
                            actionLabel,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              if (_isTeacher)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openDisponibiliteConfiguration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text(
                      'Demander un rendez-vous',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

              if (_isTeacher) const SizedBox(height: 15),

              /// STATS
              Row(
                children: [
                  Expanded(
                    child: statusCard(
                      _rdvs
                          .where((rdv) {
                            final status =
                                (rdv['statuts'] ?? rdv['status'] ?? '')
                                    .toString();
                            return _statusLabel(status) == 'En attente';
                          })
                          .length
                          .toString(),
                      "En attente",
                      Colors.orange.shade200,
                      Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: statusCard(
                      _rdvs
                          .where((rdv) {
                            final status =
                                (rdv['statuts'] ?? rdv['status'] ?? '')
                                    .toString();
                            return _statusLabel(status) == 'Acceptés';
                          })
                          .length
                          .toString(),
                      "Acceptés",
                      Colors.green.shade200,
                      Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: statusCard(
                      _rdvs
                          .where((rdv) {
                            final status =
                                (rdv['statuts'] ?? rdv['status'] ?? '')
                                    .toString();
                            return _statusLabel(status) == 'Rejetés';
                          })
                          .length
                          .toString(),
                      "Rejetés",
                      Colors.red.shade200,
                      Colors.red.shade800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              /// TYPE SEGMENTED CONTROL
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: _typeFilters.map((type) {
                    final bool selected = _selectedType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedType == type) return;
                          setState(() {
                            _selectedType = type;
                          });
                          _fetchRdv();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? primary : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              type,
                              style: TextStyle(
                                color: selected ? Colors.white : primary,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 15),

              /// FILTERS
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: _statusFilters.map((filter) {
                    final bool selected = _selectedFilter == filter;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? primary : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: selected ? Colors.white : primary,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _rdvs.where(_matchesFilter).isEmpty
                    ? const Center(
                        child: Text("Aucun rendez-vous pour le moment"),
                      )
                    : ListView.builder(
                        itemCount: _rdvs.where(_matchesFilter).length,
                        itemBuilder: (context, index) {
                          final filteredRdvs = _rdvs
                              .where(_matchesFilter)
                              .toList();
                          final rdv = filteredRdvs[index];
                          final date = (rdv['date'] ?? '').toString().trim();
                          final heureDebut = (rdv['heureDebut'] ?? '')
                              .toString()
                              .trim();
                          final heureFin = (rdv['heureFin'] ?? '')
                              .toString()
                              .trim();
                          final status = (rdv['statuts'] ?? rdv['status'] ?? '')
                              .toString();
                          final contactName = _contactName(rdv);
                          final subject =
                              (rdv['nomMatiere'] ??
                                      rdv['matiere'] ??
                                      rdv['sujet'] ??
                                      rdv['motif'] ??
                                      'Rendez-vous')
                                  .toString();
                          final duration = _formatDuration(
                            heureDebut,
                            heureFin,
                          );
                          final time = heureDebut.isEmpty && heureFin.isEmpty
                              ? 'Heure à confirmer'
                              : '$heureDebut - $heureFin';
                          final bool showActions =
                              _selectedType == 'Rendez-vous reçus' &&
                              _isPendingStatus(status);
                          final rdvProvider = Provider.of<RdvProvider>(
                            context,
                            listen: false,
                          );

                          return AppointmentCard(
                            tutorName: contactName,
                            subject: subject,
                            duration: duration,
                            date: date.isEmpty ? 'Date à confirmer' : date,
                            time: time,
                            scolor: _statusColor(status),
                            state: _statusLabel(status),
                            onTap: () => _showRdvDetails(context, rdv),
                            onAccept: showActions
                                ? () async {
                                    final rdvId = rdv['id'] ?? rdv['idRdv'];
                                    await rdvProvider.acceptTeacherRDV(rdvId);
                                    await _fetchRdv();
                                  }
                                : null,
                            onReject: showActions
                                ? () async {
                                    final rdvId = rdv['id'] ?? rdv['idRdv'];
                                    await rdvProvider.rejectTeacherRDV(rdvId);
                                    await _fetchRdv();
                                  }
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget statusCard(String count, String title, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bg.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            count,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget appointmentCard({
    required String name,
    required String subject,
    required String date,
    required String hour,
    required String status,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: const Icon(Icons.person_outline),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(subject, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status, style: TextStyle(color: color)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(date),
              const SizedBox(width: 20),
              Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(hour),
            ],
          ),
        ],
      ),
    );
  }
}
