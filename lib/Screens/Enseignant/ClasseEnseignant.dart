import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/providers/EnseignantProvider.dart';
import 'package:test/Screens/Widgets/ClasseCard.dart';
import 'package:test/Screens/Enseignant/TeacherStudentsParentsScreen.dart';

class ClasseEnseignant extends StatefulWidget {
  const ClasseEnseignant({super.key});

  @override
  State<ClasseEnseignant> createState() => _ClasseEnseignantState();
}

class _ClasseEnseignantState extends State<ClasseEnseignant> {
  int idEnseignant = 0;
  Map<String, String> classMap = {};

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    final prefs = await SharedPreferences.getInstance();

    // Read possible int or String stored variants safely
    int parsePossibleInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    idEnseignant = parsePossibleInt(prefs.get('idE'))
        ;
    if (idEnseignant == 0) idEnseignant = parsePossibleInt(prefs.get('idEnseignant'));

    if (idEnseignant == 0) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = 'Identifiant enseignant introuvable.';
      });
      return;
    }

    if (!mounted) {
      return;
    }

    await Provider.of<EnseignantProvider>(
      context,
      listen: false,
    ).getEnseignantsClasse(idEnseignant);

    final stored = prefs.getString('classMap');

    if (stored != null) {
      final decoded = jsonDecode(stored);
      classMap = Map<String, String>.from(decoded);
    }

    await prefs.setString('rdvFlow', 'teacher');

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xff253858),
        title: const Text(
          'Demander un rendez-vous',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisir une classe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sélectionnez la classe de l\'enseignant pour afficher les élèves et leurs parents.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(
                            child: Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade400),
                            ),
                          )
                        : classMap.isEmpty
                            ? const Center(child: Text('Aucune classe trouvée'))
                            : ListView.builder(
                                itemCount: classMap.length,
                                itemBuilder: (context, index) {
                                  final key = classMap.keys.elementAt(index);
                                  final value = classMap[key]!;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ClasseCard(
                                      NomClasse: value,
                                      onTap: () async {
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.setString('rdvFlow', 'teacher');
                                        await prefs.setString('selectedTeacherClassId', key);
                                        await prefs.setString('selectedTeacherClassName', value);

                                        if (!context.mounted) {
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TeacherStudentsParentsScreen(
                                              classId: int.tryParse(key) ?? 0,
                                              className: value,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
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
}