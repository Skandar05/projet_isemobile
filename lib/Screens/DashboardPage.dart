import 'package:flutter/material.dart';
import 'package:test/Screens/parent/home_Parent.dart';
import 'package:test/Screens/Enseignant/home_Enseignant.dart';
import 'package:test/Screens/Widgets/custom_app_bar.dart';
import 'Widgets/DashboardCard.dart';
import '../Screens/Rdv/rendezvous_screen.dart';
import 'package:test/Screens/Enseignant/ClasseEnseignant.dart';
import 'package:test/Screens/Pedagogique/Pd_rendezvous_screen.dart';
import 'package:test/Screens/Pedagogique/HomePD.dart';

class DashboardPage extends StatelessWidget {
  final bool isTeacher;
  final bool isPedagogique;
  final String? classId;
  final String? className;

  const DashboardPage({
    super.key,
    this.isTeacher = false,
    this.isPedagogique = false,
    this.classId,
    this.className,
  });

  @override
  Widget build(BuildContext context) {
    Color primary = const Color(0xff1F4B8F);
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: CustomAppBar(
          interfacePage: isTeacher ? const HomeEnseignant() : isPedagogique ? const HomePD() : const HomeParent(),
          title: "Tableau de bord",
          subtitle: "",
          showBackButton: true,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [

              const SizedBox(height: 10),

              /// HEADER
              

                
              


              const SizedBox(height: 20),


              // Dashboard cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,

                  children: [

                    DashboardCard(
                      title: isTeacher ? 'Rendez_vous' : 'Rendez_vous',
                      icon: Icons.schedule,
                      iconColor: const Color(0xFF5B9BD5),

                      onTap: () {
                        if (isPedagogique) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Pd_rendezvous_screen(),
                            ),
                          );
                        } else if (isTeacher) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RendezVousPage(isTeacher: true),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RendezVousPage(),
                            ),
                          );
                        }
                      },
                    ),

                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}