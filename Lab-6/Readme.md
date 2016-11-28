## Computer Architecture
### Lab 6: Intro to Reverse Engineering

#### Overview
This lab will introduce you to the very basics of reverse engineering. For the first time in this class you won't be writing a program on your own. Instead, we will be injecting binary in some portion of a given executable to change its behavior. Needless to say, the injected binary must be meaningful. You can't simply insert or replace binary in an executable without carefully analyzing the program structure. We will be making use of your ARM skills to read the executable and get a better insight of what it is doing. In the end, you will have enough information to change its behavior.

##### Objectives
* Test your knowledge of the ARM architecture.
* Read and interpret basic programs from a third-party.
* Introduce or replace binary in an executable.
* Become familiar with a hex editor.

---

#### Preparing the Pi
Once the Pi is ready `ssh` into it like this:

```console
ssh pi@<assignedHostname>.local
```

If the connection was successful then your Pi is ready. Keep this connection alive as we will be using it later.

----

#### Disassembling an executable
The first step toward replacing the binary in an executable is to see the binary. We are going to be using a simple disassembler bundled with your Linux distribution.

The sample `a.out` is located [here](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-6/a.out?raw=true).

1. Navigate to the folder containing the sample `a.out`.
2. Run the executable by doing `./a.out`
3. Verify that the output is **Hello World**.
4. Execute the following command: `objdump -D ./a.out > dump.txt`
5. A file named **dump.txt** is located in your directory. It contains the disassembly of the executable.

The steps above make use of the `objdump` disassembler. We use the `-D` option to disassemble all sections of the executable. We later redirect this output to the file.

Your file should look like this:

<br>
<img src="https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-6/dump.png?raw=true" width="550">

<br>
There are several columns in the listing. The first column is the address. The second column is the hexadecimal representation of the executed binary. The third column is the instruction that corresponds to that binary. The tricky part is that this column is not always correct. Some data sections might be interpreted as instructions and so those instructions might not be correct. It is up to you to differentiate.

Throughout the code you will see sections annotated like this:

```
Disassembly of section .note.ABI-tag:

00010150 <.note.ABI-tag>:
   10150:       00000004        andeq   r0, r0, r4
   10154:       00000010        andeq   r0, r0, r0, lsl r0
   10158:       00000001        andeq   r0, r0, r1
   1015c:       00554e47        subseq  r4, r5, r7, asr #28
   10160:       00000000        andeq   r0, r0, r0
   10164:       00000002        andeq   r0, r0, r2
   10168:       00000006        andeq   r0, r0, r6
   1016c:       00000020        andeq   r0, r0, r0, lsr #32
```

The disassembler will tell you which section has been disassembled and give you the label of that section in angled brackets. In this case the label is `.note.ABI-tag`. Every executable must contain this section and the compiler adds it to your code. To learn more on the ABI note tag visit [this](https://refspecs.linuxfoundation.org/LSB_1.2.0/gLSB/noteabitag.html).

Similarly, if the **symbol table** has not been stripped from the executable you will find function names in the disassembly. We will use this information to locate the `main` function. For now we will ignore the rest of the **libc initialization code** present in the disassembly.

As always, make sure that you pay attention to the endianness of the system. You can verify this by typing `lscpu` in your Linux console.

---

#### On your own

##### Program #1: lab6a.s
Replace some binary in the executable so that it prints **IWantPie!!!** instead of **Hello World**.

#### Review Questions

1. What is `objdump`.

2. What is the purpose of a disassembler.

3. What would be the source code of the executable given to you?
