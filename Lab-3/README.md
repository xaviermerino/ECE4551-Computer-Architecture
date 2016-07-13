## Computer Architecture
### Lab 3: Functions and Floating Point Instructions

#### Overview
We have learned quite a bit on how memory works and how to use the stack to store values. The stack is useful but it is also fragile, handle it wrong and your whole program can crash (or if you are lucky it might just not run properly). You probably already know that the stack can be used to keep track of function calls. Today, we are going to use it for that purpose. We are going to learn how to call and write functions using the function standards defined in the **Application Binary Interface (ABI)**. We are going to focus, particularly, on the **AAPCS (Procedure Call Standard for the ARM Architecture)**. We will use some functions included in the C standard function library to get input and provide output. We will also talk about the **VFP extensions** that will (finally!) let us use floating point numbers in our programs.

##### Objectives
* Learn how to use some libc functions in our assembly programs.
* Learn the function calling conventions.
* Use the stack to keep track of the function calls.
* Learn how to use Floating Point instructions.
* Learn how to execute VFP code under a certain condition.
* Learn how to perform vector operations.

---

#### Preparing the Pi
Once the Pi is ready `ssh` into it like this:

```console
ssh pi@<assignedHostname>.local
```

If the connection was successful then your Pi is ready. Keep this connection alive as we will be using it later.

---

#### Introducing libc
We have been using the system calls to perform actions such as writing to the console. There are other system calls that allow you to read input from the keyboard or to create directories. So instead of writing our own functions let's reuse the libc functions in our code to understand how to call functions and later on make our own. The libc, the C standard function library, allows you to perform system calls without really knowing the details. Your code will pretty much be wrapped within libc.

Let's see an example of C code.

```c
// C Example

#include <stdio.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
```

In the snippet above, you can see that we are calling the `printf` function to print "Hello, World!" to the screen. Every C program has the starting point at the `main` function. Since we will be using libc we need to let GCC know the entry point. So the first thing we will do is create a similar template in assembly.

```gas

@ Assembly Example

  .global main
  .func main

main:
  @ Your code

_exit:
  MOV PC, LR
```

The benefit of this is that we can simplify the assembling and linking with only one command line instruction.

```bash
gcc -o <output> <output.s>
```

##### Using printf

Let's use the `printf` function in assembly to print the same "Hello, World!" as in the C program.

```gas
@ File: usingPrintf.s

  .global main
  .func main

main:
  PUSH {R4-R12, LR} @ Saving the Registers
  LDR R0, =helloworld
  BL printf
  POP {R4-R12, PC}  @ Restoring the Registers

_exit:
  MOV PC, LR

.data
helloworld: .asciz "Hello, World!\n"

```

You might be wondering what the `PUSH {R4-R12, LR}` and `POP {R4-R12, PC}` instructions do. From our previous knowledge of stacks we know that we are saving those registers to the stack and then we are restoring them. The reason for this is that whenever we enter a function we need to preserve some registers. It is really not necessary to do that for this small program but since we are covering the **AAPCS** let's see why we are doing this here.

##### The AAPCS
The ARM convention calls for a **Full Descending Stack**. This is the one used when you use the `PUSH` and `POP` directives.

Let's see what purpose each register serves according to the **AAPCS**.

Register | Purpose              | Values Preserved?
---------|----------------------|------------------
R0       | Argument / Return    | No  
R1       | Argument             | No  
R2       | Argument             | No
R3       | Argument             | No
R4       | Any use              | Yes  
R5       | Any use              | Yes  
R6       | Any use              | Yes
R7       | Any use              | Yes
R8       | Any use              | Yes  
R8       | Any use              | Yes  
R9       | Any use              | Yes
R10      | Any use              | Yes
R11      | Any use              | Yes
R12      | Any use              | Yes*  
SP       | Stack Pointer        | Yes  
LR       | Link Register        | No
PC       | Program Counter      | No

The table above shows that whenever we call a function, the function will expect its arguments in the registers `R0-R3`. It can freely modify the values in registers `R4-R12` but after the function ends, these registers should have their original values or simply put, their contents should be preserved. The `SP` contents should be preserved as well or nasty things can occur. The `LR` stores the return address of a function. Once the function ends, the contents of the `LR` are passed to the `PC` and the execution continues through the desired path.

During the **prologue** of a procedure (fancy term for what it does in the very beginning) you will probably encounter an instruction like `STMFD SP!, {R4-R12, LR}` or `PUSH {R4-R12, LR}`. In this case we are saying registers `R4-R12` are going to be used for inner calculations (or whatever you want to do with them in your function).

During the **epilogue** of a procedure (or the end) you will encounter something like `LDMFD SP!, {R4-R12, LR}` or `POP {R4-R12, PC}` which restores the values of the registers `R4-R12` to their original ones.

Keep in mind that the function is oblivious to the condition flags and as such you should not assume any state in the flags.

##### Using scanf
When you are using the `scanf` function in `C` you obey the following function signature:

```c
int scanf ( const char * format, ... );
```

This is a C example:

```c
#include <stdio.h>

int main() {
    int number = 0;
    scanf("%d", &number);
    return 0;
}
```

We are going to use this function in assembly. In order to do that we must specify an input format and reserve a space in the stack for the value captured by `scanf`. The first argument `R0` contains the address of the input format and the second argument `R1` should contain an address in the stack where the value can be stored. Let's see a code example:

```gas
@ File: usingScanf.s

  .global main
  .func main

main:
  PUSH {R4-R12, LR}     @ Saving the Registers
  SUB SP, SP, #4        @ Making space in the stack
  LDR R0, =inputFormat  @ Loading the address of the format in R0
  MOV R1, SP            @ Moving the address of the new space into R1
  BL scanf              @ Calling scanf
  LDR R1, [SP]          @ Get the value captured by scanf
  ADD SP, SP, #4        @ Restoring the SP to its original state
  POP {R4-R12, PC}      @ Restoring the Registers

_exit:
  MOV PC, LR

.data
inputFormat: .asciz "%d"

```

##### Extra arguments
Sometimes you want to pass more arguments and the registers `R0-R3` are not enough. In those cases you need to use the stack to pass extra arguments. Just make sure that after pushing values into the stack and using them you balance the stack.

##### A word of caution
We have not talked about the stack alignment. The stack should be 8-byte aligned. The easiest way to do this is to make sure that the stack is initialized (using `PUSH`) with an even number of registers. A workaround is to handle the `SP` and use arithmetic operations to align it. In some cases this might not be necessary as you will be only accessing 4-byte values. When you start accessing 8-byte values, however, it is necessary to conserve the alignment. Let's see what GCC does underneath when it converts your C code to assembly.

```c
// C Example

#include <stdio.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
```

```gas
.arch armv6
.eabi_attribute 27, 3
.eabi_attribute 28, 1
.fpu vfp
.eabi_attribute 20, 1
.eabi_attribute 21, 1
.eabi_attribute 23, 3
.eabi_attribute 24, 1
.eabi_attribute 25, 1
.eabi_attribute 26, 2
.eabi_attribute 30, 2
.eabi_attribute 34, 1
.eabi_attribute 18, 4
.file	"main.c"
.section	.text.startup,"ax",%progbits
.align	2
.global	main
.type	main, %function

main:
  @ args = 0, pretend = 0, frame = 0
  @ frame_needed = 0, uses_anonymous_args = 0
  stmfd	sp!, {r3, lr}
  ldr	r0, .L3
  bl	puts
  mov	r0, #0
  ldmfd	sp!, {r3, pc}

.L4:
  .align	2

.L3:
  .word	.LC0
  .size	main, .-main
  .section	.rodata.str1.4,"aMS",%progbits,1
  .align	2

.LC0:
  .ascii	"Hello World!\000"
  .ident	"GCC: (Raspbian 4.9.2-10) 4.9.2"
  .section	.note.GNU-stack,"",%progbits
```

I've placed the entire assembly file above. The essential part of the code is within the `main` function. GCC aligns the stack by pushing registers `R3` and `LR`. It then loads the contents of address `.L3` (which points to `.LC0`) into `R0`. It then calls the `puts` function. Moves zero as the return value and finally restores registers `R3` and `LR` to their original value. In very simple cases the compiler converts `printf` to `puts`.

---

#### More on ARM: VFP Extensions
So far we have only been able to use integers. We are finally at the point where we can start using floating point numbers. Initially, with the original Raspberry Pi, the VFP extensions were provided by a co-processor. The VFP has been deprecated ever since and has been replaced with the **NEON** extensions in newer architectures. Co-processors are not defined past the ARMv8 Architecture.

A single precision number occupies 32-bits of memory. A double precision number occupies 64-bits of memory. A floating point number is constructed with a **sign bit**, an **exponent**, and the **mantissa** or fractional part.

##### VFP Registers
The VFP also makes use of a Load / Store architecture. It has its own sets of registers apart from the registers provided by the processor itself. There are 32 registers used for single precision storage or 16 registers for double precision storage. The registers are split in four banks.

Bank     | Single Precision     | Double Precision
---------|----------------------|------------------
0        | S0 - S7              | D0 - D3  
1        | S8 - S15             | D4 - D7  
2        | S16 - S23            | D8 - D11
3        | S24 - S31            | D12 - D15

Let's explain this a little further. Double precision register `D0` is made up of single precision registers `S0` and `S1`. `D1` is made up of single precision registers `S2` and `S3` and so on. The table below shows the relationship.

Bank | Single Register #1 | Single Register #2 | Double Register
-----|--------------------|--------------------|-----------------
0    | S0                 | S1                 | D0
0    | S2                 | S3                 | D1
0    | S4                 | S5                 | D2
0    | S6                 | S7                 | D3
1    | S8                 | S9                 | D4
1    | S10                | S11                | D5
1    | S12                | S13                | D6
1    | S14                | S15                | D7
2    | S16                | S17                | D8
2    | S18                | S19                | D9
2    | S20                | S21                | D10
2    | S22                | S23                | D11
3    | S24                | S25                | D12
3    | S26                | S27                | D13
3    | S28                | S29                | D14
3    | S30                | S31                | D15

##### From VFP to ARM and vice versa
Having the ability to use floating point numbers would be *pointless* if they could only be used within the VFP unit. In order to transfer values to and from the processor we need to use a special instruction. Just as when we used to move stuff around in the ARM ISA, we are now going to use `VMOV` to move information to and from the VFP unit.

When we have a single precision VFP register (which holds 4-bytes) the moving process is straight-forward. Since the ARM registers and a single precision register have the same bit width, we can easily transfer them. An example is provided below. The first line below copies the contents of `S0` into `R0`. The second line copies the contents of `R1` into `S0`.

```gas
VMOV R0, S0
VMOV S0, R1
```

When we have a double precision VFP register (which holds 8-bytes) the moving process is slightly different. We will now need two ARM registers to hold this value. In the example below, the double precision register `D0` is being transferred to registers `R2` and `R3`. The low bytes are copied to `R2` and the high bytes are copied to `R3`.

```gas
VMOV R2, R3, D0
```

We can similarly transfer from a VFP register to another using the same instruction.

```gas
VMOV S0, S1
```

##### Load and Store
The VFP extensions also have load and store instructions just as the ARM processor itself. The instructions behave in a similar way. We use the `VLDR` instruction to load the contents of an address into a register. We use the `VSTR` to store some contents at the specified address. We also have the `VLDM` and `VSTM` instructions, the counterparts of the ARM `LDM` and `STM` instructions. We can also make use of the stack using the `VPUSH` and `VPOP` instructions. These last two instructions use the `SP` as the base address and use a **Full Descending Stack**.

```gas
VLDR S0, =value
VSTR S0, [SP]
```

##### Changing Precisions
We can transform a number from double precision to single precision and vice versa. VFP provides the ability to perform these conversions. The instruction that allows you to perform the conversions is `VCVT` and it takes several suffixes to specify the conversion to be done.

In order to convert a double to a single we would do:

```gas
VCVT.F32.F64 S0, D1
```

The `.F32` following the `VCVT` instruction indicates that we want the target precision to be 32-bit width or single precision. The next suffix `.F64` indicates that the source register holds a 64-bit width value or double precision. Then we give the target register to store the result of the conversion followed by the source register.

The `VCVT` instruction takes the following precision suffixes:
* **.F32**: Single precision
* **.F64**: Double precision
* **.U32**: Unsigned integer
* **.S32**: Signed integer

Remember that conversions from integer to floating-point round to nearest while conversions from floating-point to integer round towards zero. For more information see the VFP Instruction Set Quick Reference Sheet under the [Scalar Convert section](http://infocenter.arm.com/help/topic/com.arm.doc.qrc0007e/QRC0007_VFP.pdf).

##### Arithmetic Instructions
You can perform arithmetic operations with the VFP registers. You have to specify if you are going to carry out a single or double precision operation by using the suffixes described above.

Some instructions are listed below:

Mnemonic     | Stands for               |
-------------|--------------------------|
**VABS**     | Absolute value                
**VNEG**     | Negative                 
**VSQRT**    | Square Root  
**VADD**     | Addition                            
**VSUB**     | Subtraction              
**VMUL**     | Multiplication  
**VMAL**     | Multiply and Accumulate            
**VMLS**     | Multiply and Subtract              
**VNMUL**    | Multiply and Negate
**VNMLA**    | Multiply, Negate, and Accumulate
**VNMLS**    | Multiply, Negate, and Subtract                
**VDIV**     | Division    

Let's see some code examples:

```gas
VADD.F32 S2, S1, S0    @ Single precision add. S2 = S1 + S0
VADD.F64 D0, D1, D2    @ Double precision add. D0 = D1 + D2
VDIV.F32 S2, S1, S0    @ Single precision division. S2 = S1 / S0
```

Just keep in mind that you can't mix single and double precision registers with these instructions. You can always refer to the quick reference sheet of the VFP instruction set to see more. [See More](http://infocenter.arm.com/help/topic/com.arm.doc.qrc0007e/QRC0007_VFP.pdf)

##### VFP Conditional Execution
To perform conditional execution in the ARM processor we made use of the flags in the **CPSR**. We have used the **N**, **Z**, **C**, **V** flags to determine execution paths. The VFP unit also has a similar register that keeps track of what happened. It is called the **FPSCR**. The **FPSCR** is a 32-bit register. Let's talk about some of those bits.

Bit          | Stands for               |
-------------|--------------------------|
**31**       | **N**: Negative Flag                
**30**       | **Z**: Zero Flag                 
**29**       | **C**: Carry Flag  
**28**       | **V**: Overflow Flag                                          

Unlike the ARM instructions, there is no `S` suffix that can be appended to the end of a VFP instruction to update the flags of the **FPSCR**. In order to update the flags we have to explicitly call the `VCMP` (the equivalent of `CMP` in the ARM ISA). Remember that the `VCMP` instruction can also use the suffixes `.F32` and `.F64` to specify what type of registers it is comparing. Simply setting the flags with the `VCMP` instruction won't allow you to use the condition codes (predication) for conditional execution. In order to do that you must update the **CPSR** flags. You achieve that by copying the **FPSCR** flags into the **CPSR** with the `VMRS` and `VMSR` instructions. The `VMRS` instruction moves a status register to a register you specify. The `VMSR` instruction moves a register to a status register. The **CPSR** contains the **APSR** (Application Program Status Register) flags: **N, Z, C, V**.

```gas
VMRS APSR_nzcv, FPSCR     @ Copy the flags in FPSCR to the APSR flags.
VMRS R0, FPSCR            @ Copy the FPSCR to the R0 register.
VMSR FPSCR, R0            @ Copy the contents of R0 into the FPSCR.
```

The following table, taken from [here](http://www.keil.com/support/man/docs/armasm/armasm_dom1359731162080.htm), shows you the meaning of the condition codes when operating with VFP instructions. It also shows you a comparison with the meaning of the suffix within the scope of ARM instructions.

![Condition Codes](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-3/conditionCodes.png?raw=true)

Let's see a code example that uses all of the material explained above.

```gas
@ File: addfp.s

	.global main
	.func main

main:
	PUSH {R0, LR}
	LDR R0, =enterFirst
	BL printf

	SUB SP, SP, #8
	LDR R0, =inputFormat
	MOV R1, SP
	BL scanf
	VLDR S1, [SP]
	VCVT.F64.F32 D1, S1

	LDR R0, =enterSecond
	BL printf

	SUB SP, SP, #8
	LDR R0, =inputFormat
	MOV R1, SP
	BL scanf
	VLDR S2, [SP]
	VCVT.F64.F32 D2, S2

	VADD.F64 D0, D1, D2
	VMOV R2, R3, D0

	LDR R0, =result
	BL printf

	LDR R0, =result2
	VCMP.F64 D1, D2
	VMRS APSR_nzcv, FPSCR
	VMOVHS R2, R3, D1
	VMOVLS R2, R3, D2
	SUB SP, SP, #8
	VSTRHS D2, [SP]
	VSTRLS D1, [SP]
	BL printf

	ADD SP, SP, #24
	POP {R0, PC}
	MOV PC, LR

.data
enterFirst:  .asciz "Enter the first number: "
enterSecond: .asciz "Enter the second number: "
inputFormat: .asciz "%f"
result:      .asciz "The result of adding is: %f.\n"
result2:		 .asciz "%f is greater than %f\n\n"

```

##### Vector Operations
So far we have only performed scalar operations, this is, operations that perform on only one value. The VFP unit allows performing vector operations that act on a set of values. In order to explore this let's look at some additional bits from the **FPSCR**.

Bits         | Stands for               |
-------------|--------------------------|
**21-20**    | Vector **Stride** Bits  
**19**       | Do not modify
**18-16**    | Vector **Length** Bits   

Let's take a look at how the **Length bits (LEN)** work. By default, the value of LEN is set to 1 so you always work in scalar mode (this is one value at a time). When you set LEN to something else than one, it means that you are picking a set of values and you have just activated vector mode. The registers in the VFP are split in four banks. Bank 0 is also called the scalar bank and banks 1-3 are vector banks.

Let's start by choosing a starting point (we will call it starting register in the examples below). Then we will choose how many registers we will pick. If we choose `LEN = 1` then we are only picking one register (the starting register). If we set `LEN = 2` then we are picking two registers (the starting register and the one right next to it). The picking process uses bank wrap around, this means that if the last register in the bank was selected as your starting register the next register will be the first in the register in the bank. You can't mix and match single precision and double precision in the picking process. Let's see some examples below.

![LEN](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-3/LEN.png?raw=true)

Now let's take a look at how the **Stride bits (STRIDE)** work. By default the value of STRIDE is set to 1 and it can only be set to 1 or 2. Setting `STRIDE = 2` will allow you to work with every other register starting at your starting register. The picking process, as before, uses bank wrap around. Let's see how this works with the examples below.

![STRIDE](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-3/STRIDE.png?raw=true)

If your choice of `LEN` and `STRIDE` allows a register to be picked twice the result of the operations will be unpredictable. For instance, in the last example above, if `LEN = 5` and `STRIDE = 2` the operation will pick the register `S10` twice and this will result unpredictable outcomes. See [this](http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0344b/Chdfafia.html) for more information.

##### Setting up LEN and STRIDE
The Vector Length Bits (LEN) occupy bits 18-16 in the **FPSCR**. This is a 3-bit field that can take 8 different values. Let's see what these values are and what they mean.

Bit Pattern  | LEN             |
-------------|-----------------|
000          | 1  
001          | 2
010          | 3  
011          | 4
100          | 5  
101          | 6
110          | 7
111          | 8

The Vector Stride Bits (STRIDE) occupy bits 21-20 in the **FPSCR**. This is a 2-bit field that can take (surprise!) only two values. Let's see what these values are and what they mean.

Bit Pattern  | STRIDE          |
-------------|-----------------|
00           | 1  
11           | 2

We need to move the appropriate bit pattern into the **FPSCR** in order to make changes to the LEN and STRIDE bits. Keep in mind that bit 19 separates the STRIDE and LEN bits and it must not be changed. We would do something like this to perform the changes:

```gas
VMRS R0, FPSCR         @ Copying the FPSCR into R0
MOV R1, #0b110011      @ STRIDE = 2 (0b11) and LEN = 4 (0b011)
MOV R1, R1, LSL #16    @ Move these bits to occupy bits 21-20 and 18-16
ORR R0, R0, R1         @ R0 = R0 OR R1
VMSR FPSCR, R0         @ Setting FPSCR to the value of R0
```

The following example makes use of the LEN and STRIDE bits to perform a vector add of single precision values.

Register Set 1 | Value | Register Set 2 | Value | Result Register | Value |
---------------|-------|----------------|-------|-----------------|-------|
**S8**         | 1.00  | **S16**        | 0.25  | **S24**         | 1.25
**S10**        | 2.00  | **S18**        | 0.50  | **S26**         | 2.50
**S12**        | 3.00  | **S20**        | 0.75  | **S28**         | 3.75
**S14**        | 4.00  | **S22**        | 1.00  | **S30**         | 5.00

The code is presented below.

```gas
@ File: vectoradd.s

	.global	main
	.func main

main:
	PUSH {R0, LR}

	@ Getting the addresses of the numbers in the ARM registers
	LDR R2, =number1
	LDR R3, =number2
	LDR R4, =number3
	LDR R5, =number4
	LDR R6, =number5
	LDR R7, =number6
	LDR R8, =number7
	LDR R9, =number8

	@ Loading the first batch of numbers into the VFP registers
	VLDR S8, [R2]
	VLDR S10, [R3]
	VLDR S12, [R4]
	VLDR S14, [R5]

	@ Loading the second batch of numbers into the VFP registers.
	VLDR S16, [R6]
	VLDR S18, [R7]
	VLDR S20, [R8]
	VLDR S22, [R9]

	@ Settings the LEN and STRIDE in the FPSCR
	VMRS R0, FPSCR
	MOV R1,  #0b110011
	MOV R1, R1, LSL #16
	ORR R0, R0, R1
	VMSR FPSCR, R0

	@ Performing the vector add
	VADD.F32 S24, S8, S16

	@ Converting all the results to double for printf
	VCVT.F64.F32 D0, S24
	VCVT.F64.F32 D1, S26
	VCVT.F64.F32 D2, S28
	VCVT.F64.F32 D3, S30

	@ Make space in the stack for 3 double precision values
	SUB SP, SP, #24

	LDR R0, =result		@ Load the result string
	VMOV R2, R3, D0		@ Move the first result to the registers

	@ Move the remaining results to the stack
	VSTR D1, [SP]
	VSTR D2, [SP, #8]
	VSTR D3, [SP, #16]

	@ Call printf
	BL	printf

	@ Balance the stack
	ADD SP, SP, #24

	@ Pop the stack
	POP {R0, PC}

	.data
number1:	.float 1.00
number2:	.float 2.00
number3:	.float 3.00
number4:  .float 4.00
number5:	.float 0.25
number6:	.float 0.50
number7:  .float 0.75
number8:	.float 1.00

result:	.asciz "Results:\n\t%f\n\t%f\n\t%f\n\t%f\n"

```

---

#### On your own

Now that you are more familiar with ARM you are able to write simple programs on your own. This week you will have two programs to write. Make sure to include plenty of proper comments.

##### Program #1: lab3a.s
You will be implementing a calculator. Use functions to define the add, subtract, and multiply functions. You will show the following menu to the user. Your program will only take integers.

```
Calculator
  1) Add
  2) Subtract
  3) Multiply
  4) Exit

Choose your option:
```

An screenshot is provided as an example of what is required.

![calculator](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-3/outputCalculator.png?raw=true)

Save this program as **lab3a.s**.

##### Program #2: lab3b.s
Rewrite the calculator program (keep the lab3a.s file!) to take floating point numbers as input. Add the ability to divide. Use functions to define the add, subtract, multiply, and divide functions. Follow the same format used for **lab3a.s**.

```
Floating Point Calculator
  1) Add
  2) Subtract
  3) Multiply
  4) Divide
  5) Exit

Choose your option:
```

Save this program as **lab3b.s**.

----

#### Review Questions
The following review questions must be answered in your lab report. It is expected that you go further than what was explained in this manual to answer the questions. Make sure you pay special attention to questions regarding the ARM instruction set since future lab material will assume you know what was taught in this manual.

1. Briefly explain the role of the **ABI** and the **AAPCS**.

2. How do you set up your program to make use of **printf**?

3. How do you set up your program to make use of **scanf**?

4. What happens if you need more than three arguments?

5. Explain how the stack works to keep track of the function calls.

6. How does the use of conditional execution differ between VFP and the ARM ISA.

7. Explain how LEN and STRIDE work for vector operations.
