import 'dart:io';
import 'package:flutter/foundation.dart'; // pour kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/supabase_service.dart'; // adapte le chemin si besoin


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
                if (imageUrlController.text.isNotEmpty)
                  Column(
                    children: [
                      Text("Aperçu de l'image :", style: TextStyle(color: darkGray)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrlController.text,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.image);
                    if (result != null && result.files.single.bytes != null) {
                      final file = result.files.single;
                      final url = await SupabaseService().uploadFile(file, 'images/${file.name}', 'images');
                      setState(() {
                        imageUrlController.text = url;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("✅ Image téléchargée"), backgroundColor: primaryColor),
                      );
                    }

                  },
                  icon: Icon(Icons.image, color: Colors.white),
                  label: Text("Choisir une image", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
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
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['mp4', 'mov', 'webm'],
                          );

                          if (result != null && result.files.single.path != null) {
                            final platformFile = result.files.single;
                            final extension = platformFile.name.split('.').last.toLowerCase();

                            if (!['mp4', 'mov', 'webm'].contains(extension)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("❌ Format non supporté"),
                                  backgroundColor: importantRed,
                                ),
                              );
                              return;
                            }

                            final url = await SupabaseService().uploadFile(platformFile, 'videos/${platformFile.name}', 'videos');

                            if (!mounted) return;

                            setState(() {
                              chapterVideos[i].text = url;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("✅ Vidéo du chapitre ${i + 1} uploadée"), backgroundColor: primaryColor),
                            );
                          }
                        },
                        icon: Icon(Icons.video_library, color: Colors.white),
                        label: Text("Choisir une vidéo", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      ),
                      // ✅ Afficher l'URL de la vidéo si présente
                      if (chapterVideos[i].text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0, bottom: 10.0),
                          child: Text(
                            "Vidéo \${i + 1} ajoutée : \${chapterVideos[i].text}",
                            style: TextStyle(color: darkGray, fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 10),
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
    String imageUrl = course['imageUrl'];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: lightGray,
          title: Text('Modifier le cours', style: TextStyle(color: primaryColor)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: titleController, decoration: InputDecoration(labelText: 'Titre')),
                TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
                TextField(controller: categoryController, decoration: InputDecoration(labelText: 'Catégorie')),
                TextField(controller: levelController, decoration: InputDecoration(labelText: 'Niveau')),
                SizedBox(height: 10),
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrl, height: 100),
                  ),
                TextButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.image);
                    if (result != null && result.files.single.bytes != null) {
                      final file = result.files.single;
                      final url = await SupabaseService().uploadFile(file, 'images/${file.name}', 'images');
                      setState(() => imageUrl = url);
                    }
                  },
                  icon: Icon(Icons.image),
                  label: Text("Changer l'image"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('courses').doc(course.id).update({
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'category': categoryController.text,
                  'level': levelController.text,
                  'imageUrl': imageUrl,
                });
                Navigator.pop(context);
                fetchCourses();
              },
              child: Text('Enregistrer'),
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
              'Chapitres du cours : ${course['title']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
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
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  final chapters = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: chapter['videoUrl'] != null
                              ? Icon(Icons.play_circle_filled, color: primaryColor)
                              : Icon(Icons.videocam_off, color: darkGray),
                          title: Text(chapter['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(chapter['summary']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: primaryColor),
                                onPressed: () => _editChapter(course.id, chapter),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: importantRed),
                                onPressed: () => _deleteChapter(course.id, chapter.id),
                              ),
                            ],
                          ),
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
    String videoUrl = chapter['videoUrl'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le chapitre'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Titre')),
              TextField(controller: summaryController, decoration: InputDecoration(labelText: 'Résumé')),
              if (videoUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    children: [
                      Icon(Icons.video_library, color: primaryColor),
                      SizedBox(width: 8),
                      Expanded(child: Text("Vidéo actuelle ajoutée", style: TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['mp4', 'mov', 'webm'],
                  );
                  if (result != null && result.files.single.bytes != null) {
                    final file = result.files.single;
                    final url = await SupabaseService().uploadFile(file, 'videos/${file.name}', 'videos');
                    videoUrl = url;
                  }
                },
                icon: Icon(Icons.upload_file),
                label: Text("Changer la vidéo"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('courses').doc(courseId).collection('chapters').doc(chapter.id).update({
                'title': titleController.text,
                'summary': summaryController.text,
                'videoUrl': videoUrl,
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
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _showChapters(course),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: course['imageUrl'] != null && course['imageUrl'].toString().isNotEmpty
                                ? Image.network(
                              course['imageUrl'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              width: 80,
                              height: 80,
                              color: lightGray,
                              child: Icon(Icons.image_not_supported, color: darkGray),
                            ),
                          ),
                        ),

                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course['title'] ?? 'Sans titre',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                course['description'] ?? '',
                                style: TextStyle(
                                  color: darkGray,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.star, color: accentYellow, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    '${(course['averageRating'] ?? 0.0).toStringAsFixed(1)}/5',
                                    style: TextStyle(color: darkGray),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
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