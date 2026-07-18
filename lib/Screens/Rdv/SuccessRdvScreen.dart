import 'package:flutter/material.dart';
import 'rendezvous_screen.dart';

class SuccessRdvScreen extends StatelessWidget {
  final String enseignantFullname;
  final bool isTeacher;

  const SuccessRdvScreen({
    super.key,
    required this.enseignantFullname,
    this.isTeacher = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [

              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                 


                  Row(
                    children: [

                   

                      const SizedBox(width: 280),


                      CircleAvatar(
                        backgroundColor: const Color(0xff1F4B8F),
                        child: ClipOval(
                          child: Image.asset(
                            'lib/images/logoise.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    ],
                  ),

                ],
              ),


              const SizedBox(height: 80),


              // Success icon
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: Color(0xffE8F8EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 60,
                  color: Color(0xff22C55E),
                ),
              ),


              const SizedBox(height: 30),


              const Text(
                "Demande envoyée !",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1F2A44),
                ),
              ),


              const SizedBox(height: 10),


              Text(
                "$enseignantFullname et l'administration ont été notifiés. "
                "Vous recevrez une confirmation dès que possible.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),


              const SizedBox(height: 25),


              // Info box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Row(
                  children: [

                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.blue,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        "Rappel automatique à 8h00 le jour du RDV",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),

                  ],
                ),
              ),


              const Spacer(),


              // Button
              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1F4B8F),
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),


                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RendezVousPage(isTeacher: isTeacher),
                      ),
                      (route) => false,
                    );
                  },


                  child: const Text(
                    "Voir mes rendez-vous",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                ),
              ),


              const SizedBox(height: 20),

            ],
          ),
        ),
      ),

    );
  }
}