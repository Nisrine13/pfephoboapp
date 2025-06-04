import 'package:flutter/material.dart';
import 'package:pfephoboapp/screens/signup_screen.dart';
import 'package:pfephoboapp/screens/login_screen.dart';
import 'package:pfephoboapp/screens/courses_screen.dart';
import 'package:pfephoboapp/screens/background_video.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On retire le backgroundColor blanc pour laisser la vidéo en plein écran
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Vidéo en arrière-plan (full screen)
          const BackgroundVideo(),

          // 2) Calque semi-transparent si vous souhaitez un léger voile par-dessus la vidéo
          //   (optionnel — si vous désirez un léger fondu pour mieux faire ressortir les boutons)
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // 3) Contenu superposé sur la vidéo (logo + boutons + lien)
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Logo + titre ---
                    // Ici je garde votre asset, mais vous pouvez le remplacer par votre logo PNG
                    Image.asset(
                      'assets/images/onboarding_image.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 400),

                    // --- Bouton "Créer un compte" ---
                    // Taille réduite, fond blanc transparent, texte noir
                    SizedBox(
                      width: 240,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          // Fond blanc semi-transparent
                          backgroundColor: Colors.white.withOpacity(0.5),
                          // Retirer l'ombre par défaut d'ElevatedButton
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Créer un compte',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Bouton "Se connecter" ---
                    // Même taille, fond transparent, bordure blanche et texte blanc + ombre
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 240,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(
                              color: Color(0x6EFFFFFF),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 14),
                          ),
                          child: const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0x6EFFFFFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- Lien "Découvrir l’app sans connexion" ---
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoursesScreen()),
                      ),
                      child: const Text(
                        'Découvrir l’app sans connexion',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xD2E6BF9F), // brun doux
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
