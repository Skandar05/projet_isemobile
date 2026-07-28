import 'package:flutter/material.dart';
import 'package:test/Screens/Rdv/creationRDV.dart';
import 'package:test/Screens/Widgets/FinalCard.dart';
import 'package:test/Screens/Widgets/custom_app_bar.dart';
import 'package:test/Screens/parent/RdvParentPedagogique.dart';
import 'package:test/Screens/parent/home_Parent.dart';

class RdvType extends StatelessWidget {
  const RdvType({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: const CustomAppBar(
    interfacePage: HomeParent(),
    showBackButton: true,
    title: "Type de rendez-vous",
    subtitle: "a qui vous souhaitez prendre rendez-vous",
  ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0 , vertical: 40.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinalCard(
                child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Enseignants',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.black54,
                      size: 20,
                    ),
                  ],
                ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChooseContactScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              FinalCard(
  child: Padding(
    padding: const EdgeInsets.only(top: 30),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(
            Icons.menu_book,
            color: Colors.blue,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Pédagogique',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios,
          color: Colors.black54,
          size: 20,
        ),
      ],
    ),
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RdvParentPd(),
      ),
    );
  },
),
              
              
            ],
          ),
        ),
      ),
    ),
    );
  }
}
