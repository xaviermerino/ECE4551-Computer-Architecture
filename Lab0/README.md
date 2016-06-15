## Computer Architecture
###Lab 0: Setting up - Introduction to ARM

  - [Overview](#overview)
      - [ARM and Instruction Sets](#arm-and-instruction-sets)
      - [Who else uses this?](#who-else-uses-this)
      - [Objectives](#objectives)
  - [Preparing the Pi](#preparing-the-pi)
  - [Machine Code](#machine-code)
  - [Assembly Instructions](#assembly-instructions)
  - [Your first ARM Assembly program](#your-first-arm-assembly-program)
      - [Transferring the source code to the Pi](#transferring-the-source-code-to-the-pi)
      - [Producing an executable](#producing-an-executable)
      - [Running the executable](#running-the-executable)
  - [More on ARM: Registers](#more-on-arm-registers)
  - [On your own](#on-your-own)
      - [Program #1: lab0a.s](#program-1-lab0as)
      - [Program #2: lab0b.s](#program-2-lab0bs)
  - [Review Questions](#review-questions)

#### Overview
In this lab you will set up the Raspberry Pi and prepare the environment you are going to be using to develop for an ARM processor.

This course will focus on the chip to the right of the Raspberry Pi logo. It is a System on a Chip (SOC) by Broadcom that contains a  32-bit ARM processor clocked at 700MHz and a Videocore IV Graphics Processing Unit. The chip itself is called Broadcom BCM2835.

##### ARM and Instruction Sets
The Raspberry Pi uses the ARM11 microarchitecture and supports the ARMv6 instruction set. It also supports the Thumb1 and Jazelle extensions.

In this course we will focus mainly on the ARMv6 Instruction Set.

##### Who else uses this?
ARM is one of the most popular instruction set architectures out there. Some popular products use the same instruction set as the one you are about to learn. Examples of this are the Nintendo 3DS, the iPhone 3G, and some low-end Android phones. The newer instruction set architectures such as ARMv7 and ARMv8 are backwards compatible so most of what you will be learning will still be applicable to newer microarchitectures.

##### Objectives
* To get familiar with the Raspberry Pi
* To get familiar with a UNIX-like environment
* To understand the role of the Assembler and Linker
* Write your first program in ARMv6 Assembly

---

#### Preparing the Pi
Your Raspberry Pi should be ready to boot into `Raspbian`. It should have an SD card and be connected to the network through an Ethernet cable. Plug the power cord into the Pi and some LEDs will flash. Give it some time to boot (around a minute) and it will be ready for you.

Next we are going to set up a proper `hostname` for the Pi. The Raspbian operating system comes bundled with `Bonjour` or `zeroconf`. This allows us to refer to the Pi by its hostname and not an IP. Essentially, the Pi will have a name on the network and you won't need to remember its local IP.

Since we need to access the Pi and the hostname hasn't been set, the instructor will provide you with your Pi's local IP. On your computer, open the `Terminal`. Type the commands shown below:

```bash
ssh pi@<localip>
```

If the Pi is not ready or you mistyped the IP address an error will occur and `ssh` will let you know. Otherwise ssh should ask you for a password. The default password is `raspberry`. If you haven't connected to this device before you will be told that the authenticity can't be established and an `RSA fingerprint` will appear on the screen. You will be asked if you want to continue with the connection. Say yes. You should now be logged in to the Pi.

We will now verify the current working directory by typing the command shown below. The output should be `/home/pi`.

```bash
pwd
```
We will now download the configuration script. The script will be downloaded to the working directory using `wget`, a utility for downloading network data.

```bash
wget https://raw.githubusercontent.com/xaviermerino/ECE4551-Computer-Architecture/master/Lab0/hostnameScript.sh
```

We must ensure that the `bash` script that you just downloaded is executable by altering the executable flag with `chmod`. We will then proceed to run the script with the hostname assigned to you.

```bash
chmod u+x ./hostnameScript.sh
sudo ./hostnameScript.sh -n <assignedHostname>
```

The script will set the new hostname and reboot the Pi. Once the Pi is done rebooting you will `ssh` into it like this:

```bash
ssh pi@<assignedHostname>.local
```

If the connection was successful then your Pi is ready. Keep this connection alive as we will be using it later.

----

#### Machine Code
Machine code is a sequence of 0s and 1s ordered in such a way that they are meaningful to the microprocessor.

A machine code program might look like this:

```binary
0000 0001 0000 0000 1010 0000 1110 0011
0000 0100 0001 0000 1010 0000 1110 0011
0000 0001 0000 0000 1000 0000 1110 0000
0000 0001 0111 0000 1010 0000 1110 0011
0000 0000 0000 0000 0000 0000 1110 1111
```

Assembly language allows you to write machine code programs using mnemonics. You will be writing the program listed above in Assembly.

----

#### Assembly Instructions
The ARM processor in your Raspberry Pi takes a specific set of machine code instructions. The Raspberry Pi model B makes use of the ARMv6 instruction set. You cannot take a program written for an ARMv6 compliant microarchitecture (such as the ARM11 in your Pi) and run it in a x86-64 one. You will need to learn another instruction set to port your code.

As mentioned before, we will focus on the ARMv6 instruction set. A processor is able to move and process data and as such you can expect the instruction set to provide support for these operations.

Some common instructions are:
```assembly
MOV               @ Move
ADD               @ Add
SUB               @ Subtract
MUL               @ Multiply
AND               @ And
ORR               @ Or
```

There are two ways to specify comments in Assembly. If you are familiar with the `C` language you will recognize the style below.

```assembly
/* This is a comment */
```

You can also comment using the `@` character.

```assembly
MOV R0, #1         @ Moves the constant 1 to the Register R0
```
----

#### Your first ARM Assembly program
In this lab we will be making a very simple adding program. You will set two numbers and add them together. Use your favorite editor to type the source code below. Save it as `lab0.s`.

```assembly
@ File: lab0.s

  .global _start

_start:
MOV R0, #1         @ Moves the constant 1 to the Register R0
MOV R1, #4         @ Moves the constant 4 to the Register R1
ADD R0, R0, R1     @ R0 = R0 + R1

@ The lines below exit the code back to the command line prompt.
@ Register R7 holds the System call number.
@ Syscall #1 indicates exit.

MOV R7, #1         @ Moves the constant 1 to the Register R7
SWI 0              @ Executes Software Interrupt determined by R7
```

##### Transferring the source code to the Pi
Open a new terminal session in your computer. Using the terminal navigate to the directory where your source code file is located. You can do this using the `cd` command like shown below.

```bash
cd /your/directory/
```
Now we must transfer the source code to the Pi via the network. We will use `scp` to perform the transfer.

```bash
scp ./lab0.s pi@<assignedHostname.local>:/home/pi
```

You will be prompted for the password. After that your file should start transferring. Once it is done you can close that terminal session but make sure that the terminal with the `ssh` session is active.

###### Producing an executable
Now we must convert the source file into an executable file. Assuming that you named your file `lab0.s` we must enter the following in the command prompt. These commands will assemble and link your program producing an executable you can run.

```bash
as -o lab0.o lab0.s
ld -o lab0 lab0.o
```

If everything went well you should now have `lab0.s`, `lab0.o`, and `lab0` in your working directory. Otherwise read the assembler errors, fix them, and retry the steps above.

##### Running the executable

To run your program just type:

```bash
./lab0
```

Although you just ran your program it might look a little bit uneventful. There was nothing really shown on the screen and you might argue that nothing really took place. To show you otherwise type this in the command prompt. You should see number five being displayed on the terminal.

```bash
echo $?
```

When programs exit the return value indicates if they have exited successfully. The command above prints the return value or exit status of the last executed statement. It would normally be zero to indicate that everything went well. In our code we placed the result of the addition as the return value instead of the traditional zero. By convention return values should always be passed to register R0.

----

#### More on ARM: Registers

As of right now you've only executed code that was provided to you. We have mentioned `register` R0 but we haven't really explained what a register is. A register is a small amount of fast storage that is part of the processor. Operations on registers are fast since they don't involve access to external memory. ARM uses a `load-store architecture` meaning that non-load and non-store instructions (such as `ADD`) can only operate on values in the registers.

The ARM processor has 17 (32-bits) registers:
* 13 general-purpose registers (R0 - R12)
* One Stack Pointer (SP or R13)
* One Link Register (LR or R14)
* One Program Counter (PC or R15)
* One Current Program Status Register (CPSR)

Registers R0 to R12 are safe to play with. Registers R13 to R15 have predefined uses. You can use these registers if you want, however, bear in mind that unless you know what you are doing odd things might happen.

We will cover the `Current Program Status Register` in the next lab.

----

#### On your own

Now that you are more familiar with ARM you are able to write simple programs on your own. This week you will have two programs to write.

##### Program #1: lab0a.s
You will be writing a program that is able to calculate the following:

> Result = A + (B * C) - D

Place the result as the return value so you can print it afterwards in the command prompt. Save this program as `lab0a.s`.

##### Program #2: lab0b.s
Your task in this second program is to reduce the number of instructions in Program #1 by using the `MLA` instruction. Place the result as the return value so you can print it afterwards in the command prompt. Save this program as `lab0b.s`.

----
#### Review Questions
The following review questions must be answered in your lab report. It is expected that you go further than what was explained in this manual to answer the questions. Make sure you pay special attention to questions regarding the ARM instruction set since future lab material will assume you know what was taught in this manual.

1. What is Raspbian?

3. Briefly explain what Zeroconf is.

4. Briefly explain RISC vs CISC.

2. What is the difference between the ARM instruction set and the Thumb extensions?

5. Briefly explain what a register is.

6. Explain what the following instructions do and give an example (the first one is done for you):

   * **MOV**: Mnemonic that stands for move. Moves an immediate value or constant to a register. It can also copy the contents of a register to another.
      *  Example:
         * MOV R1, #32
   * **ADD**
   * **SUB**
   * **MUL**
   * **MLA**
   * **RSB**

If you haven't used a UNIX-like environment before make sure you get familiar with it. You can read the manual of almost any command using `man <command>`.
