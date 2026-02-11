# 🌟 Résumé du Projet : ONG-Connect

**ONG-Connect** est une plateforme solidaire conçue pour la Mauritanie. Elle permet de mettre en relation des Organisations Non Gouvernementales (ONG) avec des personnes ayant des besoins spécifiques (cas sociaux).

---

## 🚀 Caractéristiques Principales

1.  **🌍 Impact Local** : Focus sur les régions de la Mauritanie (Wilayas et Moughataas).
2.  **📱 Multi-plateforme** :
    *   **Web** : Pour l'administration et la gestion lourde.
    *   **Mobile** : Pour une consultation facile par le public et les ONG sur le terrain.
3.  **🛡️ Sécurité & Validation** : Chaque ONG et chaque cas social doit être validé par un administrateur avant d'être visible.
4.  **🗣️ Multilingue** : Support complet de l'**Arabe**, du **Français** et de l'**Anglais**.
5.  **📍 Carte Interactive** : Visualisation des cas sociaux sur une carte pour une meilleure répartition de l'aide.

---

## 💻 Explication Simple du Code

Le projet est divisé en deux grandes parties qui communiquent entre elles.

### 1. Le Cerveau : Le Backend (`OngWeb`)
C'est ici que toute la logique et les données sont stockées.
*   **Technologie** : Flask (Python).
*   **Fichiers importants** :
    *   `app.py` : C'est le "chef d'orchestre". Il reçoit les demandes, vérifie les mots de passe, et envoie les données.
    *   `config.py` : Contient les "clés" de la maison (connexion à la base de données).
*   **Base de données** : MySQL. C'est la mémoire du projet où sont rangés les noms des ONG, les photos et les descriptions des cas.

### 2. Le Visage : L'Application Mobile (`OngMobile`)
C'est ce que l'utilisateur voit et touche.
*   **Technologie** : Flutter (Dart).
*   **Comment ça marche ?** :
    *   L'application demande au "Cerveau" (Backend) : *"Donne-moi la liste des cas urgents"*.
    *   Le Cerveau répond en format **JSON** (un langage simple que les deux comprennent).
    *   L'application transforme ces données en jolies cartes et images sur l'écran du téléphone.

---

## 🛠 Structure des Dossiers

*   📂 `OngWeb/` : Le serveur et le site web.
    *   📂 `templates/` : Les pages HTML (ce qu'on voit sur le web).
    *   📂 `static/uploads/` : Là où sont rangées les photos envoyées par les ONG.
*   📂 `OngMobile/` : Le code de l'application smartphone.
    *   📂 `lib/presentation/` : Contient les écrans (Screens) et les petits éléments (Widgets) comme les boutons ou les listes.

---

## 🛠 Comment tout cela fonctionne ensemble ? (Le Flux)

1.  **Inscription** : Une ONG crée un compte sur mobile.
2.  **Validation** : L'Admin se connecte sur le web et dit "OK, cette ONG est sérieuse".
3.  **Publication** : L'ONG ajoute une photo et un texte pour une famille en besoin.
4.  **Visibilité** : N'importe qui en Mauritanie ouvre l'appli et peut voir où aider.

---
*Ce document sert de guide simplifié pour comprendre rapidement l'architecture du projet.*
