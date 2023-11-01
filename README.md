# Building A Programming Lanuage

The directory `week8` contains the code that implments the basic language presented in the class lectures.

# Goals

My central goal in this course was to understand the different components that are involved in parsing, compiling and interpreting a programming language.  Designing my own language was not my main goal.  I wanted to be a more intelligent user of the languages I use, and I wanted to be able to create and use tools that analyze and manipulate programs.

# Implementation Experiments

A few times, I considered whether or not I would use the facilities of lua in the VM implementation.  In particular, in implemeting multi-dimentional new.  I would like to see if I can generate code for a different VM at some point, so I decided to essentially implement a loop in the machine language of the VM, with the addition of a primitive stolen from FORTH (2dup).  Writing code in the VM primitives was quite fun.

In order to reduce the risk of dumb errors in manipulating the top-of-stack variable, I decided to implement the VM stack in an "object-oriented" manner.  In some cases it may have sacrificed some efficiency but on the whole made the implementation much cleaner.

# In An Ideal World...

## Closures

## Tail Call Optimization

## Macros (LISP-like, not C pre-processor-like)

AST->AST transformations

## Inializer Lists for Arrays

I wanted to implment multi-dimentional array initializtion, such as 
```
a = { {1,2}, {3,4} }
```
My general approach was to try to "insert" into the AST where te result of this parse would have occurred with the AST corresponding to
```
a = new [2][2]
a[1][1] = 1
a[1][2] = 2
a[2][1] = 3
a[2][2] = 4
```
However, I was not able to figure out how to do that in the time I had left.

I think if I had implemented multi-dimentional arrays differently, by leaving the work to the VM and relying on lua there it may have made attempting the
initializer list easier. 
