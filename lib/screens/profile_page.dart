import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Palette de couleurs
  final Color primaryColor = const Color(0xFF30B0C7);
  final Color accentYellow = const Color(0xFFFFD700);
  final Color importantRed = const Color(0xFFE53935);
  final Color lightGray = const Color(0xFFEEEEEE);
  final Color darkGray = const Color(0xFF757575);
  final Color white = Colors.white;

  // Données utilisateur
  final User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '');
    _surnameController = TextEditingController(text: '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .get();

      setState(() {
        _nameController.text = userDoc['nom'] ?? '';
        _surnameController.text = userDoc['prenom'] ?? '';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.uid)
            .update({
          'nom': _nameController.text,
          'prenom': _surnameController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil mis à jour avec succès'),
            backgroundColor: primaryColor,
          ),
        );
        Navigator.pop(context); // Fermer le dialogue après la mise à jour
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: importantRed,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez remplir tous les champs'),
          backgroundColor: importantRed,
        ),
      );
      return;
    }

    try {
      // Vérifier le mot de passe actuel
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _currentPasswordController.text,
      );

      await user!.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await user!.updatePassword(_newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mot de passe changé avec succès'),
          backgroundColor: primaryColor,
        ),
      );

      // Vider les champs
      _currentPasswordController.clear();
      _newPasswordController.clear();
      Navigator.pop(context); // Fermer le dialogue après le changement
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.message}'),
          backgroundColor: importantRed,
        ),
      );
    }
  }

  void _showProfileEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Modifier le profil',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      labelStyle: TextStyle(color: darkGray),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      labelStyle: TextStyle(color: darkGray),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(color: darkGray),
              ),
            ),
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: white,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Changer le mot de passe',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    labelStyle: TextStyle(color: darkGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    labelStyle: TextStyle(color: darkGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(color: darkGray),
              ),
            ),
            ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentYellow,
                foregroundColor: darkGray,
              ),
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Carte pour les informations personnelles
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: white,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: _showProfileEditDialog,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 40, color: primaryColor),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations personnelles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Modifier votre nom et prénom',
                              style: TextStyle(
                                color: darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: darkGray),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Carte pour changer le mot de passe
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: white,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: _showPasswordChangeDialog,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 40, color: accentYellow),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Changer le mot de passe',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Mettre à jour votre mot de passe',
                              style: TextStyle(
                                color: darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: darkGray),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}