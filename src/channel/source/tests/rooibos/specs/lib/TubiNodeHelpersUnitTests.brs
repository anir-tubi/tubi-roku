'@TestSuite [TubiNodeHelpers] TubiNodeHelpers.brs

'@Setup
Function TubiNodeHelpersSetup()
  m.generateNodeTree = tubiNodeHelpersTest_generateNodeTree
End Function


'@BeforeEach
Function tubiNodeHelpers_BeforeEach() as void
  m.parent = CreateObject("roSGNode", "ContentNode")
  m.parent.id = "parent"
  m.NODEHELPERS = TubiNodeHelpers()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiNodeHelpers.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test getChildIndex unit tests
Function tubiNodeHelpers_getChildIndex_test()
  for i=0 to 4
    child = m.parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
    if i = 3
      third = child
    end if
  end for
  fakeChild = CreateObject("roSGNode", "ContentNode")
  childIndex = m.NODEHELPERS.getChildIndex(m.parent, third)
  fakeChildIndex = m.NODEHELPERS.getChildIndex(m.parent, fakeChild)
  m.AssertEqual(childIndex, 3)
  m.AssertEqual(fakeChildIndex, -1)
End Function


'@Test getChildIndexById unit tests
Function tubiNodeHelpers_getChildIndexById_test()
  for i=0 to 4
    child = m.parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
    if i = 3
      idToRemove = child.id
    end if
  end for
  fakeChild = CreateObject("roSGNode", "ContentNode")
  fakeChild.id = "fake"
  childIndex = m.NODEHELPERS.getChildIndexById(m.parent, idToRemove)
  fakeChildIndex = m.NODEHELPERS.getChildIndex(m.parent, "fake")
  m.AssertEqual(childIndex, 3)
  m.AssertEqual(fakeChildIndex, -1)
End Function


'@Test getChildIndicesById unit tests
Function tubiNodeHelpers_getChildIndicesById_test()
  idToRemove = "0"
  dupItems = "0"

  for i=0 to 5
    child = m.parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
    if i = 3
      idToRemove = child.id
    end if
    if i=4
      dupItems = child.id
      child = m.parent.createChild("ContentNode") 'duplicate CHild
      child.id = Mid(Str(i), 2)
    end if

  end for
  fakeChild = CreateObject("roSGNode", "ContentNode")
  fakeChild.id = "fake"
  'single index
  childIndex = m.NODEHELPERS.getChildIndicesById(m.parent, idToRemove)
  m.AssertEqual(childIndex, [3])
  'No index
  fakeChildIndex = m.NODEHELPERS.getChildIndicesById(m.parent, "fake")
  m.AssertEqual(fakeChildIndex, [])
  'duplicate items
  childIndices = m.NODEHELPERS.getChildIndicesById(m.parent, dupItems)
  m.AssertEqual(childIndices, [4,5])
End Function

'@Test getLastChild unit tests
Function tubiNodeHelpers_getLastChild_test()
  parent = CreateObject("roSGNode", "Group")

  ' test if there are no children in the parent
  invalidLastChild = m.nodeHelpers.getLastChild(parent)
  m.AssertInvalid(invalidLastChild)

  ' construct children with ids
  for i=0 to 4
    child = parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
    if i = 4
      fourth = child
    end if
  end for

  ' test if we get the last child
  lastChild = m.nodeHelpers.getLastChild(parent)
  m.AssertNotInvalid(lastChild)
  m.AssertEqual(lastChild.id, "4")
  m.AssertTrue(lastChild.isSameNode(fourth))
End Function


'@Test convertNodesToIdsAA unit tests
Function tubiNodeHelpers_convertNodesToIdsAA_test()
  for i=0 to 4
    child = m.parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
  end for
  aaIds = m.NODEHELPERS.convertNodesToIdsAA(m.parent)
  mockAA = {
    "0": true
    "1": true
    "2": true
    "3": true
    "4": true
  }
  m.AssertNotInvalid(aaIds["0"])
  m.AssertNotInvalid(aaIds["1"])
  m.AssertNotInvalid(aaIds["2"])
  m.AssertNotInvalid(aaIds["3"])
  m.AssertNotInvalid(aaIds["4"])
  m.AssertEqual(aaIds, mockAA)
End Function


'@Test immutableInsertChild unit tests
Function tubiNodeHelpers_immutableInsertChild_test()
  numChildren = 5
  for i=0 to numChildren-1
    child = m.parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
  end for
  insertable = CreateObject("roSGNode", "ContentNode")
  insertable.id = "insertable"
  insertIndex = 2
  clonedParent = m.NODEHELPERS.immutableInsertChild(m.parent, insertable, insertIndex)
  m.AssertFalse(m.parent.isSameNode(clonedParent))
  m.AssertEqual(m.parent.id, clonedParent.id)
  m.AssertEqual(m.parent.getChildCount()+1, clonedParent.getChildCount())
  m.AssertEqual(insertable.id, clonedParent.getChild(insertIndex).id)
  m.AssertFalse(insertable.isSameNode(clonedParent.getChild(insertIndex)))
End Function


'@Test immutableInsertChildAlreadyExists unit tests
Function tubiNodeHelpers_immutableInsertChildAlreadyExists_test()
  existingChildIndex = 3
  numChildren = 5
  for i=0 to numChildren-1
    child = m.parent.createChild("ContentNode")
    if i = existingChildIndex
      child.id = "insertable"
      insertable = child
    else
      child.id = Mid(Str(i), 2)
    end if
  end for
  insertIndex = 2
  clonedParent = m.NODEHELPERS.immutableInsertChild(m.parent, insertable, insertIndex)
  m.AssertFalse(m.parent.isSameNode(clonedParent))
  m.AssertEqual(m.parent.id, clonedParent.id)
  m.AssertEqual(m.parent.getChildCount(), clonedParent.getChildCount())
  m.AssertEqual(insertable.id, clonedParent.getChild(insertIndex).id)
  m.AssertNotEqual(insertable.id, clonedParent.getChild(existingChildIndex).id)
  m.AssertFalse(insertable.isSameNode(clonedParent.getChild(insertIndex)))
End Function


'@Test immutableRemoveChildIndex unit tests
Function tubiNodeHelpers_immutableRemoveChildIndex_test()
  numChildren = 5
  for i=0 to numChildren-1
    child = m.parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
    if i = 2
      removeIndex = i
      removeId = child.id
    end if
  end for
  clonedParent = m.NODEHELPERS.immutableRemoveChildIndex(m.parent, removeIndex)
  m.AssertFalse(m.parent.isSameNode(clonedParent))
  m.AssertEqual(m.parent.id, clonedParent.id)
  m.AssertEqual(m.parent.getChildCount()-1, clonedParent.getChildCount())
  m.AssertInvalid(clonedParent.findNode(removeId))
End Function


'@Test immutableRemoveChild unit tests
Function tubiNodeHelpers_immutableRemoveChild_test()
  for i=0 to 4
    child = m.parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
    if i = 3
      third = child   'node to remove
    end if
  end for
  clonedParent = m.NODEHELPERS.immutableRemoveChild(m.parent, third)
  m.AssertFalse(m.parent.isSameNode(clonedParent))
  m.AssertEqual(m.parent.id, clonedParent.id)
  m.AssertEqual(m.parent.getChildCount()-1, clonedParent.getChildCount())
  m.AssertInvalid(clonedParent.findNode(third.id))
End Function


'@Test immutableRemoveChildren unit tests
Function tubiNodeHelpers_immutableRemoveChildren_test()
  nodesToRemove = []
  for i=0 to 4
    child = m.parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
    if i < 3
      nodesToRemove.push(child)   'should remove 3 nodes
    end if
  end for
  clonedParent = m.NODEHELPERS.immutableRemoveChildren(m.parent, nodesToRemove)
  m.AssertFalse(m.parent.isSameNode(clonedParent))
  m.AssertEqual(m.parent.id, clonedParent.id)
  m.AssertEqual(m.parent.getChildCount()-3, clonedParent.getChildCount())
  m.AssertInvalid(clonedParent.findNode(nodesToRemove[0].id))
  m.AssertInvalid(clonedParent.findNode(nodesToRemove[1].id))
  m.AssertInvalid(clonedParent.findNode(nodesToRemove[2].id))
End Function


'@Test countNodes unit tests
Function tubiNodeHelpers_countNodes_test()
  ' test passing non node
  nodeCount = m.nodeHelpers.countNodes(invalid)
  m.AssertEqual(nodeCount, 0)

  ' test passing negative depth - depth expected to be converted to 30
  nodes = m.generateNodeTree(3, 3) 'generates 13 nodes
  nodeCount = m.nodeHelpers.countNodes(nodes, -1)
  m.AssertEqual(nodeCount, 13)

  ' test non integer depth - depth expected to be converted to 30
  nodes = m.generateNodeTree(3, 3) 'generates 13 nodes
  nodeCount = m.nodeHelpers.countNodes(nodes, "12")
  m.AssertEqual(nodeCount, 13)

  ' test non integer depth with node tree of greater than 30 layers
  nodes = m.generateNodeTree(33, 1) 'generates 33 nodes
  nodeCount = m.nodeHelpers.countNodes(nodes, "12")
  m.AssertEqual(nodeCount, 30)

  ' test passed depth of greater than 30
  nodes = m.generateNodeTree(33, 1) 'generates 33 nodes
  nodeCount = m.nodeHelpers.countNodes(nodes, 33)
  m.AssertEqual(nodeCount, 30)

  ' test node tree depth of greater than 30 with no passed depth
  nodes = m.generateNodeTree(33, 1) 'generates 33 nodes
  nodeCount = m.nodeHelpers.countNodes(nodes)
  m.AssertEqual(nodeCount, 30)

  ' test passed depth which is greater than the number of layers
  nodes = m.generateNodeTree(16, 1) 'generates 33 nodes
  nodeCount = m.nodeHelpers.countNodes(nodes, 24)
  m.AssertEqual(nodeCount, 16)

  ' test parent only node
  node = CreateObject("roSGNode", "ContentNode")
  nodeCount = m.nodeHelpers.countNodes(node)
  m.AssertEqual(nodeCount, 1)

  ' test parent with single child
  node = CreateObject("roSGNode", "ContentNode")
  node.createChild("ContentNode")
  nodeCount = m.nodeHelpers.countNodes(node)
  m.AssertEqual(nodeCount, 2)

  ' test parent with multiple children and no passed depth
  nodes = m.generateNodeTree(3, 5) 'generates tree of 3 layers, each non edge node having 5 children
  nodeCount = m.nodeHelpers.countNodes(nodes)
  m.AssertEqual(nodeCount, 31)

  nodes = m.generateNodeTree(3, 5) 'generates tree of 3 layers, each non edge node having 5 children
  nodeCount = m.nodeHelpers.countNodes(nodes)
  m.AssertEqual(nodeCount, 31)
End Function


' helper function to recursively generate a node tree containing x amount of layers of
' ContentNodes with each non leaf/external node containing y children
' (if x = 1, the root node is also a leaf node, and no children will be added).
' Total nodes on the tree = Σ (n=0...x-1) (y^(i))
Function tubiNodeHelpersTest_generateNodeTree(x, y)
  parent = CreateObject("roSGNode", "ContentNode")

  for i = 0 to y-1
    if x - 1 > 0
      child = m.generateNodeTree(x-1, y)
      parent.appendChild(child)
    end if
  end for

  return parent
End Function


'@Test getArrayInterfaceTypes unit tests
Function tubiNodeHelpers_getArrayInterfaceTypes_test()
  arrayInterfaceTypes = m.nodeHelpers.getArrayInterfaceTypes()
  m.AssertNotInvalid(arrayInterfaceTypes.floatarray)
  m.AssertNotInvalid(arrayInterfaceTypes.intarray)
  m.AssertNotInvalid(arrayInterfaceTypes.boolarray)
  m.AssertNotInvalid(arrayInterfaceTypes.stringarray)
  m.AssertNotInvalid(arrayInterfaceTypes.vector2darray)
  m.AssertNotInvalid(arrayInterfaceTypes.colorarray)
  m.AssertNotInvalid(arrayInterfaceTypes.timearray)
  m.AssertNotInvalid(arrayInterfaceTypes.nodearray)
  m.AssertNotInvalid(arrayInterfaceTypes.array)
  m.AssertInvalid(arrayInterfaceTypes.otherarray)
  m.AssertInvalid(arrayInterfaceTypes.node)
  m.AssertInvalid(arrayInterfaceTypes.string)
  m.AssertInvalid(arrayInterfaceTypes.boolean)
End Function
