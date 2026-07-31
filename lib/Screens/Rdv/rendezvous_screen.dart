import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/Screens/DashboardPage.dart';
import 'package:test/Screens/Enseignant/ClasseEnseignant.dart';
import 'package:test/Screens/Enseignant/disponibilite_configuration_screen.dart';
import 'package:test/Screens/Enseignant/home_Enseignant.dart';
import 'package:test/Screens/Widgets/appointment_card.dart';
import 'package:test/Screens/Rdv/creationRDV.dart';
import 'package:test/Screens/Widgets/custom_app_bar.dart';
import 'package:test/Screens/parent/RdvType.dart';
import 'package:test/Screens/parent/home_Parent.dart';
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
  final TextEditingController _pvController = TextEditingController();

  bool get _isTeacher => widget.isTeacher;

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


    final List<Map<String, dynamic>> rdvs = _isTeacher
        ? (
             await rdvProvider.getTeacherRDV(idTeacher))
        : ( 
             await rdvProvider.getParentRDV(currentUserId)
            
            );

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

  String _extractText(Map<String, dynamic> rdv, List<String> keys) {
    for (final key in keys) {
      final value = rdv[key];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      } else if (value is num) {
        return value.toString();
      } else if (value != null) {
        final trimmed = value.toString().trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }
    return '';
  }

  String _resolveTeacherOrPedagogiqueName(Map<String, dynamic> rdv) {
    final teacherFirst = _extractText(rdv, ['enseignantPrenomfr', 'prenomEnseignant', 'prenom']);
    final teacherLast = _extractText(rdv, ['enseignantNomfr', 'nomEnseignant', 'nom', 'enseignant']);
    final teacherFull = ('$teacherLast $teacherFirst').trim();

    final pedagogiqueFirst = _extractText(rdv, ['pedagogiquePrenomfr', 'prenomPedagogique', 'prenom']);
    final pedagogiqueLast = _extractText(rdv, ['pedagogiqueNomfr', 'nomPedagogique', 'nom']);
    final pedagogiqueFull = ('$pedagogiqueLast $pedagogiqueFirst').trim();

    if (teacherFull.isNotEmpty) {
      return teacherFull;
    }

    return pedagogiqueFull.isNotEmpty ? pedagogiqueFull : teacherFull;
  }

  String _contactName(Map<String, dynamic> rdv) {
    final teacherName =
        ('${rdv['enseignantNomfr'] ?? rdv['nomEnseignant'] ?? rdv['enseignant'] ?? ''}'
                ' ${rdv['enseignantPrenomfr'] ?? rdv['prenomEnseignant'] ?? ''}')
            .trim();
    final parentName =
        ('${rdv['parentNomfr'] ?? rdv['nomParent'] ?? rdv['parent'] ?? ''}'
                ' ${rdv['parentPrenomfr'] ?? rdv['prenomParent'] ?? ''}')
            .trim();

    if (_isTeacher) {
      return parentName.isEmpty ? 'Parent' : parentName;
    }

    final resolvedTeacherName = _resolveTeacherOrPedagogiqueName(rdv);
    return resolvedTeacherName.isEmpty ? 'Enseignant' : resolvedTeacherName;
  }

  String _senderName(Map<String, dynamic> rdv) {
    final demandeurRole = (rdv['demandeur_role'] ?? '').toString().toLowerCase();
    
    if (demandeurRole.contains('parent')) {
      // Parent initiated: sender is parent
      final first = _extractText(rdv, ['parentPrenomfr', 'parentPrenom', 'prenomParent', 'prenom']);
      final last = _extractText(rdv, ['parentNomfr', 'parentNom', 'nomParent', 'nom', 'nom_parent']);
      final full = ('$last $first').trim();
      if (full.isNotEmpty) return full;
      return _extractText(rdv, ['nomParent', 'parent', 'nom_parent', 'contactName', 'nom_contact', 'nomContact']);
    } else if (demandeurRole.contains('pedagogique')) {
      // Parent initiated: sender is parent
      final first = _extractText(rdv, ['pedagogiquePrenomfr']);
      final last = _extractText(rdv, ['pedagogiqueNomfr']);
      final full = ('$last $first').trim();
      if (full.isNotEmpty) return full;
      return _extractText(rdv, ['pedagogiquePrenomfr', 'pedagogiqueNomfr']);
    } else {
      // Teacher initiated: sender is teacher
      final first = _extractText(rdv, ['enseignantPrenomfr', 'prenomEnseignant', 'prenom']);
      final last = _extractText(rdv, ['enseignantNomfr', 'nomEnseignant', 'nom', 'enseignant']);
      final full = ('$last $first').trim();
      if (full.isNotEmpty) return full;
      return _extractText(rdv, ['nomEnseignant', 'enseignant']);
    }
  }

  String _receiverName(Map<String, dynamic> rdv) {
    final demandeurRole = (rdv['demandeur_role'] ?? '').toString().toLowerCase();
    
    if (demandeurRole.contains('parent')) {
      // Parent initiated: receiver is teacher or pedagogique
      final resolvedName = _resolveTeacherOrPedagogiqueName(rdv);
      if (resolvedName.isNotEmpty) return resolvedName;
      return _extractText(rdv, ['nomEnseignant', 'enseignant']);
    } else if (demandeurRole.contains('pedagogique')) {
      final first = _extractText(rdv, ['pedagogiquePrenomfr']);
      final last = _extractText(rdv, ['pedagogiqueNomfr']);
      final full = ('$last $first').trim();
      if (full.isNotEmpty) return full;
      return _extractText(rdv, ['pedagogiquePrenomfr', 'pedagogiqueNomfr']);
    }else {
      // Teacher initiated: receiver is parent
      final first = _extractText(rdv, ['parentPrenomfr', 'parentPrenom', 'prenomParent', 'prenom']);
      final last = _extractText(rdv, ['parentNomfr', 'parentNom', 'nomParent', 'nom', 'nom_parent']);
      final full = ('$last $first').trim();
      if (full.isNotEmpty) return full;
      return _extractText(rdv, ['nomParent', 'parent', 'nom_parent', 'contactName', 'nom_contact', 'nomContact']);
    }
  }

  bool _canPerformAction(Map<String, dynamic> rdv) {
    final demandeurRole = (rdv['demandeur_role'] ?? '').toString().toLowerCase();
    final status = _statusLabel((rdv['statuts'] ?? rdv['status'] ?? '').toString());
    
    // Only non-initiator can accept/reject pending requests
    if (status != 'En attente') return false;
    
    if (_isTeacher) {
      // Teacher can act on parent-initiated requests
      return demandeurRole.contains('parent');
    } else {
      // Parent can act on teacher-initiated requests
      return demandeurRole.contains('teacher') || demandeurRole.contains('enseignant');
    }
  }

  void _openNewRdvFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _isTeacher ? const ClasseEnseignant() : const RdvType(),
      ),
    );
  }

  void _openDisponibiliteConfiguration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DisponibiliteConfigurationScreen(isPedagogique: false),
      ),
    );
  }

  Future<void> _showRdvDetails(BuildContext context, Map<String, dynamic> rdv) async {
    final status = (rdv['statuts'] ?? rdv['status'] ?? '').toString();
    final contactName = _contactName(rdv);
    final senderName = _senderName(rdv);
    final receiverName = _receiverName(rdv);
    final subject = (rdv['nomMatiere'] ?? rdv['matiere'] ?? rdv['sujet'] ?? '')
        .toString();
    final date = (rdv['date'] ?? '').toString().trim();
    final heureDebut = (rdv['heureDebut'] ?? '').toString().trim();
    final heureFin = (rdv['heureFin'] ?? '').toString().trim();
    final motif = (rdv['motif'] ?? '').toString().trim();
    final eleveName = ('${rdv['elevePrenomfr'] ?? rdv['prenomEleve'] ?? rdv['prenomEleve'] ?? ''} ${rdv['eleveNomfr'] ?? rdv['nomEleve'] ?? rdv['nomEleve'] ?? ''}')
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
            child: StatefulBuilder(
              builder: (modalContext, modalSetState) {
                return SingleChildScrollView(
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
                        icon: Icons.send,
                        title: 'from',
                        value: senderName.isEmpty ? 'Non renseigné' : senderName,
                      ),
                      const SizedBox(height: 14),
                      _detailRow(
                        icon: Icons.inbox,
                        title: 'to',
                        value: receiverName.isEmpty ? 'Non renseigné' : receiverName,
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
                          onChanged: (_) => modalSetState(() {}),
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
                );
              },
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
  final primary = const Color(0xff1F4B8F);

  final actionLabel = _isTeacher
      ? 'Créer un rendez-vous'
      : 'Demander un rendez-vous';

  return Scaffold(
    backgroundColor: const Color(0xffF5F7FB),

    // ================= APP BAR =================
    appBar: CustomAppBar(
      interfacePage: _isTeacher
          ? const HomeEnseignant()
          : const HomeParent(),

      title: _isTeacher
          ? "Espace Enseignant"
          : "Espace Parent",

      subtitle: _isTeacher
          ? "Gérer vos rendez-vous"
          : "Créer un rendez-vous pédagogique",

      showBackButton: true,
    ),


    // ================= BODY =================
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [

            const SizedBox(height: 15),


            // ============ PARENT BUTTON ============
            if (!_isTeacher)
              Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: _openNewRdvFlow,

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        actionLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    ],
                  ),
                ),
              ),



            // ============ TEACHER BUTTONS ============
            if (_isTeacher) ...[

              const SizedBox(height: 5),

              Row(
                children: [

                  Expanded(
                    child: SizedBox(
                      height: 55,

                      child: ElevatedButton.icon(
                        onPressed: _openNewRdvFlow,

                        icon: const Icon(
                          Icons.send,
                          size: 18,
                        ),

                        label: const Text(
                          "Demander un\nrendez-vous",
                          textAlign: TextAlign.center,
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),


                  const SizedBox(width: 12),


                  Expanded(
                    child: SizedBox(
                      height: 55,

                      child: ElevatedButton.icon(
                        onPressed:
                            _openDisponibiliteConfiguration,

                        icon: const Icon(
                          Icons.calendar_today,
                          size: 18,
                        ),

                        label: const Text(
                          "Mes créneaux",
                          textAlign: TextAlign.center,
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.grey.shade200,

                          foregroundColor: primary,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ],


            const SizedBox(height: 15),



            // ============ LIST ============
            Expanded(
              child: _isLoading

                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )


                  : _rdvs.isEmpty

                      ? const Center(
                          child: Text(
                            "Aucun rendez-vous pour le moment",
                          ),
                        )


                      : ListView.builder(

                          physics:
                              const BouncingScrollPhysics(),

                          itemCount:
                              _rdvs.length,


                          itemBuilder:
                              (context, index) {


                            final rdv =
                                _rdvs[index];


                            final status =
                                (rdv['statuts'] ??
                                        rdv['status'] ??
                                        '')
                                    .toString();



                            final heureDebut =
                                (rdv['heureDebut'] ??
                                        '')
                                    .toString();



                            final heureFin =
                                (rdv['heureFin'] ??
                                        '')
                                    .toString();



                            return AppointmentCard(

                              tutorName:
                                  _contactName(rdv),

                              fromName: _senderName(rdv),
                              toName: _receiverName(rdv),
                              demandeurRole: rdv['demandeur_role'] ?? rdv['demandeurRole'] ?? '',

                              subject:
                                  (rdv['nomMatiere'] ??
                                          rdv['matiere'] ??
                                          rdv['sujet'] ??
                                          "Rendez-vous")
                                      .toString(),

                              duration:
                                  _formatDuration(
                                heureDebut,
                                heureFin,
                              ),

                              date:
                                  (rdv['date'] ??
                                          "Date à confirmer")
                                      .toString(),

                              time:
                                  heureDebut.isEmpty &&
                                          heureFin.isEmpty
                                      ? "Heure à confirmer"
                                      : "$heureDebut - $heureFin",

                              scolor:
                                  _statusColor(status),

                              state:
                                  _statusLabel(status),


                              onTap: () =>
                                  _showRdvDetails(
                                context,
                                rdv,
                              ),


                              onAccept:
                                  _canPerformAction(rdv)
                                      ? () async {

                                          final id =
                                              rdv['id'] ??
                                                  rdv['idRdv'];

                                          await context
                                              .read<RdvProvider>()
                                              .acceptTeacherRDV(
                                                  id);

                                          await _fetchRdv();
                                        }
                                      : null,


                              onReject:
                                  _canPerformAction(rdv)
                                      ? () async {

                                          final id =
                                              rdv['id'] ??
                                                  rdv['idRdv'];

                                          await context
                                              .read<RdvProvider>()
                                              .rejectTeacherRDV(
                                                  id);

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
