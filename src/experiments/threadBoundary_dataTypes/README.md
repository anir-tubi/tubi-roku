Lessons learned:

- Performing operations on large(ish) amount of data works a little bit faster in the render thread than in a task thread.
- The amount of time needed to move information across the thread boundary from a task thread to the render thread can vary greatly depending on the format of the information
- Moving content nodes across the thread boundary is much, much faster than moving an associative array of the same data
- Any functionality that is not triggered by the function designated by the task's "functionName" field has a different context than that function. In other words, it seems that the "functionName" function operates in a separate task thread, while any other functions (if not called by the "functionName" function) will operate directly in the render thread.
- Because of the fact above, when creating new task nodes, it is best to use the msgPort version of observeField, and listen for field updates in the "functionName" function, instead of using the callback version of observeField.

Some Numbers:

(Model 3700X)

- Moving a json string (representing the matrix home screen response for 100 contents per category) across the task thread boundary took <b>2118ms</b>
- Moving an associative array of the same information (after parsing the json) across the task thread boundary took <b>484ms</b>
- Moving a formatted ContentNode tree of all the categories and their contents across the task thread boundary took <b>128ms</b>
- Parsing the matrix/homescreen json response in the render thread took <b>329ms</b>
- Parsing the matrix/homescreen json response in the task thread took <b>374ms</b>

(Model 3050X)

- Moving a json string (representing the matrix home screen response for 100 contents per category) across the task thread boundary took <b>4850ms</b>
- Moving an associative array of the same information (after parsing the json) across the task thread boundary took <b>1909ms</b>
- Moving a formatted ContentNode tree of all the categories and their contents across the task thread boundary took <b>361ms</b>
- Parsing the matrix/homescreen json response in the render thread took <b>393ms</b>
- Parsing the matrix/homescreen json response in the task thread took <b>1333ms</b>