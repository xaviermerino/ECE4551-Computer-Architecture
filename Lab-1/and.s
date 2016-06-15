@ File: and.s

  .global _start

_start:
  MOV R0, #0x6
  MOV R1, #0xC
  AND R0, R0, R1
  MOV R7, #1
  SWI 0
