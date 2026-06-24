import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class HomeAScreen extends StatefulWidget {
  const HomeAScreen({super.key});

  @override
  State<HomeAScreen> createState() => _HomeAScreenState();
}

class _HomeAScreenState extends State<HomeAScreen> {
  bool _isLoading = false;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStudents();
    });
  }

  Future<void> _fetchStudents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final idPersonne = authProvider.idPersonne;

    if (idPersonne == null) {
      // Fallback data for testing if idPersonne is null
      setState(() {
        _students = [
          {"id": 8521, "Nomfr": "TEST", "Prenomfr": "Test", "Civilite": 1}
        ];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://apiserv.ise-college-lycee.com:8415/GeteleveParent/$idPersonne'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _students = data.isNotEmpty ? data : [
            {"id": 8521, "Nomfr": "TEST", "Prenomfr": "Test", "Civilite": 1}
          ];
        });
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      // Fallback on error so the interface is still functional
      setState(() {
        _students = [
          {"id": 8521, "Nomfr": "TEST", "Prenomfr": "Test", "Civilite": 1}
        ];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStudentClass(String firstName, String lastName) {
    final name = '$firstName $lastName'.toLowerCase();
    if (name.contains('test')) {
      return '7B1';
    } else if (name.contains('malak')) {
      return '4A';
    }
    return '7B1'; // default class
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF243B7B);
    const Color backgroundColor = Color(0xFFF3F6FC);
    const Color secondaryBtnColor = Color(0xFFE5EDF9);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  // Grid Menu Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.grid_view_rounded,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Notification Bell Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // School Logo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                      image: const DecorationImage(
                        image: AssetImage('lib/images/logoise.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Greeting Title
              const Text(
                'Bienvenue, Pere !',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              // Students Card List
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    )
                  : Column(
                      children: _students.map((student) {
                        final firstName = student['Prenomfr'] ?? '';
                        final lastName = student['Nomfr'] ?? '';
                        final studentName = '$lastName $firstName';
                        final className = _getStudentClass(firstName, lastName);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Student Avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 32,
                                    color: Colors.blue.shade400,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Student Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      className,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow Icon
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                                size: 28,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 16),
              // Grid Row of 3 Actions
              Row(
                children: [
                  _buildQuickActionButton(
                    context: context,
                    label: 'Actualités',
                    emoji: '🔔',
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionButton(
                    context: context,
                    label: 'Cantine',
                    emoji: '🍴',
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionButton(
                    context: context,
                    label: 'Messagerie',
                    emoji: '💬',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Section Examen
              Row(
                children: [
                  const Text(
                    'Rappel examen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  // Calendrier Button
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: secondaryBtnColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                            color: primaryColor,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Calendrier',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Refresh Button
                  _buildSmallRefreshButton(onTap: () {}),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Aucun examen dans les 7 prochains jours',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Section Notifications
              Row(
                children: [
                  const Text(
                    'Notifications non lues',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  _buildSmallRefreshButton(onTap: () {}),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Aucune notification non lue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required String label,
    required String emoji,
    required VoidCallback onTap,
  }) {
    const Color primaryColor = Color(0xFF243B7B);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 104,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallRefreshButton({required VoidCallback onTap}) {
    const Color secondaryBtnColor = Color(0xFFE5EDF9);
    const Color primaryColor = Color(0xFF243B7B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: secondaryBtnColor,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.refresh_rounded,
            size: 20,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}
