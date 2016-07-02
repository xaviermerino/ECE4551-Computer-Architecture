@ File: loadStoreMultiple.s
@ Batch Transfer

	.global _start

_start:
	LDR R0, =first		@ Loads R0 with the address of first
	MOV R1, #1
	MOV R2, #2
	MOV R3, #3
	MOV R4, #4
	@ Stores R1 through R4 starting in the address marked by R0.
	STMIA R0, {R1-R4}
	MOV R1, #0
	MOV R2, #0
	MOV R3, #0
	MOV R4, #0
	@ Loads R1 through R4 with the values that are stored at address R0.
	LDMIA R0, {R1-R4}

_exit:
	MOV R7, #1
	SWI 0

.section .data
first:
	.word 0
	.word 0
	.word 0
	.word 0
