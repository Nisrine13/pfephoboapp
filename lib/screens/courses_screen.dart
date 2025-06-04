import 'dart:async';
import 'package:flutter/material.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  // Couleurs beige/clair et marron foncé pour le dégradé
  final Color _beigeWhite = const Color(0xFFF5F1E8);
  final Color _darkBrown = const Color(0xFF805D3B);
  final Color _primaryBrown = const Color(0xFFD2B48C);
  final Color _white = Colors.white;
  final Color _white70 = Colors.white70;

  late final PageController _carouselController;
  Timer? _carouselTimer;
  int _currentPage = 0;

  final List<Map<String, String>> _carouselItems = [
    {
      'image': 'assets/images/startscreen.png',
      'title': 'welcome screen',
      'subtitle': 'Commencer avec nous votre appretissage',
    },
    {
      'image': 'assets/images/signin.png',
      'title': 'Créer un compte',
      'subtitle': 'Devenue un memebre de notre communité',
    },
    {
      'image': 'assets/images/profile.png',
      'title': 'Mon profil',
      'subtitle': 'Suivez vos certifications et statistiques',
    },
  ];

  final List<Map<String, String>> _features = [
    {
      'icon': 'search',
      'label': 'Rechercher',
      'description': 'Trouvez un cours rapidement',
    },
    {
      'icon': 'play_lesson',
      'label': 'Apprendre',
      'description': 'Suivez des leçons vidéo',
    },
    {
      'icon': 'quiz',
      'label': 'Tests',
      'description': 'Évaluez vos connaissances',
    },
    {
      'icon': 'star',
      'label': 'Évaluer',
      'description': 'Notez et commentez les cours',
    },
    {
      'icon': 'person',
      'label': 'Profil',
      'description': 'Gérez votre compte et progrès',
    },
    {
      'icon': 'forum',
      'label': 'Forum',
      'description': 'Discutez avec la communauté',
    },
  ];

  final List<Map<String, dynamic>> _featuredCourses = [
    {
      'coverImage': 'assets/courses/course1.png',
      'title': 'Flutter pour débutants',
      'rating': 4.8,
    },
    {
      'coverImage': 'assets/courses/course2.png',
      'title': 'Dart avancé',
      'rating': 4.6,
    },
    {
      'coverImage': 'assets/courses/course3.png',
      'title': 'UI/UX Design',
      'rating': 4.9,
    },
  ];

  final List<Map<String, String>> _testimonials = [
    {
      'avatar': 'assets/avatars/user1.png',
      'quote': 'Phobo m’a aidé à valider mes certifications en un mois !',
      'name': 'Laura, Étudiante',
    },
    {
      'avatar': 'assets/avatars/user2.png',
      'quote': 'Interface intuitive et contenus de qualité.',
      'name': 'Marc, Développeur',
    },
    {
      'avatar': 'assets/avatars/user3.png',
      'quote': 'J’adore la section forum pour poser mes questions.',
      'name': 'Sophie, Professeur',
    },
  ];

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _currentPage = (_currentPage + 1) % _carouselItems.length;
      _carouselController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  IconData _iconFromString(String name) {
    switch (name) {
      case 'search':
        return Icons.search;
      case 'play_lesson':
        return Icons.play_lesson;
      case 'quiz':
        return Icons.quiz;
      case 'star':
        return Icons.star;
      case 'person':
        return Icons.person;
      case 'forum':
        return Icons.forum;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dégradé vertical du haut (beige clair) vers le bas (marron foncé)
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_beigeWhite, _darkBrown],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // « AppBar » textuel minimal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Text(
                    'Phobo',
                    style: TextStyle(
                      color: _white,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                  ),
                ),

                // 1) Carrousel automatique
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: _carouselController,
                    itemCount: _carouselItems.length,
                    itemBuilder: (context, index) {
                      final item = _carouselItems[index];
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            item['image']!,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.center,
                                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            left: 24,
                            right: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['subtitle']!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 2) Section Fonctionnalités clés
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Fonctionnalités',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _white,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // On augmente le childAspectRatio pour que la carte soit un peu moins haute
                    childAspectRatio: 2.5 / 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: _features.map((feature) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white.withOpacity(0.1),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            // On met la description dans un Flexible pour qu’elle prenne l’espace restant
                            children: [
                              Icon(
                                _iconFromString(feature['icon']!),
                                size: 32,
                                color: _primaryBrown,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                feature['label']!,
                                style: TextStyle(
                                  color: _white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: Text(
                                  feature['description']!,
                                  style: TextStyle(
                                    color: _white70,
                                    fontSize: 12,
                                    fontFamily: 'Montserrat',
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // 3) Section Cours à la une
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Cours à la une',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _white,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: _featuredCourses.length,
                    itemBuilder: (context, index) {
                      final course = _featuredCourses[index];
                      return Container(
                        width: 140,
                        margin: EdgeInsets.only(
                            right: index == _featuredCourses.length - 1 ? 0 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                course['coverImage'],
                                height: 100,
                                width: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course['title'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _white,
                                fontFamily: 'Montserrat',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, size: 14, color: _primaryBrown),
                                Text(
                                  ' ${course['rating']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _white70,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 4) Section Témoignages
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Ce que disent nos apprenants',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _white,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: _testimonials.length,
                    itemBuilder: (context, index) {
                      final t = _testimonials[index];
                      return Container(
                        width: 240,
                        margin: EdgeInsets.only(
                            right: index == _testimonials.length - 1 ? 0 : 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: AssetImage(t['avatar']!),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"${t['quote']!}"',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '- ${t['name']!}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 5) Section À propos / Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'À propos de Phobo',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _white,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Phobo est une plateforme d’auto-apprentissage '
                            'collaboratif. Notre mission est de rendre l’éducation '
                            'accessible à tous, où que vous soyez. Partagez, apprenez '
                            'et progressez ensemble.',
                        style: TextStyle(
                          fontSize: 14,
                          color: _white70,
                          fontFamily: 'Montserrat',
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 20, color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            'contact@phobo.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: _white70,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.language, size: 20, color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            'www.phobo.education',
                            style: TextStyle(
                              fontSize: 14,
                              color: _white70,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
