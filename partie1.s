# Partie 1 : La pause
# Programme qui affiche les entiers de 1 � 10
# avec une pause de 500ms entre chaque affichage
# Dur�e totale : 5 secondes

.data
    newline: .string "\n"

.text
.globl main

main:
    # Initialiser le compteur � 1
    li t0, 1               # t0 = compteur (commence � 1)
    li t1, 11              # t1 = limite (s'arr�te � 10)

boucle:
    # V�rifier si on a atteint 11 (donc fini avec 10)
    bge t0, t1, fin        # Si t0 >= 11, terminer
    
    # Afficher la valeur de t0
    mv a0, t0              # Copier t0 dans a0 pour l'affichage
    li a7, 1               # Syscall 1 : print_int
    ecall
    
    # Afficher un retour � la ligne
    la a0, newline
    li a7, 4               # Syscall 4 : print_string
    ecall
    
    # Pause de 500 millisecondes
    li a0, 500             # Charger 500 dans a0
    li a7, 32              # Syscall 32 : sleep (en millisecondes)
    ecall
    
    # Incr�menter le compteur
    addi t0, t0, 1         # t0 = t0 + 1
    
    # Retour au d�but de la boucle
    j boucle

fin:
    # Terminer le programme
    li a7, 10              # Syscall 10 : exit
    ecall