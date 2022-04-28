# SceneGraph Node as Module
The goal of this experiment is to see the impact of potentially moving from AA based modules/libraries.

basic function = calling a function directly
aa function = calling a method on an AA
node function = calling a function from within a node via callFunc

# Results on 4800X Ultra
Time (in ms) for 50000 basic function calls passing no values, returning invalid 49; ms/call: 0.00098 
Time (in ms) for 50000 aa function calls passing no values, returning invalid 60; ms/call: 0.0012 
Time (in ms) for 50000 node function calls passing no values, returning invalid 1073; ms/call: 0.02146 

Time (in ms) for 50000 basic function calls passing an AA, returning invalid 49; ms/call: 0.00098 
Time (in ms) for 50000 aa function calls passing an AA, returning invalid 65; ms/call: 0.0013 
Time (in ms) for 50000 node function calls passing an AA, returning invalid 4740; ms/call: 0.0948 

Time (in ms) for 50000 basic function calls passing an AA, returning an AA 52; ms/call: 0.00104 
Time (in ms) for 50000 aa function calls passing an AA, returning an AA 69; ms/call: 0.00138 
Time (in ms) for 50000 node function calls passing an AA, returning an AA 8116; ms/call: 0.16232

# Results on 3700X Ultra
Time (in ms) for 50000 basic function calls passing no values, returning invalid 85; ms/call: 0.0017 
Time (in ms) for 50000 aa function calls passing no values, returning invalid 118; ms/call: 0.00236 
Time (in ms) for 50000 node function calls passing no values, returning invalid 5082; ms/call: 0.10164 

Time (in ms) for 50000 basic function calls passing an AA, returning invalid 99; ms/call: 0.00198 
Time (in ms) for 50000 aa function calls passing an AA, returning invalid 127; ms/call: 0.00254 
Time (in ms) for 50000 node function calls passing an AA, returning invalid 18773; ms/call: 0.37546 

Time (in ms) for 50000 basic function calls passing an AA, returning an AA 108; ms/call: 0.00216 
Time (in ms) for 50000 aa function calls passing an AA, returning an AA 136; ms/call: 0.00272 
Time (in ms) for 50000 node function calls passing an AA, returning an AA 27888; ms/call: 0.55776

# Conclusion
Passing an AA as a parameter to a function on an SGNode is significantly slower (roughly 2 orders of magnitude slower), especially on low spec models and even more so when passing information back and forth to the node. When passing and returning a smallish AA, each function call takes over half a millisecond on a 3700X Express. Given the difference in time for function calls between SGNode modules and AA modules, it seems worthwhile to not move to SGNode modules at this time.
