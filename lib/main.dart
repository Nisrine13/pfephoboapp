import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/onboarding_page.dart';
import 'screens/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialisé avec le projet: ${Firebase.app().options.projectId}");
  } catch (e) {
    print("ERREUR Firebase: ${e.toString()}");
  }
  try {
    await supa.Supabase.initialize(
      url: 'https://gclrqmbzfecsfldqmimj.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjbHJxbWJ6ZmVjc2ZsZHFtaW1qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0NzY2NDQsImV4cCI6MjA2MzA1MjY0NH0.23rXSWEFxfQNOFpTlJHMQY-40wfQXrgH-pSpRGHxnJU',
    );
    print("✅ Supabase initialisé");
  } catch (e) {
    print("ERREUR Supabase: ${e.toString()}");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phobo App',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        useMaterial3: true,
      ),
      // Toujours afficher OnboardingPage en premier
      home: const OnboardingPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/signup': (context) => const SignUpWithVerificationWrapper(),
      },
    );
  }
}

class SignUpWithVerificationWrapper extends StatefulWidget {
  const SignUpWithVerificationWrapper({super.key});

  @override
  State<SignUpWithVerificationWrapper> createState() => _SignUpWithVerificationWrapperState();
}

class _SignUpWithVerificationWrapperState extends State<SignUpWithVerificationWrapper> {
  @override
  void initState() {
    super.initState();
    _initDynamicLinks();
  }

  void _initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      _handleEmailLink(dynamicLinkData.link.toString());
    });

    final PendingDynamicLinkData? initialLink =
    await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      _handleEmailLink(initialLink.link.toString());
    }
  }

  Future<void> _handleEmailLink(String link) async {
    if (FirebaseAuth.instance.isSignInWithEmailLink(link)) {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('verificationEmail');

      if (storedEmail == null) return;

      try {
        await FirebaseAuth.instance.signInWithEmailLink(
          email: storedEmail,
          emailLink: link,
        );

        // Après vérification réussie, retour à l'onboarding
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const OnboardingPage()),
                (route) => false,
          );
        }
      } catch (e) {
        print('Erreur de vérification : $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de vérification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si l'utilisateur est déjà connecté et vérifié
        if (snapshot.hasData && snapshot.data!.emailVerified) {
          return const OnboardingPage();
        }

        // Sinon, afficher l'écran d'inscription normal
        return const SignUpScreen();
      },
    );
  }
}