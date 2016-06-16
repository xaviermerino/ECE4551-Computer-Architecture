## Computer Architecture
###Lab 1: Conditional Execution

- [Overview](#overview)
    - [Objectives](#objectives)
- [Preparing the Pi](#preparing-the-pi)
- [More on ARM: The Current Program Status Register (CPSR)](#more-on-arm-the-current-program-status-register-cpsr)
       - [Logical operations](#logical-operations)
       - [Setting flags](#setting-flags)
       - [The S Suffix](#the-s-suffix)
- [More on ARM: The Program Counter (PC)](#more-on-arm-the-program-counter-pc)
- [More on ARM: Conditional Execution and the Link Register (LR)](#more-on-arm-conditional-execution-and-the-link-register-lr)
       - [How to use the condition codes?](#how-to-use-the-condition-codes)
       - [Branching](#branching)
- [System Calls: Write](#system-calls-write)
       - [Other System Calls](#other-system-calls)
- [On your own](#on-your-own)
       - [Program #1: lab1a.s](#program-1-lab1as)
       - [Program #2: lab1b.s](#program-2-lab1bs)
       - [Program #3: lab1c.s](#program-3-lab1cs)
- [Review Questions](#review-questions)

#### Overview
In this lab you will explore deeper into the ARM registers. We will focus on the Link Register (R14), the Program Counter (R15), and the Current Program Status Register (CPSR). We will be studying instructions that manipulate these registers, set register flags, and others that perform logical operations on data. This will allow us to create code that executes if certain condition is met.

##### Objectives
* Understand when it is convenient to manipulate registers R14 and R15.
* To get familiar with instructions that manipulate the CPSR.
* Introduce the ARM Pipeline.
* Use the CPSR flags to control conditional execution.

---

#### Preparing the Pi
Once the Pi is ready `ssh` into it like this:

```console
ssh pi@<assignedHostname>.local
```

If the connection was successful then your Pi is ready. Keep this connection alive as we will be using it later.

----

#### More on ARM: The Current Program Status Register (CPSR)
The Current Program Status Register stores information about the currently running program. All registers in ARM are 32-bit wide and this one is not the exception. Each bit in this register has a special meaning. These bits store copies of the `Arithmetic Logic Unit (ALU)` status flags (or conditions) that happen as you perform operations.  

The following ALU flags are stored in the CPSR (bits 31 - 28):

* **N** (bit 31): This bit is set when the result of an operation is *negative*. It is cleared otherwise.
* **Z** (bit 30): This bit is set when the result of an operation is *zero*. It is cleared otherwise.
* **C** (bit 29): This bit is set when an operation results in a *carry*. It is cleared otherwise.
* **V** (bit 28): This bit is set when an operation causes an *overflow*. It is cleared otherwise.

The following bits represent states in the processor (bits 7 - 0):

* **I, F** (bit 7, 6): Determine which *interrupts* are enabled in the processor.
* **T** (bit 5): This bit is set if the processor is in *Thumb* mode.
* **Mode bits** (bit 4 - 0): These bits represent the mode of operation of the processor. Interrupts may change the mode bits to gain higher *privileges*.

The table below shows the representation of the CPSR:

31 | 30 | 29 | 28 | 27 - 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
---|----|----|----|--------|---|---|---|---|---|---|---|---|
N  | Z  | C  | V  | Unused | I | F | T |M4 | M3| M2| M1| M0|

Bits 27 - 8 are unused in most ARM processors. There are other bits that indicate Endianness (E) and Saturation (Q).

We will see how to set and clear these flags after we cover logical operations.

##### Logical operations
First let's review the truth table for some of the operations we will be covering today.

Input A | Input B | AND | ORR | EOR
--------|---------|-----|-----|----
**0**   | **0**   | 0   | 0   | 0
**0**   | **1**   | 0   | 1   | 1
**1**   | **0**   | 0   | 1   | 1
**1**   | **1**   | 1   | 1   | 0

These operations are performed bit by bit. Some examples are provided below:

```
0110 AND 1100 = 0100
1110 ORR 0011 = 1111
1010 EOR 0111 = 1101
```

The AND, ORR, and EOR instruction are used this way:

`AND <destination>, <operand1>, <operand2>`

`ORR <destination>, <operand1>, <operand2>`

`EOR <destination>, <operand1>, <operand2>`

Below, a code example on how to use the AND instruction:

```gas
@ File: and.s

  .global _start

_start:
  MOV R0, #0x6
  MOV R1, #0xC
  AND R0, R0, R1
  MOV R7, #1
  SWI 0
```

##### Setting flags

We will now explore four instructions that set the flags in the CPSR. These instructions are:

```gas
CMP <Operand1>, <Operand2>           @ Compare
CMN <Operand1>, <Operand2>           @ Compare Negative
TST <Operand1>, <Operand2>           @ Test Bits
TEQ <Operand1>, <Operand2>           @ Test Equivalence
```

The `CMP` instruction subtracts `<Operand2>` from `<Operand1>`. It updates the CPSR flags accordingly.

The `CMN` instruction subtracts `- <Operand2>` from `<Operand1>`, this results in `<Operand1> + <Operand2>`. It updates the CPSR flags accordingly.

The `TST` instruction tests the bits in `<Operand1>` using the bits in `<Operand2>` as a mask. It works by performing an AND between `<Operand1>` and `<Operand2>`. The Zero (Z) flag will be set if it matches. Otherwise it will be cleared.

The `TSQ` instruction tests for equivalence in the bits in `<Operand1>` using the bits in `<Operand2>`. It works by performing an EOR between `<Operand1>` and `<Operand2>`.

##### The S Suffix

We mentioned before that the Current Program Status Register has the zero flag (bit 30) that is set when the result of an operation is zero. However, if we were to execute the line of code below and it resulted in a zero, the zero flag would not be set.

```gas
SUB R0, R1, R2
```

In order to make this instruction set the flag we must add the S suffix to it. The modified versions presented below will set the flags accordingly.

```gas
SUBS R0, R1, R2
SUB S R3, R4, R5      @ You can add spaces to separate the suffix
```

The S suffix can be added to other operations as well and can be mixed with conditional suffixes. We will discuss conditional suffixes later in the manual.

---

#### More on ARM: The Program Counter (PC)
Register 15 is the Program Counter (PC) in the ARM processor. The Program Counter holds the address of the next instruction that will be fetched. This is why modifying this register at random can make your program crash.

Let's introduce a simple processor `pipeline` featured in the original ARM design.

Clock Cycle | Fetch            | Decode           | Execute
------------|------------------|------------------|------------------
1           | Operation **1**  | No Operation     | No Operation   
2           | Operation **2**  | Operation **1**  | No Operation
3           | Operation **3**  | Operation **2**  | Operation **1**   
4           | Operation **4**  | Operation **3**  | Operation **2**
5           | Operation **5**  | Operation **4**  | Operation **3**

Pipelining is a technique where multiple instructions are overlapped. The stages that need to be performed to execute an instruction can run in parallel. Without pipelining we would have to wait for an instruction to go through (let's refer to the simple 3-stage pipeline above) the 3-stages before a new instruction could be issued. With pipelining, as soon as the first instruction went into decode stage, a new instruction can go into the fetch state and so on.

The pipeline shown above needs 3 clock cycles to be filled. The ARM11 processor in the Raspberry Pi has an 8-stage pipeline that we will briefly cover later on.

Before going deeper into pipelining let's see the status of the pipeline above at clock cycle 3. At this point, the Program Counter has the address of Operation 3 that is about to be fetched. If we subtract 4 bytes to the address in the PC then we will obtain the address of the operation that is in decode stage. Subtracting 8 bytes will give you the address of the currently executing operation.

Now let's take a brief look on the 8-stages of the ARM11 processor in the Raspberry Pi.

1. **Fe1**: Instruction Received
2. **Fe2**: Branch Prediction
3. **De**: Instruction Decoding
4. **Iss**: Necessary registers are read. Issues instruction.
5. **Sh**: Performs shifting operations.
6. **ALU**: Performs integer operations.
7. **Sat**: Performs integer saturation if needed.
8. **WB**: Write results back to registers.

It is also worth mentioning that ARM11 has `out-of-order execution` and `dynamic branch prediction`. Pipelining does not reduce the total amount of time taken to finish executing an instruction. It only increases the instruction throughput.

---

#### More on ARM: Conditional Execution and the Link Register (LR)
We already mentioned that the CPSR has flags that can be set / cleared by either using instructions that directly update flags or by using the `S` suffix to force an update of the flags. We can test those flags for certain conditions and execute code accordingly.

Below, a list containing all of the condition codes:

Code      | Meaning                       | Condition Tested     
----------|-------------------------------|------------------
**MI**    | Negative                      | N == 1
**PL**    | Positive                      | N == 0
**EQ**    | Equal                         | Z == 1
**NE**    | Not Equal                     | Z == 0
**CS**    | Carry Set                     | C == 1
**CC**    | Carry Clear                   | C == 0
**VS**    | Overflow Set                  | V == 1
**VC**    | Overflow Clear                | V == 0
**HI**    | Higher (Unsigned)             | C == 1 and Z == 0
**LS**    | Lower or same (Unsigned)      | C == 0 or Z == 1
**GE**    | Greater than or equal (Signed)| N == V
**GT**    | Greater than (Signed)         | Z == 0 and N == V
**LE**    | Less than or equal (Signed)   | Z == 1 or N != V
**LT**    | Less than (Signed)            | N != V
**AL**    | Always                        | Always executes
**NV**    | Never                         | Never executes

##### How to use the condition codes?
To use the condition codes you must add the code as a suffix to the instruction. You can also use the S suffix to update the flags if the instruction got executed but the condition code must go first.

```gas
CMP R1, R2          @ Updates the flags with the result of R2 - R1
SUBGTS R1, R1, R2   @ If R1 >= R2 subtract R2 and set flags.
```

##### Branching
Just as you can use the condition codes to test the flags and execute a single line of code, you can label a section of code and jump to it in the event that your condition occurred. This is called branching. You can branch using the `B` (branch) and the `BL` (branch and link) instructions.

```gas
@ File: branches.s
.global _start

_start:         @ This is the label for the start section
  MOV R0, #1
  BAL _exit     @ Branches always to _exit
  MOV R0, #0    @ Never gets executed

_exit:          @ This is the label for the code that follows
  MOV R7, #1
  SWI 0

```

Any lines of code in the `_start` section that are after the `BAL` instruction in the example above will not execute (more specifically the `MOV R0, #0`). This is not only because the execution jumps to the `_exit` section and the program terminates but because the control was never returned to the `_start` section.

Let's take a look at the new example below:

```gas
@ File: branchLink.s

.global _start

_start:               @ This is the label for the start section
  MOV R0, #1
  BL _doSomething     @ Branches and Links to _doSomething
  ADDEQ R0, R0, #3    @ Performs R0 = R0 + 3 if Zero flag is set.
  BAL _exit           @ Branches always to _exit

_doSomething:         @ This is the label for the code that follows
  SUBS R0, R0, #1     @ Performs R0 = R0 - 1 and updates the flags
  MOV PC, LR          @ Moves the contents of the LR to the PC

_exit:                @ This is the label for the code that follows
  MOV R7, #1
  SWI 0

```

In this example, we use the `BL` instruction to branch to the `_doSomething` section. The `BL` instruction behaves exactly like the `B` instruction but when executed it also copies the contents of the `Program Counter (PC)` into the `Link Register (LR)`. This allows returning to the original execution point by doing `MOV PC, LR` at the end of the `_doSomething` section.

----

#### System Calls: Write
The Operating System that you are running in your Raspberry Pi, Raspbian, makes things easier for us. Without it we would have to write our own code to interface with the keyboard and know where the memory sections that drive the display's content are located to be able to print something on the screen.

You have already seen examples of system calls. In all of the programs we have made use of the exit system call.

```gas
MOV R7, #1        @ System call #1
SWI 0
```

The system call identifier (or 1 for exit) is assigned to register R7. Arguments are usually placed in registers R0 - R6 (following the `Embedded Application Binary Interface (EABI)`) and the system call takes place through the instruction `SWI 0` or `SVR 0`.

For now, we are going to be using the built-in Operating System routines to write to the screen.

```gas
@ File: write.s

	.global _start

_start:
_write:
	MOV R0, #1					@ Output is monitor
	LDR R1, =string			    @ The address of the string.
	MOV R2, #12					@ The number of chars to be printed
	MOV R7, #4					@ System Call #4 Write
	SWI 0

_exit:
	MOV R7, #1
	SWI 0

.data					@ Tells the assembler this is not code section
string:				    @ Name that we give to our string.
	.ascii "Hello World\n"

```

The example above sets the arguments R0 - R2 needed by the `write` system call. R7 holds the system call identifier.

* R0 determines where the output stream goes. We use 1 for the console.
* R1 holds the address of the string
* R2 holds the number of characters to be printed

The arguments that the `write` system call needs are listed in its function declaration.

```cp
ssize_t write(int fd, const void *buf, size_t count);
```

The `LDR R1, =string` line can be read as `load the address of string in the R1 register`. We will be covering more of this later on. Finally the `SWI 0` instruction makes it happen.

##### Other System Calls
You can find a list of the system calls in the `unistd.h` file.

```console
find /usr/include -name "unistd.h"
```

You will find a list of files, the one you are looking for will be something like this:

```console
/usr/include/arm-linux-gnueabihf/asm/unistd.h
```

If you would like to read it you can display its content like this:

```console
cat /usr/include/arm-linux-gnueabihf/asm/unistd.h
```

---

#### On your own

Now that you are more familiar with ARM you are able to write simple programs on your own. This week you will have three programs to write. Make sure to include plenty of proper comments.

##### Program #1: lab1a.s
You will be writing a program that will print "Hello World" ten times. The output should look like this:

```
Hello World
Hello World
Hello World
Hello World
Hello World
Hello World
Hello World
Hello World
Hello World
Hello World
```

You are expected to use branches to recreate the functionality of a `for loop` and achieve this result. Use the write system call to print to the console. Save this program as `lab1a.s`.

##### Program #2: lab1b.s
Your task in this second program is to recreate the functionality of a `switch` statement. Assign the value 1, 2, or 3 to a register.
Use the switch to print "Option 1", "Option 2", or "Option 3" to the screen. For simplicity you will hardcode the value in a register. Make sure to test for all cases. Save this program as `lab1b.s`.

##### Program #3: lab1c.s
Your task in this third program is to calculate the factorial of a number. Hardcode a number into a register and save the result of the factorial in the `R0` register. Use the `echo $?` command to print the last byte of register `R0` after the program has executed. Test your program with numbers from 1 to 5. Save this program as `lab1c.s`.

----

#### Review Questions
The following review questions must be answered in your lab report. It is expected that you go further than what was explained in this manual to answer the questions. Make sure you pay special attention to questions regarding the ARM instruction set since future lab material will assume you know what was taught in this manual.

1. Briefly explain what pipelining is.

3. Briefly explain what branch prediction is.

4. Briefly explain what out-of-order execution is.

2. Briefly explain the limitations of pipelining.

5. Briefly explain the Link Register's role in branching.

6. Explain what the following instructions do and give an example.

   * **AND**
   * **ORR**
   * **EOR**
   * **CMP**
   * **TST**
   * **B**
   * **BL**
