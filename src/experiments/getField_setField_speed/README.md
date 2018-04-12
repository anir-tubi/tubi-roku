Experiment:
Test the speed of the various options for setting and getting values of a single node's fields.A ContentNode was used for this test. The experiment sets 10 values of different types on various ContentNode fields and iterates over the process a various number of times. 

Setting methods tested:

- field dot notation
- node.setField()
- node.setFields()
- node.update()

Getting methods tested:

- field dot notation
- node.getField()
- node.getFields()

Lessons learned:


- When setting content on a single node (as opposed to building a whole node tree), dot notation is fastest, and about 40% faster than the next quickest method, node.setField()
- When setting content on a single node, dot notation is about 60% faster than the slowest method, node.update()
- When getting all the fields of a node, dot notation is the fastest method, and about 28% faster than the next fastest method, node.getFields()
- When getting all the fields of a node, dot notation is about 40% faster than the slowest method, node.getField()
- Overall, setting and getting field values of a ContentNode is fastest when using dot notation.
- <b>*Caveat: In the real dev setting, setting actual content metadata values on CategoryContentNodes and ContentNodes to build the content for the CategoryScreen, node.update() was about 25% faster than using dot notation. On a 3700X, 10 categories took about 484ms to populate metadata into ContentNodes while using node.update; dot notation required about 658ms to populate the same metadata.</b>

Some Numbers:

(Model 3700X)

- Using the dot notation method, it took <b>35ms</b> to add 10 fields to 100 content nodes for a total of 1000 fields set.
- Using the node.setField() method, it took <b>51ms</b> to add 10 fields to 100 content nodes for a total of  1000 fields set.
- Using the node.setFields() method, it took <b>80ms</b> to add 10 fields to 100 content nodes for a total of 1000 fields set.
- Using the node.update() method, it took <b>83ms</b> to add 10 fields to 100 content nodes for a total of 1000 fields set.

- Using the dot notation method, it took <b>168ms</b> to add 10 fields to 500 content nodes for a total of 5000 fields set.
- Using the node.setField() method, it took <b>257ms</b> to add 10 fields to 500 content nodes for a total of 5000 fields set.
- Using the node.setFields() method, it took <b>416ms</b> to add 10 fields to 500 content nodes for a total of 5000 fields set.
- Using the node.update() method, it took <b>410ms</b> to add 10 fields to 500 content nodes for a total of 5000 fields set.


- Using the dot notation method, it took <b>27ms</b> to get 10 field values of a content node 100 times, for a total of 1000 fields gotten.
- Using the node.getField() method, it took <b>43ms</b> to get 10 field values of a content node 100 times, for a total of 1000 fields gotten.
- Using the node.getFields() method, it took <b>40ms</b> to get 10 field values of a content node 100 times, for a total of 1000 fields gotten.

- Using the dot method, it took <b>130ms</b> to get 10 field values of a content node 500 times, for a total of 5000 fields gotten.
- Using the getField() method, it took <b>214ms</b> to get 10 field values of a content node 500 times, for a total of 5000 fields gotten.
- Using the getFields() method, it took <b>195ms</b> to get 10 field values of a content node 500 times, for a total of 5000 fields gotten.

(Model 4400X)

- Using the dot notation method, it took <b>86ms</b> to add 10 fields to 500 content nodes for a total of 5000 fields set.
- Using the node.setField() method, it took <b>138ms</b> to add 10 fields to 500 content nodes for a total of 5000 fields set.
- Using the node.setFields() method, it took <b>179ms</b> to add 10 fields to 500 content nodes for a total of 5000 fields set.
- Using the node.update method, it took <b>195ms</b> to add 10 fields to 500 content nodes for a total of 5000 fields set.

- Using the dot notation method, it took <b>167ms</b> to add 10 fields to 1000 content nodes for a total of 10000 fields set.
- Using the node.setField() method, it took <b>275ms</b> to add 10 fields to 1000 content nodes for a total of 10000 fields set.
- Using the node.setFields() method, it took <b>359ms</b> to add 10 fields to 1000 content nodes for a total of 10000 fields set.
- Using the node.update method, it took <b>390ms</b> to add 10 fields to 1000 content nodes for a total of 10000 fields set.


- Using the dot notation method, it took <b>73ms</b> to get 10 field values of a content node 500 times, for a total of 5000 fields gotten.
- Using the node.getField() method, it took <b>123ms</b> to get 10 field values of a content node 500 times, for a total of 5000 fields gotten.
- Using the node.getFields() method, it took <b>102ms</b> to get 10 field values of a content node 500 times, for a total of 5000 fields gotten.

- Using the dot notation method, it took <b>146ms</b> to get 10 field values of a content node 1000 times, for a total of 10000 fields gotten.
- Using the node.getField() method, it took <b>243ms</b> to get 10 field values of a content node 1000 times, for a total of 10000 fields gotten.
- Using the node.getFields() method, it took 205ms to get 10 field values of a content node 1000 times, for a total of 10000 fields gotten.