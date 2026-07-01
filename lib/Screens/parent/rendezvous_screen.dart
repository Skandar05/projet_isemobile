import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/Screens/DashboardPage.dart';
import 'package:test/Screens/Widgets/appointment_card.dart';
import 'package:test/Screens/parent/creationRDV.dart';
import 'package:test/providers/Rdv_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';



class RendezVousPage extends StatefulWidget {
  const RendezVousPage({super.key});
  @override
  State<RendezVousPage> createState() => _RendezVousPageState();
}
class _RendezVousPageState extends State<RendezVousPage> {
  List<Map<String, dynamic>> _rdvs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRdv();
  }

  Future<void> _fetchRdv() async {
    setState(() {
      _isLoading = true;
    });

    final rdvProvider = Provider.of<RdvProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final int idParent = prefs.getInt('idPersonne') ?? 0;
    final List<Map<String, dynamic>> rdvs = await rdvProvider.getParentRDV(idParent);

    if (mounted) {
      setState(() {
        _rdvs = rdvs;
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
      return 'Accepté';
    }
    if (value.contains('refus') || value.contains('rej')) {
      return 'Refusé';
    }
    return 'En attente';
  }

  void _showRdvDetails(BuildContext context, Map<String, dynamic> rdv) {
    final status = (rdv['statuts'] ?? rdv['status'] ?? '').toString();
    final tutorName = ('${rdv['nomEnseignant'] ?? rdv['enseignant'] ?? ''}'
            ' ${rdv['prenomEnseignant'] ?? ''}')
        .trim();
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                value: tutorName.isEmpty
                    ? 'Enseignant inconnu'
                    : '$tutorName • $subject',
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
              _detailRow(
                icon: Icons.school,
                title: 'Élève',
                value: eleveLine,
              ),
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
                style: valueStyle ?? const TextStyle(
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

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
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
                              builder: (context) => DashboardPage(
                              ),
                            ),
                          ); // go back to previous page
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
                        child: Icon(Icons.notifications_none,
                            color: primary),
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
                                child: Icon(
                                  Icons.image_outlined,
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  )
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

              /// BUTTON
              Container(
                height: 55,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(.3),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChooseContactScreen(),
                    ),
                  );
                },
                child: const Center(
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
                        "Demander un rendez-vous",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              ),
              

              const SizedBox(height: 15),

              /// STATS
              Row(
                children: [
                  Expanded(
                      child: statusCard(
                          _rdvs.where((rdv) {
                            final status = (rdv['statuts'] ?? rdv['status'] ?? '').toString();
                            return _statusLabel(status) == 'En attente';
                          }).length.toString(),
                          "En attente", Colors.orange.shade50,
                          Colors.orange)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: statusCard(
                          _rdvs.where((rdv) {
                            final status = (rdv['statuts'] ?? rdv['status'] ?? '').toString();
                            return _statusLabel(status) == 'Accepté';
                          }).length.toString(),
                          "Acceptés", Colors.green.shade50,
                          Colors.green)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: statusCard(
                          _rdvs.where((rdv) {
                            final status = (rdv['statuts'] ?? rdv['status'] ?? '').toString();
                            return _statusLabel(status) == 'Refusé';
                          }).length.toString(),
                          "Refusés", Colors.red.shade50, Colors.red)),
                ],
              ),

              const SizedBox(height: 15),

              /// FILTERS
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            "Tous",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(child: Text("En attente")),
                    ),
                    const Expanded(
                      child: Center(child: Text("Traités")),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _rdvs.isEmpty
                        ? const Center(
                            child: Text("Aucun rendez-vous pour le moment"),
                          )
                        : ListView.builder(
                            itemCount: _rdvs.length,
                            itemBuilder: (context, index) {
                              final rdv = _rdvs[index];
                              final date = (rdv['date'] ?? '').toString().trim();
                              final heureDebut =
                                  (rdv['heureDebut'] ?? '').toString().trim();
                              final heureFin = (rdv['heureFin'] ?? '').toString().trim();
                              final status =
                                  (rdv['statuts'] ?? rdv['status'] ?? '')
                                      .toString();
                              final tutorName = (
                                      '${rdv['nomEnseignant'] ?? rdv['enseignant'] ?? ''}'
                                      ' ${rdv['prenomEnseignant'] ?? ''}')
                                  .trim();
                              final subject = (rdv['nomMatiere'] ??
                                          rdv['matiere'] ??
                                          rdv['sujet'] ??
                                          rdv['motif'] ??
                                          'Rendez-vous')
                                      .toString();
                              final duration = _formatDuration(heureDebut, heureFin);
                              final time = heureDebut.isEmpty && heureFin.isEmpty
                                  ? 'Heure à confirmer'
                                  : '$heureDebut - $heureFin';

                              return AppointmentCard(
                                tutorName: tutorName.isEmpty
                                    ? 'Enseignant' : tutorName,
                                subject: subject,
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

  Widget statusCard(
      String count, String title, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            title,
            style: TextStyle(color: textColor),
          )
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
                    Text(
                      subject,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: color),
                ),
              )
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
          )
        ],
      ),
    );
  }
}