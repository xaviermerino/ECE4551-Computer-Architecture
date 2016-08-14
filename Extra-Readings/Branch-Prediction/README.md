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

In order to show you let's assume we have a *Slowtium* 20-stage pipeline processor in which branches are figured out on the 11th stage. As before, 20% of all instructions are branches and 60% of those are always taken. Our CPI for this processor becomes:

![cpi3](http://mathurl.com/z96ycq3.png)

The CPI took a tremendous hit in this deep pipeline. As you can see, the deeper the pipeline the more important branch prediction becomes. The key, therefore, lies in reducing branch instructions as much as possible and increasing the odds of predicting whether a branch is taken or not. 
