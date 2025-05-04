import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../pages/course_details_page.dart';

class HomeApprenant extends StatefulWidget {
  const HomeApprenant({super.key});

  @override
  State<HomeApprenant> createState() => _HomeApprenantState();
}

class _HomeApprenantState extends State<HomeApprenant> {
  String searchQuery = '';
  double selectedRating = 0;

  Future<void> _showRatingDialog(String courseId) async {
    double tempRating = 0;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Évaluer ce cours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisissez une note :'),
            const SizedBox(height: 10),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                tempRating = rating;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Ferme le dialog avant enregistrement
              await _updateRating(courseId, tempRating);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRating(String courseId, double rating) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final ratingRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('ratings')
          .doc(userId);

      await ratingRef.set({'rating': rating});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note enregistrée avec succès.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la notation: $e")),
      );
    }
  }

  Future<double> _calculateAverageRating(String courseId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Apprenant'),
      ),
      body: Container(
        color: const Color(0xFFF4EFFF),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un cours...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('courses').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Erreur lors du chargement des cours"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredCourses = snapshot.data!.docs.where((doc) {
                    final title = (doc['title'] as String).toLowerCase();
                    final description = (doc['description'] as String).toLowerCase();
                    final author = (doc['author'] as String?)?.toLowerCase() ?? '';
                    final category = (doc['category'] as String?)?.toLowerCase() ?? '';

                    return title.contains(searchQuery) ||
                        description.contains(searchQuery) ||
                        author.contains(searchQuery) ||
                        category.contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = filteredCourses[index];
                      final courseId = course.id;

                      return FutureBuilder<double>(
                        future: _calculateAverageRating(courseId),
                        builder: (context, snapshot) {
                          final averageRating = snapshot.data?.toStringAsFixed(1) ?? '0.0';

                          return Card(
                            margin: const EdgeInsets.all(10),
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1E9FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                      course['imageUrl'],
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    course['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    course['description'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 5),
                                  if (course['author'] != null)
                                    Text("Auteur : ${course['author']}"),
                                  if (course['category'] != null)
                                    Text("Catégorie : ${course['category']}"),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CourseDetailsPage(courseId: courseId),
                                            ),
                                          );
                                        },
                                        child: const Text('See cours'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _showRatingDialog(courseId),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber.shade400,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Évaluer'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text('Note moyenne : $averageRating / 5'),
                                ],
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
          ],
        ),
      ),
    );
  }
}
