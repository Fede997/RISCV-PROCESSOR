#-----------------------ITERATIVE-FACTORIAL------------------------------------#
#---Federico-Giusti------------------------------------------------------------#
#---Mirco-Mannino--------------------------------------------------------------#
#																			   #
# Description of 'Iterative factorial'                                         #
# This progam calculates the factorial of a number n						   #
#																			   #
# INPUT:	n  = 5															   #
# OUTPUT:	n! = 120 = 0x78													   #
#------------------------------------------------------------------------------#

.text
		addi t1, zero, 5		# n = 5                 00500313
		addi t0, zero, 1		# i = 1                 00100293
		addi t2, zero, 1		# n_Fattoriale = 1      00100393
		FOR_START:
		blt 	t1, t0, FOR_END #                       00534863
		mul		t2, t2, t0		# n_Fattoriale *= i     025383B3
		addi 	t0, t0, 1		# i++                   00128293
		jal 	FOR_START       #                       FF5FF0EF
		FOR_END:
