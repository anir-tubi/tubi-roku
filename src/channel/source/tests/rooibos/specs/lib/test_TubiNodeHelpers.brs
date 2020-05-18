Function TestSuite_TubiNodeHelpers()
  this = BaseTestSuite()
  this.name = "TubiNodeHelpersTestSuite"
  this.addTest("getChildIndex", testCase_tubiNodeHelpers_getChildIndex)
  this.addTest("getChildIndexById", testCase_tubiNodeHelpers_getChildIndexById)
  this.addTest("convertNodesToIdsAA", testCase_tubiNodeHelpers_convertNodesToIdsAA)
  this.addTest("immutableInsertChild", testCase_tubiNodeHelpers_immutableInsertChild)
  this.addTest("immutableInsertChild_exists", testCase_tubiNodeHelpers_immutableInsertChildAlreadyExists)
  this.addTest("immutableRemoveChildIndex", testCase_tubiNodeHelpers_immutableRemoveChildIndex)
  this.addTest("immutableRemoveChild", testCase_tubiNodeHelpers_immutableRemoveChild)
  this.addTest("immutableRemoveChildren", testCase_tubiNodeHelpers_immutableRemoveChildren)
  return this
End Function



Function testCase_tubiNodeHelpers_getChildIndex()
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
  result = m.assertEqual(childIndex, 3)
  result += m.assertEqual(fakeChildIndex, -1)
  return result
End Function


Function testCase_tubiNodeHelpers_getChildIndexById()
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
  result = m.assertEqual(childIndex, 3)
  result += m.assertEqual(fakeChildIndex, -1)
  return result
End Function


Function testCase_tubiNodeHelpers_convertNodesToIdsAA()
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
  result = m.assertNotInvalid(aaIds["0"])
  result += m.assertNotInvalid(aaIds["1"])
  result += m.assertNotInvalid(aaIds["2"])
  result += m.assertNotInvalid(aaIds["3"])
  result += m.assertNotInvalid(aaIds["4"])
  result += m.assertEqual(aaIds, mockAA)
  return result
End Function


Function testCase_tubiNodeHelpers_immutableInsertChild()
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
  result = m.assertFalse(parent.isSameNode(clonedParent))
  result += m.assertEqual(parent.id, clonedParent.id)
  result += m.assertEqual(parent.getChildCount()+1, clonedParent.getChildCount())
  result += m.assertEqual(insertable.id, clonedParent.getChild(insertIndex).id)
  result += m.assertFalse(insertable.isSameNode(clonedParent.getChild(insertIndex)))
  return result
End Function


Function testCase_tubiNodeHelpers_immutableInsertChildAlreadyExists()
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
  result = m.assertFalse(parent.isSameNode(clonedParent))
  result += m.assertEqual(parent.id, clonedParent.id)
  result += m.assertEqual(parent.getChildCount(), clonedParent.getChildCount())
  result += m.assertEqual(insertable.id, clonedParent.getChild(insertIndex).id)
  result += m.assertNotEqual(insertable.id, clonedParent.getChild(existingChildIndex).id)
  result += m.assertFalse(insertable.isSameNode(clonedParent.getChild(insertIndex)))
  return result
End Function


Function testCase_tubiNodeHelpers_immutableRemoveChildIndex()
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
  result = m.assertFalse(parent.isSameNode(clonedParent))
  result += m.assertEqual(parent.id, clonedParent.id)
  result += m.assertEqual(parent.getChildCount()-1, clonedParent.getChildCount())
  result += m.assertInvalid(clonedParent.findNode(removeId))
  return result
End Function


Function testCase_tubiNodeHelpers_immutableRemoveChild()
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
  result = m.assertFalse(parent.isSameNode(clonedParent))
  result += m.assertEqual(parent.id, clonedParent.id)
  result += m.assertEqual(parent.getChildCount()-1, clonedParent.getChildCount())
  result += m.assertInvalid(clonedParent.findNode(third.id))
  return result
End Function


Function testCase_tubiNodeHelpers_immutableRemoveChildren()
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
  result = m.assertFalse(parent.isSameNode(clonedParent))
  result += m.assertEqual(parent.id, clonedParent.id)
  result += m.assertEqual(parent.getChildCount()-3, clonedParent.getChildCount())
  result += m.assertInvalid(clonedParent.findNode(nodesToRemove[0].id))
  result += m.assertInvalid(clonedParent.findNode(nodesToRemove[1].id))
  result += m.assertInvalid(clonedParent.findNode(nodesToRemove[2].id))
  return result
End Function
