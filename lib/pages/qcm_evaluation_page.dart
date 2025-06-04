import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QcmEvaluationPage extends StatefulWidget {
  final String courseId;
  final String chapterId;

  const QcmEvaluationPage({
    super.key,
    required this.courseId,
    required this.chapterId,
  });

  @override
  State<QcmEvaluationPage> createState() => _QcmEvaluationPageState();
}

class _QcmEvaluationPageState extends State<QcmEvaluationPage> {
  List<Map<String, dynamic>> questions = [];
  Map<int, int> userAnswers = {};
  bool showResult = false;
  int score = 0;

  final Color primaryColor = const Color(0xFF30B0C7);
  final Color darkGray = const Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('chapters')
        .doc(widget.chapterId)
        .collection('questions')
        .get();

    setState(() {
      questions = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> addUserScoreToGlobalCollection(int score, String courseId, String chapterId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final scoreId = "${courseId}_$chapterId";

    try {
      await FirebaseFirestore.instance
          .collection('userScores')
          .doc(userId)
          .collection('scores')
          .doc(scoreId)
          .set({
        'score': score,
        'courseId': courseId,
        'chapterId': chapterId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("✅ Score global enregistré ou mis à jour : $score");
    } catch (e) {
      print("❌ Erreur en enregistrant le score global : $e");
    }
  }




  void evaluate() {
    score = 0;
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == questions[i]['correctIndex']) {
        score++;
      }
    }
    setState(() {
      showResult = true;
    });

    // Optionnel : enregistrer score
    FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('chapters')
        .doc(widget.chapterId)
        .collection('qcm_results')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({'score': score, 'total': questions.length});

    // ✅ Enregistrement global dans userScores
    addUserScoreToGlobalCollection(score, widget.courseId, widget.chapterId);
  }

  String getFeedbackEmoji() {
    final ratio = score / questions.length;
    if (ratio == 1.0) return "🌟 Parfait !";
    if (ratio >= 0.8) return "👏 Très bien";
    if (ratio >= 0.6) return "🙂 Bien";
    if (ratio >= 0.4) return "😐 Moyen";
    if (ratio >= 0.2) return "😕 Faible";
    return "😞 Très faible";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QCM'),
        backgroundColor: primaryColor,
      ),
      body: questions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (int i = 0; i < questions.length; i++)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Q${i + 1}: ${questions[i]['questionText']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      for (int j = 0; j < 4; j++)
                        RadioListTile<int>(
                          value: j,
                          groupValue: userAnswers[i],
                          onChanged: showResult
                              ? null
                              : (value) {
                            setState(() {
                              userAnswers[i] = value!;
                            });
                          },
                          title: Text(questions[i]['options'][j]),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (!showResult)
              ElevatedButton(
                onPressed: evaluate,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text("Soumettre"),
              ),
            if (showResult)
              Column(
                children: [
                  Text(
                    "Score : $score / ${questions.length}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(getFeedbackEmoji(), style: const TextStyle(fontSize: 32)),
                ],
              )
          ],
        ),
      ),
    );
  }
}
