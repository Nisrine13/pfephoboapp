// lib/screens/home_formateur.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pfephoboapp/screens/profile_page.dart';

import '../pages/comments.dart';
import '../pages/qcm_form_page.dart';
import '../services/supabase_service.dart';

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

  // Palette brun / beige / blanc transparent
  final Color _beigeWhite   = const Color(0xFFF5F1E8);
  final Color _darkBrown    = const Color(0xFF805D3B);
  final Color _primaryBrown = const Color(0xFFECBF25);
  final Color _white        = Colors.white;
  final Color _white70      = const Color(0xA9FFFFFF);
  final Color _lightGray    = const Color(0xFFEFE8E0); // très clair, nuance beige
  final Color _redImportant = const Color(0xFFE53935);

  int _currentIndex = 1; // 0 = Commentaires, 1 = Accueil, 2 = Profil

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
      final data = course.data() as Map<String, dynamic>;
      var rating = (data['averageRating'] ?? 0.0).toDouble();
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

  // ====================== Accueil Formateur ======================
  Widget _buildHomeTab() {
    return Scaffold(
      backgroundColor: _beigeWhite,
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Carte moyenne des évaluations
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
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
                Icon(Icons.star, color: _primaryBrown),
                const SizedBox(width: 8),
                Text(
                  'Moyenne des évaluations : ${averageRating.toStringAsFixed(1)} ★',
                  style: TextStyle(
                    fontSize: 18,
                    color: _darkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Liste des cours
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                final data = course.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
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
                        // Vignette image du cours (clic ouvre chapitres)
                        GestureDetector(
                          onTap: () => _showChapters(course),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (data['imageUrl'] as String?)?.isNotEmpty == true
                                ? Image.network(
                              data['imageUrl'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              width: 80,
                              height: 80,
                              color: _beigeWhite.withOpacity(0.6),
                              child: Icon(Icons.image_not_supported, color: _darkBrown),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Titre / description / note
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? 'Sans titre',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _darkBrown,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['description'] ?? '',
                                style: TextStyle(
                                  color: _darkBrown.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.star, color: _primaryBrown, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(data['averageRating'] ?? 0.0).toStringAsFixed(1)}/5',
                                    style: TextStyle(color: _darkBrown.withOpacity(0.7)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Boutons “Modifier” + “Supprimer”
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: _darkBrown),
                              onPressed: () => _editCourse(course),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: _redImportant),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: _darkBrown,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: addCourse,
      ),
    );
  }

  // ========== Méthodes auxiliaires pour la gestion des cours ==========

  Future<void> addCourse() async {
    final titleController         = TextEditingController();
    final descriptionController   = TextEditingController();
    final categoryController      = TextEditingController();
    final levelController         = TextEditingController();
    final chaptersCountController = TextEditingController();
    final imageUrlController      = TextEditingController();

    List<TextEditingController> chapterTitles    = [];
    List<TextEditingController> chapterSummaries = [];
    List<TextEditingController> chapterVideos    = [];
    int chapterCount = 0;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: _lightGray,
          title: Text('Ajouter un cours', style: TextStyle(color: _darkBrown)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Champs de saisie
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Titre du cours',
                    labelStyle: TextStyle(color: _darkBrown),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _darkBrown),
                    ),
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: _darkBrown),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _darkBrown),
                    ),
                  ),
                ),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    labelStyle: TextStyle(color: _darkBrown),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _darkBrown),
                    ),
                  ),
                ),
                TextField(
                  controller: levelController,
                  decoration: InputDecoration(
                    labelText: 'Niveau',
                    labelStyle: TextStyle(color: _darkBrown),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _darkBrown),
                    ),
                  ),
                ),
                TextField(
                  controller: chaptersCountController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de chapitres',
                    labelStyle: TextStyle(color: _darkBrown),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _darkBrown),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    int count = int.tryParse(value) ?? 0;
                    if (count > 0 && count != chapterCount) {
                      setState(() {
                        chapterCount = count;
                        chapterTitles    = List.generate(count, (i) => TextEditingController());
                        chapterSummaries = List.generate(count, (i) => TextEditingController());
                        chapterVideos    = List.generate(count, (i) => TextEditingController());
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Aperçu de l’image si URL renseignée
                if (imageUrlController.text.isNotEmpty)
                  Column(
                    children: [
                      Text("Aperçu de l'image :", style: TextStyle(color: _darkBrown)),
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

                // Bouton pour sélectionner une image
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform
                        .pickFiles(withData: true, type: FileType.image);
                    if (result != null && result.files.single.bytes != null) {
                      final file = result.files.single;
                      final url = await SupabaseService()
                          .uploadFile(file, 'images/${file.name}', 'images');
                      setState(() {
                        imageUrlController.text = url;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("✅ Image téléchargée"),
                          backgroundColor: _darkBrown,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: const Text("Choisir une image", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: _darkBrown),
                ),
                const SizedBox(height: 10),

                // Pour chaque chapitre, afficher titre / résumé / bouton vidéo
                for (int i = 0; i < chapterTitles.length; i++)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: _darkBrown),
                      Text("Chapitre ${i + 1}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _darkBrown,
                          )),
                      TextField(
                        controller: chapterTitles[i],
                        decoration: InputDecoration(
                          labelText: 'Titre',
                          labelStyle: TextStyle(color: _darkBrown),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: _darkBrown),
                          ),
                        ),
                      ),
                      TextField(
                        controller: chapterSummaries[i],
                        decoration: InputDecoration(
                          labelText: 'Résumé',
                          labelStyle: TextStyle(color: _darkBrown),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: _darkBrown),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton.icon(
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
                                    content: const Text("❌ Format non supporté"),
                                    backgroundColor: _redImportant,
                                  ),
                                );
                                return;
                              }
                              final url = await SupabaseService()
                                  .uploadFile(platformFile, 'videos/${platformFile.name}', 'videos');
                              if (!mounted) return;
                              setState(() {
                                chapterVideos[i].text = url;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("✅ Vidéo du chapitre ${i + 1} uploadée"),
                                  backgroundColor: _darkBrown,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.video_library, color: Colors.white),
                          label: const Text("Choisir une vidéo", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: _darkBrown),
                        ),
                      ),
                      // Si vidéo présente, afficher URL
                      if (chapterVideos[i].text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0, bottom: 10.0),
                          child: Text(
                            "Vidéo ${i + 1} ajoutée : ${chapterVideos[i].text}",
                            style: TextStyle(
                              color: _darkBrown.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
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
              style: TextButton.styleFrom(foregroundColor: _redImportant),
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _darkBrown),
              onPressed: () async {
                final userId = _auth.currentUser?.uid;
                if (userId == null) return;

                final userDoc = await _firestore.collection('Users').doc(userId).get();
                final firstName = userDoc.data()?['prenom'] ?? 'Inconnu';
                final lastName  = userDoc.data()?['nom'] ?? 'Inconnu';
                final authorName = "$firstName $lastName";

                final int? chaptersCount = int.tryParse(chaptersCountController.text);
                if (chaptersCount == null || chaptersCount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Nombre de chapitres invalide"),
                      backgroundColor: _redImportant,
                    ),
                  );
                  return;
                }
                if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Titre et description requis"),
                      backgroundColor: _redImportant,
                    ),
                  );
                  return;
                }
                for (int i = 0; i < chaptersCount; i++) {
                  if (chapterTitles[i].text.isEmpty
                      || chapterSummaries[i].text.isEmpty
                      || chapterVideos[i].text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Tous les champs de chapitre doivent être remplis"),
                        backgroundColor: _redImportant,
                      ),
                    );
                    return;
                  }
                }

                try {
                  // Créer le document du cours
                  final docRef = await _firestore.collection('courses').add({
                    'title'         : titleController.text,
                    'description'   : descriptionController.text,
                    'category'      : categoryController.text,
                    'level'         : levelController.text,
                    'chapterCount'  : chaptersCount,
                    'imageUrl'      : imageUrlController.text,
                    'author'        : authorName,
                    'authorId'      : userId,
                    'createdAt'     : DateTime.now(),
                    'averageRating' : 0.0,
                    'ratingCount'   : 0,
                  });
                  // Créer chaque chapitre
                  for (int i = 0; i < chaptersCount; i++) {
                    await docRef.collection('chapters').add({
                      'title'     : chapterTitles[i].text,
                      'summary'   : chapterSummaries[i].text,
                      'videoUrl'  : chapterVideos[i].text,
                      'index'     : i,
                      'courseId'  : docRef.id,
                    });
                  }
                  Navigator.pop(context);
                  await fetchCourses();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Erreur lors de l'ajout du cours."),
                      backgroundColor: _redImportant,
                    ),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCourse(DocumentSnapshot course) async {
    final titleController       = TextEditingController(text: (course.data() as Map)['title']);
    final descriptionController = TextEditingController(text: (course.data() as Map)['description']);
    final categoryController    = TextEditingController(text: (course.data() as Map)['category']);
    final levelController       = TextEditingController(text: (course.data() as Map)['level']);
    String imageUrl = (course.data() as Map)['imageUrl'] ?? '';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: _lightGray,
          title: Text('Modifier le cours', style: TextStyle(color: _darkBrown)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titre')),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Catégorie')),
                TextField(controller: levelController, decoration: const InputDecoration(labelText: 'Niveau')),
                const SizedBox(height: 10),
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
                      final url = await SupabaseService()
                          .uploadFile(file, 'images/${file.name}', 'images');
                      setState(() => imageUrl = url);
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("Changer l'image"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('courses').doc(course.id).update({
                  'title'       : titleController.text,
                  'description' : descriptionController.text,
                  'category'    : categoryController.text,
                  'level'       : levelController.text,
                  'imageUrl'    : imageUrl,
                });
                Navigator.pop(context);
                fetchCourses();
              },
              style: ElevatedButton.styleFrom(backgroundColor: _darkBrown),
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
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
        color: _beigeWhite,
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Text(
              'Chapitres : ${(course.data() as Map)['title']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkBrown,
              ),
            ),
            const Divider(color: Colors.grey),
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  final chapters = snapshot.data!.docs;
                  if (chapters.isEmpty) {
                    return Center(
                      child: Text(
                        "Aucun chapitre pour ce cours",
                        style: TextStyle(color: _darkBrown.withOpacity(0.7)),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      final chData  = chapter.data() as Map<String, dynamic>;
                      return Card(
                        color: _white,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: chData['videoUrl'] != null
                              ? Icon(Icons.play_circle_filled, color: _primaryBrown)
                              : Icon(Icons.videocam_off, color: _darkBrown.withOpacity(0.7)),
                          title: Text(
                            chData['title'],
                            style: TextStyle(fontWeight: FontWeight.bold, color: _darkBrown),
                          ),
                          subtitle: Text(
                            chData['summary'] ?? '',
                            style: TextStyle(color: _darkBrown.withOpacity(0.8)),
                          ),
                          children: [
                            // Boutons Modifier / Supprimer le chapitre
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: _darkBrown),
                                  tooltip: "Modifier le chapitre",
                                  onPressed: () => _editChapter(course.id, chapter),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: _redImportant),
                                  tooltip: "Supprimer le chapitre",
                                  onPressed: () => _deleteChapter(course.id, chapter.id),
                                ),
                              ],
                            ),
                            // QCM de ce chapitre
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('courses')
                                  .doc(course.id)
                                  .collection('chapters')
                                  .doc(chapter.id)
                                  .collection('questions')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final questions = snapshot.data!.docs;
                                if (questions.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Aucun QCM disponible",
                                      style: TextStyle(color: _darkBrown.withOpacity(0.7)),
                                    ),
                                  );
                                }
                                return Column(
                                  children: questions.map((q) {
                                    final qData = q.data() as Map<String, dynamic>;
                                    return ListTile(
                                      tileColor: _beigeWhite.withOpacity(0.6),
                                      title: Text(
                                        qData['questionText'] ?? '',
                                        style: TextStyle(color: _darkBrown),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: List.generate(qData['options'].length, (i) {
                                          final isCorrect = i == qData['correctIndex'];
                                          return Text(
                                            "${String.fromCharCode(65 + i)}. ${qData['options'][i]}",
                                            style: TextStyle(
                                              fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                              color: isCorrect ? Colors.green : _darkBrown.withOpacity(0.8),
                                            ),
                                          );
                                        }),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: _redImportant),
                                        onPressed: () async {
                                          await _firestore
                                              .collection('courses')
                                              .doc(course.id)
                                              .collection('chapters')
                                              .doc(chapter.id)
                                              .collection('questions')
                                              .doc(q.id)
                                              .delete();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("QCM supprimé")),
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QcmFormPage(
                                      courseId: course.id,
                                      chapterId: chapter.id,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.quiz, color: _darkBrown),
                              label: Text(
                                "Ajouter / Modifier QCM",
                                style: TextStyle(color: _darkBrown),
                              ),
                            ),
                            // Commentaires de ce chapitre
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('courses')
                                  .doc(course.id)
                                  .collection('chapters')
                                  .doc(chapter.id)
                                  .collection('comments')
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final comments = snapshot.data!.docs;
                                if (comments.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Aucun commentaire pour ce chapitre.",
                                      style: TextStyle(color: _darkBrown.withOpacity(0.7)),
                                    ),
                                  );
                                }
                                return Column(
                                  children: comments.map((commentDoc) {
                                    final data = commentDoc.data() as Map<String, dynamic>;
                                    return Card(
                                      color: _white.withOpacity(0.9),
                                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${data['userName'] ?? 'Utilisateur'} : ${data['comment']}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: _darkBrown,
                                              ),
                                            ),
                                            if (data['reply'] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(
                                                  "→ Votre réponse : ${data['reply']}",
                                                  style: TextStyle(color: Colors.green[800]),
                                                ),
                                              ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                if (data['reply'] == null)
                                                  TextButton.icon(
                                                    onPressed: () => _replyToComment(
                                                      course.id,
                                                      chapter.id,
                                                      commentDoc.id,
                                                      data['userId'],
                                                    ),
                                                    label: Text(
                                                      "Répondre",
                                                      style: TextStyle(color: _darkBrown),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
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
    final titleController   = TextEditingController(text: (chapter.data() as Map)['title']);
    final summaryController = TextEditingController(text: (chapter.data() as Map)['summary']);
    String videoUrl         = (chapter.data() as Map)['videoUrl'] ?? '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier le chapitre'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titre')),
                TextField(controller: summaryController, decoration: const InputDecoration(labelText: 'Résumé')),
                if (videoUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      children: [
                        Icon(Icons.video_library, color: _darkBrown),
                        const SizedBox(width: 8),
                        const Expanded(child: Text("Vidéo actuelle ajoutée", style: TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
                TextButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['mp4', 'mov', 'webm'],
                      withData: true,
                    );
                    if (result != null && result.files.single.bytes != null) {
                      final file = result.files.single;
                      final url = await SupabaseService()
                          .uploadFile(file, 'videos/${file.name}', 'videos');
                      setState(() {
                        videoUrl = url;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("✅ Vidéo téléversée avec succès."),
                          backgroundColor: _darkBrown,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Changer la vidéo"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                await _firestore
                    .collection('courses')
                    .doc(courseId)
                    .collection('chapters')
                    .doc(chapter.id)
                    .update({
                  'title'    : titleController.text,
                  'summary'  : summaryController.text,
                  'videoUrl' : videoUrl,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _darkBrown),
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteChapter(String courseId, String chapterId) async {
    try {
      final chapters = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('chapters')
          .get();
      if (chapters.docs.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Un cours doit avoir au moins un chapitre'),
            backgroundColor: _redImportant,
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
          content: Text('Erreur lors de la suppression : $e'),
          backgroundColor: _redImportant,
        ),
      );
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
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

      await _firestore.collection('courses').doc(courseId).delete();
      await fetchCourses();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Cours supprimé avec succès"),
          backgroundColor: _darkBrown,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Erreur lors de la suppression du cours"),
          backgroundColor: _redImportant,
        ),
      );
    }
  }

  // ========== Répondre / modifier réponse à un commentaire ==========
  void _replyToComment(String courseId, String chapterId, String commentId, String userId) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Répondre au commentaire"),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(hintText: "Votre réponse..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: TextStyle(color: _redImportant)),
          ),
          TextButton(
            onPressed: () async {
              final replyText = replyController.text.trim();
              if (replyText.isNotEmpty) {
                await _firestore
                    .collection('courses')
                    .doc(courseId)
                    .collection('chapters')
                    .doc(chapterId)
                    .collection('comments')
                    .doc(commentId)
                    .update({
                  'reply'         : replyText,
                  'replyTimestamp': Timestamp.fromDate(DateTime.now()),
                  'repliedBy'     : _auth.currentUser!.uid,
                  'isReplyRead'   : false,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Réponse envoyée avec succès.")),
                );
              }
            },
            child: Text("Envoyer", style: TextStyle(color: _darkBrown)),
          ),
        ],
      ),
    );
  }

  // ========== Construction de l’interface à onglets ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Onglet 0 = Commentaires
          const CommentsPage(),

          // Onglet 1 = Accueil Formateur
          _buildHomeTab(),

          // Onglet 2 = Profil
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: _darkBrown,
        selectedItemColor: _beigeWhite,
        unselectedItemColor: _white70,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.comment),
            label: 'Commentaires',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
