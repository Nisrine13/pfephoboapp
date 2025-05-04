import 'package:flutter/material.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _showFeatures = false;
  final Color _primaryColor = const Color(0xFF30B0C7);
  final Color _accentColor = const Color(0xFFF5A623); // Jaune d'accentuation
  final Color _backgroundColor = const Color(0xFFEEEEEE);
  final Color _darkGrey = const Color(0xFF333333);
  final Color _lightGrey = const Color(0xFF9E9E9E);

  final List<Map<String, dynamic>> _userActions = [
    {'icon': Icons.search, 'label': 'Rechercher'},
    {'icon': Icons.play_lesson, 'label': 'Apprendre'},
    {'icon': Icons.quiz, 'label': 'Tests'},
    {'icon': Icons.star, 'label': 'Évaluer'},
    {'icon': Icons.person, 'label': 'Profil'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Phobo',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat', // Police moderne
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo avec effet jaune
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 3,
                    )
                  ],
                ),
                child: Icon(
                  Icons.school,
                  size: 50,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 30),

              // Titre avec font personnalisée
              Text(
                'Auto-apprentissage\ncollaboratif',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _darkGrey,
                  fontFamily: 'Montserrat',
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              // Description en gris
              Text(
                'Une plateforme ouverte pour apprendre\net partager des connaissances.',
                style: TextStyle(
                  fontSize: 16,
                  color: _lightGrey,
                  fontFamily: 'Montserrat',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Bouton avec texte blanc
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white, // Couleur du texte
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: _primaryColor.withOpacity(0.4),
                ),
                onPressed: () {
                  setState(() => _showFeatures = !_showFeatures);
                },
                child: Text(
                  _showFeatures ? 'Masquer les actions' : 'Commencer l\'exploration',
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Section des icônes avec effets
              if (_showFeatures) ...[
                const SizedBox(height: 30),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: _userActions.map((action) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cercle avec effet jaune
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _accentColor.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: Icon(
                            action['icon'],
                            size: 28,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Texte en gris foncé
                        SizedBox(
                          width: 100,
                          child: Text(
                            action['label'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: _darkGrey,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}