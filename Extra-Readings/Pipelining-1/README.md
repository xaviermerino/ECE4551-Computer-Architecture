## Computer Architecture
### Introduction to Pipelining

Before going deep into a processor pipeline let’s consider a simple example. Suppose we have an 8000 gallon pool we need to fill with water. So we decide to take a 1-gallon bucket and fill it with water at the nearest water plant. We then go to the pool and dump the water there. It takes us 1 hour to travel from the water facility to the pool. You can already imagine the amount of time this would take. This is not very efficient.

Instead we come up with the bright idea of building a water pumping system for the pool. The pump will take water from the water facility and put it into the pool. It still takes 1 hour for the water to get there but afterwards, the pipe is full and the water gallons keep flowing into the pool.

Let’s translate this analogy to processors. We have been talking about ARM processors lately. So let’s consider a very basic three-stage pipeline. The stages are: **Fetch**, **Decode**, and **Execute**. You can see a processor with those three stages below.

![cpu](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Extra-Readings/Pipelining-1/pipe1.png?raw=true)

Pipelining is a technique where multiple instructions are overlapped. The stages that need to be performed to execute an instruction can run in parallel. Without pipelining we would have to wait for an instruction to go through the 3-stages before a new instruction could be issued. With pipelining, as soon as the first instruction went into decode stage, a new instruction can go into the fetch state and so on.

##### Using pipelining techniques


Clock Cycle | Fetch            | Decode           | Execute
------------|------------------|------------------|------------------
1           | Instruction **1**  | Empty     | Empty
2           | Instruction **2**  | Instruction **1**  | Empty
3           | Instruction **3**  | Instruction **2**  | Instruction **1**   
4           | Instruction **4**  | Instruction **3**  | Instruction **2**


The first instruction is fetched from the instruction memory (remember: the **program counter** points to this). The functional unit dedicated to fetching instructions fetches another one while the previous instruction goes to decoding stage. This decoding stage involves recognizing the type of instruction and might involve reading from registers and issuing actions. When that instruction is ready it is passed to the execute stage and a new one goes into decoding. The execute stage carries out the instruction. Each instruction takes 90 ns **(latency)** to be go through all of this pipeline but after the pipeline is full our **throughput** is 1 / 30 ns (or an instruction will exit the pipeline every 30 ns).

##### Not using pipelining techniques

Clock Cycle | Fetch            | Decode           | Execute
------------|------------------|------------------|------------------
1           | Instruction **1**  | Empty     | Empty
2           | Empty  | Instruction **1**  | Empty
3           | Empty | Empty | Instruction **1**   
4           | Instruction **2**  | Empty  | Empty

Each instruction still takes 90 ns to go through all of the steps but the throughput is 1 / 90 ns (or an instruction will exit the pipeline every 90 ns).

### Pipeline Issues

Ideally, with pipelining, we want to the cycles per instruction (CPI) to be one. Initially, of course, we can’t, since the pipeline has to get filled first.  But after the pipeline is full we should have a CPI of 1 (or finish one instruction every cycle). Shouldn’t we? Well not really. Sometimes we have trouble in the pipeline and it stalls.

Let’s consider an assembly line as an example. Let’s pretend we are making a happy face pillow. I present you with the finished product right below.

![happyface](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Extra-Readings/Pipelining-1/happyface.png?raw=true)

Alright so the first step in making this happy face pillow is to obtain the pillow stuffing and make the yellow area first. The second step is to give it a left eye. The third is to give it a right eye. The final step is to give the pillow a mouth.

![stalls](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Extra-Readings/Pipelining-1/pipe2.png?raw=true)

In the example above, we ran out of right eyes. The pipeline stalls until we get more right eyes and Step 3 has to be repeated. If these stalls happen a lot, then we increase our cycles per pillow (meaning we don’t finish a pillow every cycle). This is a perfect analogy to what happens inside a processor when the pipeline stalls, this is, the cycles per instruction (CPI) increases.

There are several reasons why the processor pipeline can stall. Before we cover some of these reasons let's add more stages to the processor pipeline.

![five-stage](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Extra-Readings/Pipelining-1/pipe3.png?raw=true)

We now have the classic five-stage pipeline. We have added two stages: **Memory** for memory access and **Write Back** to save results. Let's explain this a little bit more. We fetch an instruction from the instruction memory, we decode that instruction and read the registers that will be used by the ALU to execute the instruction. We then save the result to a memory address or simply write back to the registers.

Clock Cycle | Fetch       | Decode      | Execute    | Memory     | Write Back
------------|-------------|-------------|------------|------------|--------------
1           | Ins. **1**  | Empty       | Empty      | Empty      | Empty
2           | Ins. **2**  | Ins. **1**  | Empty      | Empty      | Empty
3           | Ins. **3**  | Ins. **2**  | Ins. **1** | Empty      | Empty
4           | Ins. **4**  | Ins. **3**  | Ins. **2** | Ins. **1** | Empty
5           | Ins. **5**  | Ins. **4**  | Ins. **3** | Ins. **2** | Ins. **1**
6           | Ins. **6**  | Ins. **5**  | Ins. **4** | Ins. **3** | Ins. **2**


#### Dependencies
We will now cover control and data dependencies and we'll use the five-stage pipeline as a reference.

##### Control Dependencies
Let's consider the following assembly program.

```gas
section1:
  ADDS R1, R2, R3
  SUBS R4, R5, R6
  BNE section2
  XOR R7, R8, R9
  MUL R9, R1, R2
  ...

section2:
  ADDS R1, R2, R3
  SUBS R4, R5, R6
  ...
```

This program starts running at `section1` and then finds a branch instruction `BNE`. The instructions following the `BNE` are control dependent on the branch instruction since until we evaluate the branch we don't know if we are executing those or the instructions of `section2`. Since we don't know, the pipeline starts filling itself with all these instructions and at some point it looks like this:

CC | Fetch       | Decode      | Execute    | Memory     | Write Back
------------|-------------|-------------|------------|------------|--------------
1           | ADDS | Empty       | Empty      | Empty      | Empty
2           | SUBS | ADDS | Empty      | Empty      | Empty
3           | **BNE** | SUBS  | ADDS | Empty      | Empty
4           | XOR | **BNE**  | SUBS | ADDS | Empty
5           | MUL  | XOR | **BNE** | SUBS | ADDS

If we did not figure out that we were taking the branch in the third stage of our pipeline, then that means cycles 4 and 5 were wasted because they filled the pipeline with instructions that are not supposed to be executed. In our pipeline model, each branch outcome that we didn't predict causes us to lose two clock cycles. We now have to **flush** the instructions that were wrongly fetched and continue fetching from the right location, in this case, `section2`. It will look something like this:

CC | Fetch       | Decode      | Execute    | Memory     | Write Back
------------|-------------|-------------|------------|------------|--------------
1           | ADDS | Empty       | Empty      | Empty      | Empty
2           | SUBS | ADDS | Empty      | Empty      | Empty
3           | BNE | SUBS  | ADDS | Empty      | Empty
4           | XOR | BNE  | SUBS | ADDS | Empty
5           | MUL  | XOR | BNE | SUBS | ADDS
6           | ADDS | **Empty**  | **Empty** | BNE | SUBS
7           | SUBS | ADDS  | **Empty** | **Empty** | BNE

The pipeline flushes and not being able to predict if the branch will be taken or not will increase the CPI. The key, therefore, lies in reducing branch instructions as much as possible and increasing the odds of predicting whether a branch is taken or not. As you would expect, this is called **branch prediction** and helps avoid pipeline flushes. Remember that our simple processor pipeline has five-stages, other processors such as the Intel Pentium 4 use very deep pipelines with more than 80 stages. In that case, the penalty for a wrong prediction increases tremendously.

##### Data Dependencies
There are more cases in which a pipeline can stall. In this section we will look at how data can cause this.

We will cover:
* **RAW** (Read-after-Write) Dependencies
* **WAW** (Write-after-Write) Dependencies
* **WAR** (Write-after-Read) Dependencies

###### RAW Dependencies
Let's consider the following assembly program.

```gas
section1:
  ADDS R1, R2, R3
  SUBS R4, R1, R5
  ...

```

Let's assume that before the instructions execute we have `R1 = 9`, `R2 = 2`, `R3 = 3`, and `R5 = 4`. If you run the program in your head you will probably tell me that after the second instruction finishes `R4 = 1`.

Let's put this program on a table like we have done before. It will look like this:

CC | Fetch       | Decode      | Execute    | Memory     | Write Back
------------|-------------|-------------|------------|------------|--------------
1           | ADDS | Empty       | Empty      | Empty      | Empty
2           | **SUBS** | ADDS | Empty      | Empty      | Empty
3           | ... | **SUBS** | ADDS      | Empty      | Empty
4           | ... | ... | **SUBS**      | ADDS      | Empty
5           | ... | ... | ...      | **SUBS**      | ADDS

If we were to do that, then the `SUBS` instruction would read `R1 = 9` and the result would be `R4 = 4`. This is because by the time the `SUBS` is in decode stage to read the registers, the `ADDS` instruction has not written the result back into `R1` (that happens in the fifth stage). In order to solve this **RAW** dependency (called like this because we must read after the value has been written) we must stall the pipeline by doing something like this:

CC | Fetch       | Decode      | Execute    | Memory     | Write Back
------------|-------------|-------------|------------|------------|--------------
1           | ADDS | Empty       | Empty      | Empty      | Empty
2           | **SUBS** | ADDS | Empty      | Empty      | Empty
3           | **SUBS**  | Empty | ADDS      | Empty      | Empty
4           | **SUBS** | Empty | Empty      | ADDS      | Empty
5           | **SUBS** | Empty | Empty      | Empty     | ADDS
6           | ... |  **SUBS** | Empty      | Empty     | Empty

This doesn't look very good though. Which is why we have an alternate method called **register forwarding**. We will be covering that later on.

###### WAW Dependencies
Let's consider the following assembly program.

```gas
section1:
  MUL R1, R2, R3
  SUB R4, R1, R5
  ADD R1, R6, R7
  ...

```

Let's assume that before the instructions execute we have `R1 = 9`, `R2 = 2`, `R3 = 3`, `R6 = 5`, and `R7 = 5`. If you run the program in your head you will probably tell me that after the third instruction finished `R1 = 10`. That is because when you executed this program you assumed that the first instruction `MUL` finished first (updating to `R1 = 6`) and then the third instruction `ADD` finished last (making `R1 = 10`). But the processor might take more time (in clock cycles) to perform a `MUL` instruction than an `ADD` instruction and in that case we have to ensure that the flow of the program is correct and this means that after the third instruction, `R1 = 10`. This dependency is called **Write-After-Write** because we have to preserve the writing order of the program to get a correct output. 

###### WAR Dependencies
Let's consider the following assembly program.

```gas
section1:
  MUL R1, R2, R3
  SUB R4, R1, R5
  ADD R1, R6, R7
  ...

```

Let's assume that before the instructions execute we have `R1 = 9`, `R2 = 2`, `R3 = 3`, `R5 = 5`, `R6 = 6` and `R7 = 5`. If you run the program in your head you will probably tell me that after the third instruction finished `R1 = 13`. That is because when you executed this program the first instruction `MUL` updated `R1 = 6`. And in your execution, the `SUB` instruction read that `R1 = 6` and `R5 = 5` so it produced `R4 = 1`. Lastly, the third instruction `ADD` made `R1 = 13`. You executed this correctly. But what if the `ADD` instruction takes less clock cycles to be executed? In that case the `SUB` instruction would have read `R1 = 13` instead of `R1 = 6`. We need to ensure that the `SUB` instruction has finished reading `R1` before the `ADD` instruction can write to it. This is why this type of dependency is labeled **Write-After-Read**. 

##### Structural Hazards
As mentioned before, pipelining is made possible because different functional units take care of different portions of an instruction. Structural hazards are a hardware problem. It basically means the hardware can't support the overlapped execution of all those instructions simultaneously because it doesn't have the resources to do it. Some manufacturers might choose to drop a specialized functional unit in order to have a more competitive price and in doing so they introduce a structural hazard. In order to solve it, the pipeline stalls and speed is sacrificed but the hazard will get resolved in the end.

##### Data hazards
