import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/Pd_Providers.dart';
import 'package:test/Screens/Widgets/ClasseCard.dart';
import 'package:test/Screens/Enseignant/TeacherStudentsParentsScreen.dart';

class ClassLevelsPage extends StatefulWidget {
  const ClassLevelsPage({super.key});

  @override
  State<ClassLevelsPage> createState() => _ClassLevelsPageState();
}

class _ClassLevelsPageState extends State<ClassLevelsPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _classes = [];
  String? _selectedLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClasses();
    });
  }

  Future<void> _loadClasses() async {
    try {
      final response = await context.read<PdProvider>().getAllClasses();
      setState(() {
        _classes = response.whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _extractLevel(String nomClasseFr) {
    final match = RegExp(r'^(\d+)').firstMatch(nomClasseFr);
    return match?.group(1) ?? nomClasseFr;
  }

  Map<String, List<Map<String, dynamic>>> get _groupedByLevel {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final classe in _classes) {
      final rawName = classe['nomclassefr']?.toString() ?? '';
      if (rawName.isEmpty) continue;
      final level = _extractLevel(rawName);
      groups.putIfAbsent(level, () => []).add(classe);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
        backgroundColor: const Color(0xFF1D2A4D),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Erreur: $_error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }
    

    final groups = _groupedByLevel;
    const customOrder = ['7', '8', '9', '1', '2', '3', '4'];
    final topLevels = groups.keys.toList()
      ..sort((a, b) {
        final aIndex = customOrder.indexOf(a);
        final bIndex = customOrder.indexOf(b);
        if (aIndex == -1 || bIndex == -1) {
          return a.compareTo(b);
        }
        return aIndex.compareTo(bIndex);
      });

    if (_selectedLevel != null) {
      final subclasses = groups[_selectedLevel] ?? [];
      return Column(
        children: [
          Expanded(
            child: subclasses.isEmpty
                ? const Center(child: Text('Aucune sous-classe trouvée.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: subclasses.length,
                    itemBuilder: (context, index) {
                      final classe = subclasses[index];
                      final name = classe['nomclassefr']?.toString() ?? '';
                      final classId = int.tryParse(classe['id']?.toString() ?? '') ?? 0;

                      return ClasseCard(
                        NomClasse: name,
                        onTap: () {
                          if (classId > 0) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TeacherStudentsParentsScreen(
                                  classId: classId,
                                  className: name,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: topLevels.length,
      itemBuilder: (context, index) {
        final level = topLevels[index];
        return ClasseCard(
          NomClasse: level,
          onTap: () {
            setState(() {
              _selectedLevel = level;
            });
          },
        );
      },
    );
  }
}
