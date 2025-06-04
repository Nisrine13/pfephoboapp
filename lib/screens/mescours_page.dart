// lib/screens/MesCoursPage.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages/course_details_page.dart';

class MesCoursPage extends StatefulWidget {
  const MesCoursPage({super.key});

  @override
  State<MesCoursPage> createState() => _MesCoursPageState();
}

class _MesCoursPageState extends State<MesCoursPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color primaryColor = const Color(0xFF30B0C7);
  final Color darkGray     = const Color(0xFF757575);
  final Color white        = Colors.white;
  final Color lightGray    = const Color(0xFFEEEEEE);

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes cours enregistrés", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .doc(user!.uid)
              .collection('savedCourses')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Erreur: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final savedDocs = snapshot.data!.docs;
            if (savedDocs.isEmpty) {
              return Center(
                child: Text(
                  "Vous n'avez pas encore enregistré de cours.",
                  style: TextStyle(color: darkGray, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              itemCount: savedDocs.length,
              itemBuilder: (context, index) {
                final docCours = savedDocs[index];
                final String courseId = docCours['courseId'] as String? ?? '';
                final String title    = docCours['title']    as String? ?? 'Cours';

                return FutureBuilder<double>(
                  future: _computeAverageScore(courseId),
                  builder: (context, snapshotScore) {
                    String avgScoreText = "--";
                    if (snapshotScore.connectionState == ConnectionState.waiting) {
                      avgScoreText = "…";
                    } else if (snapshotScore.hasError) {
                      avgScoreText = "erreur";
                    } else {
                      final val = snapshotScore.data ?? 0.0;
                      avgScoreText = val.toStringAsFixed(1);
                    }

                    return Card(
                      color: white,
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            "Score moyen : $avgScoreText / 10",
                            style: TextStyle(color: darkGray, fontSize: 14),
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseDetailsPage(courseId: courseId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text(
                            "Voir",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<double> _computeAverageScore(String courseId) async {
    final userId = user!.uid;

    // Récupère tous les documents de scores pour cet utilisateur où 'courseId' = courseId
    final querySnapshot = await FirebaseFirestore.instance
        .collection('userScores')
        .doc(userId)
        .collection('scores')
        .where('courseId', isEqualTo: courseId)
        .get();

    final docs = querySnapshot.docs;
    if (docs.isEmpty) return 0.0;

    double sum = 0;
    for (var doc in docs) {
      final s = doc.data()['score'];
      if (s is int) {
        sum += s.toDouble();
      } else if (s is double) {
        sum += s;
      }
    }
    return sum / docs.length;
  }
}
