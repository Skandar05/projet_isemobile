import 'package:flutter/material.dart';
import 'package:test/Screens/Widgets/custom_app_bar.dart';
import 'package:test/Screens/parent/home_Parent.dart';

class RdvParentPd extends StatelessWidget {
  const RdvParentPd({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar( interfacePage: HomeParent(),title: "Rendez-vous pédagogique", subtitle: "cree un rendez-vous pedagogique", showBackButton: true),
      
      body: const Center(
        child: Text('Contenu de la page RdvParentPedagogique'),
      ),
    );
  }
}