import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/EnseignantProvider.dart';
import 'package:test/providers/Rdv_provider.dart';
import 'package:test/providers/auth_provider.dart';
import 'package:test/providers/disponibilite_provider.dart';

class DisponibiliteConfigurationScreen extends StatefulWidget {
  const DisponibiliteConfigurationScreen({super.key});

  @override
  State<DisponibiliteConfigurationScreen> createState() =>
      _DisponibiliteConfigurationScreenState();
      
}

class _DisponibiliteConfigurationScreenState
    extends State<DisponibiliteConfigurationScreen> {
  static const List<String> _days = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
  ];

  int? _teacherId;

  @override
  void initState() {
    super.initState();
    _loadTeacherAndDisponibilites();
  }



Future<void> _loadTeacherAndDisponibilites() async {
  final authProvider = context.read<AuthProvider>();
  final personId = authProvider.idE ?? 0;

  if (personId == 0) {
    if (!mounted) return;
    setState(() {
      _teacherId = null;
    });
    return;
  }

  final teacherId = await context.read<EnseignantProvider>().getTeacherinfo(personId);

  debugPrint('Resolved teacher ID: $teacherId');

  if (!mounted) {
    return;
  }

  setState(() {
    _teacherId = teacherId == null || teacherId == 0 ? null : teacherId;
  });

  if (teacherId != null && teacherId != 0) {
    await context.read<DisponibiliteProvider>().loadDisponibilites(teacherId);
  }
}

  String _formatTime(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return const TimeOfDay(hour: 8, minute: 0);
    }

    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _displayDay(Map<String, dynamic> disponibilite) {
    return (disponibilite['jour'] ??
            disponibilite['jourSemaine'] ??
            disponibilite['day'] ??
            'Jour non défini')
        .toString();
  }

String _displayStart(Map<String, dynamic> disponibilite) {
  return (disponibilite['heuredebut'] ??
          disponibilite['heureDebut'] ??
          disponibilite['disponibilite_debut'] ??
          disponibilite['heure_debut'] ??
          disponibilite['startTime'] ??
          '')
      .toString();
}

String _displayEnd(Map<String, dynamic> disponibilite) {
  return (disponibilite['heurefin'] ??
          disponibilite['heureFin'] ??
          disponibilite['disponibilite_fin'] ??
          disponibilite['heure_fin'] ??
          disponibilite['endTime'] ??
          '')
      .toString();
}

  String _buildCardLabel(Map<String, dynamic> disponibilite) {
    final day = _displayDay(disponibilite);
    final start = _displayStart(disponibilite);
    final end = _displayEnd(disponibilite);

    final timePart = start.isNotEmpty && end.isNotEmpty
        ? '$start - $end'
        : 'Horaire à définir';
    return '$day $timePart';
  }

  Future<void> _openDisponibiliteForm({
    Map<String, dynamic>? disponibilite,
  }) async {
    // Vérifier que l'ID enseignant est disponible
    if (_teacherId == null || _teacherId == 0) {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID Enseignant introuvable. Veuillez recharger.'),
            duration: Duration(seconds: 2),
            
          ),
        );
      }
      return;
    }

    
    final provider = context.read<DisponibiliteProvider>();
    String selectedDay = _displayDay(disponibilite ?? <String, dynamic>{});
    final matchedDay = _days.firstWhere(
      (day) => day.toLowerCase() == selectedDay.toLowerCase(),
      orElse: () => _days.first,
    );
    selectedDay = matchedDay;

    TimeOfDay startTime = _parseTime(
      _displayStart(disponibilite ?? <String, dynamic>{}),
    );
    TimeOfDay endTime = _parseTime(
      _displayEnd(disponibilite ?? <String, dynamic>{}),
    );

    final isEditing = disponibilite != null;
    final formKey = GlobalKey<FormState>();
    final startController = TextEditingController(
      text: _displayStart(disponibilite ?? <String, dynamic>{}),
    );
    final endController = TextEditingController(
      text: _displayEnd(disponibilite ?? <String, dynamic>{}),
    );

    String? errorMessage;

await showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (sheetContext) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
            Future<void> pickStartTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: startTime,
                initialEntryMode: TimePickerEntryMode.input, // <-- Clavier
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      alwaysUse24HourFormat: true,
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setSheetState(() {
                  startTime = picked;
                  startController.text = _formatTime(picked);
                });
              }
            }

            Future<void> pickEndTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: startTime,
                initialEntryMode: TimePickerEntryMode.input, // <-- Clavier
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      alwaysUse24HourFormat: true,
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setSheetState(() {
                  endTime = picked;
                  endController.text = _formatTime(picked);
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: SafeArea(
                  top: false,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isEditing
                                ? 'Modifier une disponibilité'
                                : 'Ajouter une disponibilité',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (errorMessage != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          DropdownButtonFormField<String>(
                            value: selectedDay,
                            decoration: const InputDecoration(
                              labelText: 'Jour de la semaine',
                              border: OutlineInputBorder(),
                            ),
                            items: _days
                                .map(
                                  (day) => DropdownMenuItem(
                                    value: day,
                                    child: Text(day),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setSheetState(() {
                                  selectedDay = value;
                                });
                              }
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Choisissez un jour'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: startController,
                            readOnly: true,
                            onTap: pickStartTime,
                            decoration: const InputDecoration(
                              labelText: 'Heure de début',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Choisissez une heure de début'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: endController,
                            readOnly: true,
                            onTap: pickEndTime,
                            decoration: const InputDecoration(
                              labelText: 'Heure de fin',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Choisissez une heure de fin'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                if (_teacherId == null || _teacherId == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('ID Enseignant introuvable.')),
                                  );
                                  return;
                                }

                                final startMinutes =
                                    startTime.hour * 60 + startTime.minute;
                                final endMinutes =
                                    endTime.hour * 60 + endTime.minute;

                                if (endMinutes <= startMinutes) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'L’heure de fin doit être après l’heure de début.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                 final jourExiste = provider.disponibilites.any((d) {
                                    if (isEditing && d['id'] == disponibilite?['id']) {
                                      return false;
                                    }

                                    return (d['jour'] ?? '')
                                            .toString()
                                            .trim()
                                            .toLowerCase() ==
                                        selectedDay.trim().toLowerCase();
                                  });

                                  if (jourExiste) {
                                    setSheetState(() {
                                      errorMessage =
                                          'Une disponibilité est déjà configurée pour $selectedDay.';
                                    });

                                    return;
                                  }

                               final disponibiliteData = {
                                if (isEditing) 'id': disponibilite['id'],
                                'idenseignant': _teacherId,
                                'jour': selectedDay,

                                // IMPORTANT: noms EXACTS API
                                'heuredebut': _formatTime(startTime),
                                'heurefin': _formatTime(endTime),
                              };

                                bool success = false;
                                if (isEditing) {
                                  success = await provider.updateDisponibilite(
                                    _teacherId!,
                                    disponibilite['id'],
                                    disponibiliteData,
                                  );
                                } else {
                                  success = await provider.addDisponibilite(
                                    _teacherId!,
                                    disponibiliteData,
                                  );
                                }

                                if (!context.mounted) return;

                                if (success) {
                                  Navigator.of(sheetContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Disponibilité modifiée.'
                                            : 'Disponibilité ajoutée.',
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(provider.errorMessage ?? 'Erreur lors de l\'opération.'),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(isEditing ? Icons.edit : Icons.add),
                              label: Text(
                                isEditing
                                    ? 'Modifier la disponibilité'
                                    : 'Ajouter une disponibilité',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff1F4B8F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> disponibilite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer la disponibilité'),
          content: const Text(
            'Voulez-vous vraiment supprimer cette disponibilité ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (_teacherId == null || _teacherId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID Enseignant introuvable.')),
        );
        return;
      }
      
      final success = await context.read<DisponibiliteProvider>().deleteDisponibilite(
        _teacherId!,
        disponibilite['id'],
      );

      if (!mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponibilité supprimée.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression.')),
        );
      }
    }
  }

  Widget _buildAvailabilityCard(Map<String, dynamic> disponibilite) {
    final label = _buildCardLabel(disponibilite);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xff1F4B8F),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff253858),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plage horaire hebdomadaire',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  _openDisponibiliteForm(disponibilite: disponibilite),
              icon: const Icon(Icons.edit_outlined),
              color: const Color(0xff1F4B8F),
            ),
            IconButton(
              onPressed: () => _confirmDelete(disponibilite),
              icon: const Icon(Icons.delete_outline),
              color: Colors.red.shade400,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisponibiliteProvider>();

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xff253858),
        title: const Text(
          'Configuration des disponibilités',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _teacherId == null || _teacherId == 0
                ? null
                : () => context
                      .read<DisponibiliteProvider>()
                      .loadDisponibilites(_teacherId!),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDisponibiliteForm(),
        backgroundColor: const Color(0xff1F4B8F),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        icon: const Icon(Icons.add, size: 26, color: Colors.white),
        label: const Text(
          'Ajouter créneau',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
           
                 
              Text(
                'Gérez vos plages horaires sans découper les créneaux. Les rendez-vous seront générés dynamiquement plus tard.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: provider.isLoading
                    ?const Center(child: CircularProgressIndicator())
                    : provider.disponibilites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_available_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              provider.errorMessage ??
                                  'Aucune disponibilité enregistrée.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              
                              onPressed: () => _openDisponibiliteForm(),
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter une disponibilité'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff1F4B8F),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: provider.disponibilites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final disponibilite = provider.disponibilites[index];
                          return _buildAvailabilityCard(disponibilite);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
