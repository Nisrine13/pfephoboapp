import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn();

Future<void> signInWithGoogle(BuildContext context, {String role = "Apprenant"}) async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // L'utilisateur a annulé la connexion

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();

      // S'il n'existe pas encore, on l'ajoute à Firestore
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
          'prenom': user.displayName?.split(' ').first ?? '',
          'nom': user.displayName?.split(' ').skip(1).join(' ') ?? '',
          'email': user.email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion Google réussie')),
      );

      Navigator.pushReplacementNamed(context, '/home'); // Ou '/login' selon ton flow
    }
  } catch (error) {
    print("Erreur lors de la connexion avec Google: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur Google: $error")),
    );
  }
}