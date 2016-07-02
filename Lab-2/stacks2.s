@ File: stacks2.s

  .global _start

_start:
  MOV R4, #9
  MOV R5, #8
  MOV R6, #7
  @ Pushes registers R4 through R6 into the stack
  STMFD SP!, {R4-R6}
  MOV R4, #0
  MOV R5, #1
  MOV R6, #2
  @ Pops values into registers R4 through R6
  LDMFD SP!, {R4-R6}

_exit:
  MOV R7, #1
  SWI 0
