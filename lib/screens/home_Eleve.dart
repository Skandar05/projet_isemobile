import 'package:flutter/material.dart';

import 'role_home.dart';

class HomeDScreen extends StatelessWidget {
  const HomeDScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeScreen(
      title: 'Home Élève',
      subtitle: 'You are logged in as role élève.',
      accent: Color(0xFF6D28D9),
    );
  }
}
