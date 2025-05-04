import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_apprenant.dart';
import 'home_formateur.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedRole = 'Apprenant';
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _emailSent = false;
  Timer? _verificationTimer;

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  InputDecoration buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF30B0C7)),
      filled: true,
      fillColor: const Color(0xFFF0F4F5),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user!.emailVerified) {
        _verificationTimer?.cancel();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => selectedRole == 'Formateur'
                  ? HomeFormateur()
                  : const HomeApprenant(),
            ),
                (route) => false,
          );
        }
      }
    }
  }

  Future<void> _sendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
      setState(() => _emailSent = true);

      // Démarrer la vérification périodique
      _verificationTimer = Timer.periodic(
          const Duration(seconds: 5),
              (timer) => _checkEmailVerification()
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de vérification envoyé')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l\'envoi du lien: ${e.toString()}')),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez accepter les termes et conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Vérifier si l'email existe déjà
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Un compte existe déjà avec cet email',
        );
      }

      // Créer le compte
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Enregistrer dans Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user!.uid)
          .set({
        'prenom': _firstNameController.text.trim(),
        'nom': _lastNameController.text.trim(),
        'email': email,
        'role': selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Envoyer l'email de vérification
      await _sendVerificationEmail(userCredential.user!);

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "Cet email est déjà utilisé";
          break;
        case 'invalid-email':
          errorMessage = "Format d'email invalide";
          break;
        case 'operation-not-allowed':
          errorMessage = "Méthode de connexion désactivée. Contactez le support.";
          break;
        case 'weak-password':
          errorMessage = "Le mot de passe doit contenir au moins 6 caractères";
          break;
        default:
          errorMessage = "Erreur: ${e.message}";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur inattendue: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset('assets/images/status_icons.png', height: 70, width: 60),
                    const SizedBox(height: 12),
                    const Text('CRÉER UN COMPTE', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF30B0C7))),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: buildInputDecoration(hint: 'Sélectionnez votre rôle', icon: Icons.person_pin),
                      items: ['Apprenant', 'Formateur'].map((value) =>
                          DropdownMenuItem<String>(value: value, child: Text(value))
                      ).toList(),
                      onChanged: (newValue) => setState(() => selectedRole = newValue),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: buildInputDecoration(hint: 'Prénom', icon: Icons.person),
                            validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: buildInputDecoration(hint: 'Nom', icon: Icons.person_outline),
                            validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: buildInputDecoration(hint: 'Email', icon: Icons.email),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                      !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value ?? '')
                          ? 'Email invalide'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: buildInputDecoration(hint: 'Mot de passe', icon: Icons.lock),
                      validator: (value) => value!.length < 6 ? 'Minimum 6 caractères' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: buildInputDecoration(hint: 'Confirmer mot de passe', icon: Icons.lock_outline),
                      validator: (value) => value != _passwordController.text ? 'Les mots de passe ne correspondent pas' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                        ),
                        const Expanded(child: Text("J'accepte les termes et conditions")),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_emailSent) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Vérifiez votre email pour le lien de confirmation',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _checkEmailVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          "J'ai vérifié mon email",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF30B0C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("S'inscrire", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}