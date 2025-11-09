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
    jal I_creer       # Init image
    jal J_creer
    jal E_creer
    jal O_creer
    jal M_creer

boucle_jeu:
    jal I_effacer
    jal O_afficher
    jal E_afficher
    jal M_afficher
    jal J_afficher
    jal I_buff_to_visu
    jal J_deplacer
    jal M_deplacer
    jal E_deplacer
    jal verifier_collisions

    li a0, 50          # Pause 50ms
    li a7, 32
    ecall

    la t0, JEU_en_cours
    lw t0, 0(t0)
    bnez t0, boucle_jeu

    # Message fin de jeu
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
# CREATION OBJETS (simplifiée)
# ========================================

J_creer:
    ret   # Déjà initialisé par les variables globales

E_creer:
    la t0, E_nombre
    lw t0, 0(t0)
    li t1, 12
    mul t0, t0, t1       # taille totale
    mv a0, t0
    li a7, 9
    ecall
    la t1, E_tableau
    sw a0, 0(t1)

    # Initialisation positions
    la t0, E_nombre
    lw t0, 0(t0)
    la t1, E_tableau
    lw t1, 0(t1)
    la t2, E_espacement
    lw t2, 0(t2)
    la t3, E_largeur
    lw t3, 0(t3)
    add t2, t2, t3          # espacement total
    la t4, E_x_depart
    lw t4, 0(t4)
    la t5, E_y_depart
    lw t5, 0(t5)
    la t6, E_rangees
    lw t6, 0(t6)
    div t7, t0, t6           # envahisseurs par rangée

    li t8, 0
E_loop:
    bge t8, t0, E_fin
    rem t9, t8, t7           # colonne
    div s0, t8, t7           # rangée
    mul t9, t9, t2
    add t9, t9, t4
    li s1, 3
    mul s0, s0, s1
    add s0, s0, t5
    slli s2, t8, 2
    add s2, s2, t1
    sw t9, 0(s2)
    sw s0, 4(s2)
    li s3, 1
    sw s3, 8(s2)
    addi t8, t8, 1
    j E_loop
E_fin:
    ret

O_creer:
    la t0, O_nombre
    lw t0, 0(t0)
    slli t0, t0, 3
    mv a0, t0
    li a7, 9
    ecall
    la t1, O_tableau
    sw a0, 0(t1)

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
O_loop:
    bge t5, t0, O_fin
    mul t6, t5, t2
    addi t6, t6, 2
    slli s0, t5, 3
    add s0, t1, s0
    sw t6, 0(s0)
    sw t4, 4(s0)
    addi t5, t5, 1
    j O_loop
O_fin:
    ret

M_creer:
    la t0, M_max
    lw t0, 0(t0)
    slli t0, t0, 4
    mv a0, t0
    li a7, 9
    ecall
    la t1, M_tableau
    sw a0, 0(t1)

    la t0, M_max
    lw t0, 0(t0)
    la t1, M_tableau
    lw t1, 0(t1)
    li t2, 0
M_loop:
    bge t2, t0, M_fin
    slli t3, t2, 4
    add t3, t1, t3
    sw zero, 12(t3)   # inactif
    addi t2, t2, 1
    j M_loop
M_fin:
    ret

# ========================================
# AFFICHAGE (simplifié)
# ========================================

J_afficher:
    la a0, J_x
    lw a0, 0(a0)
    la a1, J_y
    lw a1, 0(a1)
    la a2, J_largeur
    lw a2, 0(a2)
    la a3, J_hauteur
    lw a3, 0(a3)
    la a4, J_couleur
    lw a4, 0(a4)
    jal I_rectangle
    ret

E_afficher:
    la t0, E_tableau
    lw t0, 0(t0)
    la t1, E_nombre
    lw t1, 0(t1)
    la t2, E_largeur
    lw t2, 0(t2)
    la t3, E_hauteur
    lw t3, 0(t3)
    la t4, E_couleur
    lw t4, 0(t4)

    li t5, 0
E_loop_aff:
    bge t5, t1, E_fin_aff
    slli t6, t5, 2
    add t6, t0, t6*3
    lw t7, 8(t6)
    beqz t7, E_skip
    lw a0, 0(t6)
    lw a1, 4(t6)
    mv a2, t2
    mv a3, t3
    mv a4, t4
    jal I_rectangle
E_skip:
    addi t5, t5, 1
    j E_loop_aff
E_fin_aff:
    ret

O_afficher:
    la t0, O_tableau
    lw t0, 0(t0)
    la t1, O_nombre
    lw t1, 0(t1)
    la t2, O_largeur
    lw t2, 0(t2)
    la t3, O_hauteur
    lw t3, 0(t3)
    la t4, O_couleur
    lw t4, 0(t4)

    li t5, 0
O_loop_aff:
    bge t5, t1, O_fin_aff
    slli t6, t5, 3
    add t6, t0, t6
    lw a0, 0(t6)
    lw a1, 4(t6)
    mv a2, t2
    mv a3, t3
    mv a4, t4
    jal I_rectangle
    addi t5, t5, 1
    j O_loop_aff
O_fin_aff:
    ret

M_afficher:
    la t0, M_tableau
    lw t0, 0(t0)
    la t1, M_max
    lw t1, 0(t1)
    la t2, M_longueur
    lw t2, 0(t2)
    la t3, M_couleur
    lw t3, 0(t3)

    li t4, 0
M_loop_aff:
    bge t4, t1, M_fin_aff
    slli t5, t4, 4
    add t5, t0, t5
    lw t6, 12(t5)
    beqz t6, M_skip
    lw a0, 0(t5)
    lw a1, 4(t5)
    li a2, 1
    mv a3, t2
    mv a4, t3
    jal I_rectangle
M_skip:
    addi t4, t4, 1
    j M_loop_aff
M_fin_aff:
    ret

# ========================================
# PARTIE 5 : Mouvement simplifié
# ========================================

J_deplacer:
    addi sp, sp, -12
    sw ra, 8(sp)
    sw t0, 4(sp)
    sw t1, 0(sp)
    
    # Lire RCR et RDR
    la t0, RCR
    lw t0, 0(t0)
    lw t1, 0(t0)
    beqz t1, J_dep_fin

    la t0, RDR
    lw t0, 0(t0)
    lw t1, 0(t0)

    # Touche gauche 'i'
    li t0, 'i'
    beq t1, t0, J_gauche
    # Touche droite 'p'
    li t0, 'p'
    beq t1, t0, J_droite
    # Touche tirer 'o'
    li t0, 'o'
    beq t1, t0, J_tirer
    j J_dep_fin

J_gauche:
    la t0, J_x
    lw t1, 0(t0)
    addi t1, t1, -1
    bltz t1, J_dep_fin
    sw t1, 0(t0)
    j J_dep_fin

J_droite:
    la t0, J_x
    lw t1, 0(t0)
    addi t1, t1, 1
    la t2, J_largeur
    lw t2, 0(t2)
    la t3, I_largeur
    lw t3, 0(t3)
    blt t1+t2, t3, J_dep_droite_ok
    j J_dep_fin
J_dep_droite_ok:
    sw t1, 0(t0)
    j J_dep_fin

J_tirer:
    jal M_tirer_joueur

J_dep_fin:
    lw t1, 0(sp)
    lw t0, 4(sp)
    lw ra, 8(sp)
    addi sp, sp, 12
    ret

# ----------------------------------------
# Déplacement et tir des missiles
# ----------------------------------------

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
M_loop:
    bge t0, s0, M_fin
    slli t1, t0, 4
    add t1, s1, t1
    lw t2, 12(t1)
    beqz t2, M_next

    lw t3, 8(t1)        # direction
    lw t4, 4(t1)        # y
    sub t4, t4, t3*s2
    bltz t4, M_desact
    la t5, I_hauteur
    lw t5, 0(t5)
    bge t4, t5, M_desact
    sw t4, 4(t1)
    j M_next
M_desact:
    sw zero, 12(t1)
M_next:
    addi t0, t0, 1
    j M_loop
M_fin:
    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

M_tirer_joueur:
    addi sp, sp, -12
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)

    la t0, M_max
    lw t0, 0(t0)
    la t1, M_tableau
    lw t1, 0(t1)
    
    li t2, 0
M_tir_loop:
    bge t2, t0, M_tir_fin
    slli a0, t2, 4
    add a0, t1, a0
    lw a1, 12(a0)
    bnez a1, M_next_missile

    # Initialiser missile
    la a1, J_x
    lw a1, 0(a1)
    la a2, J_largeur
    lw a2, 0(a2)
    srli a2, a2, 1
    add a1, a1, a2
    sw a1, 0(a0)

    la a1, J_y
    lw a1, 0(a1)
    sw a1, 4(a0)
    li a1, 1
    sw a1, 8(a0)
    sw a1, 12(a0)
    j M_tir_fin

M_next_missile:
    addi t2, t2, 1
    j M_tir_loop
M_tir_fin:
    lw t2, 0(sp)
    lw t1, 4(sp)
    lw t0, 8(sp)
    addi sp, sp, 12
    ret

# ----------------------------------------
# Déplacement des envahisseurs
# ----------------------------------------

E_deplacer:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)

    # Tir automatique
    la t0, E_tir_compteur
    lw t1, 0(t0)
    addi t1, t1, 1
    la t2, E_tir_frequence
    lw t2, 0(t2)
    blt t1, t2, E_no_tir
    li t1, 0
    jal M_tirer_envahisseur
E_no_tir:
    la t0, E_tir_compteur
    sw t1, 0(t0)

    # Déplacement envahisseurs
    la s0, E_nombre
    lw s0, 0(s0)
    la s1, E_tableau
    lw s1, 0(s1)
    la s2, E_direction
    lw s2, 0(s2)
    li t6, 0
    li t0, 0

E_check_loop:
    bge t0, s0, E_check_fin
    li t1, 12
    mul t1, t0, t1
    add t1, s1, t1
    lw t2, 8(t1)
    beqz t2, E_next_check
    lw t3, 0(t1)
    add t3, t3, s2
    la t4, I_largeur
    lw t4, 0(t4)
    blt t3, t4, E_next_check
    li t6, 1
E_next_check:
    addi t0, t0, 1
    j E_check_loop
E_check_fin:
    beqz t6, E_move

    # Descendre et inverser direction
    la t0, E_descente
    lw t0, 0(t0)
    li t1, 0
E_desc_loop:
    bge t1, s0, E_desc_fin
    li t2, 12
    mul t2, t1, t2
    add t2, s1, t2
    lw t3, 8(t2)
    beqz t3, E_desc_next
    lw t3, 4(t2)
    add t3, t3, t0
    sw t3, 4(t2)
E_desc_next:
    addi t1, t1, 1
    j E_desc_loop
E_desc_fin:
    neg s2, s2
    la t0, E_direction
    sw s2, 0(t0)

E_move:
    li t0, 0
E_move_loop:
    bge t0, s0, E_move_fin
    li t1, 12
    mul t1, t0, t1
    add t1, s1, t1
    lw t2, 8(t1)
    beqz t2, E_next_move
    lw t3, 0(t1)
    add t3, t3, s2
    sw t3, 0(t1)
E_next_move:
    addi t0, t0, 1
    j E_move_loop
E_move_fin:
    lw s3, 0(sp)
    lw s2, 4(sp)
    lw s1, 8(sp)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    ret

# ----------------------------------------
# Tir des envahisseurs
# ----------------------------------------

M_tirer_envahisseur:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)

    li a7, 30
    ecall

    la t0, E_nombre
    lw t0, 0(t0)
    remu t1, a0, t0

    la t2, E_tableau
    lw t2, 0(t2)
    li t0, 12
    mul t0, t1, t0
    add t0, t2, t0
    lw t1, 8(t0)
    beqz t1, M_env_fin

    la t1, M_max
    lw t1, 0(t1)
    la t2, M_tableau
    lw t2, 0(t2)
    li a1, 0
M_env_loop:
    bge a1, t1, M_env_fin
    slli a2, a1, 4
    add a2, t2, a2
    lw a3, 12(a2)
    bnez a3, M_env_next
    # Missile libre trouvé
    lw a3, 0(t0)
    la a4, E_largeur
    lw a4, 0(a4)
    srli a4, a4, 1
    add a3, a3, a4
    sw a3, 0(a2)
    lw a3, 4(t0)
    la a4, E_hauteur
    lw a4, 0(a4)
    add a3, a3, a4
    sw a3, 4(a2)
    li a3, -1
    sw a3, 8(a2)
    li a3, 1
    sw a3, 12(a2)
    j M_env_fin
M_env_next:
    addi a1, a1, 1
    j M_env_loop
M_env_fin:
    lw t2, 0(sp)
    lw t1, 4(sp)
    lw t0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# ========================================
# PARTIE 6-7 : Collisions simplifié
# ========================================

verifier_collisions:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s0, 0(sp)

    jal collision_missile_envahisseurs
    jal collision_missile_joueur
    jal collision_missile_obstacles
    jal verifier_fin_jeu

    lw s0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret

# ----------------------------------------
# Missiles contre envahisseurs
# ----------------------------------------

collision_missile_envahisseurs:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)

    la s0, M_max
    lw s0, 0(s0)
    la s1, M_tableau
    lw s1, 0(s1)
    la s2, E_nombre
    lw s2, 0(s2)
    la s3, E_tableau
    lw s3, 0(s3)

    li t4, 0
CME_missile_loop:
    bge t4, s0, CME_fin
    slli t0, t4, 4
    add t0, s1, t0
    lw t1, 12(t0)
    beqz t1, CME_next
    lw t1, 8(t0)
    li t2, 1
    bne t1, t2, CME_next

    li t5, 0
CME_env_loop:
    bge t5, s2, CME_next
    li t1, 12
    mul t1, t5, t1
    add t1, s3, t1
    lw t2, 8(t1)
    beqz t2, CME_next_env

    mv a0, t0
    mv a1, t1
    jal M_intersecteRectangle
    beqz a0, CME_next_env

    sw zero, 8(t1)      # Envahisseur mort
    sw zero, 12(t0)     # Missile désactivé
    j CME_next
CME_next_env:
    addi t5, t5, 1
    j CME_env_loop
CME_next:
    addi t4, t4, 1
    j CME_missile_loop
CME_fin:
    lw s3, 4(sp)
    lw s2, 8(sp)
    lw s1, 12(sp)
    lw s0, 16(sp)
    lw ra, 20(sp)
    addi sp, sp, 24
    ret

# ----------------------------------------
# Missiles contre joueur
# ----------------------------------------

collision_missile_joueur:
    addi sp, sp, -12
    sw ra, 8(sp)
    sw s0, 4(sp)
    sw s1, 0(sp)

    la s0, M_max
    lw s0, 0(s0)
    la s1, M_tableau
    lw s1, 0(s1)

    li t0, 0
CMJ_loop:
    bge t0, s0, CMJ_fin
    slli t1, t0, 4
    add t1, s1, t1
    lw t2, 12(t1)
    beqz t2, CMJ_next
    lw t2, 8(t1)
    li t3, -1
    bne t2, t3, CMJ_next

    # Adresse temporaire joueur
    la a1, J_x
    la a2, J_y
    la a3, J_largeur
    la a4, J_hauteur

    addi sp, sp, -16
    sw t1, 0(sp)
    mv a0, t1
    mv a1, a1
    jal M_intersecteRectangle
    lw t1, 0(sp)
    addi sp, sp, 16
    beqz a0, CMJ_next

    sw zero, 12(t1)        # Missile désactivé
    la t2, J_vies
    lw t3, 0(t2)
    addi t3, t3, -1
    sw t3, 0(t2)

CMJ_next:
    addi t0, t0, 1
    j CMJ_loop
CMJ_fin:
    lw s1, 0(sp)
    lw s0, 4(sp)
    lw ra, 8(sp)
    addi sp, sp, 12
    ret

# ----------------------------------------
# Missiles contre obstacles
# ----------------------------------------

collision_missile_obstacles:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    la s0, M_max
    lw s0, 0(s0)
    la s1, M_tableau
    lw s1, 0(s1)
    la s2, O_nombre
    lw s2, 0(s2)
    la s3, O_tableau
    lw s3, 0(s3)

    li t0, 0
CMO_m_loop:
    bge t0, s0, CMO_fin
    slli t1, t0, 4
    add t1, s1, t1
    lw t2, 12(t1)
    beqz t2, CMO_next

    li t3, 0
CMO_o_loop:
    bge t3, s2, CMO_next
    slli t4, t3, 3
    add t4, s3, t4
    mv a0, t1
    mv a1, t4
    jal M_intersecteRectangle
    beqz a0, CMO_next_o
    sw zero, 12(t1)
    j CMO_next
CMO_next_o:
    addi t3, t3, 1
    j CMO_o_loop

CMO_next:
    addi t0, t0, 1
    j CMO_m_loop
CMO_fin:
    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# ----------------------------------------
# Intersection rectangle simple
# ----------------------------------------

M_intersecteRectangle:
    addi sp, sp, -16
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)

    lw s0, 0(a0)      # mx
    lw s1, 4(a0)      # my
    lw s2, 0(a1)      # rx
    lw s3, 4(a1)      # ry

    # Largeur/hauteur
    la t0, O_tableau
    lw t0, 0(t0)
    blt a1, t0, MIR_env
    la t2, O_largeur
    lw t2, 0(t2)
    la t3, O_hauteur
    lw t3, 0(t3)
    j MIR_test
MIR_env:
    la t2, E_largeur
    lw t2, 0(t2)
    la t3, E_hauteur
    lw t3, 0(t3)

MIR_test:
    blt s0, s2, MIR_non
    add t4, s2, t2
    bge s0, t4, MIR_non
    add t5, s1, M_longueur
    blt t5, s3, MIR_non
    add t6, s3, t3
    bge s1, t6, MIR_non
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

# ----------------------------------------
# Vérifier fin de jeu
# ----------------------------------------

verifier_fin_jeu:
    addi sp, sp, -8
    sw t0, 4(sp)
    sw t1, 0(sp)

    la t0, J_vies
    lw t0, 0(t0)
    blez t0, fin_defaite

    la t0, E_nombre
    lw t0, 0(t0)
    la t1, E_tableau
    lw t1, 0(t1)

    li t2, 0
    li t3, 0
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
