import 'package:flutter/material.dart';
import 'package:test/Screens/Parent/home_Parent.dart';
import 'package:test/Screens/Enseignant/home_Enseignant.dart';
import 'Widgets/DashboardCard.dart';
import '../Screens/Rdv/rendezvous_screen.dart';
import 'package:test/Screens/Enseignant/ClasseEnseignant.dart';

class DashboardPage extends StatelessWidget {
  final bool isTeacher;
  final String? classId;
  final String? className;

  const DashboardPage({
    super.key,
    this.isTeacher = false,
    this.classId,
    this.className,
  });

  @override
  Widget build(BuildContext context) {
    Color primary = const Color(0xff1F4B8F);
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [

              const SizedBox(height: 10),

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  // Back button
                  InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => isTeacher 
                              ? const HomeEnseignant()
                              : const HomeParent(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: primary,
                      ),
                    ),
                  ),

                  // Class info for teacher
                  if (isTeacher && className != null)
                    Text(
                      className!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),

                  // Right icons
                  Row(
                    children: [

                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.notifications_none,
                          color: primary,
                        ),
                      ),

                      const SizedBox(width: 10),

                      CircleAvatar(
                        backgroundColor: primary,
                        
                        child: ClipOval(
                          child: Image.asset(
                            'lib/images/logoise.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                ),
                              );
                            },
                          ),
                        ),
                      )

                    ],
                  )

                ],
              ),


              const SizedBox(height: 20),


              // Dashboard cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,

                  children: [

                    DashboardCard(
                      title: isTeacher ? 'Rendez_vous\n(Demandes)' : 'Rendez_vous',
                      icon: Icons.schedule,
                      iconColor: const Color(0xFF5B9BD5),

                      onTap: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => isTeacher 
                                  ? const RendezVousPage(isTeacher: true)
                                  : const RendezVousPage(),
                          ),
                        );

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