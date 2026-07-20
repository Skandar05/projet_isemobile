import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/Screens/Auth/Auth.dart';
import 'package:test/Screens/DashboardPage.dart';
import 'package:test/Screens/Pedagogique/Pd_rendezvous_screen.dart';

import '../../providers/auth_provider.dart';

class HomeCScreen extends StatelessWidget {
  const HomeCScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomePedagogiqueBody();
  }
}

class _HomePedagogiqueBody extends StatefulWidget {
  const _HomePedagogiqueBody();

  @override
  State<_HomePedagogiqueBody> createState() => _HomePedagogiqueBodyState();
}

class _HomePedagogiqueBodyState extends State<_HomePedagogiqueBody> {
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF243B7B);
    const Color backgroundColor = Color(0xFFF3F6FC);
    const Color secondaryBtnColor = Color(0xFFE5EDF9);
    const Color accentColor = Color(0xFF1D4ED8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  _circleIcon(Icons.grid_view_rounded, Colors.grey,onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                    );
                  }),
                  const Spacer(),
                  _circleIcon(Icons.notifications_none_rounded, Colors.black),
                  const SizedBox(width: 12),
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

              // ── Greeting ─────────────────────────────────────────────
              Consumer<AuthProvider>(
                builder: (context, auth, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue, ${auth.fullName} !',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Espace Pédagogique',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Carte Pédagogique ─────────────────────────────────────
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardPage(isPedagogique: true),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 28,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tableau de bord',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Gestion et suivi pédagogique',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Actions rapides ───────────────────────────────────────
              Row(
                children: [
                  _buildQuickActionButton(
                    label: 'Actualités',
                    emoji: '🔔',
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionButton(
                    label: 'Planning',
                    emoji: '📅',
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionButton(
                    label: 'Messagerie',
                    emoji: '💬',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Section Rappel examen ─────────────────────────────────
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
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: secondaryBtnColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 18, color: primaryColor),
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
                  _buildSmallRefreshButton(onTap: () {}),
                ],
              ),
              const SizedBox(height: 12),
              _buildEmptyCard('Aucun examen dans les 7 prochains jours'),
              const SizedBox(height: 28),

              // ── Section Notifications ─────────────────────────────────
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
              _buildEmptyCard('Aucune notification non lue'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
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
        child: Center(child: Icon(icon, color: color, size: 24)),
      ),
    );
  }

  Widget _buildQuickActionButton({
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
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
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

  Widget _buildEmptyCard(String message) {
    return Container(
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
          message,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
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
          child: Icon(Icons.refresh_rounded, size: 20, color: primaryColor),
        ),
      ),
    );
  }
}