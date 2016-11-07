## Computer Architecture
### Lab 5: Using the Pi's System Timer

- [Overview](#overview)
  - [Objectives](#objectives)
- [Preparing the Pi](#preparing-the-pi)
- [The System Timer](#the-system-timer)
  - [System Timer Registers](#system-timer-registers)
  - [More on mmap](#more-on-mmap)
- [On your own](#on-your-own)
  - [Program #1: lab5a.s](#program-1-lab5as)
- [Review Questions](#review-questions)

#### Overview
In the last lab we made use of the `open()`, `close()`, and `mmap()` functions in order to access the Pi's GPIO. In this lab we are going to make use of the Pi's System Timer. Every computer that you have used has at least one hardware timer. Timers are usually counters that increment at a fixed frequency. The system's frequency is known and thus you can translate clock cycles to time. Hardware timers are used to implement fail-safe mechanisms (watchdog timers), preemptive multitasking, and of course, to provide system time.

In this lab we are going to use the system timer to implement a thread-blocking counter that will display an output like the one shown below:

<br>
<img src="https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-5/secondsElapsed.gif?raw=true" width="550">

<br>
The Raspberry Pi 3 that you are using has the **BCM2837** chip. There is very scarce documentation on the **BCM2387**. Luckily, most of the information on the **BCM2835** still applies. You can take a look at the [datasheet](https://cdn-shop.adafruit.com/product-files/2885/BCM2835Datasheet.pdf) for more information on system timer.

##### Objectives
* Learn about the registers that control the system timer.
* Monitor the timer counter to measure elapsed time.
* Implement a second delay using the system timer.

---

#### Preparing the Pi
Once the Pi is ready `ssh` into it like this:

```console
ssh pi@<assignedHostname>.local
```

If the connection was successful then your Pi is ready. Keep this connection alive as we will be using it later.

---

#### The System Timer
The system timer provides a **64-bit counter** that increments at each clock pulse. It also provides four 32-bit registers that you can use to compare with the lower 32 bits of the 64-bit counter and then trigger a signal that is fed to the interrupt controller.

We are not going to be using **interrupts** to implement the program for this lab. Instead, we are going to perform the comparisons ourselves and use our knowledge of **libc** to use the `printf` function to display the number of seconds elapsed.

##### System Timer Registers
There are 7 registers that deal with the behavior of the system timer. We will use two of those registers in this lab. The table below shows these registers and their offset from the base address. For newer Pi with 40 pins the system timer base address is `0x3F003000`. You can see more information about the system timer registers in the [BCM2835 Arm Peripherals Datasheet (page 172)](https://cdn-shop.adafruit.com/product-files/2885/BCM2835Datasheet.pdf).

| N. | Address   | Register | Description                         |
|----|-----------|----------|-------------------------------------|
| 0  | Base + 0  | CS       | System Timer Control / Status       |
| 1  | Base + 4  | CLO      | System Timer Counter Lower 32 bits  |
| 2  | Base + 8  | CHI      | System Timer Counter Higher 32 bits |
| 3  | Base + 12 | C0       | System Compare 0                    |
| 4  | Base + 16 | C1       | System Compare 1                    |
| 5  | Base + 20 | C2       | System Compare 2                    |
| 6  | Base + 24 | C3       | System Compare 3                    |

Just as a reminder, the `CLO` and `CHI` registers are **read-only**.

##### More on mmap

Let's take a look at the function prototype for the `mmap` function again.

```c
void *mmap(void addr, size_t length, int prot, int flags,
  int fd, off_t offset);
```

In the past lab, you were given a template on how to use the `mmap` function. You simply had to reuse what was given to change the behavior of the program. In this lab, you will need more information about the arguments of `mmap` to complete the task.

<br>
![mmap](http://cinsk.github.io/articles/duma_mmap.png)

<br>
In the last lab, we provided a null pointer as the `addr` argument for the mmap function. This is because `addr` is an in-out parameter. An **in-out parameter** is passed to the function, the value is modified, and then is passed back out with the modified value. Since you provide `NULL` or `0`, the kernel will choose an address and provide it. When the `mmap` function returns, the virtual memory address mapped to the physical base address is returned in `R0`. You might also take for granted the fact that we chose `R2` to be 4096 bytes as the file size. The file might be smaller than this but this is feasible because mapping occurs in page-sized chunks (which are multiples of 4096 bytes).

The `prot` argument describes the memory protection of the mapping. You must choose between:

* **PROT_NONE**: Pages may not be accessed. This has a value of `0x0`.
* **PROT_READ**: Pages may be read. This has a value of `0x1`.
* **PROT_WRITE**: Pages may be written. This has a value of `0x2`.
* **PROT_EXEC**: Pages may be executed. This has a value of `0x4`.

If you need, for instance, **Read-Write** access to a page, then you must `OR` these integers. We needed **Read-Write** in the previous lab, reason why R3 stored 3 (for `0x3`).

The `flags` argument determines whether the mapping is shared between processes or not. The most common values are presented below:

* **MAP_SHARED**: The mapping is shared among processes. This has a value of `0x1`.
* **MAP_PRIVATE**: This is a copy-on-write private mapping. This has a value of `0x2`.

We used `MAP_SHARED` for our `flags` argument and so we chose `0x1` for `R4`.

The remaining two arguments were passed via the stack. The top of the stack is the **file descriptor** for `/dev/mem`. The next element in the stack is the offset, which is the **timer base address** `0x3F003000`.

Just remember the memory protection arguments must be compatible with the file descriptor permissions. After you perform a memory un-map `munmap`, accessing that address will result in a segmentation fault.

[For more information visit the GNU manual.](http://www.gnu.org/software/libc/manual/html_node/Memory_002dmapped-I_002fO.html)

---

#### On your own

At this point you know enough about ARM, its registers, some peripherals, and memory mappings. You are now able to write some programs that make use of the system timer in the **BCM2837** chip.

##### Program #1: lab5a.s
Your task for this lab is to implement a one-second delay and print the seconds elapsed since the program started running.

<br>
<img src="https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-5/secondsElapsed.gif?raw=true" width="550">

<br>
Save this program as **la5a.s**.

----

#### Review Questions
The following review questions must be answered in your lab report. It is expected that you go further than what was explained in this manual to answer the questions. Make sure you pay special attention to questions regarding the ARM instruction set since future lab material will assume you know what was taught in this manual.

1. Describe the role of the `CLO` and `CHI` registers. How do you use these to tell time?

2. Explain why `mmap` is necessary? How does it work?
