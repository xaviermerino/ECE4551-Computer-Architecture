@ File: write.s

	.global _start

_start:
_write:
	MOV R0, #1						@ Output is monitor
	LDR R1, =string				@ The address of the string. 
	MOV R2, #12						@ The number of chars to be printed
	MOV R7, #4						@ System Call #4 Write
	SWI 0

_exit:
	MOV R7, #1
	SWI 0

.data										@ Tells the assembler this is not code section
string:									@ Name that we give to our string.
	.ascii "Hello World\n"
