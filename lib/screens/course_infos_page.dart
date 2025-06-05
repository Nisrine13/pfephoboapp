// lib/screens/course_infos_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../services/supabase_service.dart';

class CourseInfosPage extends StatefulWidget {
  final String courseId;
  const CourseInfosPage({Key? key, required this.courseId}) : super(key: key);

  @override
  State<CourseInfosPage> createState() => _CourseInfosPageState();
}

class _CourseInfosPageState extends State<CourseInfosPage> {
  final _firestore = FirebaseFirestore.instance;

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late TextEditingController _levelController;
  String _imageUrl = '';
  bool _loading = true;

  // Couleurs
  final Color _beigeWhite   = const Color(0xFFF5F1E8);
  final Color _darkBrown    = const Color(0xFF805D3B);
  final Color _primaryBrown = const Color(0xFFECBF25);
  final Color _white        = Colors.white;
  final Color _lightGray    = const Color(0xFFEFE8E0);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _categoryController = TextEditingController();
    _levelController = TextEditingController();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    final doc = await _firestore.collection('courses').doc(widget.courseId).get();
    final data = doc.data() as Map<String, dynamic>;
    _titleController.text = data['title'] ?? '';
    _descController.text = data['description'] ?? '';
    _categoryController.text = data['category'] ?? '';
    _levelController.text = data['level'] ?? '';
    _imageUrl = data['imageUrl'] ?? '';
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final url = await SupabaseService().uploadFile(file, 'images/${file.name}', 'images');
      setState(() => _imageUrl = url);
    }
  }

  Future<void> _saveCourse() async {
    await _firestore.collection('courses').doc(widget.courseId).update({
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'category': _categoryController.text.trim(),
      'level': _levelController.text.trim(),
      'imageUrl': _imageUrl,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cours mis à jour")),
    );
    Navigator.pop(context);
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
        title: const Text("Modifier le cours"),
        backgroundColor: _darkBrown,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Conteneur principal arrondi
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
                  // Titre
                  TextField(
                    controller: _titleController,
                    decoration: _inputDecoration("Titre du cours"),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  TextField(
                    controller: _descController,
                    decoration: _inputDecoration("Description"),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  // Catégorie et Niveau côte-à-côte
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _categoryController,
                          decoration: _inputDecoration("Catégorie"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _levelController,
                          decoration: _inputDecoration("Niveau"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Aperçu de l'image
                  if (_imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_imageUrl, height: 140, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 12),
                  // Bouton pour changer l'image
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Changer l'image"),
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
                    onPressed: _saveCourse,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
