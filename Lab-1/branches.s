@ File: branches.s
.global _start

_start:         @ This is the label for the start section
  MOV R0, #1
  BAL _exit     @ Branches always to _exit
  MOV R0, #0    @ Never gets executed

_exit:          @ This is the label for the code that follows
  MOV R7, #1
  SWI 0
