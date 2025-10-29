Space Invaders - Projet RISC-V
📋 Description du projet
Ce projet consiste en l'implémentation d'un jeu Space Invaders en assembleur RISC-V, développé dans le cadre du cours d'Architecture des Ordinateurs en Licence 2 Informatique. Le jeu utilise l'émulateur RARS 1.6 pour l'exécution et met en œuvre des concepts avancés d'architecture des ordinateurs.

🎮 Fonctionnalités implémentées
Partie 1 : Système de pause
Affichage séquentiel des nombres de 1 à 10

Pauses temporelles précises de 500ms entre chaque affichage

Durée totale d'exécution : exactement 5 secondes

Partie 2 : Gestion synchrone du clavier
Détection en temps réel des touches pressées via MMIO

Contrôles :

i : décrémente le compteur

p : incrémente le compteur

o : arrête le programme

Pas de blocage en attente d'entrée utilisateur

Partie 3 : Système graphique bitmap
Double buffering pour des animations fluides

Gestion des couleurs RGB 24-bit

Système de coordonnées avec conversion adresse/position

Primitives de dessin : pixels, rectangles, effacement

Animation de rectangles avec mouvement fluide

Partie 4 : Moteur de jeu Space Invaders
Entités du jeu :

Joueur contrôlable (canon bleu)

Envahisseurs multiples (rouges)

Obstacles défensifs (jaunes)

Système de missiles (blancs)

Mécaniques de jeu :

Déplacement horizontal du joueur

Mouvement collectif des envahisseurs avec changement de direction

Système de tirs pour le joueur et les envahisseurs

Détection de collisions complète

Gestion des vies et conditions de victoire/défaite

🛠️ Architecture technique
Structure des données
Joueur : position, dimensions, vies, couleur

Envahisseurs : tableau dynamique avec état vivant/mort

Obstacles : positions fixes prédéfinies

Missiles : gestion dynamique avec direction et état actif/inactif

Mémoire et affichage
Bitmap Display configuré en 256×256 pixels

Unités de 8×8 pixels pour optimisation des performances

Adressage mémoire : 0x10010000 (zone d'affichage)

Double buffering pour élimination du scintillement

Contrôles
Touche i : déplacement vers la gauche

Touche p : déplacement vers la droite

Touche o : tir de missile

📁 Structure des fichiers
text
projet-space-invaders/
├── partie1.s          # Système de pause
├── partie2.s          # Gestion synchrone du clavier
├── partie3.s          # Système graphique bitmap
├── partie4.s          # Jeu Space Invaders complet
└── README.md          # Ce fichier
🚀 Installation et exécution
Prérequis
RARS 1.6 (RISC-V Assembler and Runtime Simulator)

Connaissance de base de l'assembleur RISC-V

Configuration RARS
Ouvrir RARS 1.6

Aller dans Tools → Bitmap Display

Configurer :

Unit Width/Height : 8 pixels

Display Width/Height : 256 pixels

Base Address : 0x10010000

Cliquer sur Connect to Program

Aller dans Tools → Keyboard and Display MMIO Simulator

Cliquer sur Connect to Program

Exécution
Charger le fichier souhaité dans RARS

Assembler (F3)

Exécuter (F5) ou Exécuter pas-à-pas (F10)

🎯 Règles du jeu
Objectif
Éliminer tous les envahisseurs sans perdre toutes ses vies

Empêcher les envahisseurs d'atteindre le sol

Mécaniques
3 vies initiales pour le joueur

Missiles joueur : détruisent les envahisseurs

Missiles ennemis : réduisent les vies du joueur

Obstacles : bloquent les missiles des deux camps

Mouvement ennemi : déplacement latéral avec descente progressive

Conditions de fin
✅ Victoire : tous les envahisseurs éliminés

❌ Défaite :

Plus de vies restantes

Envahisseurs atteignent le sol

🔧 Personnalisation
Le jeu offre une grande flexibilité via les variables globales :

assembly
# Dimensions et apparence
J_largeur: .word 3       # Largeur du joueur
J_vies: .word 3          # Nombre de vies initiales

# Envahisseurs  
E_nombre: .word 12       # Nombre total d'envahisseurs
E_tir_frequence: .word 20 # Fréquence des tirs ennemis

# Gameplay
M_vitesse: .word 1       # Vitesse des missiles
📊 Évaluation du projet
Le projet est noté sur 20 points selon la répartition :

Partie	Points	Description
Pause	2 pts	Gestion temporelle précise
Clavier	2 pts	Entrées synchrones MMIO
Images	6 pts	Système graphique bitmap
Données	4 pts	Structures et gestion mémoire
Mouvement	3 pts	Déplacement des entités
Gameplay	2 pts	Mécaniques de jeu complètes
Qualité	1 pt	Lisibilité et structure
👥 Développement
Contexte : Projet académique - Licence 2 Informatique
Matière : Architecture des Ordinateurs
Environnement : RISC-V avec émulateur RARS
Langage : Assembleur RISC-V

💡 Points techniques remarquables
Optimisation mémoire avec allocation dynamique

Gestion propre de la pile pour tous les appels de fonction

Algorithmes de collision efficaces

Code modulaire et bien commenté

Configuration flexible via variables globales
