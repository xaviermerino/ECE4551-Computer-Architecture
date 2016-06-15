@ File: branchLink.s

.global _start

_start:               @ This is the label for the start section
  MOV R0, #1
  BL _doSomething     @ Branches and Links to _doSomething
  ADDEQ R0, R0, #3    @ Adds if Zero flag is set.
  BAL _exit           @ Branches always to _exit

_doSomething:         @ This is the label for the code that follows
  SUBS R0, R0, #1     @ Performs R0 = R0 - 1 and updates the flags
  MOV PC, LR          @ Moves the contents of the LR to the PC

_exit:                @ This is the label for the code that follows
  MOV R7, #1
  SWI 0
