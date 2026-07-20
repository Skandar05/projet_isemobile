import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/Screens/DashboardPage.dart';
import 'package:test/Screens/Enseignant/disponibilite_configuration_screen.dart';
import 'package:test/Screens/Widgets/appointment_card.dart';
import 'package:test/providers/Pd_Providers.dart';

String resolveRdvStatusLabel(Object? status) {
  final value = status?.toString().toLowerCase() ?? '';
  if (value.contains('accept') || value.contains('accepte')) {
    return 'Acceptés';
  }
  if (value.contains('refus') || value.contains('rej')) {
    return 'Rejetés';
  }
  return 'En attente';
}

Color resolveRdvStatusColor(Object? status) {
  final value = status?.toString().toLowerCase() ?? '';
  if (value.contains('accept') || value.contains('accepte')) {
    return Colors.green;
  }
  if (value.contains('refus') || value.contains('rej')) {
    return Colors.red;
  }
  return Colors.orange;
}

List<Map<String, dynamic>> normalizeRdvs(dynamic value) {
  if (value is! List) {
    return <Map<String, dynamic>>[];
  }

  return value.map<Map<String, dynamic>>((item) {
    if (item is Map<String, dynamic>) {
      return item;
    }
    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }
    return <String, dynamic>{};
  }).toList();
}

List<Map<String, dynamic>> filterRdvsByStatus(
  List<Map<String, dynamic>> rdvs,
  String selectedFilter,
) {
  if (selectedFilter == 'Tous') {
    return rdvs;
  }

  return rdvs.where((rdv) {
    final status = resolveRdvStatusLabel(rdv['statuts'] ?? rdv['status'] ?? '');
    return status == selectedFilter;
  }).toList();
}

Map<String, int> buildStatusCounts(List<Map<String, dynamic>> rdvs) {
  final counts = {'En attente': 0, 'Acceptés': 0, 'Rejetés': 0};

  for (final rdv in rdvs) {
    final status = resolveRdvStatusLabel(rdv['statuts'] ?? rdv['status'] ?? '');
    if (counts.containsKey(status)) {
      counts[status] = counts[status]! + 1;
    }
  }

  return counts;
}

class Pd_rendezvous_screen extends StatefulWidget {
  const Pd_rendezvous_screen({super.key});

  @override
  State<Pd_rendezvous_screen> createState() => _Pd_rendezvous_screenState();
}

class _Pd_rendezvous_screenState extends State<Pd_rendezvous_screen> {
  final List<Map<String, dynamic>> _rdvs = [];
  final Map<String, List<Map<String, dynamic>>> _rdvsByRole = {
    'pedagogiques': <Map<String, dynamic>>[],
    'parent': <Map<String, dynamic>>[],
    'enseignant': <Map<String, dynamic>>[],
  };
  bool _isLoading = false;
  bool isPedagogique = true;
  String _isselected = 'pedagogiques';
  String _selectedFilter = 'Tous';
  final List<String> _statusFilters = ['Tous', 'En attente', 'Acceptés', 'Rejetés'];


  Map<String, String> rdvCounts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllRoleData());
    loadCounts();
  }

Future<void> loadCounts() async {
  final Map<String, String> counts = await PdProvider().getPvCount();

  setState(() {
    rdvCounts = counts;
  });
}


  Future<void> _loadAllRoleData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      late final PdProvider pdProvider;
      try {
        pdProvider = context.read<PdProvider>();
      } catch (_) {
        pdProvider = PdProvider();
      }

      final roles = ['pedagogiques', 'parent', 'enseignant'];
      final results = await Future.wait(roles.map((role) async {
        final rdvs = await pdProvider.getAllRdv(role);
        return MapEntry(role, normalizeRdvs(rdvs));
      }));

      if (!mounted) return;

      final roleData = <String, List<Map<String, dynamic>>>{};
      for (final entry in results) {
        roleData[entry.key] = entry.value;
      }

      setState(() {
        _rdvsByRole.clear();
        _rdvsByRole.addAll(roleData);

        _rdvs.clear();
        _rdvs.addAll(_rdvsByRole[_isselected] ?? <Map<String, dynamic>>[]);
      });
    } catch (e) {
      debugPrint('Error loading rendezvous by role: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchRdvs([String? role]) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      late final PdProvider pdProvider;
      try {
        pdProvider = context.read<PdProvider>();
      } catch (_) {
        pdProvider = PdProvider();
      }

      final selectedRole = role ?? _isselected;
      final rdvs = await pdProvider.getAllRdv(selectedRole);

      if (!mounted) return;

      final normalizedRdvs = normalizeRdvs(rdvs);

      setState(() {
        _rdvsByRole[selectedRole] = normalizedRdvs;

        if (_isselected == selectedRole) {
          _rdvs.clear();
          _rdvs.addAll(normalizedRdvs);
        }
      });
    } catch (e) {
      debugPrint('Error fetching rendezvous: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    return resolveRdvStatusColor(status);
  }

  String _statusLabel(String status) {
    return resolveRdvStatusLabel(status);
  }

  bool _matchesFilter(Map<String, dynamic> rdv) {
    final status = resolveRdvStatusLabel(rdv['statuts'] ?? rdv['status'] ?? '');
    return _selectedFilter == 'Tous' || status == _selectedFilter;
  }

  List<Map<String, dynamic>> _visibleRdvsForCurrentSelection() {
    return _filteredRdvs;
  }

  List<Map<String, dynamic>> get _filteredRdvs {
    return filterRdvsByStatus(_rdvs, _selectedFilter);
  }

  int _countByStatus(String targetStatus, {String? role}) {
    final source = role == null ? _rdvs : (_rdvsByRole[role] ?? <Map<String, dynamic>>[]);
    return source.where((item) {
      final status = resolveRdvStatusLabel(item['statuts'] ?? item['status'] ?? '');
      return status == targetStatus;
    }).length;
  }

  int _roleCount(String role) {
    return (_rdvsByRole[role] ?? <Map<String, dynamic>>[]).length;
  }

  String _extractText(Map<String, dynamic> rdv, List<String> keys) {
    for (final key in keys) {
      final value = rdv[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  String _contactName(Map<String, dynamic> rdv) {
    final firstName = _extractText(rdv, ['prenomContact', 'prenom', 'prenomDemandeur', 'firstName']);
    final lastName = _extractText(rdv, ['nomContact', 'nom', 'nomDemandeur', 'lastName']);
    final displayName = [firstName, lastName].where((value) => value.isNotEmpty).join(' ').trim();
    return displayName.isEmpty ? 'Nom non renseigné' : displayName;
  }

  void _showRdvDetails(BuildContext context, Map<String, dynamic> rdv) {
    final status = (rdv['statuts'] ?? rdv['status'] ?? '').toString();
    final contactName = _contactName(rdv);
    final subject = _extractText(rdv, ['nomMatiere', 'matiere', 'sujet', 'motif', 'objet', 'titre']);
    final date = (rdv['date'] ?? '').toString().trim();
    final heureDebut = (rdv['heureDebut'] ?? '').toString().trim();
    final heureFin = (rdv['heureFin'] ?? '').toString().trim();
    final motif = (rdv['motif'] ?? '').toString().trim();
    final eleveName = ('${rdv['prenomEleve'] ?? ''} ${rdv['nomEleve'] ?? ''}').trim();
    final classe = (rdv['classeEleve'] ?? '').toString().trim();
    final eleveLine = eleveName.isEmpty
        ? 'Élève non renseigné'
        : '$eleveName${classe.isEmpty ? '' : ' • $classe'}';
    final time = heureDebut.isEmpty && heureFin.isEmpty
        ? 'Heure à confirmer'
        : '$heureDebut - $heureFin';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Détail du rendez-vous',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _detailRow(
                icon: Icons.person,
                title: 'Contact',
                value: subject.isEmpty ? contactName : '$contactName • $subject',
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
            ],
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
                style: valueStyle ??
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
    final primary = const Color(0xff1F4B8F);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActionsSheet(context),
        backgroundColor: const Color(0xff1F4B8F),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardPage(isPedagogique: true),
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
                  'Gategorie des rendez-vous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff253858),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: categoryCard(
                      count: rdvCounts['pedagogique'] ?? rdvCounts['pedagogiques'] ?? '0',
                      title: 'Pédagogiques',
                      icon: Icons.school,
                      background: const Color(0xffF3F7FF),
                      iconBackground: const Color(0xffDCEBFF),
                      color: const Color(0xff377DFF),
                      ontap: () {
                        setState(() {
                          _isselected = 'pedagogiques';
                          _rdvs.clear();
                          _rdvs.addAll(_rdvsByRole['pedagogiques'] ?? <Map<String, dynamic>>[]);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: categoryCard(
                      count: rdvCounts['parent'] ?? '0',
                      title: 'Parents',
                      icon: Icons.people,
                      background: const Color(0xffFAF5FF),
                      iconBackground: const Color(0xffEAD9FF),
                      color: const Color(0xff7B4FD6),
                      ontap: () {
                        setState(() {
                          _isselected = 'parent';
                          _rdvs.clear();
                          _rdvs.addAll(_rdvsByRole['parent'] ?? <Map<String, dynamic>>[]);
                        });
                        if ((_rdvsByRole['parent'] ?? <Map<String, dynamic>>[]).isEmpty) {
                          _fetchRdvs('parent');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: categoryCard(
                      count: rdvCounts['enseignant'] ?? '0',
                      title: 'Enseignants',
                      icon: Icons.co_present,
                      background: const Color(0xffF2FCF8),
                      iconBackground: const Color(0xffD7F5E8),
                      color: const Color(0xff35B88A),
                      ontap: () {
                        setState(() {
                          _isselected = 'enseignant';
                          _rdvs.clear();
                          _rdvs.addAll(_rdvsByRole['enseignant'] ?? <Map<String, dynamic>>[]);
                        });
                        if ((_rdvsByRole['enseignant'] ?? <Map<String, dynamic>>[]).isEmpty) {
                          _fetchRdvs('enseignant');
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Statut des rendez-vous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff253858),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: statusCard(
                      _countByStatus('En attente', role: _isselected).toString(),
                      'En attente',
                      Colors.orange.shade800,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: statusCard(
                      _countByStatus('Acceptés', role: _isselected).toString(),
                      'Acceptés',
                      Colors.green.shade800,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: statusCard(
                      _countByStatus('Rejetés', role: _isselected).toString(),
                      'Rejetés',
                      Colors.red.shade800,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: _statusFilters.map((filter) {
                    final selected = _selectedFilter == filter;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
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
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
                    : _visibleRdvsForCurrentSelection().isEmpty
                        ? const Center(child: Text('Aucun rendez-vous pour le moment'))
                        : ListView.builder(
                            itemCount: _visibleRdvsForCurrentSelection().length,
                            itemBuilder: (context, index) {
                              final rdv = _visibleRdvsForCurrentSelection()[index];
                              final date = (rdv['date'] ?? '').toString().trim();
                              final heureDebut = (rdv['heureDebut'] ?? '').toString().trim();
                              final heureFin = (rdv['heureFin'] ?? '').toString().trim();
                              final status = (rdv['statuts'] ?? rdv['status'] ?? '').toString();
                              final contactName = _contactName(rdv);
                              final subject = _extractText(rdv, ['nomMatiere', 'matiere', 'sujet', 'motif', 'objet', 'titre']);
                              final duration = _formatDuration(heureDebut, heureFin);
                              final time = heureDebut.isEmpty && heureFin.isEmpty
                                  ? 'Heure à confirmer'
                                  : '$heureDebut - $heureFin';

                              return AppointmentCard(
                                tutorName: contactName,
                                subject: subject.isEmpty ? 'Rendez-vous' : subject,
                                duration: duration,
                                date: date.isEmpty ? 'Date à confirmer' : date,
                                time: time,
                                scolor: _statusColor(status),
                                state: _statusLabel(status),
                                onTap: () => _showRdvDetails(context, rdv),
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

  Future<void> _showQuickActionsSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Que souhaitez-vous faire ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xff1F4B8F)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Creation d\'un rendez-vous',
                    style: TextStyle(color: Color(0xff1F4B8F)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DisponibiliteConfigurationScreen(isPedagogique: true),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xff1F4B8F)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Configuration disponibilités',
                    style: TextStyle(color: Color(0xff1F4B8F)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget statusCard(String count, String title, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bg.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
}

Widget categoryCard({
  required String count,
  required String title,
  required IconData icon,
  required Color background,
  required Color iconBackground,
  required Color color,
  required VoidCallback? ontap,
}) {
  return InkWell(
    onTap: ontap,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      height: 160,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xff222222),
            ),
          ),
        ],
      ),
    ),
  );
}