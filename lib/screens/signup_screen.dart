import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pfephoboapp/screens/home_apprenant.dart';
import 'package:pfephoboapp/screens/home_formateur.dart';
import 'package:pfephoboapp/screens/background_video.dart';

import 'login_screen.dart';

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: const Color(0xFFD2B48C)), // Marron clair
      filled: true,
      fillColor: Colors.white.withOpacity(0.15), // Blanc transparent
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        _verificationTimer?.cancel();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => selectedRole == 'Formateur'
                ? const HomeFormateur()
                : const HomeApprenant(),
          ),
              (route) => false,
        );
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
            (_) => _checkEmailVerification(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email de vérification envoyé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec envoi email: ${e.toString()}')),
        );
      }
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
          .createUserWithEmailAndPassword(email: email, password: password);

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur inattendue: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On retire le backgroundColor pour laisser la vidéo occuper tout l'espace
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Vidéo en arrière-plan (full screen)
          const BackgroundVideo(),

          // 2) Voile sombre semi-transparent (pour faire ressortir le formulaire)
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // 3) Contenu du formulaire superposé
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: ConstrainedBox(
                  // On limite la largeur max pour que le formulaire ne soit pas trop étiré
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo (vous pouvez remplacer par votre asset réel)
                      Center(
                        child: Image.asset(
                          'assets/images/onboarding_image.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Titre
                      const Text(
                        'CRÉER UN COMPTE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Le Container noir qui contient le formulaire, avec bord arrondi
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sélecteur de rôle
                              DropdownButtonFormField<String>(
                                value: selectedRole,
                                dropdownColor: Colors.black.withOpacity(0.8),
                                decoration: buildInputDecoration(
                                  hint: 'Sélectionnez votre rôle',
                                  icon: Icons.person_pin,
                                ),
                                style: const TextStyle(color: Colors.white),
                                items: ['Apprenant', 'Formateur']
                                    .map(
                                      (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                                    .toList(),
                                onChanged: (newValue) =>
                                    setState(() => selectedRole = newValue),
                              ),
                              const SizedBox(height: 16),

                              // Prénom / Nom
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _firstNameController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: buildInputDecoration(
                                        hint: 'Prénom',
                                        icon: Icons.person,
                                      ),
                                      validator: (value) =>
                                      (value == null || value.isEmpty)
                                          ? 'Champ requis'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lastNameController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: buildInputDecoration(
                                        hint: 'Nom',
                                        icon: Icons.person_outline,
                                      ),
                                      validator: (value) =>
                                      (value == null || value.isEmpty)
                                          ? 'Champ requis'
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: buildInputDecoration(
                                  hint: 'Email',
                                  icon: Icons.email,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Champ requis';
                                  }
                                  final emailRegex =
                                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  return !emailRegex.hasMatch(value.trim())
                                      ? 'Email invalide'
                                      : null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Mot de passe
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: buildInputDecoration(
                                  hint: 'Mot de passe',
                                  icon: Icons.lock,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Champ requis';
                                  }
                                  return value.length < 6
                                      ? 'Minimum 6 caractères'
                                      : null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Confirmer le mot de passe
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: buildInputDecoration(
                                  hint: 'Confirmer mot de passe',
                                  icon: Icons.lock_outline,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Champ requis';
                                  }
                                  return value != _passwordController.text
                                      ? 'Les mots de passe ne correspondent pas'
                                      : null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Checkbox pour accepter les termes
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agreeToTerms,
                                    checkColor: Colors.brown.shade800,
                                    fillColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                          (states) {
                                        return Colors.white;
                                      },
                                    ),
                                    onChanged: (val) =>
                                        setState(() => _agreeToTerms = val ?? false),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      "J'accepte les termes et conditions",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Section “Email vérifié” si besoin
                              if (_emailSent) ...[
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'Vérifiez votre email pour le lien de confirmation',
                                    style: TextStyle(color: Colors.greenAccent),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _checkEmailVerification,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                  child: const Text(
                                    "J'ai vérifié mon email",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Bouton d'inscription
                              ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD2B48C), // Marron clair
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  "S'inscrire",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Lien pour retourner à la page de Login si on a déjà un compte
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Vous avez déjà un compte ? ",
                            style: TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            ),
                            child: Text(
                              'Se connecter',
                              style: TextStyle(
                                color: const Color(0xFFD2B48C), // Marron clair
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
