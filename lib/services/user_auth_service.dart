// lib/services/user_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class UserAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Récupérer l'utilisateur actuel
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Méthode de déconnexion
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Erreur lors de la déconnexion : $e');
    }
  }
}
