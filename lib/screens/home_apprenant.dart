import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../pages/course_details_page.dart';
import '../pages/notifications_page.dart';
import 'profile_page.dart';

class HomeApprenant extends StatefulWidget {
  const HomeApprenant({super.key});

  @override
  State<HomeApprenant> createState() => _HomeApprenantState();
}

class _HomeApprenantState extends State<HomeApprenant> {
  final Color primaryColor = const Color(0xFF30B0C7);
  final Color accentYellow = const Color(0xFFFFD700);
  final Color importantRed = const Color(0xFFE53935);
  final Color lightGray = const Color(0xFFEEEEEE);
  final Color darkGray = const Color(0xFF757575);
  final Color white = Colors.white;

  String? userPhotoUrl;
  final String defaultPhotoPath = 'assets/images/defaultprofil.jpg';


  String searchQuery = '';
  double selectedRating = 0;

  int totalScore = 0;
  int unreadReplies = 0;


  String _sortCriteria = 'title'; // title | rating

  @override
  void initState() {
    super.initState();
    _fetchUserProfilePhoto();
    _fetchTotalScore();
    _countUnreadReplies();
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
      print("⚠️ Firestore error in _countUnreadReplies: $e");
    }
  }



  Future<void> _fetchTotalScore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('userScores')
          .where('userId', isEqualTo: userId)
          .get();

      int score = 0;
      for (var doc in snapshot.docs) {
        score += (doc['score'] ?? 0) as int;
      }

      setState(() {
        totalScore = score;
      });
    } catch (e) {
      print("⚠️ Firestore error in _fetchTotalScore: $e");
    }
  }


  Future<void> _fetchUserProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
        final data = doc.data();
        if (data != null) {
          setState(() {
            userPhotoUrl = data['photoUrl'] ?? '';
          });
          print("USER PHOTO URL => $userPhotoUrl");
        }
      } catch (e) {
        print("⚠️ Firestore error in _fetchUserProfilePhoto: $e");
      }
    }
  }



  Future<void> _showRatingDialog(String courseId) async {
    double tempRating = 0;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: white,
        title: Text('Évaluer ce cours', style: TextStyle(color: primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choisissez une note :', style: TextStyle(color: darkGray)),
            const SizedBox(height: 10),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemBuilder: (context, _) => Icon(Icons.star, color: accentYellow),
              onRatingUpdate: (rating) {
                tempRating = rating;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: importantRed),
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateRating(courseId, tempRating);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: white,
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
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la notation: $e"),
          backgroundColor: importantRed,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: const Text('Espace Apprenant', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: white),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: lightGray,
                backgroundImage: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                    ? NetworkImage(userPhotoUrl!)
                    : AssetImage(defaultPhotoPath) as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Row(
              children: [
                Column(
                  children: [
                    Icon(Icons.monetization_on, color: accentYellow, size: 36),
                    const SizedBox(height: 4),
                    Text(
                      "$totalScore",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationsPage()),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.message, color: primaryColor, size: 30),
                      if (unreadReplies > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$unreadReplies',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                hintStyle: TextStyle(color: darkGray),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                filled: true,
                fillColor: white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Trier par :", style: TextStyle(color: darkGray)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortCriteria,
                  icon: const Icon(Icons.arrow_drop_down),
                  underline: Container(height: 0),
                  items: const [
                    DropdownMenuItem(
                      value: 'title',
                      child: Text('Titre (A-Z)'),
                    ),
                    DropdownMenuItem(
                      value: 'rating',
                      child: Text('Note moyenne'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortCriteria = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('courses').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Erreur lors du chargement des cours",
                      style: TextStyle(color: importantRed),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
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
                    return ratingB.compareTo(ratingA); // du plus grand au plus petit
                  } else {
                    String titleA = (a['title'] ?? '').toLowerCase();
                    String titleB = (b['title'] ?? '').toLowerCase();
                    return titleA.compareTo(titleB); // A-Z
                  }
                });


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
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (course['imageUrl'] != null && course['imageUrl'].toString().isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                      course['imageUrl'],
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                            height: 150,
                                            color: lightGray,
                                            child: Icon(Icons.image, color: darkGray),
                                          ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Text(
                                  course['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  course['description'],
                                  style: TextStyle(fontSize: 14, color: darkGray),
                                ),
                                const SizedBox(height: 5),
                                if (course['author'] != null)
                                  Text(
                                    "Auteur : ${course['author']}",
                                    style: TextStyle(color: darkGray),
                                  ),
                                if (course['category'] != null)
                                  Text(
                                    "Catégorie : ${course['category']}",
                                    style: TextStyle(color: darkGray),
                                  ),
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: white,
                                      ),
                                      child: const Text('Voir le cours'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _showRatingDialog(courseId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentYellow,
                                        foregroundColor: white,
                                      ),
                                      child: const Text('Évaluer'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: accentYellow, size: 20),
                                    SizedBox(width: 5),
                                    Text(
                                      'Note moyenne : $averageRating / 5',
                                      style: TextStyle(color: darkGray),
                                    ),
                                  ],
                                ),
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
    );
  }
}
