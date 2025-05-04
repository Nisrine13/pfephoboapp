import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../auth/forgot_password_screen.dart'; // Nouvel import
import 'signup_screen.dart';
import 'home_apprenant.dart';
import 'home_formateur.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  InputDecoration buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF30B0C7)),
      filled: true,
      fillColor: const Color(0xFFF0F4F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService().loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result['role'] == 'Formateur') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeFormateur()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeApprenant()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
                    const Text('SE CONNECTER', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF30B0C7))),
                    const SizedBox(height: 24),
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
                      validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                    ),
                    // Ajout du lien "Mot de passe oublié"
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        ),
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: Color(0xFFC73030),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF30B0C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Connexion', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      ),
                      child: const Text("Vous n'avez pas de compte ? S'inscrire", style: TextStyle(color: Color(0xFF30B0C7))),
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