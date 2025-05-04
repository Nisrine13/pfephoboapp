import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'YoutubeThumbnailPlayer.dart';

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

  int selectedChapterIndex = 0;
  List<DocumentSnapshot> chapters = [];

  @override
  void initState() {
    super.initState();
    fetchChapters();
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
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final isSelected = index == selectedChapterIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedChapterIndex = index;
                    });
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
                    YoutubeThumbnailPlayer(youtubeUrl: data['videoUrl'] ?? ''),
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