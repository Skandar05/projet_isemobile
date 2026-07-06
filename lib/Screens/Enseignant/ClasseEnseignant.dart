import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/providers/EnseignantProvider.dart';
import 'package:test/Screens/Widgets/ClasseCard.dart';

class ClasseEnseignant extends StatefulWidget {
  const ClasseEnseignant({super.key});

  @override
  State<ClasseEnseignant> createState() => _ClasseEnseignantState();
}

class _ClasseEnseignantState extends State<ClasseEnseignant> {
  int idEnseignant = 0;
  Map<String, String> classMap = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load teacher ID correctly
    idEnseignant = prefs.getInt('idE') ?? 0;

    debugPrint("ID Enseignant: $idEnseignant");

    // 2. Call API
    await Provider.of<EnseignantProvider>(
      context,
      listen: false,
    ).getEnseignantsClasse(idEnseignant);

    // 3. Load saved class map
    final stored = prefs.getString('classMap');

    if (stored != null) {
      final decoded = jsonDecode(stored);
      classMap = Map<String, String>.from(decoded);
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Classes")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : classMap.isEmpty
              ? const Center(child: Text("Aucune classe trouvée"))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: classMap.length,
                  itemBuilder: (context, index) {
                    final key = classMap.keys.elementAt(index);
                    final value = classMap[key]!;

                    return ClasseCard(
                      NomClasse: value,
                      onTap: () {
                        debugPrint("Classe ID selected: $key");
                      },
                    );
                  },
                ),
    );
  }
}