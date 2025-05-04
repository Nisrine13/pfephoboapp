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

  Future<void> deleteCourse(String courseId) async {
    await _firestore.collection('courses').doc(courseId).delete();
    fetchCourses();
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
                    leading: Icon(Icons.book, color: primaryColor),
                    title: Text(
                      course['title'] ?? 'Sans titre',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      course['description'] ?? '',
                      style: TextStyle(color: darkGray),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: importantRed),
                      onPressed: () => deleteCourse(course.id),
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