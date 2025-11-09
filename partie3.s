.data
    # Dimensions de l'image et des units
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
    COULEUR_ROUGE: .word 0x00FF0000

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

# Fonction : I_creer
I_creer:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t0, 8(sp)
    sw t1, 4(sp)

   # Calculer I_largeur = LARGEUR_PIXELS / UNIT_WIDTH
    la t0, LARGEUR_PIXELS         # Charge l'adresse de LARGEUR_PIXELS
    lw t0, 0(t0)                  # t0 = 256 (valeur)
    la t1, UNIT_WIDTH             # Charge l'adresse de UNIT_WIDTH  
    lw t1, 0(t1)                  # t1 = 8 (valeur)
    div t0, t0, t1                # t0 = 256 / 8 = 32
    la t1, I_largeur              # Charge l'adresse de I_largeur
    sw t0, 0(t1)                  # Stocke 32 dans I_largeur

    # Calculer I_hauteur = HAUTEUR_PIXELS / UNIT_HEIGHT
    la t0, HAUTEUR_PIXELS
    lw t0, 0(t0)
    la t1, UNIT_HEIGHT
    lw t1, 0(t1)
    div t0, t0, t1         # t0 = I_hauteur (en Units)
    la t1, I_hauteur
    sw t0, 0(t1)           # Sauvegarder I_hauteur

    # Calculer la taille nécessaire pour I_buff
    la t0, I_largeur
    lw t0, 0(t0)
    la t1, I_hauteur
    lw t1, 0(t1)
    mul t0, t0, t1         # t0 = nombre total de Units
    slli t0, t0, 2         # t0 = t0 * 4 (2**2) (car chaque Unit = 4 octets), cela décale tous les bits de t0 de 2 vers la gauche

    # Allouer la mémoire avec sbrk
    mv a0, t0
    li a7, 9               # 9 : sbrk (allocation mémoire)
    ecall
    # a0 contient maintenant l'adresse du buffer alloué

    # Sauvegarder l'adresse dans I_buff
    la t1, I_buff
    sw a0, 0(t1)

    lw t1, 4(sp)
    lw t0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# Fonction : I_xy_to_addr
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

# Fonction : I_addr_to_xy   
I_addr_to_xy:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)

    # Charger l'adresse de base I_buff
    la t0, I_buff
    lw t0, 0(t0)           # t0 = adresse de début du buffer

    # Charger I_largeur
    la t1, I_largeur
    lw t1, 0(t1)           # t1 = largeur en Units

    # Calculer l'offset depuis le début (en octets)
    sub t2, a0, t0         # t2 = adresse - I_buff (offset en octets)

    # Convertir l'offset en nombre de Units (÷4)
    srli t2, t2, 2         # t2 = offset / 4 (maintenant en Units)

    # Calculer y = offset / I_largeur
    div a1, t2, t1         # a1 = y (ligne)

    # Calculer x = offset % I_largeur  
    rem a0, t2, t1         # a0 = x (colonne)

    lw t2, 0(sp)
    lw t1, 4(sp)
    lw t0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
# Fonction : I_plot
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

# Fonction : I_effacer
# Cette fonction remplit tout l’écran en noir, pixel par pixel.
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

# Fonction : I_rectangle
# Dessine un rect de couleur en utilisant I_plot 
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

    # Calculer x_fin et y_fin pour savoir ou va finir la boucle 
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

# Fonction : I_buff_to_visu
#La fonct copie l’image temporaire I_buff (le "brouillon", la mémoire intermédiaire où on dessine) vers I_visu (la mémoire réellement affichée à l’écran).
I_buff_to_v :
 # t0 = I_buff 
 # t1 = I_visu 
 # t2 = taille totale à copier (32×32×4 = 4096 octets)
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
    mul t2, t2, t3         # # largeur × hauteur, nb de uunit 
    slli t2, t2, 2         # t2 = nombre d'octets
    
    # Boucle qui copie 4 octets par 4 octets
    # Boucle de copie
    li t3, 0               # t3 = compteur
copie_boucle:
# Lit 4 octets depuis I_buff
# Écrit 4 octets dans I_visu  
# Répète jusqu'à avoir tout copié
    bge t3, t2, copie_fin # Si t3 >= t2 suate copie fin 

    # Copier un mot (4 octets)
    add a0, t0, t3         # a0 pointe sur le premier pixel de I_buff, car t3 = 0 
    lw a2, 0(a0)           # lire depuis I_buff
    add a0, t1, t3         # adresse destination
    sw a2, 0(a0)           # écrire dans I_visu

    addi t3, t3, 4
    j copie_boucle

copie_fin:
    lw t3, 0(sp)
    lw t2, 4(sp)
    lw t1, 8(sp)
    lw t0, 12(sp)
    addi sp, sp, 16
    ret

# Fonction : test_animation
test_animation:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)
    sw s4, 0(sp)

    # Paramètres du rectangle
    li s0, 0               # x (commence à 0)
    li s1, 10              # y
    li s2, 5               # largeur
    li s3, 3               # hauteur
    la s4, COULEUR_ROUGE
    lw s4, 0(s4)           # couleur

    # Boucle d'animation (déplace le rectangle de gauche à droite)
anim_boucle:
    la t5, I_largeur
    lw t5, 0(t5)
    sub t5, t5, s2         # t5 = limite droite (I_largeur - largeur du rectangle)
    bge s0, t5, anim_fin   # Si x >= limite droite, termine

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
