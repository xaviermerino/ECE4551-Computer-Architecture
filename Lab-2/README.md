## Computer Architecture
### Lab 2: Handling Memory

- [Overview](#overview)
	- [Objectives](#objectives)
- [Preparing the Pi](#preparing-the-pi)
- [More on ARM: The Barrel Shifter](#more-on-arm-the-barrel-shifter)
	- [Logical Shift Left](#logical-shift-left)
	- [Logical Shift Right](#logical-shift-right)
	- [Rotate Right](#rotate-right)
- [More on ARM: Immediate Values](#more-on-arm-immediate-values)
- [More on ARM: Addressing Modes](#more-on-arm-addressing-modes)
	- [Indirect Addressing](#indirect-addressing)
	- [Pre-Indexed Addressing](#pre-indexed-addressing)
	- [Post-Indexed Addressing](#post-indexed-addressing)
	- [Memory](#memory)
- [More on ARM: Load / Store Multiple Registers](#more-on-arm-load--store-multiple-registers)
- [More on ARM: Stacks](#more-on-arm-stacks)
- [On your own](#on-your-own)
	- [Program #1: lab2a.s](#program-1-lab2as)
	- [Program #2: lab2b.s](#program-2-lab2bs)
	- [Program #3: lab2c.s](#program-3-lab2cs)
- [Review Questions](#review-questions)

#### Overview
In all of our previous programs we have only used registers and immediate values to provide our programs with data. There are only a limited number of registers and we might need to store more information. We will be exploring memory, how to load information from it, and how to store information back to it. In the process we will introduce the limitations of immediate values and the barrel shifter.

##### Objectives
* Understand the limitations of the immediate values.
* Understand how the barrel shifter can help with these limitations.
* Understand the ARM Addressing Modes
* Understand the need for Stacks and how to use them.

---

#### Preparing the Pi
Once the Pi is ready `ssh` into it like this:

```console
ssh pi@<assignedHostname>.local
```

If the connection was successful then your Pi is ready. Keep this connection alive as we will be using it later.

----

#### More on ARM: The Barrel Shifter
The barrel shifter is the functional unit that allows to perform shifts and rotations. We will cover three instructions that allow us to perform these shifts. Its worth noting that these instructions can only occur as part of other instructions affecting `<Operand2>`.

##### Logical Shift Left
The `LSL` operation moves all the bits on a word to the left. The most significant bit (b31) is pushed into the carry flag bit and a zero covers the space left behind. You can specify how many shifts you want to perform using for instance `LSL #1` for one shift to the left or `LSL #2` for two. You can see the result of applying `LSL` to the word below. The labels on the right are related to the number of bit shifts applied to the original set of data.


![Logical Shift Left](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/logicalShiftLeft.png?raw=true)

In the code example below you can notice that the `LSL` operation has been performed on `<Operand2> ` of the other instruction.  

```gas
MOV R0, #2        
MOVS R1, R0, LSL #1  @ Moves into R1 the result of shifting left R0 one time
```

##### Logical Shift Right
The `LSR` operation moves all the bits on a word to the right. The most significant bit (b31) is pushed to the right and the least significant bit that appears to "drop" nowhere goes into the carry flag bit. A zero covers the space left behind. You can specify how many shifts you want to perform using for instance `LSR #1` for one shift to the left or `LSR #2` for two. You can see the result of applying `LSR` to the word below. The labels on the right are related to the number of bit shifts applied to the original set of data.

![Logical Shift Right](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/logicalShiftRight.png?raw=true)

In the code example below you can notice that the `LSR` operation has been performed on `<Operand2> ` of the other instruction.  

```gas
MOV R0, #128        
MOVS R1, R0, LSR #1  @ Moves into R1 the result of shifting right R0 one time
```

##### Rotate Right
The `ROR` operation rotates the bits to the right. It moves the least significant bit to the most significant bit while pushing everything to the right. The least significant bit also gets copied to the carry flag bit. The labels on the right are related to the number of rotations applied to the original set of data.

![Rotate Right](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/rotateRight.png?raw=true)

In the code example below you can notice that the `ROR` operation has been performed on `<Operand2> ` of the other instruction.  

```gas
MOV R0, #0xC0000034       
MOVS R1, R0, ROR #1     
```

---

#### More on ARM: Immediate Values
So far we have tried loading small values as immediate constants. Usually our values have been between 0 - 255. Other values may not work.

```gas
MOV R0, #45       @ This will work
MOV R0, #289      @ This won't work
```

Mr. Alisdair McDiarmid has an excellent explanation to this immediate value issue. [Read what he has to say](https://alisdair.mcdiarmid.org/arm-immediate-value-encoding/) before continuing with the material in this lab.

[![Alisdair Website](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/alisdair.png?raw=true)][alisdair]

[alisdair]: https://alisdair.mcdiarmid.org/arm-immediate-value-encoding/

---

#### More on ARM: Addressing Modes
Like we discussed before, there are only so many registers available to do any sort of data processing. For all the other data that we can't fit in the registers we need to store it in the memory. To load and store data in memory we need the address of the data and where is it going.

We will summarize the ways of accessing the data in three addressing modes. In reality, there are more than three but all those extra ones derive from the ones we will cover.

We will be covering:

* Indirect addressing
* Pre-Indexed addressing
* Post-Indexed addressing

##### Indirect addressing
We can't access memory locations directly. We need two instructions that provide a liaison between the registers and memory. These are the `LDR` and `STR` instructions.

Let's say we want to give register `R1` the address `0x100`, we would do something like:

```gas
MOV R1, #0x100
```

You can also combine the shifting operations discussed before to generate an address.
When using indirect addressing, the address of the desired memory location is held in a register.

In the image below, the register `R1` contains the value `0x100`. In the memory location `0x100`, we can find the value `0x200`. After we execute the `LDR R0, [R1]` instruction, we see that register `R0` was loaded with the contents of the memory address `0x100` (this is the value `0x200`). This address was specified by the `R1` register.

![Indirect Addressing](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/indirectAddressing.png?raw=true)

##### Pre-Indexed addressing
Pre-Indexed addressing adds an offset to the original (base) address. This offset can be an immediate value, the result of a bit shift operation, or the contents of another register.

In the example below, `R1` has the value of the base address (`0x100`) and we are adding the `#4` offset to this value. This results in loading memory location `0x104` into register `R0`. The value of `R1` remains unaltered.

![Pre-Indexed Addressing](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/preIndexedAddressing.png?raw=true)

Sometimes it is useful to update `R1` to reflect the addition of the offset. We can do that using the `!` operator. You can see that it behaves exactly like the example above with the only difference being that `R1` now holds `0x104`. This is called Pre-Indexed Addressing with `Write Back`.

![Pre-Indexed Addressing Write Back](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/writebackPreIndexedAddressing.png?raw=true)

##### Post-Indexed addressing
Post-Indexed addressing takes a base address and an offset and it always uses the `Write Back` feature. The offset is not added to the base address until the data is loaded to a register. After this happens, the base address value is updated to reflect the addition of the offset.

You can see from the example below that register `R1` contains the base adress `0x100`. The contents of memory location `0x100` are stored in register `R0` and then register `R1` is updated with the addition of the offset.

![Post-Indexed Addressing](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/postIndexedAddressing.png?raw=true)

##### Memory
We have seen ways of accessing memory to store contents or retrieve contents and place them back into the registers. All of the examples seen above have been loading or storing 32-bits of information. Remember that the word size is 32-bits or 4 bytes. That's the reason why the diagrams above have addresses like `0x100`, `0x104`, `0x108` and so on. It turns out that memory is byte addressable. This means you can access each byte in a memory location.

We can use the `LDR` and `STR` instructions to access individual bytes by using the `B` suffix. Notice that conditional execution suffixes can be used as well and if you are planning to mix them you should know that conditional execution suffixes go before the `B` suffix. You can also use the Write-Back operator `!` when accessing individual bytes. An example is shown below.

```gas
@ Store R5 in location indicated by R1 (base) + R3 (offset)
@ If the Greater Than flags have been set.

STRGTB R5, [R1, R3]

@ Load into R0 the value in memory indicated by the R1 (base) + R3 (offset)
@ Updates R3 with the value R1 + R3.

LDRB R0, [R1, R3]!
```

---

#### More on ARM: Load / Store Multiple Registers
Sometimes we want to load or store multiple registers. We could have several `LDR` and `STR` instructions to accomplish this. We can also use the `LDM` or `STM` to load and store multiple registers all at once. We just need to specify a starting address and the registers you wish to store or load.

In the example below we have an address stored in `R0` and we have data stored in registers `R1` and `R2`. When we use the instruction `STMIA R0, {R1-R2}` we are storing the information in `R1` and `R2` at the location specified by `R0`. `R1` and `R2` are both 4 bytes wide, `R1` is saved directly at address `0x100` and `R2` is stored at `0x104`. Since we are not using the Write-Back operator `!`, `R0` retains its original value.

![Batch Transfer](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/stmia.png?raw=true)

We said that the instructions to load and store multiple registers are `LDM` and `STM`. In the example above we have used the suffix `IA` with the `STM` instruction to indicate that we wanted `R1` to be at `0x100`, then increment the address, and then store `R2` at `0x104`. The `IA` suffix stands for `Increment After`. It increments the address after it has saved the register.
There are four suffixes for the `LDM` and `STM` instructions:
* **IA**: Increment After
* **DA**: Decrement After
* **IB**: Increment Before
* **DB**: Decrement Before

These suffixes are placed after any conditional execution suffixes.

In the example below, we load `R0` with the address of the `first` label. Then we move information into the registers `R1` through `R4`. We then store the values in those registers at the address given by `R0`. If we were to replace the values with something else and then would like to restore them to their original state then we could load them by using the address at `R0` in which they were stored. Note that since we didn't use the Write-Back operator `!`, the value in `R0` was not modified.

```gas
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

```

#### More on ARM: Stacks
You are probably familiar with the `Stack` data structure. If you are not, then read a bit about stacks before continuing with the lab. A stack has two basic operations: `Push` and `Pop`.

The picture below provides an example on how a stack works.

![Stack](https://upload.wikimedia.org/wikipedia/commons/b/b4/Lifo_stack.png)

You can recreate this behavior by using the load and store commands already shown to you. You can have several stacks in your assembly program but there is one register that has been provided as the `Stack Pointer (SP)`, this is register `R13`.

The example below pushes registers `R4` through `R6` to a stack. The `SP` register handles the address and keeps track of the locations. Notice that the instructions to push and pop from the stack are opposite. When pushing we've used `STMIA` and when popping we have used `LDMDB`. The suffixes, as well as the instructions, are opposite. If we didn't use the Write-Back operator `!`, the `SP` would never be updated and we would lose track of the where the information was stored.

```gas
@ File: stacks1.s

  .global _start

_start:
  MOV R4, #9
  MOV R5, #8
  MOV R6, #7
  @ Pushes registers R4 through R6 into the stack
  STMIA SP!, {R4-R6}
  MOV R4, #0
  MOV R5, #1
  MOV R6, #2
  @ Pops values into registers R4 through R6
  LDMDB SP!, {R4-R6}

_exit:
  MOV R7, #1
  SWI 0
```

To convince you that this work, I've provided a print out of the registers before the program exits. Notice how the value of `R4`, `R5`, and `R6` are the ones we expected.

![Stacks 1](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/stacks1Registers.png?raw=true)

Your stack can grow up or down depending on how you handle the counting options (`IA`, `IB`, `DA`, and `DB`). However you do it, its important to keep track of it. Or you could just use instructions that handle that for you. Before talking about those instructions, let's talk about four types of stacks:

* **FA**: Full Ascending Stack
* **EA**: Empty Ascending Stack
* **FD**: Full Descending Stack
* **ED**: Empty Descending Stack

The *ascending* and *descending* option describes whether the stack grows up or down.

The *full* and *empty* option describes whether the `Stack Pointer` points to the last saved address on the stack or the next empty one. It does not mean that the stack itself is empty or full.

The default one is usually the *Full Descending Stack*. Using this simplifies your work. You can see the previous example rewritten to make use of a *Full Descending Stack* below.

```gas
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

```

You can compare the registers with the previous example's registers. The result is the same.

![Stacks 2](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/stacks2Registers.png?raw=true)

For an even more simplified way of handling stacks, let's consider the use of assembler directives. The `PUSH` and `POP` directives are available under the GCC compiler and the ARM compiler. If you use any other compiler these might not be available and you will have to use the options presented to you above. When you are using `PUSH` and `POP` you are using a *Full Descending Stack* with `SP` as the `Stack Pointer`.

You can think of `PUSH` as a synonym for 	`STMDB SP!, { Registers }` and `POP` as a synonym for `LDMIA SP!, { Registers }`.

```gas
@ File: stacks3.s

  .global _start

_start:
  MOV R4, #9
  MOV R5, #8
  MOV R6, #7
  @ Pushes registers R4 through R6 into the stack
  PUSH {R4-R6}
  MOV R4, #0
  MOV R5, #1
  MOV R6, #2
  @ Pops values into registers R4 through R6
  POP {R4-R6}

_exit:
  MOV R7, #1
  SWI 0

```

Again, you can compare the register list below with the other ones. They are the same.

![Stacks 3](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-2/stacks3Registers.png?raw=true)

---

#### On your own

Now that you are more familiar with ARM you are able to write simple programs on your own. This week you will have three programs to write. Make sure to include plenty of proper comments.

##### Program #1: lab2a.s
You will be implementing bubble sort in assembly. Use the following template to help you build the code.

```gas
@ Use this template to help you build the code.

	.global _start

_start:

_exit:
	MOV R7, #1
	SWI 0

.data
	array:
		.ascii "538129"
```

In the template you can see we have labeled a string as *array*. Your goal for this first program is to sort all of the numbers in there and then print the output to the screen. You are going to use bubble sort to achieve this. Save this program as `lab2a.s`.

##### Program #2: lab2b.s
You will be implementing insertion sort in assembly. Use the following template to help you build the code.

```gas
@ Use this template to help you build the code.

	.global _start

_start:

_exit:
	MOV R7, #1
	SWI 0

.data
	array:
		.ascii "538129"
```

In the template you can see we have labeled a string as *array*. Your goal for this first program is to sort all of the numbers in there and then print the output to the screen. You are going to use insertion sort to achieve this. Save this program as `lab2b.s`.

##### Program #3: lab2c.s
Your task in this third program is to print out the 32-bits of a register in binary. You will load a number to a register of your choice. For example, `0xC0000034` and print out its binary representation. In this example it would be `11000000000000000000000000110100`. Consider that the ASCII table defines `0` as 48 and `1` as 49. Save this program as `lab2c.s`. Hint: Try using the `TST` instruction.

----

#### Review Questions
The following review questions must be answered in your lab report. It is expected that you go further than what was explained in this manual to answer the questions. Make sure you pay special attention to questions regarding the ARM instruction set since future lab material will assume you know what was taught in this manual.

1. Briefly explain how an ARM instruction is made up.

3. Briefly explain what the barrel shifter, the limitation of immediate values, and how the barrel shifter helps overcome the limitations of immediate values.

2. Briefly explain the difference between `Pre-Indexed Addressing` and `Post-Indexed Addressing`.

5. Briefly explain how to access individual memory bytes.

6. Briefly explain what is a stack, its operations, and what could it be used for.

5. Briefly explain the four types of stacks mentioned above.

6. Explain what the following instructions do and give an example.

   * **ASR**
   * **BIC**
   * **LDR**
   * **STR**
   * **LDM**
   * **STM**
