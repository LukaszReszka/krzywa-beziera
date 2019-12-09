#	Program rysujący trójpunktową krzywą Beziera
#	Autor: Łukasz Reszka
#	laboratorium ARKO grupa 103

	.data
	
welcome:	.asciiz  "*****Quadratic Bézier curves printer (in BMP files)*****\n"

get_file_name:	.asciiz  "\nEnter the name of the BMP file (up to 31 characters):\n"
creating_curve:	.asciiz  "\nGenerating Bézier curve...\n"
curve_done:	.asciiz  "\nBézier curve generated!!!\n"

#coordinates of distinct points
get_first_x:	.asciiz  "\nEnter x coordinate of the first point:\n"
get_first_y:	.asciiz  "\nEnter y coordinate of the first point:\n"
get_second_x:	.asciiz  "\nEnter x coordinate of the second point:\n"
get_second_y:	.asciiz  "\nEnter y coordinate of the second point:\n"
get_third_x:	.asciiz  "\nEnter x coordinate of the third point:\n"
get_third_y:	.asciiz  "\nEnter y coordinate of the third point:\n"

#errors' messages
file_not_found:	.asciiz	 "\nFile not found\n"
wrong_file:	.asciiz	 "\nInappropriate file\n"
wrong_coordinate: .asciiz "\nInappropriate coordinate\n"
	

#data buffers
header:		.space  54
file_name:	.space 32

	.text
	.globl main

main:
	la $a0, welcome
	li $v0, 4
	syscall
	
choosing_file:

	la $a0, get_file_name	#requesting for file's name
	li $v0, 4
	syscall
	
	la $a0, file_name
	li $a1, 32		#entering file name
	li $v0, 8
	syscall
		
process_file_name:

	move $t0, $a0
	li $t1, ' '
	addiu $t0, $t0, -1

  next_sign_loop:
	addiu $t0, $t0, 1
	lb $t2, ($t0)
	bge $t2, $t1, next_sign_loop	
	
	li $t2, '\0'		#terminating file's name with '\0'
	sb $t2, ($t0)

opening_file:
		
	la $a0, file_name
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	
	bltz $v0, error_file_not_found		#if file not found...
	
	move $s0, $v0		#saving file descriptor

read_header:	
	
	move $a0, $s0
	la $a1, header
	li $a2, 54
	li $v0, 14
	syscall

check_header_correctness:
	
	bne $v0, 54, error_wrong_file	#if header < 54 bytes...
	
	la $t0, header		#checking ID field (should be "BM")
	lb $t1, ($t0)
	bne $t1, 'B', error_wrong_file
	
	lb $t1, 1($t0)
	bne $t1, 'M', error_wrong_file
	
read_dimensions_from_header:
	
	ulw $t7, 2($t0)		#saving the size of the file, ...
	ulw $t8, 18($t0)	# ... the width ...
	ulw $t9, 22($t0)	# ... and the height of bitmap (in pixels)
	
reset_file_pointer:

	move $a0, $s0		#closing file
	li $v0, 16
	syscall
	
	la $a0, file_name	#re-opening the file
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	
	move $s0, $v0		#saving new file descriptor 
	
allocate_heap_memory:
	
	move $a0, $t7
	li $v0, 9
	syscall
	
	move $s7, $v0		#saving the adress of alocated memory
	
read_whole_file:
	
	move $a0, $s0
	move $a1, $s7 
	move $a2, $t7
	li $v0, 14		#reading characters into allocated memory
	syscall

	bne $v0, $t7, error_wrong_file	#if number of the read characters =/= size of the file...
	
close_file:

	move $a0, $s0
	li $v0, 16
	syscall
	
	move $s0, $s7
	addiu $s0, $s0, 54	#setting $s0 on the begining of the pixel array
	
get_coordinates:

	la $a0, get_first_x	#getting first coordinate of the first point
	li $v0, 4
	syscall	
		
	li $v0, 5
	syscall
	
	move $s1, $v0
	
	bltz $s1, error_wrong_coordinate	#checking if 0 < x < width
	bgt $s1, $t8, error_wrong_coordinate
	
	la $a0, get_first_y		#getting second coordinate of the first point
	li $v0, 4
	syscall	
		
	li $v0, 5
	syscall
	
	move $s2, $v0
	
	bltz $s2, error_wrong_coordinate	#checking if 0 < y < height
	bgt $s2, $t9, error_wrong_coordinate
	
	
	la $a0, get_second_x		#getting coordinates of the second point
	li $v0, 4
	syscall	
		
	li $v0, 5
	syscall
	
	move $s3, $v0
	
	bltz $s3, error_wrong_coordinate
	bgt $s3, $t8, error_wrong_coordinate
	
	la $a0, get_second_y
	li $v0, 4
	syscall
		
	li $v0, 5
	syscall
	
	move $s4, $v0
	
	bltz $s4, error_wrong_coordinate
	bgt $s4, $t9, error_wrong_coordinate
	
	
	la $a0, get_third_x		#getting coordinates of the third point
	li $v0, 4
	syscall	
		
	li $v0, 5
	syscall
	
	move $s5, $v0
	
	bltz $s5, error_wrong_coordinate
	bgt $s5, $t8, error_wrong_coordinate
	
	la $a0, get_third_y
	li $v0, 4
	syscall	
		
	li $v0, 5
	syscall
	
	move $s6, $v0
	
	bltz $s6, error_wrong_coordinate
	bgt $s6, $t9, error_wrong_coordinate
	
generate_curve_message:

	la $a0, creating_curve
	li $v0, 4
	syscall	

calculate_padding:

	mulu $t8, $t8, 3	#width in pixels*3 byte per pixel
	andi $t0, $t8, 3	#modulo 4
	li $t1, 4
	subu $t1, $t1, $t0	
	andi $t1, $t1, 3	#padding bytes that should be added
	addu $t8, $t8, $t1	#width in bytes (instead of width in pixels)
	
whiten_pixels:
	
	mulu $t0, $t8, $t9	#height*width in bytes = total  size of pixel array
	move $t1, $s0		#$t1 is at the begining of pixel array
	li $t2, 0xFF		#white color
	
  white_pixel_loop:
  	sb  $t2, ($t1)
  	addiu $t1, $t1, 1
  	addiu $t0, $t0, -1
  	bnez $t0, white_pixel_loop
  	
  	
draw_Bezier_curve:	#format -> 21 b for integral part, 11 b for fractional part 

	li $t0, 1	#t variable in formula P(t) = A(1-t)^2+2Bt(1-t)+Ct^2, 0 =< t =< 1
	sll $t0, $t0, 11
	
	sll $s1, $s1, 11	#saving coordinates in described format 
	sll $s2, $s2, 11
	sll $s3, $s3, 11
	sll $s4, $s4, 11
	sll $s5, $s5, 11
	sll $s6, $s6, 11
	
  calculate_coordinates_loop:
  	li $t3, 1
  	sll $t3, $t3, 11
  	subu $t3, $t3, $t0	#(1-t)
  	
  	mulu $t4, $t3, $t3	#(1-t)^2
  	srl $t4, $t4, 11
  	
  	mulu $t5, $t0, $t0	#t^2
  	srl $t5, $t5, 11
  	
  x_coordinate:
	
	move $t6, $s1
	mulu $t6, $t6, $t4	#A(1-t)^2
	srl $t6, $t6, 11
	move $t1, $t6		#calculated x in $t1
	
	move $t6, $s5
	mulu $t6, $t6, $t5	#Ct^2
	srl $t6, $t6, 11
	addu $t1, $t1, $t6	#in $t1 A(1-t)^2+Ct^2
	
	move $t6, $s3
	mulu $t6, $t6, $t0
	srl $t6, $t6, 11	#Bt
	mulu $t6, $t6, $t3
	srl $t6, $t6, 10	#2Bt(1-t)
	addu $t1, $t1, $t6	#in $t1 P(t)
	
	srl $t1, $t1, 11	#cutting the fractional part of x
	
  y_coordinate:
	
	move $t6, $s2
	mulu $t6, $t6, $t4	#A(1-t)^2
	srl $t6, $t6, 11
	move $t2, $t6		#calculated y in $t1
	
	move $t6, $s6
	mulu $t6, $t6, $t5	#Ct^2
	srl $t6, $t6, 11
	addu $t2, $t2, $t6	#in $t1 A(1-t)^2+Ct^2
	
	move $t6, $s4
	mul $t6, $t6, $t0
	srl $t6, $t6, 11	#Bt
	mulu $t6, $t6, $t3
	srl $t6, $t6, 10	#2Bt(1-t)
	addu $t2, $t2, $t6	#in $t1 P(t)
	
	srl $t2, $t2, 11	#cutting the fractional part of y
	
  draw_pixel:
  
  	mulu $t6, $t8, $t2	#y * width in bytes
  	mulu $t5, $t1, 3	#x*3 bytes
  	addu $t6, $t6, $t5	#x*3 bytes + y * width in bytes
  	
  	addu $t6, $s0, $t6	#address of calculated byte
  	li $t5, 0xFF		#make pixel blue
  	sb $t5, ($t6)		#b		
  	sb $zero, 1($t6)	#g
  	sb $zero, 2($t6)	#r
  	
  increase_parameter_t:
  	
  	addiu $t0, $t0, -1
  	bge $t0, 0, calculate_coordinates_loop

save_curve_in_file:

	la $a0, file_name	#opening file to save generated curve
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall

	move $s0, $v0		#saving file descriptor
	
	move $a0, $s0		#writing into the file
	move $a1, $s7		#allocated memory
	move $a2, $t7		#its size
	li $v0, 15
	syscall
	
	li $v0, 16		#closing file
	syscall
	
the_end:

	la $a0, curve_done	#the last message
	li $v0, 4
	syscall
	
	li $v0, 17
	syscall

error_file_not_found:
	
	la $a0, file_not_found
	li $v0, 4
	syscall
	
	li $v0, 17		#the end of the program
	syscall

error_wrong_file:

	la $a0, wrong_file
	li $v0, 4
	syscall
	
	li $v0, 17		#the end of the program
	syscall		

error_wrong_coordinate:
	
	la $a0, wrong_coordinate
	li $v0, 4
	syscall
	
	li $v0, 17		#the end of the program
	syscall			
