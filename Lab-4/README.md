## Computer Architecture
### Lab 4: Using the Pi's GPIO

  - [Overview](#overview)
    - [Objectives](#objectives)
  - [Preparing the Pi](#preparing-the-pi)
  - [The General Purpose Input/Output Pins](#the-general-purpose-inputoutput-pins)
    - [Wiring](#wiring)
  - [Python: RPi.GPIO](#python-rpigpio)
    - [Turn on pin 17.](#turn-on-pin-17)
    - [Turn off pin 17.](#turn-off-pin-17)
    - [Running the Python Script](#running-the-python-script)
  - [More on the Pins](#more-on-the-pins)
    - [Pin Numbering Scheme](#pin-numbering-scheme)
    - [Pin Modes](#pin-modes)
    - [Digital Output](#digital-output)
  - [ARM Assembly: GPIO](#arm-assembly-gpio)
    - [GPIO Registers](#gpio-registers)
    - [Initializing Pin 17](#initializing-pin-17)
    - [Setting Pin 17 to Output Mode](#setting-pin-17-to-output-mode)
    - [Setting Pin 17's output to HIGH or LOW](#setting-pin-17s-output-to-high-or-low)
    - [Before stepping into the real thing.](#before-stepping-into-the-real-thing)
      - [Open](#open)
      - [Close](#close)
      - [Mmap](#mmap)
    - [The Real Thing](#the-real-thing)
    - [Graphical Representation of Registers](#graphical-representation-of-registers)
  - [On your own](#on-your-own)
    - [Program #1: lab4a.s](#program-1-lab4as)
    - [Program #2: lab4b.s](#program-2-lab4bs)
    - [Program #3: lab4c.s](#program-3-lab4cs)
  - [Review Questions](#review-questions)

#### Overview
We are finally ready to put to use all of the knowledge we have acquired in the past weeks. This week we will be covering the use of the **GPIO** (General Purpose Input/Output) pins in the Raspberry Pi. This will allow you to connect external components such as LEDs, switches, sensors, and even communicate with other devices. Even though you will be using a Raspberry Pi 3, the pins will look like the ones presented below.

![Pins](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/pinspi.jpg?raw=true)

We are going to focus on the registers that control the behavior of the GPIO, how to set a specific pin as **input** or **output**, and how to **set** or **clear** that pin. We will be creating two applications in this lab. The first one will be a **Python** application that uses the `RPi.GPIO` library to interface with the pins. This Python application will be used to test your wiring / connections. Once your Python application runs as expected we will be writing code that produces the same output in ARM Assembly.

The Raspberry Pi 3 that you are using has the **BCM2837** chip. There is very scarce documentation on the **BCM2387**. Luckily, most of the information on the **BCM2835** still applies. You can take a look at the [datasheet](https://cdn-shop.adafruit.com/product-files/2885/BCM2835Datasheet.pdf) for more information on the peripherals.

##### Objectives
* Learn about the registers that control the GPIO pins.
* Set a pin as input / output.
* Set or clear a pin.
* Familiarize with the `RPi.GPIO` Python library.

---

#### Preparing the Pi
Once the Pi is ready `ssh` into it like this:

```console
ssh pi@<assignedHostname>.local
```

If the connection was successful then your Pi is ready. Keep this connection alive as we will be using it later.

---

#### The General Purpose Input/Output Pins
The pins allow you to expand the capabilities of your Pi. You can introduce yourself to physical computing by connecting sensors and performing data analysis on the information. The Pi has pins that allow communicating via I2C, SPI, and Serial communication. It also has pins that provide 3.3V and 5V. Unlike the Arduino, the pins are not numbered on the board. You will need a diagram that allows you to connect your devices to the right pins. You refer to the pins by numbers. There are two numbering systems that are used to refer to them. The first one (the one we will be using), is called **BCM** because it is the number assigned to the pin by the Broadcom chip. The other numbering system is the physical or **board** system in which basically the pins are numbered from top-to-bottom, left-to-right, starting with pin 1 and ending in pin 40.

##### Wiring
We will be using an LED, a small resistor, and some jumper wires.
Make sure you connect the components like the diagram below:

![Wiring Diagram](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/wiringDiagram.png?raw=true)

#### Python: RPi.GPIO
We have been using **Raspbian** in the Raspberry Pi. It comes bundled with Python and the `RPi.GPIO` module. This means that we can use this module out of the box. Since **Python** performs garbage collection and resides on top of an OS whose **scheduling** you can't control, you can't really use this module (or any of the programs we have been writing so far) for real-time applications. This, however, is not a problem for our simple programs.

In this section you will find two scripts. The first script will turn on the LED attached to pin 17. The second script will turn it off. There are some constants in the scripts that might be confusing even if you are familiar with Python. These are related to how the SOC handles the GPIO. We will be covering these as we explain the scripts.

##### Turn on pin 17.
The program below will turn **ON** the LED attached to BCM pin 17.

```python
# Imports the module RPi.GPIO and names it GPIO
import RPi.GPIO as GPIO
from time import sleep

# Sets the Pin Numbering scheme to the ones defined by the SOC.
GPIO.setmode(GPIO.BCM)

# Sets pin 17 for output
GPIO.setup(17, GPIO.OUT)

# Turns "on" pin 17 by setting it to HIGH
GPIO.output(17, GPIO.HIGH)

# sleep
time.sleep(2)

# Allows Python to perform GC on these resources
GPIO.cleanup()
```

##### Turn off pin 17.
The program below will turn **OFF** the LED attached to BCM pin 17.

```python
# Imports the module RPi.GPIO and names it GPIO
import RPi.GPIO as GPIO

# Sets the Pin Numbering scheme to the ones defined by the SOC.
GPIO.setmode(GPIO.BCM)

# Sets pin 17 for output
GPIO.setup(17, GPIO.OUT)

# Turns "off" pin 17 by setting it to LOW
GPIO.output(17, GPIO.LOW)

# Allows Python to perform GC on these resources
GPIO.cleanup()
```

##### Running the Python Script
Copy the code to turn on the LED on BCM pin 17 and name the file `led.py`. Transfer the file to the Raspberry Pi. Navigate to the directory where you saved the file. Execute the file as root with the following command.

```bash
sudo python led.py
```

The LED at pin 17 should turn on. If it doesn't, check your wiring.

#### More on the Pins

This is the Raspberry Pi 3's 40-pin layout.

![Pin Out](http://data.designspark.info/uploads/images/53bc258dc6c0425cb44870b50ab30621)

##### Pin Numbering Scheme

In the picture above you can see the physical pin number and the BCM numbering scheme. The physical or board numbering starts at pin 1 and ends with pin 40 on the bottom right. In the Python example above, we used the BCM scheme and chose pin 17 (physical pin 11).  

When we use `GPIO.setmode(GPIO.BCM)` we are telling Python that we want to use the SOC's numbering scheme. There are two pin numbering schemes available. The one we will be using is the `GPIO.BCM`. The other one is the physical pin numbering, which Python refers to as `GPIO.BOARD`.

##### Pin Modes
Before you can use a pin you need to set it as an input or output. In the scripts above we set pin 17 as an output by doing `GPIO.setup(17, GPIO.OUT)`. You could also set it as an input provided you specify whether the pin is using a **pull-up** or **pull-down resistor**. To set up pin 17 as an input pin with a pull-up resistor you would do `GPIO.setup(17, GPIO.IN, pull_up_down = PUD_UP)`.

##### Digital Output
Once you are done setting your pin as an output pin you can turn on or off the pin by setting it to HIGH or LOW. Setting a pin to **HIGH** will make it output 3.3V. Setting it to **LOW** will make it output 0V. In the scripts we did this with `GPIO.output(17, GPIO.HIGH)` and `GPIO.output(17, GPIO.LOW)`.

#### ARM Assembly: GPIO
Before continuing with this section, make sure that your wiring works (if your Python scripts behaved as expected then your wiring is correct!) and that the LED at BCM pin 17 is off.

In order to turn on the LED at pin 17 using Assembly we have to follow these steps:

1. **Initialize** pin 17.
2. Set the pin mode to **output**.
3. Set the pin's output to **HIGH**.

Initializing a pin requires you to set it to input and then to output. You can set it to whatever mode you desire afterwards.
The GPIO controller in charge of the pins considers the existence of 54 GPIO pins. We are only given access to 40 of those when using the Raspberry Pi. To use a specific pin we have to set up some special bit patterns to the register in charge of the pin to define under what mode it will be operating.

##### GPIO Registers
There are 41 registers that deal with the behavior of the GPIO pins. We will deal with 10 of those registers in this lab. The table below shows some of these registers. In the address column you can see that we refer to a **base** address. Since our programs sit on top of Raspbian, the physical address gets mapped into virtual one by the OS. For an older Raspberry Pi with 24 pins the mapped base address is `0x20200000`. For newer Pi with 40 pins the mapped base address is `0x3F200000`. You can see more information about the GPIO registers in the [BCM2835 Arm Peripherals Datasheet (page 90)](https://cdn-shop.adafruit.com/product-files/2885/BCM2835Datasheet.pdf).

N. | Address    | Register | Description              | Pins Controlled    
---|------------|----------|--------------------------|-----------------
0  | Base + 0   | GPFSEL0  | GPIO Function Select 0   |  0 -  9
1  | Base + 4   | GPFSEL1  | GPIO Function Select 1   | 10 - 19
2  | Base + 8   | GPFSEL2  | GPIO Function Select 2   | 20 - 29
3  | Base + 12  | GPFSEL3  | GPIO Function Select 3   | 30 - 39
4  | Base + 16  | GPFSEL4  | GPIO Function Select 4   | 40 - 49
5  | Base + 20  | GPFSEL5  | GPIO Function Select 5   | 50 - 53
6  | Base + 24  | Reserved | Reserved                 |
7  | Base + 28  | GPSET0   | GPIO Pin Output Set 0    |  0 - 31
8  | Base + 32  | GPSET1   | GPIO Pin Output Set 1    | 32 - 53
9  | Base + 36  | Reserved | Reserved                 |
10 | Base + 40  | GPCLR0   | GPIO Pin Output Clear 0  |  0 - 31
11 | Base + 44  | GPCLR1   | GPIO Pin Output Clear 1  | 32 - 53
12 | Base + 48  | Reserved | Reserved                 |
13 | Base + 52  | GPLEV0   | GPIO Pin Level 0         |  0 - 31
14 | Base + 56  | GPLEV1   | GPIO Pin Level 1         | 32 - 53

##### Initializing Pin 17
Initializing a pin means setting it to input and then output. You can later set it to another mode. In order to do that we must use the **GPFSELn** registers. Let's take a look at register GPFSEL1. This register takes care of pins 10 - 19.

![GPFSEL1](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPFSEL1.png?raw=true)

Each pin is assigned three bits within the register. Since we are given 3 bits, there are 8 (2^3 = 8) possible combinations we could fit in there. For now we are only going to cover two (input / output) of these combinations. The other ones are for alternate functions.

To set a pin to **input mode** we must set the corresponding three bits to `000`. To set a pin to **output mode** we must set the corresponding three bits to `001`. Needless to say, we must preserve other bits when we set these patterns so that we do not overwrite other pin modes.

Let's say we want to set GPIO pin 17 as input. To do so, we would need to place `000` in bits 23, 22, and 21 of register GPFSEL1. Now we need to set GPIO pin to output mode. To do so, we need to place `001` in bits 23, 22, and 21 of register GPFSEL1. The C++ example below illustrates how to do this. If you wish you can run it and see the output. We will be doing the real thing in Assembly later on.

```c++
#include <iostream>
#include <bitset>

using namespace std;

int main(){
    // Simulate the state of GPFSEL1 with a random number.
    unsigned int gpfsel1 = 1006515180;
    bitset<32> bitset1{gpfsel1};
    cout << "Before setting to input: " << bitset1 << endl;

    gpfsel1 &= ~(7 << 21);    
    bitset<32> bitset2{gpfsel1};
    cout << "After setting to input:  " << bitset2 << endl;

    gpfsel1 |= (1 << 21);
    bitset<32> bitset3{gpfsel1};
    cout << "After setting to output: " << bitset3 << endl;

    return 0;
}

```

Now that we have done this, the pin is ready to be set to any mode we wish.

##### Setting Pin 17 to Output Mode
The next step to replicate our Python program is to set GPIO pin 17 to output mode. From the section above, we already know how to accomplish this. Once again, we need to place `001` in bits 23, 22, and 21 of register GPFSEL1 to set pin 17 to output mode.

##### Setting Pin 17's output to HIGH or LOW
The registers associated with driving the output to **HIGH** are the **GPSETn** registers. The **GPCLRn** registers, on the other hand, drive the output to **LOW**. Let's take a look at register GPSET0. This register takes care of pins 0 - 31.

![GPSET0](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPSET0.png?raw=true)

Each pin is represented by a bit within the register. So for pin 17 we would use bit 17. Placing a 1 on GPSET0's bit 17 will drive pin 17's output to HIGH (if the pin was set to output mode) and will turn on the LED attached to it.

Let's take a look at register GPCLR0. This register takes care of pins 0 - 31.

![GPCLR0](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPCLR0.png?raw=true)

Each pin is represented by a bit within the register. So for pin 17 we would use bit 17. Placing a 1 on GPCLR0's bit 17 will drive pin 17's output to LOW and will turn off the LED attached to it.

It seems odd that two registers control whether a pin is HIGH or LOW. However, the GPIO controller remembers which was the last operation you did. If you set the pin LOW and then HIGH, the last operation will be the one that takes effect.

The final step to replicate our Python program is to set pin 17's output to HIGH.

##### Before stepping into the real thing.
Before we write the program in assembly we need to learn how to use the **open**, **close**, and **mmap** libc functions since we will be calling them from our program. Remember the function calling rules!

In this section you will find portions of the GNU Libc documentation that explain how to use the mentioned functions.

###### Open
Let's see the function prototype for the `open` function.

```c
int open (const char *filename, int flags[, mode_t mode])
```

> The `open` function creates and returns a new **file descriptor** for the file named by filename. Initially, the file position indicator for the file is at the beginning of the file. The argument mode is used only when a file is created, but it doesn’t hurt to supply the argument in any case. The flags argument controls how the file is to be opened. This is a bit mask; you create the value by the bitwise OR of the appropriate parameters.

[For more information visit the GNU manual.](http://www.gnu.org/software/libc/manual/html_node/Opening-and-Closing-Files.html)

###### Close
Let's see the function prototype for the `close` function.

```c
int close (int filedes)
```

The `close` function closes the file descriptor provided.

[For more information visit the GNU manual.](http://www.gnu.org/software/libc/manual/html_node/Opening-and-Closing-Files.html)

###### Mmap
Let's see the function prototype for the `mmap` function.

```c
void * mmap (void *address, size_t length, int protect, int flags, int filedes, off_t offset)
```

> On modern operating systems, it is possible to `mmap` (pronounced “em-map”) a file to a region of memory. When this is done, the file can be accessed just like an array in the program.

> This is more efficient than read or write, as only the regions of the file that a program actually accesses are loaded. Accesses to not-yet-loaded parts of the mmapped region are handled in the same way as swapped out pages.

> The mmap function creates a new mapping, connected to bytes (offset) to (offset + length - 1) in the file open on filedes. A new reference for the file specified by filedes is created, which is not removed by closing the file.

[For more information visit the GNU manual.](http://www.gnu.org/software/libc/manual/html_node/Memory_002dmapped-I_002fO.html)

##### The Real Thing
So now we are ready to start coding in Assembly. Inspect the code and see how each section has been separated by labels in order to achieve the same results we had in Python. If you run the example make sure to do it as a super user.

```gas
@ File: pin17on.s
@ Turns on led in pin 17.

	.global main
	.func main

main:
	SUB	SP, SP, #16				@ Reserve 16 bytes storage

openFile:
	LDR	R0, .filedir			@ Get /dev/mem file address
	LDR	R1, .flags				@ Set flags for file permissions
	BL	open							@ Call open function, R0 will have file descriptor

map:
	STR	R0, [SP, #12]			@ Save file descriptor on stack
	LDR	R3, [SP, #12]			@ R3 gets a copy of the file descriptor
	STR	R3, [sp, #0]			@ Store the file descriptor at the top of the stack (SP + 0)
	LDR	R3, .gpiobase			@ Get gpio base address in R3
	STR	R3, [sp, #4]			@ Store the gpio base address in the stack (SP + 4)

	@ Parameters for mmap function, the 4 below and the file descriptor and gpio
	@ base address in the stack. This lets the kernel choose the vmem address,
	@ sets the page size, desired memory protection.
	MOV	R0, #0
	MOV	R1, #4096
	MOV	R2, #3
	MOV	R3, #1
	BL	mmap							@ R0 now has the vmem address.

clear:
	STR	R0, [SP, #16]			@ Store vmem address in stack
	LDR	R3, [SP, #16]			@ Make a copy of vmem address in R3
	ADD	R3, R3, #4				@ Add 4 bytes to R3 to get address of GPFSEL1
	LDR	R2, [SP, #16]			@ Make a copy of vmem address in R2.
	ADD	R2, R2, #4				@ Add 4 bytes to R2 to get address of GPFSEL1
	LDR	R2, [R2, #0]			@ Make a copy of GPFSEL1 in R2
	BIC	R2, R2, #0b111<<21	@ Bitwise clear of bits 23, 22, 21
	STR	R2, [R3, #0]			@ Store result in address specified by R3 (GPFSEL1)

set:
	LDR	R3, [SP, #16]			@ Make a copy of vmem address in R3
	ADD	R3, R3, #4				@ Add 4 bytes to R3 to get address of GPFSEL1
	LDR	R2, [SP, #16]			@ Make a copy of vmem address in R2
	ADD	R2, R2, #4				@ Add 4 bytes to R2 to get address of GPFSEL1
	LDR	R2, [R2, #0]			@ Make a copy of GPFSEL1 in R2
	ORR	R2, R2, #1<<21		@ Bitwise set of bit 21
	STR	R2, [R3, #0]			@ Store result in address specified by R3 (GPFSEL1)

turnOn:
	LDR	R3, [SP, #16]			@ Make a copy of vmem address in R3
	ADD	R3, R3, #28				@ Add 28 bytes to R3 to get address of GPFSET0
	MOV	R4, #1						@ Move a 1 to register R4 to prepare for shifting.
	MOV	R2, R4, LSL#17		@ Shift 1 to bit 17 to turn on pin 17
	STR	R2, [R3, #0]			@ Store result in address specified by R3 (GPFSET0)

exit:
	LDR	R0, [SP, #12]			@ Get file descriptor in R0
	BL	close							@ Close the file
	ADD	SP, SP, #16				@ Restore the stack
	MOV R7, #1						@ System call 1, exit
	SWI 0									@ Perform system call


.filedir:		.word	.file
.flags:			.word	1576962
.gpiobase:	.word	0x3F200000

.data
.file: .asciz "/dev/mem"

```

##### Graphical Representation of Registers
In this section you will find a graphical representation of the GPIO registers that are relevant to what we just covered.

![GPFSEL0](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPFSEL0.png?raw=true)

![GPFSEL1](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPFSEL1.png?raw=true)

![GPFSEL2](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPFSEL2.png?raw=true)

![GPFSEL3](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPFSEL3.png?raw=true)

![GPFSEL4](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPFSEL4.png?raw=true)

![GPFSEL5](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPFSEL5.png?raw=true)

![GPSET0](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPSET0.png?raw=true)

![GPSET1](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPSET1.png?raw=true)

![GPCLR0](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPCLR0.png?raw=true)

![GPCLR1](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Lab-4/GPCLR1.png?raw=true)
---

#### On your own

Now that you are more familiar with ARM you are able to write simple programs on your own. This week you will have three programs to write. Make sure to include plenty of proper comments.

##### Program #1: lab4a.s
You will be writing a file to turn off pin 17.
Save this program as **lab4a.s**.

##### Program #2: lab4b.s
You will be writing a file to turn on pin 22.
Save this program as **lab4b.s**.

##### Program #3: lab4c.s
You will be writing a file to turn off pin 22.
Save this program as **lab4c.s**.

----

#### Review Questions
The following review questions must be answered in your lab report. It is expected that you go further than what was explained in this manual to answer the questions. Make sure you pay special attention to questions regarding the ARM instruction set since future lab material will assume you know what was taught in this manual.

1. Briefly describe the GPIO controller and its registers.

2. What steps are required to set a pin to output in ARM assembly?

3. What does the function mmap do?
