import 'package:flutter/material.dart';

import 'role_home.dart';

class HomeBScreen extends StatelessWidget {
  const HomeBScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeScreen(
      title: 'Home Enseignant',
      subtitle: 'You are logged in as role enseignant.',
      accent: Color(0xFFB45309),
    );
  }
}