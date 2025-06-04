// lib/screens/CourseDetailsPage.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pfephoboapp/pages/qcm_evaluation_page.dart';
import '../screens/supabase_video_player.dart';

class CourseDetailsPage extends StatefulWidget {
  final String courseId;

  const CourseDetailsPage({super.key, required this.courseId});

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  // Palette de couleurs
  final Color primaryColor = const Color(0xFF6A2E05);    // brun foncé
  final Color accentYellow = const Color(0xD0805D3B);    // jaune
  final Color importantRed = const Color(0xFFE53935);    // rouge pour suppression
  final Color lightGray = const Color(0xFFEEEEEE);       // gris clair pour fond d'input
  final Color darkGray = const Color(0xFF757575);        // gris foncé pour textes secondaires
  final Color white = Colors.white;

  final TextEditingController _commentController = TextEditingController();

  int selectedChapterIndex = 0;
  List<DocumentSnapshot> chapters = [];
  bool isSaved = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchChapters();
    checkIfSaved();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('savedCourses')
        .doc(widget.courseId)
        .get();
    setState(() {
      isSaved = doc.exists;
    });
  }

  Future<void> _toggleSaveCourse() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || isLoading) return;
    setState(() => isLoading = true);
    try {
      final docRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('savedCourses')
          .doc(widget.courseId);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
        setState(() {
          isSaved = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cours retiré de vos favoris."),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        final courseDoc = await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .get();
        await docRef.set({
          'courseId': widget.courseId,
          'title': courseDoc['title'] ?? '',
          'timestamp': Timestamp.now(),
        });
        setState(() {
          isSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Cours enregistré dans votre profil."),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la sauvegarde : $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchChapters() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('chapters')
        .orderBy('index')
        .get();
    setState(() {
      chapters = snapshot.docs;
    });
    if (chapters.isNotEmpty) {
      _markRepliesAsRead(chapters[0].id);
    }
  }

  void _markRepliesAsRead(String chapterId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('chapters')
        .doc(chapterId)
        .collection('comments')
        .where('userId', isEqualTo: userId)
        .where('reply', isGreaterThan: '')
        .where('isReplyRead', isEqualTo: false)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({'isReplyRead': true});
    }
  }

  void _goToPreviousChapter() {
    if (selectedChapterIndex > 0) {
      setState(() {
        selectedChapterIndex--;
      });
      _markRepliesAsRead(chapters[selectedChapterIndex].id);
    }
  }

  void _goToNextChapter() {
    if (selectedChapterIndex < chapters.length - 1) {
      setState(() {
        selectedChapterIndex++;
      });
      _markRepliesAsRead(chapters[selectedChapterIndex].id);
    }
  }

  Future<double> _calculateAverageRating(
      String courseId, String chapterId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('chapters')
        .doc(chapterId)
        .collection('ratings')
        .get();
    if (snapshot.docs.isEmpty) return 0.0;
    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['rating'] ?? 0).toDouble();
    }
    return total / snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return Scaffold(
        backgroundColor: white,
        appBar: AppBar(
          backgroundColor: white,
          automaticallyImplyLeading: false,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: primaryColor,
              ),
              onPressed: _toggleSaveCourse,
            )
          ],
        ),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final chapter = chapters[selectedChapterIndex];
    final data = chapter.data() as Map<String, dynamic>;
    final String? chapterAuthorId = (data['authorId'] as String?);

    // largeur vidéo = largeur écran - 10 pixels
    final screenWidth = MediaQuery.of(context).size.width;
    final videoWidth = screenWidth - 10;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: primaryColor,
            ),
            onPressed: _toggleSaveCourse,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) Titre du chapitre
            Text(
              data['title'] ?? '',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 10),

            // 2) Vidéo avec cadre arrondi
            Center(
              child: Container(
                width: videoWidth,
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: SupabaseVideoPlayer(
                  key: ValueKey(data['videoUrl']),
                  videoUrl: data['videoUrl'] ?? '',
                  onVideoEnded: () async {
                    final questionsSnapshot = await FirebaseFirestore.instance
                        .collection('courses')
                        .doc(widget.courseId)
                        .collection('chapters')
                        .doc(chapter.id)
                        .collection('questions')
                        .get();

                    if (questionsSnapshot.docs.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QcmEvaluationPage(
                            courseId: widget.courseId,
                            chapterId: chapter.id,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                          const Text("Aucun QCM disponible pour ce chapitre."),
                          backgroundColor: primaryColor,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3) Boutons Précédent / Suivant (icônes YouTube)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed:
                  selectedChapterIndex > 0 ? _goToPreviousChapter : null,
                  iconSize: 35,
                  icon: Icon(
                    Icons.skip_previous_rounded,
                    color: selectedChapterIndex > 0
                        ? primaryColor
                        : primaryColor.withOpacity(0.4),
                  ),
                ),
                IconButton(
                  onPressed: selectedChapterIndex < chapters.length - 1
                      ? _goToNextChapter
                      : null,
                  iconSize: 35,
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: selectedChapterIndex < chapters.length - 1
                        ? primaryColor
                        : primaryColor.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4) Résumé du chapitre
            Text(
              data['summary'] ?? '',
              style: TextStyle(fontSize: 16, color: darkGray),
            ),
            const SizedBox(height: 20),

            // 5) Section Commentaires
            Text(
              "Commentaires",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkGray,
              ),
            ),
            const SizedBox(height: 10),

            // 5.1) Liste des commentaires
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(widget.courseId)
                  .collection('chapters')
                  .doc(chapter.id)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final comments = snapshot.data!.docs;
                if (comments.isEmpty) {
                  return Text(
                    "Aucun commentaire pour ce chapitre.",
                    style: TextStyle(color: darkGray),
                  );
                }
                return Column(
                  children: comments.map((doc) {
                    final dataComm = doc.data() as Map<String, dynamic>;
                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;
                    final isOwner = dataComm['userId'] == currentUserId;
                    final hasReply = dataComm.containsKey('reply') &&
                        (dataComm['reply'] as String).isNotEmpty;

                    // On récupère l’URL de la photo du commentateur
                    final String? userPhotoUrl =
                    dataComm['userPhotoUrl'] as String?; // doit exister en base
                    final DateTime time =
                    (dataComm['timestamp'] as Timestamp).toDate();
                    final String formattedDate =
                        "${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute}";

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1), // marron très transparent
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Ligne du titre du commentaire (avatar, nom + date) ---
                          Row(
                            children: [
                              // Avatar circulaire
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                                    ? Image.network(
                                  userPhotoUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                    width: 40,
                                    height: 40,
                                    color: lightGray,
                                    child: Icon(
                                      Icons.person,
                                      color: primaryColor,
                                    ),
                                  ),
                                )
                                    : Container(
                                  width: 40,
                                  height: 40,
                                  color: lightGray,
                                  child: Icon(
                                    Icons.person,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Nom + prénom
                              Expanded(
                                child: Text(
                                  dataComm['userName'] ?? "Utilisateur",
                                  style: TextStyle(
                                    color: darkGray,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),

                              // Date à droite
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: darkGray.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // --- Texte du commentaire (occupe la largeur entière) ---
                          Text(
                            dataComm['comment'] ?? "",
                            style: TextStyle(color: darkGray, fontSize: 15),
                          ),

                          const SizedBox(height: 2),

                          // --- Icônes Modifier / Supprimer alignées à droite sous la date ---
                          if (isOwner)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_rounded,
                                      size: 17,
                                      color: Colors.grey.shade700,
                                    ),
                                    onPressed: () async {
                                      final editController =
                                      TextEditingController(text: dataComm['comment']);
                                      final edited = await showDialog<String>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: white,
                                          title: Text(
                                            'Modifier le commentaire',
                                            style: TextStyle(color: darkGray),
                                          ),
                                          content: TextField(
                                            controller: editController,
                                            decoration: const InputDecoration(
                                                hintText: 'Votre commentaire'),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, null),
                                              child: Text(
                                                'Annuler',
                                                style:
                                                TextStyle(color: primaryColor),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  context, editController.text.trim()),
                                              child: Text(
                                                'Enregistrer',
                                                style:
                                                TextStyle(color: primaryColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (edited != null &&
                                          edited != dataComm['comment']) {
                                        await doc.reference.update({'comment': edited});
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_rounded,
                                      size: 17,
                                      color: importantRed,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: white,
                                          title: Text('Supprimer',
                                              style: TextStyle(color: darkGray)),
                                          content: const Text(
                                              'Voulez-vous supprimer ce commentaire ?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(
                                                'Annuler',
                                                style:
                                                TextStyle(color: primaryColor),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(
                                                'Supprimer',
                                                style:
                                                TextStyle(color: primaryColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await doc.reference.delete();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 8),

                          // --- Section “Réponse” (si existante) placée en bas à droite ---
                          if (hasReply)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Réponse : ${dataComm['reply']}",
                                  style: TextStyle(
                                      color: accentYellow, fontSize: 14),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // 6) Champ “Ajouter un commentaire” + bouton send sur la même ligne
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Ajouter un commentaire…",
                      hintStyle: TextStyle(color: darkGray.withOpacity(0.7)),
                      filled: true,
                      fillColor: lightGray,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null ||
                        _commentController.text.trim().isEmpty) return;

                    final userDoc = await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(user.uid)
                        .get();
                    final userName = "${userDoc['prenom']} ${userDoc['nom']}";
                    final userPhotoUrl = userDoc['photoUrl'] ?? '';

                    await FirebaseFirestore.instance
                        .collection('courses')
                        .doc(widget.courseId)
                        .collection('chapters')
                        .doc(chapter.id)
                        .collection('comments')
                        .add({
                      'userId': user.uid,
                      'userName': userName,
                      'userPhotoUrl': userPhotoUrl, // URL de l’avatar
                      'comment': _commentController.text.trim(),
                      'timestamp': Timestamp.now(),
                      'reply': '',
                      'isReplyRead': false,
                    });

                    _commentController.clear();
                    setState(() {}); // pour rafraîchir
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Icon(Icons.send, size: 20, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
