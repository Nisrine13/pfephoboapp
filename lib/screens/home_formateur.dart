import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeFormateur extends StatelessWidget {
  const HomeFormateur({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Formateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenue dans votre espace Formateur'),
      ),
    );
  }
}