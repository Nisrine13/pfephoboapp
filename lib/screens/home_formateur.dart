import 'dart:io';
import 'package:flutter/foundation.dart'; // pour kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeFormateur extends StatefulWidget {
  const HomeFormateur({Key? key}) : super(key: key);

  @override
  State<HomeFormateur> createState() => _HomeFormateurState();
}

class _HomeFormateurState extends State<HomeFormateur> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DocumentSnapshot> _courses = [];
  double averageRating = 0.0;

  // Couleurs de la nouvelle palette
  final Color primaryColor = const Color(0xFF30B0C7); // Bleu principal
  final Color accentYellow = const Color(0xFFFFD700); // Jaune pour les accents
  final Color importantRed = const Color(0xFFE53935); // Rouge pour les éléments importants
  final Color lightGray = const Color(0xFFEEEEEE); // Gris clair pour les fonds
  final Color darkGray = const Color(0xFF757575); // Gris foncé pour le texte secondaire

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await _firestore
        .collection('courses')
        .where('authorId', isEqualTo: userId)
        .get();

    double totalRating = 0.0;
    int ratedCourses = 0;

    setState(() {
      _courses = snapshot.docs;
    });

    for (var course in _courses) {
      var rating = course['averageRating'] ?? 0.0;
      if (rating > 0) {
        totalRating += rating;
        ratedCourses++;
      }
    }

    if (ratedCourses > 0) {
      setState(() {
        averageRating = totalRating / ratedCourses;
      });
    }
  }

  Future<void> addCourse() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final levelController = TextEditingController();
    final chaptersCountController = TextEditingController();
    final imageUrlController = TextEditingController();

    List<TextEditingController> chapterTitles = [];
    List<TextEditingController> chapterSummaries = [];
    List<TextEditingController> chapterVideos = [];

    int chapterCount = 0;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: lightGray,
          title: Text('Ajouter un cours', style: TextStyle(color: primaryColor)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Titre du cours',
                    labelStyle: TextStyle(color: darkGray),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: darkGray),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    labelStyle: TextStyle(color: darkGray),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                TextField(
                  controller: levelController,
                  decoration: InputDecoration(
                    labelText: 'Niveau',
                    labelStyle: TextStyle(color: darkGray),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                TextField(
                  controller: chaptersCountController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de chapitres',
                    labelStyle: TextStyle(color: darkGray),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    int count = int.tryParse(value) ?? 0;
                    if (count > 0 && count != chapterCount) {
                      setState(() {
                        chapterCount = count;
                        chapterTitles = List.generate(count, (i) => TextEditingController());
                        chapterSummaries = List.generate(count, (i) => TextEditingController());
                        chapterVideos = List.generate(count, (i) => TextEditingController());
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'URL de l\'image (facultatif)',
                    labelStyle: TextStyle(color: darkGray),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < chapterTitles.length; i++)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: primaryColor),
                      Text("Chapitre ${i + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                      TextField(
                        controller: chapterTitles[i],
                        decoration: InputDecoration(
                          labelText: 'Titre',
                          labelStyle: TextStyle(color: darkGray),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                      TextField(
                        controller: chapterSummaries[i],
                        decoration: InputDecoration(
                          labelText: 'Résumé',
                          labelStyle: TextStyle(color: darkGray),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                      TextField(
                        controller: chapterVideos[i],
                        decoration: InputDecoration(
                          labelText: 'Lien vidéo',
                          labelStyle: TextStyle(color: darkGray),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: importantRed,
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
              onPressed: () async {
                final userId = _auth.currentUser?.uid;
                if (userId == null) return;

                final userDoc = await _firestore.collection('Users').doc(userId).get();
                final firstName = userDoc.data()?['prenom'] ?? 'Inconnu';
                final lastName = userDoc.data()?['nom'] ?? 'Inconnu';
                final authorName = "$firstName $lastName";

                int? chaptersCount = int.tryParse(chaptersCountController.text);
                if (chaptersCount == null || chaptersCount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Nombre de chapitres invalide"),
                        backgroundColor: importantRed,
                      )
                  );
                  return;
                }

                if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Titre et description requis"),
                        backgroundColor: importantRed,
                      )
                  );
                  return;
                }

                for (int i = 0; i < chaptersCount; i++) {
                  if (chapterTitles[i].text.isEmpty || chapterSummaries[i].text.isEmpty || chapterVideos[i].text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Tous les champs de chapitre doivent être remplis"),
                          backgroundColor: importantRed,
                        )
                    );
                    return;
                  }
                }

                try {
                  final docRef = await _firestore.collection('courses').add({
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'category': categoryController.text,
                    'level': levelController.text,
                    'chapterCount': chaptersCount,
                    'imageUrl': imageUrlController.text,
                    'author': authorName,
                    'authorId': userId,
                    'createdAt': DateTime.now(),
                    'averageRating': 0.0,
                    'ratingCount': 0,
                  });

                  for (int i = 0; i < chaptersCount; i++) {
                    await docRef.collection('chapters').add({
                      'title': chapterTitles[i].text,
                      'summary': chapterSummaries[i].text,
                      'videoUrl': chapterVideos[i].text,
                      'index': i,
                      'courseId': docRef.id,
                    });
                  }

                  Navigator.pop(context);
                  await fetchCourses();
                } catch (e) {
                  print("❌ Erreur lors de l'ajout du cours : $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erreur lors de l'ajout du cours."),
                        backgroundColor: importantRed,
                      )
                  );
                }
              },
              child: Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCourse(DocumentSnapshot course) async {
    final titleController = TextEditingController(text: course['title']);
    final descriptionController = TextEditingController(text: course['description']);
    final categoryController = TextEditingController(text: course['category']);
    final levelController = TextEditingController(text: course['level']);
    final imageUrlController = TextEditingController(text: course['imageUrl']);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: lightGray,
          title: Text('Modifier le cours', style: TextStyle(color: primaryColor)),
          content: Container(
            height: MediaQuery.of(context).size.height * 0.6, // Increased height
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Titre du cours',
                      labelStyle: TextStyle(color: darkGray),
                    ),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: darkGray),
                    ),
                  ),
                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      labelStyle: TextStyle(color: darkGray),
                    ),
                  ),
                  TextField(
                    controller: levelController,
                    decoration: InputDecoration(
                      labelText: 'Niveau',
                      labelStyle: TextStyle(color: darkGray),
                    ),
                  ),
                  TextField(
                    controller: imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'URL de l\'image',
                      labelStyle: TextStyle(color: darkGray),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: importantRed),
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () async {
                try {
                  await _firestore.collection('courses').doc(course.id).update({
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'category': categoryController.text,
                    'level': levelController.text,
                    'imageUrl': imageUrlController.text,
                  });
                  Navigator.pop(context);
                  fetchCourses();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erreur lors de la modification"),
                      backgroundColor: importantRed,
                    ),
                  );
                }
              },
              child: Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChapters(DocumentSnapshot course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Text(
              'Chapitres du cours: ${course['title']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('courses')
                    .doc(course.id)
                    .collection('chapters')
                    .orderBy('index')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final chapters = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(chapter['title']),
                          subtitle: Text(chapter['summary']),
                          trailing: chapters.length > 1
                              ? IconButton(
                            icon: Icon(Icons.delete, color: importantRed),
                            onPressed: () => _deleteChapter(course.id, chapter.id),
                          )
                              : null,
                          onTap: () => _editChapter(course.id, chapter),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editChapter(String courseId, DocumentSnapshot chapter) async {
    final titleController = TextEditingController(text: chapter['title']);
    final summaryController = TextEditingController(text: chapter['summary']);
    final videoUrlController = TextEditingController(text: chapter['videoUrl']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le chapitre'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Titre'),
              ),
              TextField(
                controller: summaryController,
                decoration: InputDecoration(labelText: 'Résumé'),
              ),
              TextField(
                controller: videoUrlController,
                decoration: InputDecoration(labelText: 'Lien vidéo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore
                  .collection('courses')
                  .doc(courseId)
                  .collection('chapters')
                  .doc(chapter.id)
                  .update({
                'title': titleController.text,
                'summary': summaryController.text,
                'videoUrl': videoUrlController.text,
              });
              Navigator.pop(context);
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChapter(String courseId, String chapterId) async {
    try {
      // First check how many chapters exist
      final chapters = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('chapters')
          .get();

      if (chapters.docs.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Un cours doit avoir au moins un chapitre'),
            backgroundColor: importantRed,
          ),
        );
        return;
      }

      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('chapters')
          .doc(chapterId)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: importantRed,
        ),
      );
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      // First delete all chapters in subcollection
      final chaptersSnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('chapters')
          .get();

      final batch = _firestore.batch();
      for (var doc in chaptersSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Then delete the course document
      await _firestore.collection('courses').doc(courseId).delete();

      // Refresh the course list
      await fetchCourses();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cours supprimé avec succès"),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print("❌ Erreur lors de la suppression du cours : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la suppression du cours"),
          backgroundColor: importantRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: Text("Espace Formateur", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: addCourse,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: accentYellow),
                SizedBox(width: 8),
                Text(
                  'Moyenne des évaluations : ${averageRating.toStringAsFixed(1)} ★',
                  style: TextStyle(
                    fontSize: 18,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                var course = _courses[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: IconButton(
                      icon: Icon(Icons.book, color: primaryColor),
                      onPressed: () => _showChapters(course),
                    ),
                    title: Text(
                      course['title'] ?? 'Sans titre',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['description'] ?? '',
                          style: TextStyle(color: darkGray),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: accentYellow, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${(course['averageRating'] ?? 0.0).toStringAsFixed(1)}/5',
                              style: TextStyle(
                                color: darkGray,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: primaryColor),
                        onPressed: () => _editCourse(course),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: importantRed),
                        onPressed: () => deleteCourse(course.id),
                      ),
                    ],
                  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}