import 'package:firebase_auth/firebase_auth.dart';

class EmailVerifier {
  static Future<bool> verifyEmailExists(String email) async {
    try {
      // Méthode 1: Vérification via Firebase
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://yourappdomain.com/verify', // À remplacer
          handleCodeInApp: true,
          androidPackageName: 'com.your.package',
          iOSBundleId: 'com.your.package.ios',
        ),
      );
      return true;
    } catch (e) {
      // Si l'envoi échoue, l'email est probablement invalide
      return false;
    }
  }

  // Alternative pour la réinitialisation de mot de passe
  static Future<bool> verifyEmailBeforeReset(String email) async {
    try {
      // Tente d'envoyer un lien de réinitialisation
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }
}


