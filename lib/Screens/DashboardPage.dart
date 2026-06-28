import 'package:flutter/material.dart';
import 'package:test/screens/Parent/home_Parent.dart';
import 'Widgets/DashboardCard.dart';
import '../Screens/parent/rendezvous_screen.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
                              builder: (context) => HomeParent(
                              ),
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
                      title: 'Rendez_vous',
                      icon: Icons.schedule,
                      iconColor: const Color(0xFF5B9BD5),

                      onTap: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RendezVousPage(),
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