# Partie 3 : Entrée synchrone au clavier
# Programme qui affiche t0 toutes les 500ms
# 'i' diminue t0, 'p' augmente t0, 'o' arrête le programme

.data
    # Adresses des registres MMIO pour le clavier
    RCR: .word 0xffff0000    # Registre de Contrôle du Récepteur
    RDR: .word 0xffff0004    # Registre de Données du Récepteur
    
    # Codes ASCII des touches
    TOUCHE_I: .byte 'i'      # Code ASCII de 'i' = 105
    TOUCHE_P: .byte 'p'      # Code ASCII de 'p' = 112
    TOUCHE_O: .byte 'o'      # Code ASCII de 'o' = 111
    
    # Messages pour l'affichage
    msg_valeur: .string "Valeur de t0 : "
    msg_newline: .string "\n"

.text
.globl main

main:
    # Initialisation de t0 à une valeur de départ (par exemple 0)
    li t0, 0
    
boucle_principale:
    # 1. Afficher la valeur actuelle de t0
    jal afficher_t0
    
    # 2. Vérifier si une touche a été pressée
    jal lire_clavier
    
    # 3. Attendre 500ms (pause)
    jal pause_500ms
    
    # 4. Retour au début de la boucle
    j boucle_principale

# ========================================
# Fonction : afficher_t0
# Affiche le message et la valeur de t0
# ========================================
afficher_t0:
    # Sauvegarder les registres utilisés
    addi sp, sp, -16
    sw ra, 12(sp)
    sw a0, 8(sp)
    sw t0, 4(sp)
    
    # Afficher le message "Valeur de t0 : "
    la a0, msg_valeur
    li a7, 4              # Syscall 4 : print_string
    ecall
    
    # Afficher la valeur de t0
    mv a0, t0
    li a7, 1              # Syscall 1 : print_int
    ecall
    
    # Afficher un retour à la ligne
    la a0, msg_newline
    li a7, 4              # Syscall 4 : print_string
    ecall
    
    # Restaurer les registres
    lw t0, 4(sp)
    lw a0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# ========================================
# Fonction : lire_clavier
# Vérifie si une touche est pressée et agit en conséquence
# Modifie : t0 (peut être incrémenté/décrémenté)
# ========================================
lire_clavier:
    # Sauvegarder les registres
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t1, 8(sp)
    sw t2, 4(sp)
    
    # Charger l'adresse du RCR (Registre de Contrôle)
    la t1, RCR
    lw t1, 0(t1)          # t1 = adresse 0xffff0000
    lw t2, 0(t1)          # t2 = contenu du RCR (0 ou 1)
    
    # Vérifier si une touche est pressée (RCR == 1)
    beqz t2, fin_lire_clavier  # Si RCR == 0, aucune touche pressée
    
    # Une touche est pressée, lire le code ASCII dans RDR
    la t1, RDR
    lw t1, 0(t1)          # t1 = adresse 0xffff0004
    lw t2, 0(t1)          # t2 = code ASCII de la touche (lecture du RDR)
                          # Note: cette lecture remet automatiquement RCR à 0
    
    # Vérifier quelle touche a été pressée
    
    # Est-ce 'i' ? (diminuer t0)
    li t1, 'i'
    beq t2, t1, touche_i_pressee
    
    # Est-ce 'p' ? (augmenter t0)
    li t1, 'p'
    beq t2, t1, touche_p_pressee
    
    # Est-ce 'o' ? (arrêter le programme)
    li t1, 'o'
    beq t2, t1, touche_o_pressee
    
    # Autre touche : ne rien faire
    j fin_lire_clavier

touche_i_pressee:
    # Diminuer t0
    addi t0, t0, -1
    j fin_lire_clavier

touche_p_pressee:
    # Augmenter t0
    addi t0, t0, 1
    j fin_lire_clavier

touche_o_pressee:
    # Arrêter le programme proprement
    lw t2, 4(sp)
    lw t1, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    
    # Syscall pour terminer le programme
    li a7, 10             # Syscall 10 : exit
    ecall

fin_lire_clavier:
    # Restaurer les registres
    lw t2, 4(sp)
    lw t1, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# ========================================
# Fonction : pause_500ms
# Met le processeur en pause pendant 500 millisecondes
# ========================================
pause_500ms:
    # Sauvegarder les registres
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp)
    
    # Charger 500 dans a0 (500 millisecondes)
    li a0, 500
    
    # Syscall 32 : sleep (pause en millisecondes)
    li a7, 32
    ecall
    
    # Restaurer les registres
    lw a0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret