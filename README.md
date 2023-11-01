The directory `week8` contains the code that implments the basic language presented in the class lectures.

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
