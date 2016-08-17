## Computer Architecture
### Introduction to Branch Prediction

When we introduced the classical five-stage pipeline we talked about dependencies and hazards that may affect the processor's CPI. We also mentioned it was ideal to keep a CPI of 1 (or finish an instruction every cycle).

Before talking about branch prediction let's recap what we learned about control hazards. Let's bring our old example back.

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

This program starts running at `section1` and then finds a branch instruction `BNE`. The instructions following the `BNE` are control dependent on the branch instruction since until we evaluate the branch we don't know if we are executing those or the instructions of `section2`. Since we don't know, the pipeline starts filling itself with the instructions that immediately follow the `BNE` instruction and at some point it looks like this:

CC | Fetch       | Decode      | Execute    | Memory     | Write Back
------------|-------------|-------------|------------|------------|--------------
1           | ADDS | Empty       | Empty      | Empty      | Empty
2           | SUBS | ADDS | Empty      | Empty      | Empty
3           | **BNE** | SUBS  | ADDS | Empty      | Empty
4           | XOR | **BNE**  | SUBS | ADDS | Empty
5           | MUL  | XOR | **BNE** | SUBS | ADDS

If we did not figure out that we were taking the branch in the third stage of our pipeline, then that means cycles 4 and 5 were wasted because they filled the pipeline with instructions that are not supposed to be executed. In our pipeline model, each branch outcome that we didn't predict causes us to lose two clock cycles (and the `BNE` instruction itself adds an extra one like any other instruction). We now have to **flush** the instructions that were wrongly fetched and continue fetching from the right location, in this case, `section2`. It will look something like this:

CC | Fetch       | Decode      | Execute    | Memory     | Write Back
------------|-------------|-------------|------------|------------|--------------
1           | ADDS | Empty       | Empty      | Empty      | Empty
2           | SUBS | ADDS | Empty      | Empty      | Empty
3           | BNE | SUBS  | ADDS | Empty      | Empty
4           | XOR | BNE  | SUBS | ADDS | Empty
5           | MUL  | XOR | BNE | SUBS | ADDS
6           | ADDS | **Empty**  | **Empty** | BNE | SUBS
7           | SUBS | ADDS  | **Empty** | **Empty** | BNE

The pipeline flushes and not being able to predict if the branch will be taken or not will increase the CPI. In this case, our pipeline assumes that the branches are not taken (reason why it fetched the `XOR` and `MUL` instructions instead of the `ADDS` and `SUBS`). We can say that our processor's branch prediction scheme is **Predict Branch Not Taken**. If we consider that 20% of all instructions are branches and 60% of those branches are always taken then our CPI becomes:

![cpi](http://mathurl.com/jf3e59a.png)

Knowing that 60% of the branches are always taken we could design a processor whose branch prediction scheme is **Predict Branch Taken**. Then, for the same set of instructions, our pipeline would look like this:

CC | Fetch       | Decode      | Execute    | Memory     | Write Back
------------|-------------|-------------|------------|------------|--------------
1           | ADDS | Empty       | Empty      | Empty      | Empty
2           | SUBS | ADDS | Empty      | Empty      | Empty
3           | BNE | SUBS  | ADDS | Empty      | Empty
4           | **ADDS** | BNE  | SUBS | ADDS | Empty
5           | **SUBS**  | **ADDS** | BNE | SUBS | ADDS

And you can also expect our CPI to be better than the one for **Predict Branch Not Taken**. See for yourself below.

![cpi2](http://mathurl.com/zxxw7c6.png)

The key, therefore, lies in reducing branch instructions as much as possible and increasing the odds of predicting whether a branch is taken or not. As you would expect, this is called **branch prediction** and helps avoid pipeline flushes. Remember that our simple processor pipeline has five-stages, other processors such as the Intel Pentium 4 have 20 stages. In that case, the penalty for a wrong prediction increases tremendously.

In order to show you let's assume we have a *Slowtium* 20-stage pipeline processor in which branches are figured out on the 11th stage. It uses a **Predict Branch Taken** scheme. As before, 20% of all instructions are branches and 60% of those are always taken. Our CPI for this processor becomes:

![cpi3](http://mathurl.com/z96ycq3.png)

The CPI took a tremendous hit in this deep pipeline. As you can see, the deeper the pipeline the more important branch prediction becomes.

#### Improving the Prediction
We need to improve our prediction schemes if we want to design better performing processors. So far our branch prediction techniques have only relied on current information i.e. whats happening at that moment in the processor. We could probably try to see what branches were taken in the past to make a better guess at what to do when we encounter a branch. These new type of predictors will use **history** to make a more informed prediction.

Before talking about these schemes let's add some hardware that keeps track of this history.

![branch1](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Extra-Readings/Branch-Prediction/branch1.png?raw=true)

We've added a **Branch Target Predictor** (also called **Branch Target Buffer**) which is basically a table that holds the last predicted program counter for a branch. Remember that each instruction has an address and that the **Program Counter** points to this address. So when the processor fetches a new instruction it uses a portion of that address as an index to the **Branch Target Predictor**. This index allows you to get a new address that is the new *predicted address*. When the instruction reaches the **Execute** stage you'll know if the prediction was right. If it was, then the entry at the table doesn't change. If it was wrong, then it updates the entry (and of course it flushes the pipeline to get the right instructions). Each entry in the **Branch Target Predictor** should contain an address. So if you have a 64-bit processor, then each entry takes up 8 bytes of space. Since when you fetch the instruction you don't know which instruction is a branch instruction you should ideally have a **Branch Target Predictor** entry for each instruction. This can turn costly since programs have a lot of instructions.

We want to keep a reasonable number of entries in the **Branch Target Predictor** table. If it is possible we would like entries for branch instructions only. We can modify the hardware to accommodate for this.

![branch2](https://github.com/xaviermerino/ECE4551-Computer-Architecture/blob/master/Extra-Readings/Branch-Prediction/branch2.png?raw=true)

We have modified the hardware to include the **Branch History Table**. With this new table we can keep the **Branch Target Predictor** table short since the effect of this change is that this target predictor table will only keep entries for branch instructions. The entries at the **Branch History Table** can be smaller in size, let's say 1 bit, and so you can have several of them indexed by a portion of the current program counter. So when you get a not taken branch, or simply a non-branch instruction, we just increment the PC to get the next immediate instruction. If it is a taken branch, then we get the new predicted address from the **Branch Target Predictor** as the program counter.  

*Give an assembly example and walk through it*
