import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pfephoboapp/pages/qcm_evaluation_page.dart';
import 'package:pfephoboapp/pages/qcm_form_page.dart';
import '../screens/supabase_video_player.dart';

class CourseDetailsPage extends StatefulWidget {
  final String courseId;


  const CourseDetailsPage({super.key, required this.courseId});

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  // Palette de couleurs (identique aux autres pages)
  final Color primaryColor = const Color(0xFF30B0C7); // Bleu principal
  final Color accentYellow = const Color(0xFFFFD700); // Jaune pour les accents
  final Color importantRed = const Color(0xFFE53935); // Rouge pour les éléments importants
  final Color lightGray = const Color(0xFFEEEEEE); // Gris clair pour les fonds
  final Color darkGray = const Color(0xFF757575); // Gris foncé pour le texte secondaire
  final Color white = Colors.white;

  final TextEditingController _commentController = TextEditingController();

  int selectedChapterIndex = 0;
  List<DocumentSnapshot> chapters = [];



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


  bool isSaved = false;
  bool isLoading = false;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cours retiré de vos favoris."),
          backgroundColor: Colors.grey,
        ));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cours enregistré dans votre profil."),
          backgroundColor: primaryColor,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Erreur lors de la sauvegarde : $e"),
        backgroundColor: Colors.red,
      ));
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
      if (chapters.isNotEmpty) {
        _markRepliesAsRead(chapters[0].id);
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    final chapter = chapters.isNotEmpty ? chapters[selectedChapterIndex] : null;
    final data = chapter?.data() as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Cours', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: white),
        leading: BackButton(color: white),
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 100,
            color: lightGray,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == selectedChapterIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedChapterIndex = index;
                          });
                          _markRepliesAsRead(chapters[index].id);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: isSelected ? primaryColor : white,
                                foregroundColor: isSelected ? white : primaryColor,
                                child: Text('${index + 1}'),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Chap ${index + 1}',
                                style: TextStyle(
                                  color: isSelected ? primaryColor : darkGray,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _toggleSaveCourse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(48, 36), // tu peux ajuster la taille
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                  ),
                )
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              color: white,
              padding: const EdgeInsets.all(20),
              child: data == null
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? '',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['summary'] ?? '',
                      style: TextStyle(fontSize: 16, color: darkGray),
                    ),
                    const SizedBox(height: 20),
                    SupabaseVideoPlayer(
                      key: ValueKey(data?['videoUrl']),
                      videoUrl: data['videoUrl'] ?? '',
                      onVideoEnded: () async {
                        final chapterId = chapter?.id;
                        if (chapterId == null) return;

                        final questionsSnapshot = await FirebaseFirestore.instance
                            .collection('courses')
                            .doc(widget.courseId)
                            .collection('chapters')
                            .doc(chapterId)
                            .collection('questions')
                            .get();

                        if (questionsSnapshot.docs.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QcmEvaluationPage(
                                courseId: widget.courseId,
                                chapterId: chapterId,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Aucun QCM disponible pour ce chapitre."),
                              backgroundColor: primaryColor,
                            ),
                          );
                        }
                      },
                    ),
                      const SizedBox(height: 20),
                      Text(
                        "Commentaires",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGray),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('courses')
                            .doc(widget.courseId)
                            .collection('chapters')
                            .doc(chapter!.id)
                            .collection('comments')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                          final comments = snapshot.data!.docs;
                          if (comments.isEmpty) {
                            return Text("Aucun commentaire pour ce chapitre.", style: TextStyle(color: darkGray));
                          }
                          return Column(
                            children: comments.map((doc) {
                            final isAuthor = FirebaseAuth.instance.currentUser?.uid == data?['authorId'];
                            final hasReply = doc.data().toString().contains('reply') &&
                                doc['reply'] != null &&
                                doc['reply'].toString().isNotEmpty;

                            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                            final isOwner = doc['userId'] == currentUserId;
                            final DateTime time = (doc['timestamp'] as Timestamp).toDate();
                            final String formattedDate = "${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute}";


                            final replyController = TextEditingController();

                            return Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              doc['userName'] ?? "Utilisateur",
                                              style: TextStyle(color: lightGray, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),
                                        Text(doc['comment'] ?? "", style: TextStyle(color: white, fontSize: 16)),

                                        if (isOwner)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit, size: 18, color: Colors.white),
                                                onPressed: () async {
                                                  TextEditingController editController = TextEditingController(text: doc['comment']);
                                                  final edited = await showDialog(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: Text('Modifier le commentaire'),
                                                      content: TextField(
                                                        controller: editController,
                                                        decoration: InputDecoration(hintText: 'Votre commentaire'),
                                                      ),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, editController.text.trim()),
                                                          child: Text('Enregistrer'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (edited != null && edited != doc['comment']) {
                                                    await doc.reference.update({'comment': edited});
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete, size: 18, color: Colors.white),
                                                onPressed: () async {
                                                  bool confirm = await showDialog(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: Text('Supprimer'),
                                                      content: Text('Voulez-vous supprimer ce commentaire ?'),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler')),
                                                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Supprimer')),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm) {
                                                    await doc.reference.delete();
                                                  }
                                                },
                                              ),
                                            ],
                                          ),

                                        if (hasReply)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(color: primaryColor),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text("Réponse : ${doc['reply']}", style: TextStyle(color: primaryColor)),
                                            ),
                                          ),
                                        if (isAuthor && !hasReply)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Column(
                                              children: [
                                                TextField(
                                                  controller: replyController,
                                                  decoration: InputDecoration(
                                                    hintText: 'Répondre au commentaire...',
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    final reply = replyController.text.trim();
                                                    if (reply.isNotEmpty) {
                                                      await doc.reference.update({
                                                        'reply': reply,
                                                        'repliedBy': FirebaseAuth.instance.currentUser!.uid,
                                                        'replyTimestamp': Timestamp.now(),
                                                        'isReplyRead': false,
                                                      });
                                                      replyController.clear();
                                                    }
                                                  },
                                                  child: const Text('Envoyer'),
                                                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _commentController,
                        style: TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Ajouter un commentaire...",
                          hintStyle: TextStyle(fontSize: 14),
                          filled: true,
                          fillColor: lightGray,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null || _commentController.text.trim().isEmpty) return;

                      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
                      final userName = "${userDoc['prenom']} ${userDoc['nom']}";

                      await FirebaseFirestore.instance
                          .collection('courses')
                          .doc(widget.courseId)
                          .collection('chapters')
                          .doc(chapter!.id)
                          .collection('comments')
                          .add({
                        'userId': user.uid,
                        'userName': userName,
                        'comment': _commentController.text.trim(),
                        'timestamp': Timestamp.now(),
                      });

                      _commentController.clear();
                    },
                    icon: Icon(Icons.send, size: 16),
                    label: Text("Ajouter", style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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