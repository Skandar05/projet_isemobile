
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:test/Screens/Auth/Auth.dart';
import 'package:test/providers/EnseignantProvider.dart';
import 'package:test/screens/DashboardPage.dart';


import '../../providers/auth_provider.dart';

class HomeEnseignant extends StatefulWidget {
  const HomeEnseignant({super.key});


  @override
  State<HomeEnseignant> createState() => _HomeEnseignantState();
}




class _HomeEnseignantState extends State<HomeEnseignant> {

@override
void initState() {
  super.initState();
  // Fetch the teacher's ID when the widget is initialized
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _data();
  });
}


Future<void> _data() async {
  final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
  final EnseignantProvider enseignantProvider = Provider.of<EnseignantProvider>(context, listen: false);
  int ides = int.parse(authProvider.idE.toString());

  await enseignantProvider.getTeacherinfo(ides);
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
                    child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                    },
                    child: const Center(
                      child: Icon(
                        Icons.grid_view_rounded,
                        color: Colors.grey,
                        size: 24,
                      ),
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
              Consumer<AuthProvider>(
                builder: (context, auth, _) => Text(
                  'Bienvenue, ${auth.fullName} !',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              
              Column(
                children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DashboardPage(isTeacher: true,
                              ),
                            ),
                          );
                        },

                        child: Container(
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
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Mes classes",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
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
                        ),
                        ),
                      ],
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
