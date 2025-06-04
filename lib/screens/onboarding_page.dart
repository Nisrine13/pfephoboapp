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

      body: Stack(
        fit: StackFit.expand,
        children: [

          const BackgroundVideo(),


          Container(
            color: Colors.black.withOpacity(0.3),
          ),


          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Image.asset(
                      'assets/images/onboarding_image.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 400),

                    SizedBox(
                      width: 240,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        ),
                        style: ElevatedButton.styleFrom(

                          backgroundColor: Colors.white.withOpacity(0.5),
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
