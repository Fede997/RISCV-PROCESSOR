#-----------------------------SUMMATION----------------------------------------#
#---Federico Giusti------------------------------------------------------------#
#---Mirco Mannino--------------------------------------------------------------#
#                                                                              #
# Decription of 'summation':																									 #
# This program calculates the summation of the numbers from 0 to n             #
#                                                                              #
# INPUT:   n = 5                                                               #
# OUTPUT:  result_expected = 15 (= 0xF)                                        #
#------------------------------------------------------------------------------#
.text
addi 			t0, zero, 5 						# n = 5					0x0050'0293
addi 			t1, zero, 0							# sum = 0				0x0000'0313
addi 			t2, zero, 1							# i = 1					0x00100393
FOR_START:
	slt 		t3, t2, t0							# (i < n)?			0x0053AE33
	beq 		t2, t0, FOR_BODY				# (i == n)?		  0x00538463
	beq 		t3, zero, FOR_END				#               0x000E0863
	FOR_BODY:
	add 		t1, t1, t2 							# sum += i		  0x00730333
	addi 		t2, t2, 1							  # i++					  0x00138393
	j			FOR_START							    #               0xFEDFF06F
FOR_END:
