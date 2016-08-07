## Computer Architecture
### Introduction to Pipelining

Let’s consider a simple example. Suppose we have an 8000 gallon pool we need to fill with water. So we decide to take a 1-gallon bucket and fill it with water at the nearest water plant. We then go to the pool and dump the water there. It takes us 1 hour to travel from the water facility to the pool. You can already imagine the amount of time this would take. This is not very efficient. 

Instead we come up with the bright idea of building a water pumping system for the pool. The pump will take water from the water facility and put it into the pool. It still takes 1 hour **(latency)** for the water to get there but afterwards, the pipe is full and the water gallons keep flowing into the pool. 

Let’s translate this analogy to processors. We have been talking about ARM processors lately. So let’s consider a very basic three-stage pipeline. The stages are: **Fetch**, **Decode**, and **Execute**. You can see a processor with those three stages below. 

![cpu](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Extra-Readings/Pipelining-1/pipe1.png?raw=true)

##### Using pipelining techniques 


Clock Cycle | Fetch            | Decode           | Execute
------------|------------------|------------------|------------------
1           | Instruction **1**  | Empty     | Empty 
2           | Instruction **2**  | Instruction **1**  | Empty
3           | Instruction **3**  | Instruction **2**  | Instruction **1**   
4           | Instruction **4**  | Instruction **3**  | Instruction **2**


The first instruction is fetched from the instruction memory (remember: the **program counter** points to this). The functional unit dedicated to fetching instructions fetches another one while the previous instruction goes to decoding stage. This decoding stage involves recognizing the type of instruction and might involve reading from registers and issuing actions. When that instruction is ready it is passed to the execute stage and a new one goes into decoding. The execute stage carries out the instruction. Each instruction takes 90 ns (latency) to be go through all of this pipeline but after the pipeline is full our throughput is 1 / 30 ns (or an instruction will exit the pipeline every 30 ns).

##### Not using pipelining techniques

Clock Cycle | Fetch            | Decode           | Execute
------------|------------------|------------------|------------------
1           | Instruction **1**  | Empty     | Empty 
2           | Empty  | Instruction **1**  | Empty
3           | Empty | Empty | Instruction **1**   
4           | Instruction **2**  | Empty  | Empty

Each instruction still takes 90 ns to go through all of the steps but the throughput is 1 / 90 ns (or an instruction will exit the pipeline every 90 ns).

Ideally, with pipelining, we want to the cycles per instruction (CPI) to be one. Initially, of course, we can’t since the pipeline has to get filled first.  But after the pipeline is full we should have a CPI of 1 (or finish one instruction every cycle). Shouldn’t we? Well not really. Sometimes we have trouble in the pipeline and it stalls. 

##### Pipeline Stalls

Let’s consider an assembly line as an example. Let’s pretend we are making a happy face pillow. I present you with the finished product right below. 

![happyface](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Extra-Readings/Pipelining-1/happyface.png?raw=true)

Alright so the first step in making this happy face pillow is to obtain the pillow stuffing and make the yellow area first. The second step is to give it a left eye. The third is to give it a right eye. The final step is to give the pillow a mouth. 

![stalls](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Extra-Readings/Pipelining-1/pipe2.png?raw=true)

In the example above, we ran out of right eyes. The pipeline stalls until we get more right eyes and Step 3 has to be repeated. If these stalls happen a lot, then we increase our cycles per pillow (meaning we don’t finish a pillow every cycle). This is a perfect analogy to what happens inside a processor when the pipeline stalls, this is, the cycles per instruction (CPI) increases.
