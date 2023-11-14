# Building A Programming Language

The directory `week8` contains the code that implements the basic language presented in the class lectures.

# Goals

My central goal in this course was to understand the different components that are involved in parsing, compiling and interpreting a programming language.  Designing my own language was not my main goal.  I wanted to be a more intelligent user of the languages I use, and I wanted to be able to create and use tools that analyze and manipulate programs.

# Implementation Experiments

A few times, I considered whether or not I would use the facilities of lua in the VM implementation.  In particular, in implementing multi-dimensional new.  I would like to see if I can generate code for a different VM at some point, so I decided to essentially implement a loop in the machine language of the VM, with the addition of a primitive stolen from FORTH (2dup).  Writing code in the VM primitives was quite fun.

In order to reduce the risk of dumb errors in manipulating the top-of-stack variable, I decided to implement the VM stack in an "object-oriented" manner.  In some cases it may have sacrificed some efficiency but on the whole made the implementation much cleaner.

# Self-Evaluation

## Rubric

### Language Completion

I'd give myself a (1) Needs Improvement here.  I did not go much beyond the base language

### Code Quality and Report

I think my code is well organized, though error messages could definitely be better.  I'd give myself a (2) Meets Expectations

### Originality and Scope

I'd give myself a (2) Meets expectations, largely because of how I handled multi-dimensional arrays

## Personal Notes

- I enjoyed implementing the language and trying to make the code clean.  Each week I tried to get as much work done in the weekend following the live session in order to improve the odds of staying on track.  I would watch the recorded lectures and then try to anticipate the implementation once the general idea was outlined.  I find I learn more when things break and I have to work through fixing them, as opposed to having full solutions laid out for me

- As far as I can remember I managed to add all of the features that were suggested in the exercises :)

- However, I wish I had buttressed the code with more tests.  In the last week, I discovered a few errors in short-circuit logical evaluation that I had missed (but which did give me the opportunity to make that code better).  A test suite *may* have helped pick up some things more quickly when I had left them for a little while

- At one point I feel I lost a sense of how I was manipulating (well, adding to and then compiling) the AST.  It might have made it easier to implement the array initialization I had hoped to add

# In An Ideal World...

## Initializer Lists for Arrays

I wanted to implement multi-dimensional array initialization, such as 
```
a = { {1,2}, {3,4} }
```
My general approach was to try to "insert" into the AST where the result of this parse would have occurred with the AST corresponding to
```
a = new [2][2]
a[1][1] = 1
a[1][2] = 2
a[2][1] = 3
a[2][2] = 4
```
However, I was not able to figure out how to do that in the time I had left.

I think if I had implemented multi-dimensional arrays differently, by leaving the work to the VM and relying on lua there it may have made attempting the
initializer list easier. 

## Local arrays and array parameters

Since the arrays are always allocated in the global store, I think the best I could hope for is a local reference to an array in the global store.  But, it would certainly be interesting to be able to be able to add, say, functions that could perform matrix arithmetic using arrays to represent matrices.

## Closures

I would need to do more research on this.  I make heavy use of closures in other languages that I use that support this.  The lecture given on this area was a good introduction, but I'd not feel confident using just that to start.  I'm still waiting for the references :).

## Tail Call Optimization

I think it should be feasible to detect in the AST whether a call is in the tail position with what we have in place, and thus manipulate the stack such that any provided arguments and local variables are cleaned up prior to the tail call.  

## Macros (LISP-like, not C pre-processor-like)

This would have been something like a holy grail for me (other that some sort of type system) - an AST to AST transformation.  It would have enabled something like the initializer lists to be implemented as a macro.  I'd have to figure out how to splice statements in to statement lists.  For example, suppose we have 

```
{ s1 = <statement1>, s2 = <subsequent statements> } 
```

and <statement1> is then processed by a macro to produce its own statement list 

```
{ s1 = <statement1a>, {s2 = { s1 = <statement 1b>, s2 = { s1 = <statement1c>} } } }
```  

I'd have to add code to insert this properly back into the original AST.

```
{ s1 = <statement1a>, {s2 = { s1 = <statement 1b>, s2 = { s1 = <statement1c>, s2 = <subsequent statements} } } }
```

