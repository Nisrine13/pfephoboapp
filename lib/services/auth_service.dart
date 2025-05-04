import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Enregistrement utilisateur avec email/mot de passe
  Future<void> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      // 1. Création du compte dans Firebase Auth
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Vérification que l'utilisateur est bien créé
      if (userCredential.user == null) {
        throw "La création du compte a échoué";
      }

      // 3. Enregistrement dans Firestore avec les mêmes noms de champs que dans SignUpScreen
      await _firestore.collection('Users').doc(userCredential.user!.uid).set({
        'prenom': firstName.trim(),    // Correspond à _firstNameController
        'nom': lastName.trim(),        // Correspond à _lastNameController
        'email': email.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

    } on FirebaseAuthException catch (e) {
      // Gestion spécifique des erreurs d'authentification
      String errorMessage = "Erreur d'inscription";
      if (e.code == 'email-already-in-use') {
        errorMessage = "Cet email est déjà utilisé";
      } else if (e.code == 'weak-password') {
        errorMessage = "Le mot de passe doit contenir au moins 6 caractères";
      }
      throw errorMessage;

    } on FirebaseException catch (e) {
      // Gestion des erreurs Firestore
      throw "Erreur de base de données: ${e.message}";

    } catch (e) {
      // Erreurs générales
      throw "Erreur inattendue: ${e.toString()}";
    }
  }

  // Connexion utilisateur
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Authentification
      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Vérification que l'utilisateur existe
      if (userCredential.user == null) {
        throw "La connexion a échoué";
      }

      // 3. Récupération du rôle depuis Firestore
      final DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw "Profil utilisateur introuvable";
      }

      return {
        'user': userCredential.user,
        'role': userDoc['role'] ?? 'Apprenant', // Valeur par défaut
      };

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Erreur de connexion";
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = "Email ou mot de passe incorrect";
      }
      throw errorMessage;

    } catch (e) {
      throw "Erreur de connexion: ${e.toString()}";
    }
  }

  // Récupération du rôle de l'utilisateur actuel
  Future<String?> getCurrentUserRole() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final DocumentSnapshot userDoc =
      await _firestore.collection('Users').doc(user.uid).get();

      return userDoc['role'] as String?;

    } catch (e) {
      print("Erreur lors de la récupération du rôle: $e");
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }
}