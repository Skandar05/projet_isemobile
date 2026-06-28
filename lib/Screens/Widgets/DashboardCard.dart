import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 180,
        height: 175,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Couche d'ombre en bas (le bloc bleu foncé)
            Positioned(
              left: 2,
              right: 2,
              top: 8,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFBDD3EA), 
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            // La carte principale en haut
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 14,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0F8), 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD0DEF0), 
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 18.0, left: 16.0, right: 16.0),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1D2A4D),
                          height: 1.2,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 14,
                      child: Icon(
                        icon,
                        size: 44,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}