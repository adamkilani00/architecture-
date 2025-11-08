.data
    newline: .asciiz "\n"

.text
    li t0, 0           # Initialise t0 à 0

loop:
    # Vérifie si une touche a été pressée
    lw t1, 0xffff0000  # Lit la valeur de RCR (0xffff0000)
    beq t1, zero, no_key_pressed  # Si RCR == 0, aucune touche pressée

    # Une touche a été pressée : lit le code ASCII
    lw t2, 0xffff0004  # Lit la valeur de RDR (0xffff0004)

    # Teste la touche pressée
    li t3, 'i'         # Code ASCII de 'i'
    beq t2, t3, decrease_t0
    li t3, 'p'         # Code ASCII de 'p'
    beq t2, t3, increase_t0
    li t3, 'o'         # Code ASCII de 'o'
    beq t2, t3, end_program

    # Si la touche n'est ni 'i', ni 'p', ni 'o', ignore
    j no_key_pressed

decrease_t0:
    addi t0, t0, -1    # t0 = t0 - 1
    j no_key_pressed

increase_t0:
    addi t0, t0, 1     # t0 = t0 + 1
    j no_key_pressed

end_program:
    # Termine le programme
    li a7, 10          # Code de l'appel système pour exit
    ecall              # Appel système

no_key_pressed:
    # Affiche la valeur de t0
    mv a0, t0          # Place la valeur de t0 dans a0
    li a7, 1           # Code de l'appel système pour print_int
    ecall              # Appel système

    # Affiche un retour à la ligne
    la a0, newline     # Charge l'adresse de la chaîne newline
    li a7, 4           # Code de l'appel système pour print_string
    ecall              # Appel système

    # Pause de 500 ms
    li a0, 500         # 500 ms
    li a7, 32          # Code de l'appel système pour sleep
    ecall              # Appel système

    j loop             # Retourne au début de la boucle
