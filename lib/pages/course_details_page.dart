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
        title: const Text('Course Details'),
        leading: BackButton(),
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 100,
            color: const Color(0xFFF2E8FF),
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
                          backgroundColor:
                          isSelected ? Colors.purple[300] : Colors.purple[100],
                          child: Text('${index + 1}'),
                        ),
                        const SizedBox(height: 4),
                        Text('Chap ${index + 1}'),
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
              color: const Color(0xFFF7EBFF),
              padding: const EdgeInsets.all(20),
              child: data == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? '',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['summary'] ?? '',
                      style: const TextStyle(fontSize: 16),
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
