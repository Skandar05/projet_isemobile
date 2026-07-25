import 'package:flutter/material.dart';

class TestInterfacePage extends StatelessWidget {
  const TestInterfacePage({Key? key}) : super(key: key);

  // Palette de couleurs
  final Color bgColor = const Color(0xFFF3F6FA);
  final Color textDark = const Color(0xFF1E3354);
  final Color textGray = const Color(0xFF7A8B9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildProfileSection(),
            const SizedBox(height: 12),
            _buildTitleSection(),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 20),
                  children: [
                    _buildExamCard(
                      time: '11:00 - 12:00',
                      date: '2026-01-13',
                      subject: 'Géographie',
                      room: 'S 7',
                    ),
                    _buildExamCard(
                      time: '15:00 - 16:00',
                      date: '2026-01-22',
                      subject: 'إنشاء',
                      room: 'S 5',
                    ),
                    _buildExamCard(
                      time: '08:00 - 09:00',
                      date: '2026-01-23',
                      subject: 'SVT',
                      room: 'S 8',
                    ),
                    _buildExamCard(
                      time: '10:00 - 11:00',
                      date: '2026-01-24',
                      subject: 'Mathématiques',
                      room: 'S 3',
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.notifications_none, color: textDark, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF1A2A47),
                child: Text(
                  'ISE',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=47'),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BENABDA Malak',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Classe 8B3',
                style: TextStyle(
                  fontSize: 14,
                  color: textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contrôle',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Calendrier des examens',
            style: TextStyle(
              fontSize: 14,
              color: textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard({
    required String time,
    required String date,
    required String subject,
    required String room,
  }) {
    // COULEURS EXACTES EXTRAITES DE VOTRE NOUVELLE IMAGE
    const Color cardShadowLipColor = Color(0xFF9CBEE0); // Le bord épais en bas (effet 3D bleu plus foncé)
    const Color cardSurfaceColor = Color(0xFFF1F6FB); // Le fond principal très clair de la carte
    const Color cardBorderColor = Color(0xFFD4E3F3); // La fine bordure autour de la carte
    const Color pillBlueBg = Color(0xFFD8E5F2); // Le fond bleu des capsules "Heure" et "Salle"
    const Color textDarkColor = Color(0xFF223654); // Le texte bleu marine

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      // CONTENEUR EXTERIEUR : Crée le rebord 3D et l'ombre portée
      decoration: BoxDecoration(
        color: cardShadowLipColor, // Couleur du rebord épais
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9CBEE0).withOpacity(0.3), // Ombre diffuse sous la carte
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        // Le margin bottom de 6px laisse apparaître le conteneur parent en dessous, créant le rebord 3D !
        margin: const EdgeInsets.only(bottom: 6), 
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        // CONTENEUR INTERIEUR : La face de la carte
        decoration: BoxDecoration(
          color: cardSurfaceColor,
          borderRadius: BorderRadius.circular(26), // Même rayon pour épouser parfaitement le parent
          border: Border.all(color: cardBorderColor, width: 1.5), // Fine bordure comme sur l'image
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Capsule Heure (Bleu clair)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: pillBlueBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: textDarkColor),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: const TextStyle(
                          color: textDarkColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Capsule Date (Blanche)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 15, color: textDarkColor),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          color: textDarkColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Icône Matière (Carré blanc arrondi)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(Icons.school, color: textDarkColor, size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Nom Matière
                      Expanded(
                        child: Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textDarkColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Capsule Salle (Bleu clair comme sur votre image, pas bleu foncé)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: pillBlueBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 15, color: textDarkColor),
                      const SizedBox(width: 4),
                      Text(
                        room,
                        style: const TextStyle(
                          color: textDarkColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}