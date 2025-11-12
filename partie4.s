# ========================================
# PROJET SPACE INVADERS - RISC-V
# Architecture des Ordinateurs - Licence 2
# ========================================

.data
    # ========================================
    # PARTIE 3 : Configuration de l'image
    # ========================================
    LARGEUR_PIXELS: .word 256      # Largeur totale en pixels
    HAUTEUR_PIXELS: .word 256      # Hauteur totale en pixels
    UNIT_WIDTH: .word 8            # Largeur d'une Unit en pixels
    UNIT_HEIGHT: .word 8           # Hauteur d'une Unit en pixels
    
    I_largeur: .word 0             # Calculé : 32 Units
    I_hauteur: .word 0             # Calculé : 32 Units
    I_visu: .word 0x10010000       # Buffer visible
    I_buff: .word 0                # Buffer de travail
    
    # Couleurs
    COULEUR_NOIR: .word 0x00000000
    COULEUR_ROUGE: .word 0x00ff0000
    COULEUR_BLEU: .word 0x000088ff
    COULEUR_JAUNE: .word 0x00ffff00
    COULEUR_BLANC: .word 0x00ffffff
    
    # ========================================
    # PARTIE 4 : Données du jeu
    # ========================================
    
    # --- JOUEUR ---
    # Structure : [x, y, largeur, hauteur, vies]
    J_x: .word 13              # Position x initiale
    J_y: .word 28              # Position y (sous le sol)
    J_largeur: .word 3
    J_hauteur: .word 2
    J_vies: .word 3
    J_couleur: .word 0x000088ff
    
    # --- ENVAHISSEURS ---
    # Structure par envahisseur : [x, y, vivant] (3 entiers = 12 octets)
    E_nombre: .word 12         # Nombre d'envahisseurs
    E_rangees: .word 2         # Nombre de rangées
    E_largeur: .word 2
    E_hauteur: .word 2
    E_couleur: .word 0x00ff0000
    E_espacement: .word 3      # Espacement horizontal
    E_descente: .word 2        # Descente quand changement de direction
    E_direction: .word 1       # 1 = droite, -1 = gauche
    E_x_depart: .word 2
    E_y_depart: .word 2
    E_tableau: .word 0         # Adresse du tableau (alloué dynamiquement)
    E_tir_compteur: .word 0    # Compteur pour les tirs
    E_tir_frequence: .word 20  # Tirer tous les 20 frames
    
    # --- OBSTACLES ---
    # Structure par obstacle : [x, y] (2 entiers = 8 octets)
    O_nombre: .word 4
    O_largeur: .word 3
    O_hauteur: .word 2
    O_couleur: .word 0x00ffff00
    O_y: .word 23              # À 1/5 de la hauteur (32/5 ? 6, donc y=26)
    O_espacement: .word 6
    O_tableau: .word 0         # Adresse du tableau
    
    # --- MISSILES ---
    # Structure par missile : [x, y, direction, actif] (4 entiers = 16 octets)
    # direction: 1 = haut (joueur), -1 = bas (envahisseurs)
    M_max: .word 20            # Nombre max de missiles
    M_couleur: .word 0x00ffffff
    M_longueur: .word 2
    M_vitesse: .word 1
    M_tableau: .word 0         # Adresse du tableau
    
    # --- CLAVIER (MMIO) ---
    RCR: .word 0xffff0000
    RDR: .word 0xffff0004
    
    # --- ÉTAT DU JEU ---
    JEU_en_cours: .word 1      # 1 = en cours, 0 = terminé
    JEU_victoire: .word 0      # 1 = victoire, 0 = défaite
    
    # Messages
    msg_victoire: .string "\n=== VICTOIRE ! ===\n"
    msg_defaite: .string "\n=== DEFAITE ! ===\n"
    msg_vies: .string "Vies: "

.text
.globl main

# ========================================
# MAIN : Boucle principale du jeu
# ========================================
main:
    # Initialiser le système
    jal I_creer
    jal J_creer
    jal E_creer
    jal O_creer
    jal M_creer
    
    # Boucle de jeu
boucle_jeu:
    # Vérifier si le jeu est terminé
    la t0, JEU_en_cours
    lw t0, 0(t0)
    beqz t0, fin_jeu  # Si t0 == 0 le jeu se termine et on saute a fin_jeu 
    
    # Effacer le buffer et met tt l'ecran en noir 
    jal I_effacer 
    
    # Afficher tous les éléments
    jal O_afficher
    jal E_afficher
    jal M_afficher
    jal J_afficher
    
    # Copier vers l'écran
    jal I_buff_to_visu
    
    # Lire le clavier
    jal J_deplacer
    
    # Déplacer les missiles
    jal M_deplacer
    
    # Déplacer les envahisseurs
    jal E_deplacer
    
    # Vérifier les collisions
    jal verifier_collisions
    
    # Pause de 50ms (20 FPS)
    li a0, 50
    li a7, 32
    ecall
    
    j boucle_jeu
    
fin_jeu:
    # Afficher le message final
    la t0, JEU_victoire
    lw t0, 0(t0)
    bnez t0, afficher_victoire
    
    la a0, msg_defaite
    li a7, 4
    ecall
    j quitter
    
afficher_victoire:
    la a0, msg_victoire
    li a7, 4
    ecall
    
quitter:
    li a7, 10
    ecall

# ========================================
# PARTIE 3 : Fonctions d'image
# ========================================

I_creer:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t0, 8(sp)
    sw t1, 4(sp)
    
    # Calculer I_largeur et I_hauteur
    la t0, LARGEUR_PIXELS
    lw t0, 0(t0)
    la t1, UNIT_WIDTH
    lw t1, 0(t1)
    div t0, t0, t1
    la t1, I_largeur
    sw t0, 0(t1)
    
    la t0, HAUTEUR_PIXELS
    lw t0, 0(t0)
    la t1, UNIT_HEIGHT
    lw t1, 0(t1)
    div t0, t0, t1
    la t1, I_hauteur
    sw t0, 0(t1)
    
    # Allouer I_buff
    la t0, I_largeur
    lw t0, 0(t0)
    la t1, I_hauteur
    lw t1, 0(t1)
    mul t0, t0, t1
    slli t0, t0, 2
    
    mv a0, t0
    li a7, 9
    ecall
    
    la t0, I_buff
    sw a0, 0(t0)
    
    lw t1, 4(sp)
    lw t0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

I_xy_to_addr:
    addi sp, sp, -12
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)
    
    la t0, I_largeur
    lw t0, 0(t0)
    mul t1, a1, t0
    add t1, t1, a0 # index= y ∗ largeur + x
    slli t1, t1, 2 # t1 = t1 * 4 
    
    la t2, I_buff
    lw t2, 0(t2)
    add a0, t2, t1
    
    lw t2, 0(sp)
    lw t1, 4(sp)
    lw t0, 8(sp)
    addi sp, sp, 12
    ret

I_plot:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw a0, 12(sp)
    sw a1, 8(sp)
    sw a2, 4(sp)
    sw t0, 0(sp)
    
    # Vérifier les limites
    la t0, I_largeur
    lw t0, 0(t0)
    bge a0, t0, I_plot_fin # Si a0 >= t0
    bltz a0, I_plot_fin # si a0 < 0 
    
    la t0, I_hauteur
    lw t0, 0(t0)
    bge a1, t0, I_plot_fin
    bltz a1, I_plot_fin
    
    mv t0, a2
    jal I_xy_to_addr # Va a l'adresse memoire  
    sw t0, 0(a0) # Colorie le pixel (met la couleur dans l'adresse du pixel a colorier)
    
I_plot_fin:
    lw t0, 0(sp)
    lw a2, 4(sp)
    lw a1, 8(sp)
    lw a0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    ret

I_effacer:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)
    
    la s0, I_largeur
    lw s0, 0(s0)
    la s1, I_hauteur
    lw s1, 0(s1)
    la s2, COULEUR_NOIR
    lw s2, 0(s2)
    
    li s3, 0
I_eff_y:
    bge s3, s1, I_eff_fin
    li t0, 0
I_eff_x:
    bge t0, s0, I_eff_ny
    mv a0, t0
    mv a1, s3
    mv a2, s2
    jal I_plot
    addi t0, t0, 1
    j I_eff_x
I_eff_ny:
    addi s3, s3, 1
    j I_eff_y
I_eff_fin:
    lw s3, 0(sp)
    lw s2, 4(sp)
    lw s1, 8(sp)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    ret

I_rectangle:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    sw s3, 12(sp)
    sw s4, 8(sp)
    sw s5, 4(sp)
    sw s6, 0(sp)
    
    mv s0, a0
    mv s1, a1
    mv s2, a2
    mv s3, a3
    mv s4, a4
    add s5, s0, s2 # x_max 
    add s6, s1, s3 # y_max
    
    mv t0, s1
I_rect_y:
    bge t0, s6, I_rect_fin
    mv t1, s0
I_rect_x:
    bge t1, s5, I_rect_ny
    mv a0, t1
    mv a1, t0
    mv a2, s4
    jal I_plot
    addi t1, t1, 1
    j I_rect_x
I_rect_ny:
    addi t0, t0, 1
    j I_rect_y
I_rect_fin:
    lw s6, 0(sp)
    lw s5, 4(sp)
    lw s4, 8(sp)
    lw s3, 12(sp)
    lw s2, 16(sp)
    lw s1, 20(sp)
    lw s0, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
    ret

I_buff_to_visu:
    addi sp, sp, -16
    sw t0, 12(sp)
    sw t1, 8(sp)
    sw t2, 4(sp)
    sw t3, 0(sp)
    
    la t0, I_buff
    lw t0, 0(t0) # adresse I_buff
    la t1, I_visu
    lw t1, 0(t1) #adresse I_visu
    
    
    la t2, I_largeur
    lw t2, 0(t2)
    la t3, I_hauteur
    lw t3, 0(t3)
    mul t2, t2, t3
    slli t2, t2, 2
    
    li t3, 0
I_copie:
    bge t3, t2, I_copie_fin
    add a0, t0, t3
    add a1, t1, t3
    lw a2, 0(a0)
    sw a2, 0(a1)
    addi t3, t3, 4
    j I_copie
I_copie_fin:
    lw t3, 0(sp)
    lw t2, 4(sp)
    lw t1, 8(sp)
    lw t0, 12(sp)
    addi sp, sp, 16
    ret

# ========================================
# PARTIE 4 : Création des objets
# ========================================

J_creer:
    # Le joueur est déjà initialisé par les variables globales
    ret

E_creer:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)
    
    # Allouer tableau : nombre * 3 * 4 octets
    la t0, E_nombre
    lw t0, 0(t0)
    li t1, 12
    mul t0, t0, t1
    
    mv a0, t0
    li a7, 9
    ecall
    
    la t0, E_tableau
    sw a0, 0(t0)
    
    # Initialiser les envahisseurs
    la t0, E_nombre
    lw t0, 0(t0)
    la t1, E_tableau
    lw t1, 0(t1)
    la t2, E_espacement
    lw t2, 0(t2)
    la t3, E_largeur
    lw t3, 0(t3)
    add t2, t2, t3 #distance entre le début d'un envahisseur et le début du suivant
    
    la t4, E_x_depart
    lw t4, 0(t4)
    la t5, E_y_depart
    lw t5, 0(t5)
    la t6, E_rangees
    lw t6, 0(t6)
    
    div a1, t0, t6      # Envahisseurs par rangée
    
    li a2, 0            # Compteur
    li a3, 0            # x courant
    li a4, 0            # y courant
    
E_init_loop:
    bge a2, t0, E_init_fin
    
    # Calculer position
    rem a5, a2, a1      # a5 contient la colonne de l'envahisseur dans sa rangée.
    div a6, a2, a1      # a6 contient la rangée de l'envahisseur.
    
    mul a5, a5, t2      # On multiplie la colonne (a5) par cet espacement pour obtenir le décalage horizontal par rapport au premier envahisseur de la rangée
    add a5, a5, t4      # On ajoute ce décalage de départ au décalage calculé précédemment pour obtenir la position x finale de l'envahisseur.
    
    li t3, 3
    mul a6, a6, t3      # On multiplie la rangée (a6) par 3 pour obtenir le décalage vertical par rapport à la première rangée.
    add a6, a6, t5      # On ajoute ce décalage de départ au décalage vertical calculé précédemment pour obtenir la position y finale de l'envahisseur.
    
    # Écrire dans le tableau
    li t3, 12
    mul a7, a2, t3
    add a7, t1, a7
    
    sw a5, 0(a7)        # x
    sw a6, 4(a7)        # y
    li t3, 1
    sw t3, 8(a7)        # vivant = 1
    
    addi a2, a2, 1
    j E_init_loop
    
E_init_fin:
    lw t2, 0(sp)
    lw t1, 4(sp)
    lw t0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

O_creer:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)
    
    # Allouer tableau : nombre * 2 * 4 octets
    la t0, O_nombre
    lw t0, 0(t0)
    slli t0, t0, 3
    
    mv a0, t0
    li a7, 9
    ecall
    
    la t0, O_tableau
    sw a0, 0(t0)
    
    # Initialiser les obstacles
    la t0, O_nombre
    lw t0, 0(t0)
    la t1, O_tableau
    lw t1, 0(t1)
    la t2, O_espacement
    lw t2, 0(t2)
    la t3, O_largeur
    lw t3, 0(t3)
    add t2, t2, t3
    
    la t4, O_y
    lw t4, 0(t4)
    
    li t5, 0
O_init_loop:
    bge t5, t0, O_init_fin
    
    # x = 2 + i * espacement
    mul t6, t5, t2
    addi t6, t6, 2
    
    slli a0, t5, 3
    add a0, t1, a0
    sw t6, 0(a0)        # x
    sw t4, 4(a0)        # y
    
    addi t5, t5, 1
    j O_init_loop
    
O_init_fin:
    lw t2, 0(sp)
    lw t1, 4(sp)
    lw t0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

M_creer:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw t0, 0(sp)
    
    # Allouer tableau : max * 4 * 4 octets
    la t0, M_max
    lw t0, 0(t0)
    slli t0, t0, 4
    
    mv a0, t0
    li a7, 9
    ecall
    
    la t0, M_tableau
    sw a0, 0(t0)
    
    # Initialiser tous à inactifs
    la t0, M_max
    lw t0, 0(t0)
    la t1, M_tableau
    lw t1, 0(t1)
    
    li t2, 0
M_init_loop:
    bge t2, t0, M_init_fin
    slli t3, t2, 4
    add t3, t1, t3
    sw zero, 12(t3)     # actif = 0
    addi t2, t2, 1
    j M_init_loop
    
M_init_fin:
    lw t0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret

# ========================================
# Fonctions d'affichage
# ========================================

J_afficher:
    addi sp, sp, -8
    sw ra, 4(sp)
    
    la t0, J_x
    lw a0, 0(t0)
    la t0, J_y
    lw a1, 0(t0)
    la t0, J_largeur
    lw a2, 0(t0)
    la t0, J_hauteur
    lw a3, 0(t0)
    la t0, J_couleur
    lw a4, 0(t0)
    
    jal I_rectangle
    
    lw ra, 4(sp)
    addi sp, sp, 8
    ret

E_afficher:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)
    sw s4, 0(sp)
    
    la s0, E_nombre
    lw s0, 0(s0)
    la s1, E_tableau
    lw s1, 0(s1)
    la s2, E_largeur
    lw s2, 0(s2)
    la s3, E_hauteur
    lw s3, 0(s3)
    la s4, E_couleur
    lw s4, 0(s4)
    
    li t0, 0
E_aff_loop:
    bge t0, s0, E_aff_fin
    
    li t1, 12
    mul t1, t0, t1
    add t1, s1, t1
    
    lw t2, 8(t1)        # vivant ?
    beqz t2, E_aff_next
    
    lw a0, 0(t1)        # x
    lw a1, 4(t1)        # y
    mv a2, s2
    mv a3, s3
    mv a4, s4
    
    addi sp, sp, -4
    sw t0, 0(sp)
    jal I_rectangle
    lw t0, 0(sp)
    addi sp, sp, 4
    
E_aff_next:
    addi t0, t0, 1
    j E_aff_loop
    
E_aff_fin:
    lw s4, 0(sp)
    lw s3, 4(sp)
    lw s2, 8(sp)
    lw s1, 12(sp)
    lw s0, 16(sp)
    lw ra, 20(sp)
    addi sp, sp, 24
    ret

O_afficher:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)
    sw s4, 0(sp)
    
    la s0, O_nombre
    lw s0, 0(s0)
    la s1, O_tableau
    lw s1, 0(s1)
    la s2, O_largeur
    lw s2, 0(s2)
    la s3, O_hauteur
    lw s3, 0(s3)
    la s4, O_couleur
    lw s4, 0(s4)
    
    li t0, 0
O_aff_loop:
    bge t0, s0, O_aff_fin
    
    slli t1, t0, 3
    add t1, s1, t1
    
    lw a0, 0(t1)
    lw a1, 4(t1)
    mv a2, s2
    mv a3, s3
    mv a4, s4
    
    addi sp, sp, -4
    sw t0, 0(sp)
    jal I_rectangle
    lw t0, 0(sp)
    addi sp, sp, 4
    
    addi t0, t0, 1
    j O_aff_loop
    
O_aff_fin:
    lw s4, 0(sp)
    lw s3, 4(sp)
    lw s2, 8(sp)
    lw s1, 12(sp)
    lw s0, 16(sp)
    lw ra, 20(sp)
    addi sp, sp, 24
    ret

M_afficher:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)
    
    la s0, M_max
    lw s0, 0(s0)
    la s1, M_tableau
    lw s1, 0(s1)
    la s2, M_longueur
    lw s2, 0(s2)
    la s3, M_couleur
    lw s3, 0(s3)
    
    li t0, 0
M_aff_loop:
    bge t0, s0, M_aff_fin
    
    slli t1, t0, 4
    add t1, s1, t1
    
    lw t2, 12(t1)       # actif ? Si le missile est inactif (0), on ne l’affiche pas.
    beqz t2, M_aff_next
    
    lw a0, 0(t1)        # x
    lw a1, 4(t1)        # y
    li a2, 1            # largeur = 1
    mv a3, s2           # hauteur = longueur
    mv a4, s3           # couleur
    
    addi sp, sp, -4
    sw t0, 0(sp)
    jal I_rectangle
    lw t0, 0(sp)
    addi sp, sp, 4
    
M_aff_next:
    addi t0, t0, 1
    j M_aff_loop
    
M_aff_fin:
    lw s3, 0(sp)
    lw s2, 4(sp)
    lw s1, 8(sp)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    ret

# ========================================
# PARTIE 5 : Mouvement
# ========================================

J_deplacer:
    addi sp, sp, -12
    sw ra, 8(sp)
    sw t0, 4(sp)
    sw t1, 0(sp)
    
    # Lire RCR
    la t0, RCR
    lw t0, 0(t0)
    lw t1, 0(t0)
    beqz t1, J_dep_fin
    
    # Lire RDR
    la t0, RDR
    lw t0, 0(t0)
    lw t1, 0(t0)
    
    # Touche 'i' - gauche
    li t0, 'i'
    bne t1, t0, J_test_p
    la t0, J_x
    lw t1, 0(t0)
    addi t1, t1, -1
    bltz t1, J_dep_fin
    sw t1, 0(t0)
    j J_dep_fin
    
J_test_p:
    # Touche 'p' - droite
    li t0, 'p'
    bne t1, t0, J_test_o
    la t0, J_x
    lw t1, 0(t0)
    addi t1, t1, 1
    la t2, J_largeur
    lw t2, 0(t2)
    add t3, t1, t2
    la t2, I_largeur
    lw t2, 0(t2)
    bge t3, t2, J_dep_fin
    sw t1, 0(t0)
    j J_dep_fin
    
J_test_o:
    # Touche 'o' - tirer
    li t0, 'o'
    bne t1, t0, J_dep_fin
    jal M_tirer_joueur
    
J_dep_fin:
    lw t1, 0(sp)
    lw t0, 4(sp)
    lw ra, 8(sp)
    addi sp, sp, 12
    ret

M_tirer_joueur:
    addi sp, sp, -12
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)
    
    # Trouver un missile libre
    la t0, M_max
    lw t0, 0(t0)
    la t1, M_tableau
    lw t1, 0(t1)
    
    li t2, 0
M_tir_j_loop:
    bge t2, t0, M_tir_j_fin
    slli a0, t2, 4
    add a0, t1, a0
    lw a1, 12(a0)
    bnez a1, M_tir_j_next
    
   # Missile trouvé
    la a1, J_x
    lw a1, 0(a1)
    la a2, J_largeur
    lw a2, 0(a2)
    srli a2, a2, 1
    add a1, a1, a2
    sw a1, 0(a0)        # x = centre du joueur
    
    la a1, J_y
    lw a1, 0(a1)
    sw a1, 4(a0)        # y
    
    li a1, 1
    sw a1, 8(a0)        # direction = 1 (haut)
    sw a1, 12(a0)       # actif = 1
    
    j M_tir_j_fin
    
M_tir_j_next:
    addi t2, t2, 1
    j M_tir_j_loop
    
M_tir_j_fin:
    lw t2, 0(sp)
    lw t1, 4(sp)
    lw t0, 8(sp)
    addi sp, sp, 12
    ret

M_deplacer:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)
    
    la s0, M_max
    lw s0, 0(s0)
    la s1, M_tableau
    lw s1, 0(s1)
    la s2, M_vitesse
    lw s2, 0(s2)
    
    li t0, 0
M_dep_loop:
    bge t0, s0, M_dep_fin
    
    slli t1, t0, 4
    add t1, s1, t1
    
    lw t2, 12(t1)       # actif ?
    beqz t2, M_dep_next
    
    # Déplacer selon la direction
    lw t3, 8(t1)        # direction
    lw t4, 4(t1)        # y actuel
    
    mul t3, t3, s2
    sub t4, t4, t3      # y -= direction * vitesse
    
    # Vérifier les limites
    bltz t4, M_dep_desactiver
    la t5, I_hauteur
    lw t5, 0(t5)
    bge t4, t5, M_dep_desactiver
    
    sw t4, 4(t1)        # Nouvelle position
    j M_dep_next
    
M_dep_desactiver:
    sw zero, 12(t1)     # Désactiver
    
M_dep_next:
    addi t0, t0, 1
    j M_dep_loop
    
M_dep_fin:
    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

E_deplacer:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)
    
    # Vérifier si on doit tirer
    la t0, E_tir_compteur
    lw t1, 0(t0)
    addi t1, t1, 1
    la t2, E_tir_frequence
    lw t2, 0(t2)
    blt t1, t2, E_dep_pas_tir
    
    li t1, 0
    jal M_tirer_envahisseur
    
E_dep_pas_tir:
    la t0, E_tir_compteur
    sw t1, 0(t0)
    
    # Déplacer les envahisseurs
    la s0, E_nombre
    lw s0, 0(s0)
    la s1, E_tableau
    lw s1, 0(s1)
    la s2, E_direction
    lw s2, 0(s2)
    
    # Vérifier si on touche un bord
    li t6, 0            # Flag collision
    li t0, 0
E_dep_check:
    bge t0, s0, E_dep_check_fin
    
    li t1, 12
    mul t1, t0, t1
    add t1, s1, t1
    
    lw t2, 8(t1)        # vivant ?
    beqz t2, E_dep_check_next
    
    lw t3, 0(t1)        # x
    la t4, E_largeur
    lw t4, 0(t4)
    add t3, t3, t4
    
    # Si direction = 1 (droite), vérifier bord droit
    li t4, 1
    bne s2, t4, E_dep_check_gauche
    
    la t4, I_largeur
    lw t4, 0(t4)
    add t5, t3, s2
    bge t5, t4, E_dep_collision
    j E_dep_check_next
    
E_dep_check_gauche:
    # Si direction = -1 (gauche), vérifier bord gauche
    lw t3, 0(t1)
    add t5, t3, s2
    bltz t5, E_dep_collision
    j E_dep_check_next
    
E_dep_collision:
    li t6, 1
    
E_dep_check_next:
    addi t0, t0, 1
    j E_dep_check
    
E_dep_check_fin:
    # Si collision, descendre et changer de direction
    beqz t6, E_dep_move
    
    # Descendre
    la t0, E_descente
    lw t0, 0(t0)
    li t1, 0
E_dep_descendre:
    bge t1, s0, E_dep_desc_fin
    li t2, 12
    mul t2, t1, t2
    add t2, s1, t2
    
    lw t3, 8(t2)
    beqz t3, E_dep_desc_next
    
    lw t3, 4(t2)
    add t3, t3, t0
    sw t3, 4(t2)
    
    # Vérifier si atteint le sol
    la t4, O_y
    lw t4, 0(t4)
    bge t3, t4, E_dep_game_over
    
E_dep_desc_next:
    addi t1, t1, 1
    j E_dep_descendre
    
E_dep_desc_fin:
    # Changer de direction
    neg s2, s2
    la t0, E_direction
    sw s2, 0(t0)
    
E_dep_move:
    # Déplacer tous les envahisseurs
    li t0, 0
E_dep_move_loop:
    bge t0, s0, E_dep_move_fin
    
    li t1, 12
    mul t1, t0, t1
    add t1, s1, t1
    
    lw t2, 8(t1)
    beqz t2, E_dep_move_next
    
    lw t3, 0(t1)
    add t3, t3, s2
    sw t3, 0(t1)
    
E_dep_move_next:
    addi t0, t0, 1
    j E_dep_move_loop
    
E_dep_move_fin:
    lw s3, 0(sp)
    lw s2, 4(sp)
    lw s1, 8(sp)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    ret
    
E_dep_game_over:
    la t0, JEU_en_cours
    sw zero, 0(t0)
    la t0, JEU_victoire
    sw zero, 0(t0)
    j E_dep_move_fin

M_tirer_envahisseur:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)
    
    # Choisir un envahisseur vivant aléatoirement
    # Utiliser le temps comme générateur simple
    li a7, 30
    ecall
    
    la t0, E_nombre
    lw t0, 0(t0)
    remu t1, a0, t0     # Index aléatoire
    
    # Vérifier si vivant
    la t2, E_tableau
    lw t2, 0(t2)
    li t0, 12
    mul t0, t1, t0
    add t0, t2, t0
    
    lw t1, 8(t0)
    beqz t1, M_tir_e_fin
    
    # Trouver un missile libre
    la t1, M_max
    lw t1, 0(t1)
    la t2, M_tableau
    lw t2, 0(t2)
    
    li a1, 0
M_tir_e_loop:
    bge a1, t1, M_tir_e_fin
    slli a2, a1, 4
    add a2, t2, a2
    lw a3, 12(a2)
    bnez a3, M_tir_e_next
    
    # Missile trouvé
    lw a3, 0(t0)        # x envahisseur
    la a4, E_largeur
    lw a4, 0(a4)
    srli a4, a4, 1
    add a3, a3, a4
    sw a3, 0(a2)        # x
    
    lw a3, 4(t0)        # y envahisseur
    la a4, E_hauteur
    lw a4, 0(a4)
    add a3, a3, a4
    sw a3, 4(a2)        # y
    
    li a3, -1
    sw a3, 8(a2)        # direction = -1 (bas)
    
    li a3, 1
    sw a3, 12(a2)       # actif = 1
    
    j M_tir_e_fin
    
M_tir_e_next:
    addi a1, a1, 1
    j M_tir_e_loop
    
M_tir_e_fin:
    lw t2, 0(sp)
    lw t1, 4(sp)
    lw t0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# ========================================
# PARTIE 6-7 : Collisions
# ========================================

verifier_collisions:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s0, 0(sp)
    
    # Vérifier missiles contre envahisseurs
    jal collision_missile_envahisseurs
    
    # Vérifier missiles contre joueur
    jal collision_missile_joueur
    
    # Vérifier missiles contre obstacles
    jal collision_missile_obstacles
    
    # Vérifier fin du jeu
    jal verifier_fin_jeu
    
    lw s0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret

collision_missile_envahisseurs:
    addi sp, sp, -28
    sw ra, 24(sp)
    sw s0, 20(sp)
    sw s1, 16(sp)
    sw s2, 12(sp)
    sw s3, 8(sp)
    sw s4, 4(sp)
    sw s5, 0(sp)
    
    la s0, M_max
    lw s0, 0(s0)
    la s1, M_tableau
    lw s1, 0(s1)
    la s2, E_nombre
    lw s2, 0(s2)
    la s3, E_tableau
    lw s3, 0(s3)
    
    li s4, 0            # Index missile
CME_loop_m:
    bge s4, s0, CME_fin
    
    slli t0, s4, 4
    add t0, s1, t0
    
    lw t1, 12(t0)       # actif ?
    beqz t1, CME_next_m
    
    lw t1, 8(t0)        # direction
    li t2, 1
    bne t1, t2, CME_next_m  # Seulement missiles du joueur
    
    # Tester contre tous les envahisseurs
    li s5, 0
CME_loop_e:
    bge s5, s2, CME_next_m
    
    li t1, 12
    mul t1, s5, t1
    add t1, s3, t1
    
    lw t2, 8(t1)        # vivant ?
    beqz t2, CME_next_e
    
    # Vérifier intersection
    mv a0, t0           # Adresse missile
    mv a1, t1           # Adresse envahisseur
    
    addi sp, sp, -8
    sw t0, 4(sp)
    sw t1, 0(sp)
    jal M_intersecteRectangle
    lw t1, 0(sp)
    lw t0, 4(sp)
    addi sp, sp, 8
    
    beqz a0, CME_next_e
    
    # Collision détectée
    sw zero, 8(t1)      # Envahisseur mort
    sw zero, 12(t0)     # Missile désactivé
    j CME_next_m
    
CME_next_e:
    addi s5, s5, 1
    j CME_loop_e
    
CME_next_m:
    addi s4, s4, 1
    j CME_loop_m
    
CME_fin:
    lw s5, 0(sp)
    lw s4, 4(sp)
    lw s3, 8(sp)
    lw s2, 12(sp)
    lw s1, 16(sp)
    lw s0, 20(sp)
    lw ra, 24(sp)
    addi sp, sp, 28
    ret

collision_missile_joueur:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)
    
    la s0, M_max
    lw s0, 0(s0)
    la s1, M_tableau
    lw s1, 0(s1)
    
    li s2, 0
CMJ_loop:
    bge s2, s0, CMJ_fin
    
    slli t0, s2, 4
    add t0, s1, t0
    
    lw t1, 12(t0)
    beqz t1, CMJ_next
    
    lw t1, 8(t0)
    li t2, -1
    bne t1, t2, CMJ_next    # Seulement missiles ennemis
    
    # Créer rectangle joueur temporaire
    la t1, J_x
    lw t1, 0(t1)
    la t2, J_y
    lw t2, 0(t2)
    la t3, J_largeur
    lw t3, 0(t3)
    la t4, J_hauteur
    lw t4, 0(t4)
    
    addi sp, sp, -20
    sw t1, 0(sp)
    sw t2, 4(sp)
    sw t3, 8(sp)
    sw t4, 12(sp)
    sw t0, 16(sp)
    
    mv a0, t0
    mv a1, sp
    jal M_intersecteRectangle
    
    lw t0, 16(sp)
    addi sp, sp, 20
    
    beqz a0, CMJ_next
    
    # Collision - perdre une vie
    sw zero, 12(t0)
    la t1, J_vies
    lw t2, 0(t1)
    addi t2, t2, -1
    sw t2, 0(t1)
    
CMJ_next:
    addi s2, s2, 1
    j CMJ_loop
    
CMJ_fin:
    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

collision_missile_obstacles:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)
    sw s4, 0(sp)
    
    la s0, M_max
    lw s0, 0(s0)
    la s1, M_tableau
    lw s1, 0(s1)
    la s2, O_nombre
    lw s2, 0(s2)
    la s3, O_tableau
    lw s3, 0(s3)
    
    li s4, 0
CMO_loop_m:
    bge s4, s0, CMO_fin
    
    slli t0, s4, 4
    add t0, s1, t0
    
    lw t1, 12(t0)
    beqz t1, CMO_next_m
    
    # Tester contre obstacles
    li t5, 0
CMO_loop_o:
    bge t5, s2, CMO_next_m
    
    slli t1, t5, 3
    add t1, s3, t1
    
    addi sp, sp, -8
    sw t0, 4(sp)
    sw t1, 0(sp)
    
    mv a0, t0
    mv a1, t1
    jal M_intersecteRectangle
    
    lw t1, 0(sp)
    lw t0, 4(sp)
    addi sp, sp, 8
    
    beqz a0, CMO_next_o
    
    # Collision
    sw zero, 12(t0)
    j CMO_next_m
    
CMO_next_o:
    addi t5, t5, 1
    j CMO_loop_o
    
CMO_next_m:
    addi s4, s4, 1
    j CMO_loop_m
    
CMO_fin:
    lw s4, 0(sp)
    lw s3, 4(sp)
    lw s2, 8(sp)
    lw s1, 12(sp)
    lw s0, 16(sp)
    lw ra, 20(sp)
    addi sp, sp, 24
    ret

M_intersecteRectangle:
    addi sp, sp, -16
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)
    
    # a0 = adresse missile [x, y, dir, actif]
    # a1 = adresse rectangle [x, y, largeur, hauteur] ou [x, y] pour obstacles
    
    lw s0, 0(a0)        # mx
    lw s1, 4(a0)        # my
    
    lw s2, 0(a1)        # rx
    lw s3, 4(a1)        # ry
    
    # Déterminer largeur/hauteur du rectangle
    lw t0, 4(a1)
    la t1, O_tableau
    lw t1, 0(t1)
    blt a1, t1, MIR_envahisseur
    
    # C'est un obstacle
    la t2, O_largeur
    lw t2, 0(t2)
    la t3, O_hauteur
    lw t3, 0(t3)
    j MIR_test
    
MIR_envahisseur:
    la t2, E_largeur
    lw t2, 0(t2)
    la t3, E_hauteur
    lw t3, 0(t3)
    
MIR_test:
    # Vérifier si mx est dans [rx, rx+largeur]
    blt s0, s2, MIR_non
    add t4, s2, t2
    bge s0, t4, MIR_non
    
    # Vérifier si my est dans [ry, ry+hauteur]
    la t4, M_longueur
    lw t4, 0(t4)
    add t5, s1, t4      # my + longueur
    
    blt t5, s3, MIR_non
    add t6, s3, t3
    bge s1, t6, MIR_non
    
    # Intersection détectée
    li a0, 1
    j MIR_fin
    
MIR_non:
    li a0, 0
    
MIR_fin:
    lw s3, 0(sp)
    lw s2, 4(sp)
    lw s1, 8(sp)
    lw s0, 12(sp)
    addi sp, sp, 16
    ret

verifier_fin_jeu:
    addi sp, sp, -8
    sw t0, 4(sp)
    sw t1, 0(sp)
    
    # Vérifier si le joueur a perdu toutes ses vies
    la t0, J_vies
    lw t0, 0(t0)
    blez t0, fin_defaite
    
    # Vérifier si tous les envahisseurs sont morts
    la t0, E_nombre
    lw t0, 0(t0)
    la t1, E_tableau
    lw t1, 0(t1)
    
    li t2, 0            # Compteur vivants
    li t3, 0            # Index
VFJ_loop:
    bge t3, t0, VFJ_check
    
    li t4, 12
    mul t4, t3, t4
    add t4, t1, t4
    lw t5, 8(t4)
    
    add t2, t2, t5
    
    addi t3, t3, 1
    j VFJ_loop
    
VFJ_check:
    beqz t2, fin_victoire
    j VFJ_fin
    
fin_victoire:
    la t0, JEU_en_cours
    sw zero, 0(t0)
    la t0, JEU_victoire
    li t1, 1
    sw t1, 0(t0)
    j VFJ_fin
    
fin_defaite:
    la t0, JEU_en_cours
    sw zero, 0(t0)
    la t0, JEU_victoire
    sw zero, 0(t0)
    
VFJ_fin:
    lw t1, 0(sp)
    lw t0, 4(sp)
    addi sp, sp, 8
    ret
