# Partie 1 : La pause
# Programme qui affiche les entiers de 1 à 10
# avec une pause de 500ms entre chaque affichage
# Durée totale : 5 secondes

.data
    newline: .string "\n"

.text
.globl main

main:
    # Initialiser le compteur à 1
    li t0, 1               # ont met t0 = 1 pour commencer la boucle 
    li t1, 11              # t1 va etre notre arret de boucle 
boucle:
    # Vérifier si on a atteint 11 , car la focntion s arrete a 10
    bge t0, t1, fin        # Si t0 >= 11, on saute vers fin
    
    # Afficher la valeur de t0
    mv a0, t0              # on copie ici t0 dans a0 pour l'affichage
    li a7, 1               # 1 en a7 = print_int
    ecall
    
    # Afficher un retour à la ligne
    la a0, newline
    li a7, 4               # 4 = print_string
    ecall
    
    # Pause de 500 ms
    li a0, 500             #  On met 500  dans a0 pour la pause 
    li a7, 32              # 32 = sleep (en millisecondes)
    ecall
    
    # Incrémenter le compteur
    addi t0, t0, 1         # t0 = t0 + 1
    
    # Retour au début de la boucle
    j boucle

fin:
    # Terminer le programme
    li a7, 10              # 10 = exit
    ecall
