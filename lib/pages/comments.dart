// lib/pages/comments.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({Key? key}) : super(key: key);

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  // Palette « brun / beige / blanc » identique à HomeFormateur
  final Color _beigeWhite   = const Color(0xFFF5F1E8);
  final Color _darkBrown    = const Color(0xFF805D3B);
  final Color _primaryBrown = const Color(0xFFECBF25);
  final Color _white        = Colors.white;
  final Color _white70      = const Color(0xA9FFFFFF);
  final Color _lightGray    = const Color(0xFFEFE8E0);
  final Color _redImportant = const Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _beigeWhite,
      body: StreamBuilder<QuerySnapshot>(
        // 1) Récupérer tous les cours dont authorId == utilisateur actuel
        stream: _firestore
            .collection('courses')
            .where('authorId', isEqualTo: _userId)
            .snapshots(),
        builder: (context, snapCourses) {
          if (snapCourses.hasError) {
            return Center(
              child: Text(
                "Erreur de chargement des cours.",
                style: TextStyle(color: _redImportant),
              ),
            );
          }
          if (!snapCourses.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapCourses.data!.docs;
          if (courses.isEmpty) {
            return Center(
              child: Text(
                "Vous n'avez pas encore créé de cours.",
                style: TextStyle(color: _darkBrown, fontSize: 16),
              ),
            );
          }

          // 2) Pour chaque cours, on affiche un ExpansionTile
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: courses.length,
            itemBuilder: (ctxCourse, indexCourse) {
              final courseDoc  = courses[indexCourse];
              final courseId   = courseDoc.id;
              final courseData = courseDoc.data() as Map<String, dynamic>;
              final courseTitle = courseData['title'] ?? 'Cours sans titre';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ExpansionTile(
                  backgroundColor: _white,
                  collapsedBackgroundColor: _white,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    courseTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkBrown,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12),
                      child: _buildChaptersList(courseId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Affiche tous les chapitres du cours donné : pour chacun, on liste les commentaires
  Widget _buildChaptersList(String courseId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('courses')
          .doc(courseId)
          .collection('chapters')
          .orderBy('index')
          .snapshots(),
      builder: (context, snapChapters) {
        if (snapChapters.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Erreur de chargement des chapitres.",
              style: TextStyle(color: _redImportant),
            ),
          );
        }
        if (!snapChapters.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final chapters = snapChapters.data!.docs;
        if (chapters.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Aucun chapitre dans ce cours.",
              style: TextStyle(color: _darkBrown),
            ),
          );
        }

        // Pour chaque chapitre, on crée un ExpansionTile
        return Column(
          children: chapters.map((chapDoc) {
            final chapterId    = chapDoc.id;
            final chapData     = chapDoc.data() as Map<String, dynamic>;
            final chapterTitle = chapData['title'] ?? 'Chapitre sans titre';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 1,
              child: ExpansionTile(
                backgroundColor: _white,
                collapsedBackgroundColor: _white,
                tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: chapData['videoUrl'] != null && (chapData['videoUrl'] as String).isNotEmpty
                    ? Icon(Icons.play_circle_fill, color: _primaryBrown)
                    : Icon(Icons.videocam_off, color: _darkBrown.withOpacity(0.7)),
                title: Text(
                  chapterTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _darkBrown,
                  ),
                ),
                children: [
                  // Ensuite, on affiche la liste des commentaires de ce chapitre
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    child: _buildCommentsList(courseId, chapterId),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Retourne la liste de tous les commentaires d’un chapitre donné
  Widget _buildCommentsList(String courseId, String chapterId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('courses')
          .doc(courseId)
          .collection('chapters')
          .doc(chapterId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapComments) {
        if (snapComments.hasError) {
          return Text(
            "Erreur de chargement des commentaires.",
            style: TextStyle(color: _redImportant),
          );
        }
        if (!snapComments.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapComments.data!.docs;
        if (comments.isEmpty) {
          return Text(
            "Aucun commentaire.",
            style: TextStyle(color: _darkBrown),
          );
        }

        return Column(
          children: comments.map((cmtDoc) {
            final data      = cmtDoc.data() as Map<String, dynamic>;
            final commenter = data['userName'] ?? 'Utilisateur';
            final content   = data['comment'] ?? '';
            final reply     = data['reply'] as String?; // peut être null ou vide
            final isRead    = data['isReplyRead'] == true;

            // Formatage de la date du commentaire
            final Timestamp ts = data['timestamp'] as Timestamp;
            final dt = ts.toDate();
            final formattedDate =
                "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}";

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                _showCommentDetailSheet(courseId, chapterId, cmtDoc.id, data);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En‐tête : icône, pseudo, date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.comment, color: _primaryBrown, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "$commenter : « ${content.length > 60 ? "${content.substring(0,60)}…" : content} »",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _darkBrown,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 11,
                              color: _darkBrown.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Ligne « → Votre réponse » si déjà existante
                      if (reply != null && reply.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            "→ Votre réponse : ${reply.length > 60 ? "${reply.substring(0,60)}…" : reply}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Icône « lu » / « non lu »
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          isRead ? Icons.check_circle : Icons.markunread,
                          color: isRead ? Colors.green : Colors.red,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Affiche un bottom sheet contenant le commentaire complet, la date, et options « Répondre » / « Supprimer »
  void _showCommentDetailSheet(
      String courseId,
      String chapterId,
      String commentId,
      Map<String, dynamic> data,
      ) {
    final commenter = data['userName'] ?? 'Utilisateur';
    final content   = data['comment'] ?? '';
    final reply     = data['reply'] as String?; // peut être null
    final Timestamp ts = data['timestamp'] as Timestamp;
    final dt = ts.toDate();
    final formattedDate =
        "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}";

    showModalBottomSheet(
      context: context,
      backgroundColor: _beigeWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiret de « poignée » en haut
                Align(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _darkBrown.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // En‐tête : pseudo + date
                Row(
                  children: [
                    Icon(Icons.account_circle, color: _primaryBrown, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        commenter,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkBrown,
                        ),
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: _darkBrown.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contenu du commentaire complet
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    color: _darkBrown.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),

                // Si l’enseignant a déjà répondu, on montre la réponse
                if (reply != null && reply.trim().isNotEmpty) ...[
                  Divider(color: _darkBrown.withOpacity(0.3)),
                  Text(
                    "Votre réponse :",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _darkBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reply,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Boutons « Répondre / Modifier » et « Supprimer »
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        Icons.reply,
                        color: _darkBrown,
                      ),
                      label: Text(
                        reply == null || reply.trim().isEmpty ? "Répondre" : "Modifier",
                        style: TextStyle(color: _darkBrown),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showReplyDialog(courseId, chapterId, commentId);
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: Icon(Icons.delete, color: _redImportant),
                      label: Text(
                        "Supprimer",
                        style: TextStyle(color: _redImportant),
                      ),
                      onPressed: () async {
                        // Supprime le commentaire
                        await _firestore
                            .collection('courses')
                            .doc(courseId)
                            .collection('chapters')
                            .doc(chapterId)
                            .collection('comments')
                            .doc(commentId)
                            .delete();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Commentaire supprimé"),
                            backgroundColor: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog pour répondre ou modifier une réponse à un commentaire donné.
  void _showReplyDialog(String courseId, String chapterId, String commentId) {
    final replyController = TextEditingController();

    // Si une réponse existe déjà, on la pré-remplit
    _firestore
        .collection('courses')
        .doc(courseId)
        .collection('chapters')
        .doc(chapterId)
        .collection('comments')
        .doc(commentId)
        .get()
        .then((snapshot) {
      final d = snapshot.data();
      if (d != null && d['reply'] != null) {
        replyController.text = d['reply'] as String;
      }
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _lightGray,
        title: Text(
          "Répondre au commentaire",
          style: TextStyle(color: _darkBrown),
        ),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(hintText: "Tapez votre réponse…"),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Annuler", style: TextStyle(color: _redImportant)),
          ),
          TextButton(
            onPressed: () async {
              final text = replyController.text.trim();
              if (text.isEmpty) return;

              await _firestore
                  .collection('courses')
                  .doc(courseId)
                  .collection('chapters')
                  .doc(chapterId)
                  .collection('comments')
                  .doc(commentId)
                  .update({
                'reply': text,
                'replyTimestamp': Timestamp.now(),
                'repliedBy': _userId,
                'isReplyRead': false,
              });

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Réponse enregistrée"),
                  backgroundColor: _darkBrown,
                ),
              );
            },
            child: Text("Valider", style: TextStyle(color: _darkBrown)),
          ),
        ],
      ),
    );
  }
}
