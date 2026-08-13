import 'package:flutter/material.dart';

/// Placeholder do Perfil — será desenvolvido nas próximas etapas.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: const Center(
        child: Text('Seus dados e preferências — em construção 👤'),
      ),
    );
  }
}
