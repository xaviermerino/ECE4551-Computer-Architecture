@ File: pin17on.s
@ Turns on led in pin 17.

	.global main
	.func main

main:
	SUB	SP, SP, #16				@ Reserve 16 bytes storage

openFile:
	LDR	R0, .filedir			@ Get /dev/mem file address
	LDR	R1, .flags				@ Set flags for file permissions
	BL	open							@ Call open function, R0 will have file descriptor

map:
	STR	R0, [SP, #12]			@ Save file descriptor on stack
	LDR	R3, [SP, #12]			@ R3 gets a copy of the file descriptor
	STR	R3, [sp, #0]			@ Store the file descriptor at the top of the stack (SP + 0)
	LDR	R3, .gpiobase			@ Get gpio base address in R3
	STR	R3, [sp, #4]			@ Store the gpio base address in the stack (SP + 4)

	@ Parameters for mmap function, the 4 below and the file descriptor and gpio
	@ base address in the stack. This lets the kernel choose the vmem address,
	@ sets the page size, desired memory protection.
	MOV	R0, #0
	MOV	R1, #4096
	MOV	R2, #3
	MOV	R3, #1
	BL	mmap							@ R0 now has the vmem address.

clear:
	STR	R0, [SP, #16]			@ Store vmem address in stack
	LDR	R3, [SP, #16]			@ Make a copy of vmem address in R3
	ADD	R3, R3, #4				@ Add 4 bytes to R3 to get address of GPFSEL1
	LDR	R2, [SP, #16]			@ Make a copy of vmem address in R2.
	ADD	R2, R2, #4				@ Add 4 bytes to R2 to get address of GPFSEL1
	LDR	R2, [R2, #0]			@ Make a copy of GPFSEL1 in R2
	BIC	R2, R2, #0b111<<21	@ Bitwise clear of bits 23, 22, 21
	STR	R2, [R3, #0]			@ Store result in address specified by R3 (GPFSEL1)

set:
	LDR	R3, [SP, #16]			@ Make a copy of vmem address in R3
	ADD	R3, R3, #4				@ Add 4 bytes to R3 to get address of GPFSEL1
	LDR	R2, [SP, #16]			@ Make a copy of vmem address in R2
	ADD	R2, R2, #4				@ Add 4 bytes to R2 to get address of GPFSEL1
	LDR	R2, [R2, #0]			@ Make a copy of GPFSEL1 in R2
	ORR	R2, R2, #1<<21		@ Bitwise set of bit 21
	STR	R2, [R3, #0]			@ Store result in address specified by R3 (GPFSEL1)

turnOn:
	LDR	R3, [SP, #16]			@ Make a copy of vmem address in R3
	ADD	R3, R3, #28				@ Add 28 bytes to R3 to get address of GPFSET0
	MOV	R4, #1						@ Move a 1 to register R4 to prepare for shifting.
	MOV	R2, R4, LSL#17		@ Shift 1 to bit 17 to turn on pin 17
	STR	R2, [R3, #0]			@ Store result in address specified by R3 (GPFSET0)

exit:
	LDR	R0, [SP, #12]			@ Get file descriptor in R0
	BL	close							@ Close the file
	ADD	SP, SP, #16				@ Restore the stack
	MOV R7, #1						@ System call 1, exit
	SWI 0									@ Perform system call


.filedir:		.word	.file
.flags:			.word	1576962
.gpiobase:	.word	0x3F200000

.data
.file: .asciz "/dev/mem"
