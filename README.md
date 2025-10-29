# 🛸 Space Invaders – Projet RISC-V

## 📋 Description du projet
Ce projet consiste en l’implémentation complète du jeu **Space Invaders** en **assembleur RISC-V**, développé dans le cadre du cours **Architecture des Ordinateurs** en **Licence 2 Informatique**.  
Le jeu s’exécute sur l’émulateur **RARS 1.6** et met en œuvre des concepts avancés d’architecture des ordinateurs tels que la gestion du clavier via MMIO, le double buffering graphique et la manipulation de structures mémoire complexes.

---

## 🎮 Fonctionnalités implémentées

### Partie 1 : Système de pause
- Affichage séquentiel des nombres de **1 à 10**
- Pauses précises de **500 ms** entre chaque affichage  
- Durée totale d’exécution : **exactement 5 secondes**

### Partie 2 : Gestion synchrone du clavier
- Détection **en temps réel** des touches via **MMIO**
- Contrôles :
  - `i` → décrémente le compteur  
  - `p` → incrémente le compteur  
  - `o` → arrête le programme
- Lecture **non bloquante** des entrées clavier

### Partie 3 : Système graphique bitmap
- **Double buffering** pour des animations fluides  
- Gestion des couleurs **RGB 24-bit**  
- Conversion **coordonnées ↔ adresse mémoire**
- Primitives graphiques :
  - Pixel
  - Rectangle
  - Effacement
- Animation de rectangles avec mouvement fluide

### Partie 4 : Moteur du jeu Space Invaders
#### Entités :
- Joueur (canon bleu)
- Envahisseurs (rouges)
- Obstacles (jaunes)
- Missiles (blancs)

#### Mécaniques :
- Déplacement horizontal du joueur
- Mouvement collectif et changement de direction des envahisseurs
- Tirs (joueur et ennemis)
- Détection complète des **collisions**
- Gestion des **vies**, **victoire** et **défaite**

---

## 🛠️ Architecture technique

### Structures de données
- **Joueur** : position, dimensions, vies, couleur  
- **Envahisseurs** : tableau dynamique avec état vivant/mort  
- **Obstacles** : positions fixes prédéfinies  
- **Missiles** : direction et état actif/inactif

### Mémoire et affichage
- **Bitmap Display** : 256 × 256 pixels  
- Unités graphiques de **8×8 pixels** (optimisation)
- Adresse mémoire : `0x10010000`  
- **Double buffering** pour éviter le scintillement

### Contrôles
| Touche | Action |
|:-------:|:--------|
| `i` | Déplacement à gauche |
| `p` | Déplacement à droite |
| `o` | Tir de missile |

---

## 📁 Structure du projet
text
projet-space-invaders/
├── partie1.s # Système de pause
├── partie2.s # Gestion synchrone du clavier
├── partie3.s # Système graphique bitmap
├── partie4.s # Jeu Space Invaders complet
└── README.md # Documentation du projet

yaml
Copier le code

---

## 🚀 Installation et exécution

### Prérequis
- **RARS 1.6** (RISC-V Assembler and Runtime Simulator)
- Connaissances de base en **assembleur RISC-V**

### Configuration RARS
1. Ouvrir **RARS 1.6**
2. Aller dans **Tools → Bitmap Display**
   - Unit Width/Height : `8`
   - Display Width/Height : `256`
   - Base Address : `0x10010000`
   - Cliquer sur **Connect to Program**
3. Aller dans **Tools → Keyboard and Display MMIO Simulator**
   - Cliquer sur **Connect to Program**

### Exécution
1. Charger le fichier `.s` souhaité dans RARS  
2. Assembler (`F3`)  
3. Exécuter (`F5`) ou **pas-à-pas** (`F10`)

---

## 🎯 Règles du jeu

### Objectif
Éliminer tous les envahisseurs sans perdre toutes ses vies et **empêcher** qu’ils atteignent le sol.

### Mécaniques
- 3 vies initiales pour le joueur  
- Les missiles du joueur détruisent les envahisseurs  
- Les missiles ennemis réduisent les vies du joueur  
- Les obstacles bloquent les tirs des deux côtés  
- Les envahisseurs descendent progressivement à chaque bord atteint

### Conditions de fin
- ✅ **Victoire** : tous les envahisseurs sont éliminés  
- ❌ **Défaite** :
  - Plus de vies restantes  
  - Les envahisseurs atteignent le sol  

---

## 🔧 Personnalisation

Tu peux ajuster facilement les paramètres du jeu via les **variables globales** dans le code :

```assembly
# Dimensions et apparence
J_largeur:      .word 3   # Largeur du joueur
J_vies:         .word 3   # Nombre de vies initiales

# Envahisseurs
E_nombre:       .word 12  # Nombre total d'envahisseurs
E_tir_frequence:.word 20  # Fréquence des tirs ennemis

# Gameplay
M_vitesse:      .word 1   # Vitesse des missiles
```
## 📊 Évaluation du projet
Partie	Points	Description
Pause	2 pts	Gestion temporelle précise
Clavier	2 pts	Entrées synchrones via MMIO
Images	6 pts	Système graphique bitmap
Données	4 pts	Structures et gestion mémoire
Mouvement	3 pts	Déplacement des entités
Gameplay	2 pts	Mécaniques de jeu complètes
Qualité	1 pt	Lisibilité et structure



##  👥 Développement
-Contexte : Projet académique – Licence 2 Informatique

-Matière : Architecture des Ordinateurs

-Environnement : RARS (RISC-V)

-Langage : Assembleur RISC-V

 ## 💡 Points techniques remarquables
-Optimisation mémoire via allocation dynamique

-Gestion propre de la pile pour chaque fonction

-Algorithmes de collision efficaces

-Code modulaire, clair et abondamment commenté

-Paramétrage flexible via variables globales
