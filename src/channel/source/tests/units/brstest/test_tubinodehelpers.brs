Function testGetChildIndex(t As Object)
  NODEHELPERS = TubiNodeHelpers()

  parent = CreateObject("roSGNode", "ContentNode")
  for i=0 to 4
    child = parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
    if i = 3
      third = child
    end if
  end for

  fakeChild = CreateObject("roSGNode", "ContentNode")
  
  childIndex = NODEHELPERS.getChildIndex(parent, third)
  fakeChildIndex = NODEHELPERS.getChildIndex(parent, fakeChild)

  t.assertEqual(childIndex, 3)
  t.assertEqual(fakeChildIndex, -1)
End Function


Function testGetChildIndexById(t As Object)
  NODEHELPERS = TubiNodeHelpers()

  parent = CreateObject("roSGNode", "ContentNode")
  for i=0 to 4
    child = parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
    if i = 3
      idToRemove = child.id
    end if
  end for

  fakeChild = CreateObject("roSGNode", "ContentNode")
  fakeChild.id = "fake"
  
  childIndex = NODEHELPERS.getChildIndexById(parent, idToRemove)
  fakeChildIndex = NODEHELPERS.getChildIndex(parent, "fake")

  t.assertEqual(childIndex, 3)
  t.assertEqual(fakeChildIndex, -1)
End Function


Function testUnobserveAllScoped(t As Object)
  ' NOT SURE HOW TO TEST THIS - BRYAN
End Function


Function testConvertNodesToIdsAA(t As Object)
  NODEHELPERS = TubiNodeHelpers()

  parent = CreateObject("roSGNode", "ContentNode")
  for i=0 to 4
    child = parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
  end for

  aaIds = NODEHELPERS.convertNodesToIdsAA(parent)
  mockAA = {
    "0": true
    "1": true
    "2": true
    "3": true
    "4": true
  }

  t.assertNotInvalid(aaIds["0"])
  t.assertNotInvalid(aaIds["1"])
  t.assertNotInvalid(aaIds["2"])
  t.assertNotInvalid(aaIds["3"])
  t.assertNotInvalid(aaIds["4"])
  t.assertEqual(aaIds, mockAA)
End Function


Function testImmutableInsertChild(t As Object)
  NODEHELPERS = TubiNodeHelpers()

  parent = CreateObject("roSGNode", "ContentNode")
  parent.id = "parent"
  numChildren = 5
  for i=0 to numChildren-1
    child = parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
  end for

  insertable = CreateObject("roSGNode", "ContentNode")
  insertable.id = "insertable"

  insertIndex = 2
  clonedParent = NODEHELPERS.immutableInsertChild(parent, insertable, insertIndex)

  t.assertFalse(parent.isSameNode(clonedParent))
  t.assertEqual(parent.id, clonedParent.id)
  t.assertEqual(parent.getChildCount()+1, clonedParent.getChildCount())
  t.assertEqual(insertable.id, clonedParent.getChild(insertIndex).id)
  t.assertFalse(insertable.isSameNode(clonedParent.getChild(insertIndex)))
End Function


Function testImmutableInsertChildAlreadyExists(t As Object)
  NODEHELPERS = TubiNodeHelpers()

  parent = CreateObject("roSGNode", "ContentNode")
  parent.id = "parent"
  existingChildIndex = 3
  numChildren = 5
  for i=0 to numChildren-1
    child = parent.createChild("ContentNode")
    if i = existingChildIndex
      child.id = "insertable"
      insertable = child
    else
      child.id = Mid(Str(i), 2)
    end if
  end for

  insertIndex = 2
  clonedParent = NODEHELPERS.immutableInsertChild(parent, insertable, insertIndex)

  t.assertFalse(parent.isSameNode(clonedParent))
  t.assertEqual(parent.id, clonedParent.id)
  t.assertEqual(parent.getChildCount(), clonedParent.getChildCount())
  t.assertEqual(insertable.id, clonedParent.getChild(insertIndex).id)
  t.assertNotEqual(insertable.id, clonedParent.getChild(existingChildIndex).id)
  t.assertFalse(insertable.isSameNode(clonedParent.getChild(insertIndex)))
End Function


Function testImmutableRemoveChildIndex(t As Object)
  NODEHELPERS = TubiNodeHelpers()

  parent = CreateObject("roSGNode", "ContentNode")
  parent.id = "parent"
  numChildren = 5
  for i=0 to numChildren-1
    child = parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)

    if i = 2
      removeIndex = i
      removeId = child.id
    end if
  end for

  clonedParent = NODEHELPERS.immutableRemoveChildIndex(parent, removeIndex)

  t.assertFalse(parent.isSameNode(clonedParent))
  t.assertEqual(parent.id, clonedParent.id)
  t.assertEqual(parent.getChildCount()-1, clonedParent.getChildCount())
  t.assertInvalid(clonedParent.findNode(removeId))
End Function


Function testImmutableRemoveChild(t As Object)
  NODEHELPERS = TubiNodeHelpers()

  parent = CreateObject("roSGNode", "ContentNode")
  for i=0 to 4
    child = parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
    if i = 3
      third = child   'node to remove
    end if
  end for

  clonedParent = NODEHELPERS.immutableRemoveChild(parent, third)

  t.assertFalse(parent.isSameNode(clonedParent))
  t.assertEqual(parent.id, clonedParent.id)
  t.assertEqual(parent.getChildCount()-1, clonedParent.getChildCount())
  t.assertInvalid(clonedParent.findNode(third.id))
End Function


Function testImmutableRemoveChildren(t As Object)
  NODEHELPERS = TubiNodeHelpers()

  nodesToRemove = []
  parent = CreateObject("roSGNode", "ContentNode")
  for i=0 to 4
    child = parent.createChild("ContentNode")
    child.id = Mid(Str(i), 2)
    if i < 3
      nodesToRemove.push(child)   'should remove 3 nodes
    end if
  end for

  clonedParent = NODEHELPERS.immutableRemoveChildren(parent, nodesToRemove)

  t.assertFalse(parent.isSameNode(clonedParent))
  t.assertEqual(parent.id, clonedParent.id)
  t.assertEqual(parent.getChildCount()-3, clonedParent.getChildCount())
  t.assertInvalid(clonedParent.findNode(nodesToRemove[0].id))
  t.assertInvalid(clonedParent.findNode(nodesToRemove[1].id))
  t.assertInvalid(clonedParent.findNode(nodesToRemove[2].id))
End Function
