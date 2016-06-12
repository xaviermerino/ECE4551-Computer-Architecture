@ File: lab0.s

  .global _start

_start:
  MOV R0, #1         @ Moves the constant 1 to the Register R0
  MOV R1, #4         @ Moves the constant 4 to the Register R1
  ADD R0, R0, R1     @ R0 = R0 + R1

  @ The lines below exit the code back to the command line prompt.
  @ Register R7 holds the Syscall number.
  @ Syscall #1 indicates exit.

  MOV R7, #1         @ Moves the constant 1 to the Register R7
  SWI 0              @ Executes Software Interrupt determined by R7
  
