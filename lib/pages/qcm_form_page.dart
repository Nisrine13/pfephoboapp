import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QcmFormPage extends StatefulWidget {
  final String courseId;
  final String chapterId;

  const QcmFormPage({required this.courseId, required this.chapterId, super.key});

  @override
  State<QcmFormPage> createState() => _QcmFormPageState();
}

class _QcmFormPageState extends State<QcmFormPage> {
  final List<QuestionForm> _questions = [];
  int _questionCount = 5;

  final Color primaryColor = const Color(0xFF30B0C7);
  final Color accentYellow = const Color(0xFFFFD700);
  final Color importantRed = const Color(0xFFE53935);
  final Color lightGray = const Color(0xFFEEEEEE);
  final Color darkGray = const Color(0xFF757575);
  final Color white = Colors.white;


  @override
  void initState() {
    super.initState();
    _generateQuestions(5);
  }

  void _generateQuestions(int count) {
    _questions.clear();
    for (int i = 0; i < count; i++) {
      _questions.add(QuestionForm(
        primaryColor: primaryColor,
        darkGray: darkGray,
      ));
    }
    setState(() {});
  }

  Future<void> _submitQuestions() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (var question in _questions) {
      if (!question.isValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Veuillez remplir correctement toutes les questions"),
              backgroundColor: importantRed,
            )
        );
        return;
      }

      final questionRef = firestore
          .collection('courses')
          .doc(widget.courseId)
          .collection('chapters')
          .doc(widget.chapterId)
          .collection('questions')
          .doc();

      batch.set(questionRef, question.toMap());
    }

    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Questions ajoutées avec succès"),
          backgroundColor: primaryColor,
        )
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Ajouter un QCM", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text("Nombre de questions :", style: TextStyle(color: darkGray)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: darkGray.withOpacity(0.4)),
                  ),
                  child: DropdownButton<int>(
                    value: _questionCount,
                    underline: SizedBox(),
                    items: List.generate(15, (i) => i + 5)
                        .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _questionCount = value;
                        _generateQuestions(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < _questions.length; i++) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Question ${i + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                    const SizedBox(height: 10),
                    _questions[i],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submitQuestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer le QCM"),
            ),
          ],
        ),
      ),
    );
  }
}
class QuestionForm extends StatefulWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> options = List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;

  final Color primaryColor;
  final Color darkGray;

  QuestionForm({required this.primaryColor, required this.darkGray, Key? key}) : super(key: key);

  bool isValid() {
    return _formKey.currentState?.validate() == true;
  }

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionController.text.trim(),
      'options': options.map((o) => o.text.trim()).toList(),
      'correctIndex': correctIndex,
    };
  }

  @override
  State<QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<QuestionForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget._formKey,
      child: Column(
        children: [
          TextFormField(
            controller: widget.questionController,
            decoration: InputDecoration(
              labelText: "Question",
              labelStyle: TextStyle(color: widget.darkGray),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.primaryColor)),
            ),
            validator: (value) => (value == null || value.isEmpty) ? "Obligatoire" : null,
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < 4; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Radio<int>(
                value: i,
                groupValue: widget.correctIndex,
                onChanged: (value) {
                  setState(() {
                    widget.correctIndex = value!;
                  });
                },
                activeColor: widget.primaryColor,
              ),
              title: TextFormField(
                controller: widget.options[i],
                decoration: InputDecoration(
                  labelText: "Option ${i + 1}",
                  labelStyle: TextStyle(color: widget.darkGray),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.primaryColor)),
                ),
                validator: (value) => (value == null || value.isEmpty) ? "Obligatoire" : null,
              ),
            ),
        ],
      ),
    );
  }
}
