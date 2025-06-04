// lib/screens/QcmEvaluationPage.dart

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

  // Palette de couleurs
  final Color beigeLight = const Color(0xFFF5F1E8);
  final Color beigeTransparent = const Color(0x80F5F1E8); // 50% opaque
  final Color grayLight = const Color(0xFFF0F0F0);
  final Color grayMedium = const Color(0xFFB0B0B0);
  final Color grayDark = const Color(0xFF757575);
  final Color blackTransparent = const Color(0x6E575454); // 67% opaque
  final Color white = Colors.white;

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
      questions = snapshot.docs.map((doc) {
        final data = doc.data();
        // On s’assure que chaque question contient :
        //   - questionText : String
        //   - options : List<String> de taille 4
        //   - correctIndex : int (0,1,2,3)
        return {
          'questionText': data['questionText'] as String? ?? '',
          'options': List<String>.from(data['options'] ?? []),
          'correctIndex': data['correctIndex'] as int? ?? 0,
        };
      }).toList();
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
    } catch (e) {
      // Vous pouvez logger l’erreur si besoin
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

    // Enregistrement local du résultat du chapitre
    FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('chapters')
        .doc(widget.chapterId)
        .collection('qcm_results')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({'score': score, 'total': questions.length});

    // Enregistrement global
    addUserScoreToGlobalCollection(score, widget.courseId, widget.chapterId);
  }

  String getFeedbackEmoji() {
    final ratio = questions.isEmpty ? 0.0 : score / questions.length;
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
      // Dégradé vertical clair-doux
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [beigeLight, beigeTransparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: questions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              // 1) Titre fixe en haut
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  "Évaluation du Chapitre",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: grayDark,
                  ),
                ),
              ),

              // 2) Zone de questions déroulante
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      for (int i = 0; i < questions.length; i++)
                        _buildQuestionCard(i),
                      const SizedBox(height: 24),
                      if (!showResult)
                        _buildSubmitButton(),
                      if (showResult) _buildResultCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Carte représentant la question n°i
  Widget _buildQuestionCard(int index) {
    final q = questions[index];
    return Card(
      color: white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Texte de la question
            Text(
              "Q${index + 1}. ${q['questionText']}",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: grayDark,
              ),
            ),
            const SizedBox(height: 12),

            // Liste des options
            for (int optIndex = 0; optIndex < 4; optIndex++)
              _buildOptionButton(index, optIndex, q['options'][optIndex]),
          ],
        ),
      ),
    );
  }

  // Bouton stylisé pour chaque option de réponse
  Widget _buildOptionButton(int questionIndex, int optIndex, String text) {
    final isSelected = userAnswers[questionIndex] == optIndex;
    final isDisabled = showResult;

    // Si on affiche le résultat : on colore en vert la bonne réponse, en rouge la mauvaise sélectionnée
    Color backgroundColor;
    Color textColor = grayDark;
    if (showResult) {
      final correctIndex = questions[questionIndex]['correctIndex'] as int;
      if (optIndex == correctIndex) {
        backgroundColor = Colors.green.withOpacity(0.4);
        textColor = Colors.green.shade900;
      } else if (isSelected && optIndex != correctIndex) {
        backgroundColor = Colors.red.withOpacity(0.4);
        textColor = Colors.red.shade900;
      } else {
        backgroundColor = grayLight;
      }
    } else {
      // État normal avant soumission
      backgroundColor = isSelected ? beigeTransparent : grayLight;
    }

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
        setState(() {
          userAnswers[questionIndex] = optIndex;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? grayDark.withOpacity(0.6)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Cercle indiquant la sélection
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: grayMedium, width: 1.5),
                color: isSelected ? grayDark : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: white)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            // Texte de l’option
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bouton “Soumettre” stylisé
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        // S'assurer que toutes les questions ont été répondues
        if (userAnswers.length < questions.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Veuillez répondre à toutes les questions."),
              backgroundColor: blackTransparent,
            ),
          );
          return;
        }
        evaluate();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: grayDark,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: const Text(
        "Soumettre",
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  // Carte de résultat affichée après évaluation
  Widget _buildResultCard() {
    final emoji = getFeedbackEmoji();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: blackTransparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Votre score :",
            style: TextStyle(
              color: white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$score / ${questions.length}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
        ],
      ),
    );
  }
}
