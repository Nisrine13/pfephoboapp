import 'package:flutter/material.dart';
import '../screens/background_video.dart';
import 'reset_password_sent_screen.dart';
import 'email_verifier.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Même InputDecoration que sur SignUp / Login :
  /// fond blanc semi‐transparent et icône marron clair
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

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      // Vérifier que l'email existe avant d'envoyer le lien
      final emailValid = await EmailVerifier.verifyEmailBeforeReset(email);
      if (!emailValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Aucun compte valide trouvé avec cet email")),
          );
        }
        return;
      }

      // Si c'est bon, naviguer vers l'écran "ResetPasswordSentScreen"
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResetPasswordSentScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond transparent pour laisser la vidéo apparaître dessous
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Vidéo en arrière‐plan (full screen)
          const BackgroundVideo(),

          // 2) Voile sombre semi-transparent pour que le formulaire ressorte
          Container(color: Colors.black.withOpacity(0.5)),

          // 3) Contenu superposé
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Titre principal en haut ---
                      const Text(
                        'Mot de passe oublié ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Container noir arrondi contenant le formulaire ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Entrez votre adresse email pour recevoir un lien de réinitialisation',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            // Champ Email
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: buildInputDecoration(
                                hint: 'Adresse email',
                                icon: Icons.email,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Champ requis';
                                }
                                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                return !emailRegex.hasMatch(value.trim())
                                    ? 'Email invalide'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 30),

                            // Bouton “Continuer”
                            ElevatedButton(
                              onPressed: _isLoading ? null : _sendResetEmail,
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
                                'Continuer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bouton “Retour à la connexion”
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFD2B48C), // Marron clair
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          'Retour à la connexion',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
