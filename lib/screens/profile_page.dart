// lib/screens/ProfilePage.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/supabase_service.dart';
import 'mescours_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Palette de couleurs
  final Color primaryColor   = const Color(0xFF30B0C7);  // bleu principal
  final Color accentYellow   = const Color(0xFFFFD700);  // jaune accent
  final Color importantRed   = const Color(0xFFE53935);  // rouge (erreur)
  final Color lightGray      = const Color(0xFFEEEEEE);  // fond légers
  final Color darkGray       = const Color(0xFF757575);  // textes secondaires
  final Color white          = Colors.white;

  String? userPhotoUrl;
  final String defaultPhotoPath = 'assets/images/defaultprofil.jpg';

  final User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;

  @override
  void initState() {
    super.initState();
    _nameController           = TextEditingController(text: '');
    _surnameController        = TextEditingController(text: '');
    _currentPasswordController = TextEditingController();
    _newPasswordController    = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('Users').doc(user!.uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _nameController.text    = data['nom']    ?? '';
          _surnameController.text = data['prenom'] ?? '';
          userPhotoUrl            = data['photoUrl'] ?? '';
        });
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.image,
    );
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      // Upload sur Supabase (ou autre service), puis récupérer l'URL
      final url = await SupabaseService().uploadFile(
        file,
        'images/${file.name}',
        'images',
      );
      // Mettre à jour dans Firestore
      await FirebaseFirestore.instance.collection('Users').doc(user!.uid).update({
        'photoUrl': url,
      });
      setState(() {
        userPhotoUrl = url;
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
          'nom':    _nameController.text,
          'prenom': _surnameController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil mis à jour avec succès'),
            backgroundColor: primaryColor,
          ),
        );
        Navigator.pop(context); // Fermer le dialogue
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
      // Ré-authentification
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _currentPasswordController.text,
      );
      await user!.reauthenticateWithCredential(credential);

      // Mise à jour du mot de passe
      await user!.updatePassword(_newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mot de passe changé avec succès'),
          backgroundColor: primaryColor,
        ),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      Navigator.pop(context);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                  // Champ “Nom”
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
                  // Champ “Prénom”
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                // Champ ‘‘Mot de passe actuel’’
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
                // Champ ‘‘Nouveau mot de passe’’
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
            // Avatar + bouton Modifier
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: lightGray,
                  backgroundImage: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                      ? NetworkImage(userPhotoUrl!)
                      : AssetImage(defaultPhotoPath) as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _changeProfilePhoto,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: primaryColor,
                      child: Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Carte “Informations personnelles”
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                              style: TextStyle(color: darkGray),
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
            // Carte “Changer mot de passe”
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                              style: TextStyle(color: darkGray),
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

            // Bouton pour accéder à “Mes cours”
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MesCoursPage()),
                );
              },
              icon: const Icon(Icons.bookmark, color: Colors.white),
              label: const Text('Mes cours enregistrés', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}