# Partie 4 : Les images (Bitmap Display)
# Système d'affichage pour le jeu Space Invaders

.data
    # ========================================
    # 1. Variables globales pour l'image
    # ========================================
    # À configurer selon vos choix dans Bitmap Display
    LARGEUR_PIXELS: .word 256      # Largeur totale en pixels
    HAUTEUR_PIXELS: .word 256      # Hauteur totale en pixels
    UNIT_WIDTH: .word 8            # Largeur d'une Unit en pixels
    UNIT_HEIGHT: .word 8           # Hauteur d'une Unit en pixels
    
    # Variables calculées (nombre de Units)
    I_largeur: .word 0             # Sera calculé : 256/8 = 32 Units
    I_hauteur: .word 0             # Sera calculé : 256/8 = 32 Units
    
    # Adresses des buffers d'image
    I_visu: .word 0x10010000       # Buffer visible (adresse fixe dans Bitmap Display)
    I_buff: .word 0                # Buffer de travail (alloué dynamiquement)
    
    # Couleurs prédéfinies
    COULEUR_NOIR: .word 0x00000000
    COULEUR_ROUGE: .word 0x00ff0000
    COULEUR_VERT: .word 0x0000ff00
    COULEUR_BLEU: .word 0x000000ff
    COULEUR_JAUNE: .word 0x00ffff00
    COULEUR_BLANC: .word 0x00ffffff

.text
.globl main

main:
    # Initialiser le système d'image
    jal I_creer
    
    # Tester l'affichage avec une animation
    jal test_animation
    
    # Fin du programme
    li a7, 10
    ecall

# ========================================
# Fonction : I_creer
# Initialise le système d'image
# - Calcule I_largeur et I_hauteur
# - Alloue la mémoire pour I_buff
# ========================================
I_creer:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t0, 8(sp)
    sw t1, 4(sp)
    
    # Calculer I_largeur = LARGEUR_PIXELS / UNIT_WIDTH
    la t0, LARGEUR_PIXELS
    lw t0, 0(t0)
    la t1, UNIT_WIDTH
    lw t1, 0(t1)
    div t0, t0, t1         # t0 = I_largeur (en Units)
    la t1, I_largeur
    sw t0, 0(t1)           # Sauvegarder I_largeur
    
    # Calculer I_hauteur = HAUTEUR_PIXELS / UNIT_HEIGHT
    la t0, HAUTEUR_PIXELS
    lw t0, 0(t0)
    la t1, UNIT_HEIGHT
    lw t1, 0(t1)
    div t0, t0, t1         # t0 = I_hauteur (en Units)
    la t1, I_hauteur
    sw t0, 0(t1)           # Sauvegarder I_hauteur
    
    # Calculer la taille nécessaire pour I_buff
    # Taille = I_largeur * I_hauteur * 4 octets
    la t0, I_largeur
    lw t0, 0(t0)
    la t1, I_hauteur
    lw t1, 0(t1)
    mul t0, t0, t1         # t0 = nombre total de Units
    slli t0, t0, 2         # t0 = t0 * 4 (car chaque Unit = 4 octets)
    
    # Allouer la mémoire avec sbrk
    mv a0, t0
    li a7, 9               # Syscall 9 : sbrk (allocation mémoire)
    ecall
    # a0 contient maintenant l'adresse du buffer alloué
    
    # Sauvegarder l'adresse dans I_buff
    la t0, I_buff
    sw a0, 0(t0)
    
    lw t1, 4(sp)
    lw t0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# ========================================
# Fonction : I_xy_to_addr
# Convertit des coordonnées (x, y) en adresse mémoire
# Entrée : a0 = x, a1 = y
# Sortie : a0 = adresse dans I_buff
# Formule : adresse = I_buff + (y * I_largeur + x) * 4
# ========================================
I_xy_to_addr:
    addi sp, sp, -12
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)
    
    # Charger I_largeur
    la t0, I_largeur
    lw t0, 0(t0)
    
    # Calculer offset = (y * I_largeur + x)
    mul t1, a1, t0         # t1 = y * I_largeur
    add t1, t1, a0         # t1 = y * I_largeur + x
    slli t1, t1, 2         # t1 = offset * 4 (octets)
    
    # Ajouter l'adresse de base I_buff
    la t2, I_buff
    lw t2, 0(t2)
    add a0, t2, t1         # a0 = I_buff + offset
    
    lw t2, 0(sp)
    lw t1, 4(sp)
    lw t0, 8(sp)
    addi sp, sp, 12
    ret

# ========================================
# Fonction : I_addr_to_xy
# Convertit une adresse mémoire en coordonnées (x, y)
# Entrée : a0 = adresse dans I_buff
# Sortie : a0 = x, a1 = y
# ========================================
I_addr_to_xy:
    addi sp, sp, -12
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)
    
    # Calculer offset = adresse - I_buff
    la t0, I_buff
    lw t0, 0(t0)
    sub t0, a0, t0         # t0 = offset en octets
    srli t0, t0, 2         # t0 = offset en Units (diviser par 4)
    
    # Charger I_largeur
    la t1, I_largeur
    lw t1, 0(t1)
    
    # y = offset / I_largeur
    div a1, t0, t1
    
    # x = offset % I_largeur
    rem a0, t0, t1
    
    lw t2, 0(sp)
    lw t1, 4(sp)
    lw t0, 8(sp)
    addi sp, sp, 12
    ret

# ========================================
# Fonction : I_plot
# Colorie un pixel à la position (x, y) avec une couleur
# Entrée : a0 = x, a1 = y, a2 = couleur
# CHOIX DE REPRÉSENTATION : On utilise (x, y) car c'est plus intuitif
# pour dessiner. La conversion en adresse est faite par I_xy_to_addr.
# ========================================
I_plot:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw a0, 12(sp)
    sw a1, 8(sp)
    sw a2, 4(sp)
    sw t0, 0(sp)
    
    # Sauvegarder la couleur
    mv t0, a2
    
    # Convertir (x, y) en adresse
    jal I_xy_to_addr       # a0 contient maintenant l'adresse
    
    # Écrire la couleur à cette adresse
    sw t0, 0(a0)
    
    lw t0, 0(sp)
    lw a2, 4(sp)
    lw a1, 8(sp)
    lw a0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    ret

# ========================================
# Fonction : I_effacer
# Remplit toute l'image avec du noir
# ========================================
I_effacer:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)
    
    # Charger les dimensions
    la s0, I_largeur
    lw s0, 0(s0)           # s0 = I_largeur
    la s1, I_hauteur
    lw s1, 0(s1)           # s1 = I_hauteur
    
    # Couleur noire
    la s2, COULEUR_NOIR
    lw s2, 0(s2)
    
    # Boucle sur y
    li s3, 0               # s3 = y
effacer_boucle_y:
    bge s3, s1, effacer_fin
    
    # Boucle sur x
    li t0, 0               # t0 = x
effacer_boucle_x:
    bge t0, s0, effacer_next_y
    
    # Dessiner le pixel (x, y) en noir
    mv a0, t0              # a0 = x
    mv a1, s3              # a1 = y
    mv a2, s2              # a2 = noir
    jal I_plot
    
    addi t0, t0, 1
    j effacer_boucle_x
    
effacer_next_y:
    addi s3, s3, 1
    j effacer_boucle_y
    
effacer_fin:
    lw s3, 0(sp)
    lw s2, 4(sp)
    lw s1, 8(sp)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    ret

# ========================================
# Fonction : I_rectangle
# Dessine un rectangle plein
# Entrée : a0 = x (coin sup gauche)
#          a1 = y (coin sup gauche)
#          a2 = largeur
#          a3 = hauteur
#          a4 = couleur
# ========================================
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
    
    # Sauvegarder les paramètres
    mv s0, a0              # s0 = x_depart
    mv s1, a1              # s1 = y_depart
    mv s2, a2              # s2 = largeur
    mv s3, a3              # s3 = hauteur
    mv s4, a4              # s4 = couleur
    
    # Calculer x_fin et y_fin
    add s5, s0, s2         # s5 = x_fin
    add s6, s1, s3         # s6 = y_fin
    
    # Boucle sur y
    mv t0, s1              # t0 = y
rect_boucle_y:
    bge t0, s6, rect_fin
    
    # Boucle sur x
    mv t1, s0              # t1 = x
rect_boucle_x:
    bge t1, s5, rect_next_y
    
    # Dessiner le pixel (x, y)
    mv a0, t1              # a0 = x
    mv a1, t0              # a1 = y
    mv a2, s4              # a2 = couleur
    jal I_plot
    
    addi t1, t1, 1
    j rect_boucle_x
    
rect_next_y:
    addi t0, t0, 1
    j rect_boucle_y
    
rect_fin:
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

# ========================================
# Fonction : I_buff_to_visu
# Copie le contenu de I_buff vers I_visu
# (pour le double buffering)
# ========================================
I_buff_to_visu:
    addi sp, sp, -16
    sw t0, 12(sp)
    sw t1, 8(sp)
    sw t2, 4(sp)
    sw t3, 0(sp)
    
    # Charger les adresses
    la t0, I_buff
    lw t0, 0(t0)           # t0 = adresse source (I_buff)
    la t1, I_visu
    lw t1, 0(t1)           # t1 = adresse destination (I_visu)
    
    # Calculer le nombre d'octets à copier
    la t2, I_largeur
    lw t2, 0(t2)
    la t3, I_hauteur
    lw t3, 0(t3)
    mul t2, t2, t3         # t2 = nombre de Units
    slli t2, t2, 2         # t2 = nombre d'octets
    
    # Boucle de copie
    li t3, 0               # t3 = compteur
copie_boucle:
    bge t3, t2, copie_fin
    
    # Copier un mot (4 octets)
    add a0, t0, t3         # adresse source
    add a1, t1, t3         # adresse destination
    lw a2, 0(a0)           # lire depuis I_buff
    sw a2, 0(a1)           # écrire dans I_visu
    
    addi t3, t3, 4
    j copie_boucle
    
copie_fin:
    lw t3, 0(sp)
    lw t2, 4(sp)
    lw t1, 8(sp)
    lw t0, 12(sp)
    addi sp, sp, 16
    ret

# ========================================
# Fonction : test_animation
# Dessine un rectangle qui se déplace
# ========================================
test_animation:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)
    sw s4, 0(sp)
    
    # Paramètres du rectangle
    li s0, 5               # x
    li s1, 10              # y
    li s2, 5               # largeur
    li s3, 3               # hauteur
    la s4, COULEUR_ROUGE
    lw s4, 0(s4)           # couleur
    
    # Boucle d'animation (20 frames)
    li t6, 0
anim_boucle:
    li t5, 20
    bge t6, t5, anim_fin
    
    # Effacer I_buff
    jal I_effacer
    
    # Dessiner le rectangle dans I_buff
    mv a0, s0
    mv a1, s1
    mv a2, s2
    mv a3, s3
    mv a4, s4
    jal I_rectangle
    
    # Copier I_buff vers I_visu
    jal I_buff_to_visu
    
    # Pause de 50ms
    li a0, 50
    li a7, 32
    ecall
    
    # Déplacer le rectangle (vers la droite)
    addi s0, s0, 1
    
    addi t6, t6, 1
    j anim_boucle
    
anim_fin:
    lw s4, 0(sp)
    lw s3, 4(sp)
    lw s2, 8(sp)
    lw s1, 12(sp)
    lw s0, 16(sp)
    lw ra, 20(sp)
    addi sp, sp, 24
    ret