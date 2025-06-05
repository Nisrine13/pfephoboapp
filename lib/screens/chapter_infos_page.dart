// lib/screens/chapter_infos_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../pages/qcm_form_page.dart';
import '../services/supabase_service.dart';

class ChapterInfosPage extends StatefulWidget {
  final String courseId;
  const ChapterInfosPage({Key? key, required this.courseId}) : super(key: key);

  @override
  State<ChapterInfosPage> createState() => _ChapterInfosPageState();
}

class _ChapterInfosPageState extends State<ChapterInfosPage> {
  final _firestore = FirebaseFirestore.instance;

  // Couleurs
  final Color _beigeWhite   = const Color(0xFFF5F1E8);
  final Color _darkBrown    = const Color(0xFF805D3B);
  final Color _primaryBrown = const Color(0xFFECBF25);
  final Color _white        = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _beigeWhite,
      appBar: AppBar(
        title: const Text("Chapitres du cours"),
        backgroundColor: _darkBrown,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('courses')
            .doc(widget.courseId)
            .collection('chapters')
            .orderBy('index')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chapters = snapshot.data!.docs;
          if (chapters.isEmpty) {
            return const Center(
              child: Text(
                "Aucun chapitre créé",
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: chapters.length,
            itemBuilder: (ctx, i) {
              final chap = chapters[i];
              final data = chap.data() as Map<String, dynamic>;
              return Card(
                color: _white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    data['title'] ?? "Sans titre",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkBrown,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data['summary'] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _darkBrown.withOpacity(0.7)),
                    ),
                  ),
                  leading: data['videoUrl'] != null && (data['videoUrl'] as String).isNotEmpty
                      ? Icon(Icons.play_circle_filled, color: _primaryBrown, size: 28)
                      : Icon(Icons.videocam_off, color: Colors.grey, size: 28),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: _darkBrown),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditChapterPage(
                            courseId: widget.courseId,
                            chapterId: chap.id,
                            existingData: data,
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    // Ouvrir la page de modification du chapitre
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditChapterPage(
                          courseId: widget.courseId,
                          chapterId: chap.id,
                          existingData: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EditChapterPage extends StatefulWidget {
  final String courseId;
  final String chapterId;
  final Map<String, dynamic> existingData;
  const EditChapterPage({
    Key? key,
    required this.courseId,
    required this.chapterId,
    required this.existingData,
  }) : super(key: key);

  @override
  State<EditChapterPage> createState() => _EditChapterPageState();
}

class _EditChapterPageState extends State<EditChapterPage> {
  final _firestore = FirebaseFirestore.instance;
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  String _videoUrl = '';
  bool _loading = false;

  // Couleurs
  final Color _beigeWhite   = const Color(0xFFF5F1E8);
  final Color _darkBrown    = const Color(0xFF805D3B);
  final Color _primaryBrown = const Color(0xFFECBF25);
  final Color _white        = Colors.white;
  final Color _lightGray    = const Color(0xFFEFE8E0);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingData['title']);
    _summaryController = TextEditingController(text: widget.existingData['summary']);
    _videoUrl = widget.existingData['videoUrl'] ?? '';
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'webm'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() => _loading = true);
      final file = result.files.single;
      final url = await SupabaseService().uploadFile(file, 'videos/${file.name}', 'videos');
      setState(() {
        _videoUrl = url;
        _loading = false;
      });
    }
  }

  Future<void> _saveChapter() async {
    setState(() => _loading = true);
    await _firestore
        .collection('courses')
        .doc(widget.courseId)
        .collection('chapters')
        .doc(widget.chapterId)
        .update({
      'title': _titleController.text.trim(),
      'summary': _summaryController.text.trim(),
      'videoUrl': _videoUrl,
    });
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chapitre mis à jour")),
    );
    Navigator.pop(context);
  }

  Future<bool> _qcmExists() async {
    final snap = await _firestore
        .collection('courses')
        .doc(widget.courseId)
        .collection('chapters')
        .doc(widget.chapterId)
        .collection('questions')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _darkBrown.withOpacity(0.8)),
      filled: true,
      fillColor: _white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _beigeWhite,
      appBar: AppBar(
        title: const Text("Modifier le chapitre"),
        backgroundColor: _darkBrown,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Conteneur arrondi pour les champs
            Container(
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Titre du chapitre
                  TextField(
                    controller: _titleController,
                    decoration: _inputDecoration("Titre du chapitre"),
                  ),
                  const SizedBox(height: 16),
                  // Résumé
                  TextField(
                    controller: _summaryController,
                    decoration: _inputDecoration("Résumé"),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  // Aperçu vidéo
                  if (_videoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        color: _lightGray,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          "Vidéo actuelle : $_videoUrl",
                          style: TextStyle(color: _darkBrown.withOpacity(0.7)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Bouton pour changer la vidéo
                  ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_library),
                    label: const Text("Changer la vidéo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBrown,
                      foregroundColor: _white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bouton enregistrer
                  ElevatedButton(
                    onPressed: _saveChapter,
                    child: const Text("Enregistrer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkBrown,
                      foregroundColor: _white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bouton pour modifier QCM si existant
                  FutureBuilder<bool>(
                    future: _qcmExists(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const SizedBox();
                      }
                      if (snap.data == true) {
                        return ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QcmFormPage(
                                  courseId: widget.courseId,
                                  chapterId: widget.chapterId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.quiz),
                          label: const Text("Modifier le QCM"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _darkBrown,
                            foregroundColor: _white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
