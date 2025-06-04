// lib/screens/HomeApprenant.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../pages/course_details_page.dart';
import '../pages/notifications_page.dart';
import 'profile_page.dart';

class HomeApprenant extends StatefulWidget {
  const HomeApprenant({Key? key}) : super(key: key);

  @override
  State<HomeApprenant> createState() => _HomeApprenantState();
}

class _HomeApprenantState extends State<HomeApprenant> {
  // Palette marron / beige / blanc
  final Color _beigeWhite = const Color(0xFFF5F1E8);
  final Color _darkBrown = const Color(0xFF805D3B);
  final Color _primaryBrown = const Color(0xFFECBF25);
  final Color _white = Colors.white;
  final Color _white70 = const Color(0xA9FFFFFF);

  // Photo utilisateur
  String? userPhotoUrl;
  final String defaultPhotoPath = 'assets/images/defaultprofil.jpg';

  // Recherche + tri
  String searchQuery = '';
  String _sortCriteria = 'title'; // "title" ou "rating"

  // Score et notifications non lues
  int totalScore = 0;
  int unreadReplies = 0;
  StreamSubscription? _scoreSubscription;

  // Index de l’onglet actif (0=Notifications, 1=Accueil, 2=Profil)
  int _currentIndex = 1; // Par défaut sur "Accueil"

  @override
  void initState() {
    super.initState();
    _fetchUserProfilePhoto();
    _countUnreadReplies();
    _listenToTotalScore();
  }

  @override
  void dispose() {
    _scoreSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          userPhotoUrl = data['photoUrl'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("⚠️ Firestore error in _fetchUserProfilePhoto: $e");
    }
  }

  Future<void> _countUnreadReplies() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('comments')
          .where('userId', isEqualTo: userId)
          .where('reply', isGreaterThan: '')
          .where('isReplyRead', isEqualTo: false)
          .get();
      setState(() {
        unreadReplies = snapshot.docs.length;
      });
    } catch (e) {
      debugPrint("⚠️ Firestore error in _countUnreadReplies: $e");
    }
  }

  void _listenToTotalScore() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    _scoreSubscription = FirebaseFirestore.instance
        .collection('userScores')
        .doc(userId)
        .collection('scores')
        .snapshots()
        .listen((snapshot) {
      int score = 0;
      for (var doc in snapshot.docs) {
        score += (doc['score'] ?? 0) as int;
      }
      setState(() {
        totalScore = score;
      });
    });
  }

  Future<void> _showRatingDialog(String courseId) async {
    double tempRating = 0;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title:
        Text('Évaluer ce cours', style: TextStyle(color: _darkBrown)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choisissez une note :', style: TextStyle(color: _darkBrown)),
            const SizedBox(height: 10),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemBuilder: (context, _) => Icon(Icons.star, color: _primaryBrown),
              onRatingUpdate: (rating) {
                tempRating = rating;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _primaryBrown),
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateRating(courseId, tempRating);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkBrown,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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

      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('ratings')
          .get();
      double total = 0;
      for (var doc in ratingsSnapshot.docs) {
        total += (doc.data()['rating'] ?? 0).toDouble();
      }
      double newAverage = total / ratingsSnapshot.docs.length;
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({
        'averageRating': newAverage,
        'ratingCount': ratingsSnapshot.docs.length,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Note enregistrée avec succès."),
          backgroundColor: _darkBrown,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la notation: $e"),
          backgroundColor: _primaryBrown,
        ),
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

  Widget _buildNotificationsTab() {
    return const NotificationsPage();
  }

  Widget _buildHomeTab() {
    return Container(
      color: _beigeWhite,
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Barre de recherche + critère de tri dans un même Container blanc arrondi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Champ de recherche
                  TextField(
                    onChanged: (value) {
                      setState(() => searchQuery = value.toLowerCase());
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher un cours...',
                      hintStyle: TextStyle(color: _darkBrown),
                      prefixIcon: Icon(Icons.search, color: _darkBrown),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _beigeWhite.withOpacity(0.6),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sélecteur de tri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Trier par :", style: TextStyle(color: _darkBrown)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _beigeWhite.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButton<String>(
                          value: _sortCriteria,
                          dropdownColor: _white, // fond blanc
                          icon: Icon(Icons.arrow_drop_down, color: _darkBrown),
                          underline: const SizedBox.shrink(),
                          style: TextStyle(color: _darkBrown),
                          items: const [
                            DropdownMenuItem(value: 'title', child: Text('Titre (A-Z)')),
                            DropdownMenuItem(value: 'rating', child: Text('Note moyenne')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _sortCriteria = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Liste des cours
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('courses').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Plus aucun texte rouge, juste un loader
                  return Center(
                    child: CircularProgressIndicator(color: _darkBrown),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: _darkBrown));
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

                filteredCourses.sort((a, b) {
                  if (_sortCriteria == 'rating') {
                    double ratingA = (a['averageRating'] ?? 0.0).toDouble();
                    double ratingB = (b['averageRating'] ?? 0.0).toDouble();
                    return ratingB.compareTo(ratingA);
                  } else {
                    String titleA = (a['title'] ?? '').toLowerCase();
                    String titleB = (b['title'] ?? '').toLowerCase();
                    return titleA.compareTo(titleB);
                  }
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredCourses.length,
                  itemBuilder: (context, index) {
                    final course = filteredCourses[index];
                    final courseId = course.id;
                    // on calcule la largeur de la vignette
                    final double w = MediaQuery.of(context).size.width * 0.27;

                    return FutureBuilder<double>(
                      future: _calculateAverageRating(courseId),
                      builder: (context, snapRating) {
                        final averageRating = snapRating.data?.toStringAsFixed(1) ?? '0.0';

                        return InkWell(
                          onTap: () {
                            // Sur un tap sur la carte, on navigue vers les détails
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseDetailsPage(courseId: courseId),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: _white.withOpacity(0.9),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Vignette carrée de côté w
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: course['imageUrl'] != null &&
                                            course['imageUrl'].toString().isNotEmpty
                                            ? Image.network(
                                          course['imageUrl'],
                                          width: w,
                                          height: w, // hauteur = largeur
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                                width: w,
                                                height: w,
                                                color: _beigeWhite.withOpacity(0.5),
                                                child: Icon(Icons.image, color: _darkBrown),
                                              ),
                                        )
                                            : Container(
                                          width: w,
                                          height: w,
                                          color: _beigeWhite.withOpacity(0.5),
                                          child: Icon(Icons.image, color: _darkBrown),
                                        ),
                                      ),

                                      const SizedBox(width: 8), // espace horizontal réduit

                                      // Infos à droite (2/3 largeur)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              course['title'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: _darkBrown,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2), // espacement vertical réduit
                                            Text(
                                              course['description'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _darkBrown.withOpacity(0.8),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.star, color: _primaryBrown, size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  averageRating,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _darkBrown.withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Icône Évaluer (jaune)
                                      IconButton(
                                        onPressed: () => _showRatingDialog(courseId),
                                        icon: Icon(Icons.star, color: _primaryBrown),
                                        splashRadius: 20,
                                        tooltip: 'Évaluer ce cours',
                                      ),
                                    ],
                                  ),
                                  // Les boutons « Voir » et « Évaluer » sont supprimés
                                ],
                              ),
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
    );
  }

  // --- Onglet Profil (index = 2) ---
  Widget _buildProfileTab() {
    return const ProfilePage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildNotificationsTab(),
          SafeArea(child: _buildHomeTab()),
          _buildProfileTab(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: _darkBrown,
        selectedItemColor: _beigeWhite,
        unselectedItemColor: _white70,
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications),
                if (unreadReplies > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '$unreadReplies',
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 0) {
              _countUnreadReplies();
            }
          });
        },
      ),
    );
  }
}
