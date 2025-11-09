// Enum pour les catégories prédéfinies
enum CategorieType {
  sport,           // 🏃 Sport & Fitness
  bienEtre,        // 🧘 Bien-être & Méditation
  apprentissage,   // 📚 Apprentissage & Lecture
  sante,           // 💧 Santé & Hydratation
  nutrition,       // 🍎 Nutrition
  sommeil,         // 😴 Sommeil
  productivite,    // 💼 Productivité
  creativite,      // 🎨 Créativité
  social,          // 👥 Social
  routine,         // 🏠 Routine domestique
}

// Classe pour gérer les catégories
class Categorie {
  final CategorieType type;
  final String nom;
  final String icone;
  final String couleur;

  const Categorie({
    required this.type,
    required this.nom,
    required this.icone,
    required this.couleur,
  });

  static const List<Categorie> categories = [
    Categorie(
      type: CategorieType.sport,
      nom: 'Sport & Fitness',
      icone: '🏃',
      couleur: '#FF6B6B',
    ),
    Categorie(
      type: CategorieType.bienEtre,
      nom: 'Bien-être & Méditation',
      icone: '🧘',
      couleur: '#4ECDC4',
    ),
    Categorie(
      type: CategorieType.apprentissage,
      nom: 'Apprentissage & Lecture',
      icone: '📚',
      couleur: '#45B7D1',
    ),
    Categorie(
      type: CategorieType.sante,
      nom: 'Santé & Hydratation',
      icone: '💧',
      couleur: '#96CEB4',
    ),
    Categorie(
      type: CategorieType.nutrition,
      nom: 'Nutrition',
      icone: '🍎',
      couleur: '#FFEAA7',
    ),
    Categorie(
      type: CategorieType.sommeil,
      nom: 'Sommeil',
      icone: '😴',
      couleur: '#DFE6E9',
    ),
    Categorie(
      type: CategorieType.productivite,
      nom: 'Productivité',
      icone: '💼',
      couleur: '#A29BFE',
    ),
    Categorie(
      type: CategorieType.creativite,
      nom: 'Créativité',
      icone: '🎨',
      couleur: '#FD79A8',
    ),
    Categorie(
      type: CategorieType.social,
      nom: 'Social',
      icone: '👥',
      couleur: '#FDCB6E',
    ),
    Categorie(
      type: CategorieType.routine,
      nom: 'Routine domestique',
      icone: '🏠',
      couleur: '#6C5CE7',
    ),
  ];

  static Categorie getByType(CategorieType type) {
    return categories.firstWhere((cat) => cat.type == type);
  }
}