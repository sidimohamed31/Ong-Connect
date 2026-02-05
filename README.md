# ONG Connect

![ONG Connect](https://img.shields.io/badge/Plateforme-Web%20%26%20Mobile-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.10.3-02569B?logo=flutter)
![Flask](https://img.shields.io/badge/Flask-Python-000000?logo=flask)
![License](https://img.shields.io/badge/Licence-MIT-green)

**ONG Connect** est une plateforme complète qui connecte les Organisations Non Gouvernementales (ONG) aux besoins réels de la communauté. La plateforme permet aux ONG de s'inscrire, de publier des cas sociaux, et permet aux donateurs et visiteurs de parcourir et de contribuer à un impact positif.

## 📋 Table des Matières

- [Fonctionnalités](#-fonctionnalités)
- [Stack Technologique](#-stack-technologique)
- [Structure du Projet](#-structure-du-projet)
- [Installation](#-installation)
  - [Configuration Backend](#configuration-backend-application-web-flask)
  - [Configuration Application Mobile](#configuration-application-mobile-flutter)
- [Utilisation](#-utilisation)
- [Documentation API](#-documentation-api)
- [Captures d'écran](#-captures-décran)
- [Contribuer](#-contribuer)
- [Licence](#-licence)
- [Contact](#-contact)

## ✨ Fonctionnalités

### Pour les ONG
- **Inscription & Validation** : Les ONG peuvent s'inscrire avec des documents de vérification et attendre l'approbation de l'administrateur
- **Gestion des Cas** : Créer, modifier et gérer des cas sociaux avec support multimédia enrichi
- **Gestion de Profil** : Maintenir les profils d'organisation avec logos et informations de contact
- **Analytiques** : Voir les statistiques sur les cas publiés et les métriques d'impact

### Pour les Administrateurs
- **Système d'Approbation des ONG** : Examiner et approuver/rejeter les inscriptions d'ONG en attente
- **Modération des Cas** : Approuver ou rejeter les cas sociaux avant leur publication
- **Tableau de Bord** : Analytiques complètes montrant les statistiques de la plateforme
- **Gestion des Utilisateurs** : Gérer les administrateurs et les comptes ONG

### Pour les Donateurs & Visiteurs
- **Parcourir les Cas** : Explorer les cas sociaux par catégorie, localisation ou urgence
- **Filtrage Avancé** : Filtrer les cas par wilaya (région), moughataa (district), statut et catégorie
- **Carte Interactive** : Voir les cas sur une carte interactive avec géolocalisation
- **Support Multilingue** : Disponible en Arabe (العربية), Français et Anglais
- **Détails des Cas** : Voir les informations détaillées incluant bénéficiaires, galerie média et infos contact

### Fonctionnalités Générales
- **Design Responsive** : Fonctionne parfaitement sur ordinateur, tablette et mobile
- **Statistiques en Temps Réel** : Graphiques en direct montrant l'impact par secteur et organisation
- **Authentification Sécurisée** : Hachage de mots de passe, protection CSRF et tokens JWT pour mobile
- **Galerie Média** : Support pour images et vidéos dans les présentations de cas
- **Pagination** : Chargement de données efficace avec support de pagination

## 🛠 Stack Technologique

### Backend (Application Web)
- **Framework** : Flask (Python)
- **Base de Données** : MySQL (PyMySQL)
- **Authentification** : Werkzeug Security (hachage de mots de passe)
- **API** : API RESTful avec support CORS
- **ORM** : Requêtes SQL directes avec PyMySQL

### Frontend (Web)
- **Templates** : Jinja2
- **Styles** : CSS avec support RTL pour l'arabe
- **JavaScript** : Vanilla JS pour l'interactivité
- **Graphiques** : Bibliothèques de visualisation de graphiques

### Application Mobile
- **Framework** : Flutter 3.10.3
- **Langage** : Dart
- **Gestion d'État** : Gestion d'état Flutter intégrée
- **Client HTTP** : package http
- **Dépendances Clés** :
  - `flutter_map` & `latlong2` - Cartes interactives
  - `cached_network_image` - Mise en cache d'images
  - `fl_chart` - Visualisation de statistiques
  - `shimmer` - Animations de chargement
  - `photo_view` - Visualisation d'images
  - `google_fonts` - Typographie
  - `flutter_localizations` - Support multilingue
  - `share_plus` - Fonctionnalité de partage
  - `url_launcher` - Intégration appel et email

## 📁 Structure du Projet

```
Ong-Connect/
├── OngWeb/                    # Application Flask backend
│   ├── static/                # Fichiers statiques (CSS, JS, uploads)
│   │   └── uploads/          # Uploads utilisateurs (média, logos, docs)
│   ├── templates/             # Templates HTML Jinja2
│   ├── app.py                 # Application Flask principale
│   ├── config.py              # Paramètres de configuration
│   ├── locations_data.py      # Données de localisation Mauritanie
│   └── requirements.txt       # Dépendances Python (si existe)
│
├── OngMobile/                 # Application mobile Flutter
│   ├── lib/
│   │   ├── core/             # Utilitaires et constantes de base
│   │   │   ├── constants/    # Constantes API
│   │   │   └── theme/        # Thème de l'application
│   │   ├── data/             # Couche de données
│   │   │   ├── models/       # Modèles de données
│   │   │   └── services/     # Services API et authentification
│   │   ├── l10n/             # Fichiers de localisation
│   │   ├── presentation/     # Couche UI
│   │   │   ├── screens/      # Écrans de l'application
│   │   │   └── widgets/      # Widgets réutilisables
│   │   └── main.dart         # Point d'entrée de l'application
│   ├── android/              # Fichiers spécifiques Android
│   ├── ios/                  # Fichiers spécifiques iOS
│   ├── pubspec.yaml          # Dépendances Flutter
│   └── l10n.yaml             # Configuration de localisation
│
├── .gitignore                # Fichier Git ignore
└── README.md                 # Ce fichier
```

## 🚀 Installation

### Prérequis
- **Backend** : Python 3.7+, MySQL
- **Mobile** : Flutter SDK 3.10.3+, Android Studio/Xcode

### Configuration Backend (Application Web Flask)

1. **Cloner le dépôt**
   ```bash
   git clone https://github.com/sidimohamed31/Ong-Connect.git
   cd Ong-Connect/OngWeb
   ```

2. **Créer un environnement virtuel**
   ```bash
   python -m venv venv
   ```

3. **Activer l'environnement virtuel**
   - Windows :
     ```bash
     venv\Scripts\activate
     ```
   - macOS/Linux :
     ```bash
     source venv/bin/activate
     ```

4. **Installer les dépendances**
   ```bash
   pip install flask pymysql flask-cors werkzeug
   ```

5. **Configurer la base de données**
   - Créer une base de données MySQL nommée `ong_connecte`
   - Mettre à jour `config.py` avec vos identifiants de base de données :
     ```python
     DB_HOST = 'localhost'
     DB_USER = 'votre_nom_utilisateur'
     DB_PASSWORD = 'votre_mot_de_passe'
     DB_NAME = 'ong_connecte'
     ```

6. **Initialiser la base de données**
   ```bash
   python -c "from app import init_db; init_db()"
   ```

7. **Créer un administrateur par défaut (optionnel)**
   - Visiter : `http://localhost:5000/create_default_admin`
   - Identifiants par défaut : `admin@ongconnect.com` / `admin123`

8. **Lancer l'application**
   ```bash
   python app.py
   ```
   L'application web sera disponible sur `http://localhost:5000`

### Configuration Application Mobile (Flutter)

1. **Naviguer vers le répertoire mobile**
   ```bash
   cd ../OngMobile
   ```

2. **Installer les dépendances Flutter**
   ```bash
   flutter pub get
   ```

3. **Mettre à jour le point de terminaison API**
   - Ouvrir `lib/core/constants/api_constants.dart`
   - Mettre à jour l'URL de base vers votre serveur backend :
     ```dart
     static const String baseUrl = 'http://votre-ip-serveur:5000';
     ```

4. **Lancer l'application**
   - Pour Android :
     ```bash
     flutter run
     ```
   - Pour iOS :
     ```bash
     flutter run -d ios
     ```
   - Pour un appareil spécifique :
     ```bash
     flutter devices  # Lister les appareils disponibles
     flutter run -d <device-id>
     ```

## 📱 Utilisation

### Pour les ONG

1. **S'inscrire**
   - Lancer l'application mobile ou visiter le portail web
   - Cliquer sur "Inscrivez-vous maintenant" et remplir les détails de votre organisation
   - Télécharger les documents de vérification
   - Attendre l'approbation de l'administrateur

2. **Connexion & Gestion des Cas**
   - Se connecter avec vos identifiants approuvés
   - Naviguer vers "Mes cas sociaux" pour voir les cas existants
   - Cliquer sur "Ajouter un cas" pour créer un nouveau cas social
   - Remplir les détails du cas, sélectionner la catégorie et ajouter des médias
   - Soumettre pour approbation de l'administrateur

3. **Suivre l'Impact**
   - Voir les statistiques sur votre page de profil
   - Surveiller le statut des cas (En cours, Urgent, Résolu)

### Pour les Administrateurs

1. **Connexion**
   - Accéder au portail admin sur `/admin_login`
   - Utiliser vos identifiants administrateur

2. **Approuver les Organisations**
   - Naviguer vers "ONGs en attente de validation"
   - Examiner les documents de vérification
   - Approuver ou rejeter les inscriptions

3. **Modérer les Cas**
   - Aller dans "Cas en attente de révision"
   - Examiner les détails et médias des cas
   - Approuver pour visibilité publique ou rejeter

### Pour les Donateurs/Visiteurs

1. **Parcourir les Cas** (Aucune connexion requise)
   - Ouvrir l'application mobile ou visiter le tableau de bord public
   - Parcourir les derniers cas sociaux
   - Utiliser les filtres pour trouver des cas spécifiques par :
     - Catégorie (Santé, Éducation, Logement, Alimentation, Eau)
     - Localisation (Wilaya & Moughataa)
     - Statut (En cours, Urgent, Résolu)
     - ONG

2. **Voir les Détails**
   - Appuyer sur une carte de cas pour voir tous les détails
   - Voir les informations sur les bénéficiaires
   - Parcourir la galerie média
   - Contacter l'ONG directement par appel ou email

3. **Voir sur la Carte**
   - Naviguer vers l'écran Carte
   - Voir tous les cas avec marqueurs de géolocalisation
   - Appuyer sur les marqueurs pour info rapide du cas

## 🔌 Documentation API

Le backend fournit des points de terminaison API RESTful pour l'intégration de l'application mobile :

### Authentification
- `POST /api/auth/login` - Connexion (ONG ou Admin)
- `POST /api/auth/register` - Inscrire une nouvelle ONG

### Cas Sociaux
- `GET /api/cases` - Obtenir tous les cas approuvés (avec pagination & filtres)
- `GET /api/cases/<id>` - Obtenir les détails d'un cas
- `POST /api/cases` - Créer un nouveau cas (ONG uniquement)
- `PUT /api/cases/<id>` - Mettre à jour un cas (ONG uniquement)
- `DELETE /api/cases/<id>` - Supprimer un cas (ONG uniquement)

### Catégories
- `GET /api/categories` - Obtenir toutes les catégories

### Statistiques
- `GET /api/stats` - Obtenir les statistiques de la plateforme
- `GET /api/stats/ong/<id>` - Obtenir les statistiques spécifiques d'une ONG

### Opérations Admin
- `GET /api/admin/pending-cases` - Obtenir les cas en attente d'approbation
- `GET /api/admin/pending-ongs` - Obtenir les ONG en attente de validation
- `POST /api/admin/approve-case/<id>` - Approuver un cas
- `POST /api/admin/reject-case/<id>` - Rejeter un cas
- `POST /api/admin/approve-ong/<id>` - Approuver une ONG
- `POST /api/admin/reject-ong/<id>` - Rejeter une ONG

Toutes les réponses API sont au format JSON avec encodage UTF-8 approprié pour le support multilingue.

## 📸 Captures d'écran

*Ajoutez des captures d'écran de votre application ici pour présenter l'UI/UX*

## 🤝 Contribuer

Les contributions sont les bienvenues ! Veuillez suivre ces étapes :

1. Fork le dépôt
2. Créer une branche de fonctionnalité (`git checkout -b feature/NouvelleFonctionnalité`)
3. Commit vos changements (`git commit -m 'Ajout d'une nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/NouvelleFonctionnalité`)
5. Ouvrir une Pull Request

### Directives de Développement
- Suivre PEP 8 pour le code Python
- Utiliser les meilleures pratiques Flutter/Dart
- Écrire des messages de commit descriptifs
- Tester vos changements minutieusement
- Mettre à jour la documentation au besoin

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.

## 📞 Contact

**Dépôt du Projet** : [https://github.com/sidimohamed31/Ong-Connect](https://github.com/sidimohamed31/Ong-Connect)

**Email** : ongconnecte@gmail.com

## 🙏 Remerciements

- Merci à toutes les ONG utilisant cette plateforme pour faire une différence
- Contributeurs de la communauté et testeurs
- Mainteneurs de packages open-source

---

**Fait avec ❤️ pour un monde meilleur - Ensemble pour un changement positif**
