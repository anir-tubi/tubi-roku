Function TubiNodeHelpers()
  return {
    getChildIndex: tubiNodeHelpers_getChildIndex
    getChildIndexById: tubiNodeHelpers_getChildIndexById
    getChildIndicesById: tubiNodeHelpers_getChildIndicesById
    getLastChild: tubiNodeHelpers_getLastChild
    unobserveAllScoped: tubiNodeHelpers_unobserveAllScoped
    unobserveAll: tubiNodeHelpers_unobserveAll
    convertNodesToIdsAA: tubiNodeHelpers_convertNodesToIdsAA
    immutableInsertChild: tubiNodeHelpers_immutableInsertChild
    immutableRemoveChildren: tubiNodeHelpers_immutableRemoveChildren
    immutableRemoveChildIndex: tubiNodeHelpers_immutableRemoveChildIndex
    immutableRemoveChild: tubiNodeHelpers_immutableRemoveChild
    countNodes: tubiNodeHelpers_countNodes
  }
End Function


' used to determine the index of the child with respect to the parent
' returns the index or -1 if the passed in child does not belong to the parent
Function tubiNodeHelpers_getChildIndex(parent, child)
  if parent <> invalid
    for i=0 to parent.getChildCount()-1
      if parent.getChild(i).isSameNode(child)
        return i
      end if
    end for
  end if
  return -1
End Function


' used to determine the index of the child having childId with respect to the parent
' can be used if the parent along with children have been cloned and getChildIndex won't work
' returns the index or -1 if the passed in child does not belong to the parent
Function tubiNodeHelpers_getChildIndexById(parent, childId)
  if parent.getChildCount() > 0
    for i=0 to parent.getChildCount()-1
      if parent.getChild(i).id <> invalid AND parent.getChild(i).id = childId
        return i
      end if
    end for
    return -1
  else
    return -1
  end if
End Function


' used to determine all the Indices(array) of the child having childId with respect to the parent
' can be used if the parent along with children have been cloned and getChildIndex won't work
' returns the indices or [] if the passed in child does not belong to the parent
Function tubiNodeHelpers_getChildIndicesById(parent, childId)
  indices = []
  if parent <> invalid AND parent.getChildCount() > 0
    for i=0 to parent.getChildCount()-1
      if parent.getChild(i).id <> invalid AND parent.getChild(i).id = childId
        indices.push(i)
      end if
    end for
  end if
  return indices
End Function


' Get the last child of a node. Great for getting a modal from the ContentController.
' This function only gets first level children (ie. it doesn't look at grand children)
Function tubiNodeHelpers_getLastChild(parent)
  childCount = parent.getChildCount()

  lastChild = invalid
  if childCount > 0
    lastChild = parent.getChild(childCount - 1)
  end if

  return lastChild
End Function


' Remove all scoped observers.  This adds safety for when we want to ensure
' observer state so we don't do double observation
Function tubiNodeHelpers_unobserveAllScoped(node)
  if type(node) = "roSGNode"
    for each field in node.getFields()
      node.unobserveFieldScoped(field)
    end for
  end if
End Function


' Remove all non scoped observers.  This adds safety for when we want to ensure
' observer state so we don't do double observation
Function tubiNodeHelpers_unobserveAll(node)
  if type(node) = "roSGNode"
    for each field in node.getFields()
      node.unobserveField(field)
    end for
  end if
End Function


'Given a parent node, return an AA of consisting of ids of the 1st level children nodes:
' {
'   childId1: true
'   childId2: true
'   ...
' }
'
Function tubiNodeHelpers_convertNodesToIdsAA(parent)
  ids = {}
  children = parent.getChildren(parent.getChildCount(), 0)
  for each child in children
    ids[child.id] = true
  end for

  return ids
End Function


' Clones the parent node and inserts the child node at the given index.
' Returns an updated copy of the original parent node with a copy of the child inserted into it,
' or the unchanged parent node if the insert didn't work.
' Inserting the original child node instead of a clone of the child would remove the child from the original parent.
Function tubiNodeHelpers_immutableInsertChild(parent as object, child as object, index as Integer)
  clonedParent = parent.clone(true)
  clonedChild = child.clone(true)

  ' the default insertChild() (undocumented) behavior, will move the child to the new index
  ' if it already exists in the parent
  childIndex = m.getChildIndex(parent, child)
  if childIndex > -1
    clonedParent.removeChildIndex(childIndex)
  end if
  inserted = clonedParent.insertChild(clonedChild, index)
  if inserted <> true then return parent
  return clonedParent
End Function


' Clones the parent node and removes the child node at the given index.
' Returns an updated copy of the original parent node or the unchanged parent node if the removal didn't work
Function tubiNodeHelpers_immutableRemoveChildIndex(parent as object, index as Integer)
  clonedParent = parent.clone(true)
  removed = clonedParent.removeChildIndex(index)
  if removed <> true then return parent
  return clonedParent
End Function


' Clones the parent node and removes the child node
' Returns an updated copy of the original parent node or the unchanged parent node if the removal didn't work
Function tubiNodeHelpers_immutableRemoveChild(parent as object, child as object)
  childIndex = m.getChildIndex(parent, child)
  clonedParent = m.immutableRemoveChildIndex(parent, childIndex)
  return clonedParent
End Function


' Clones the parent node and removes the children nodes
' @children: array, array of children nodes
' Returns an updated copy of the original parent node or the unchanged parent node if none
' of the child nodes were successfully removed
Function tubiNodeHelpers_immutableRemoveChildren(parent as object, children as object)
  clonedParent = parent.clone(true)
  allFailed = true
  for i=children.count()-1 to 0 Step -1
    child = children[i]
    childIndex = m.getChildIndex(parent, child)
    removed = clonedParent.removeChildIndex(childIndex)
    if removed = true then allFailed = false
  end for

  if allFailed = true then return parent
  return clonedParent
End Function


' @node: roSGNode, a node whose children (including self) will be counted
' @depth: integer, the number of layers of children to count. For instance, depth of 1 will count
'         just the passed in node. Depth of 2 will count the passed node and it's immediate children.
'         Depth of 3 will include the passed node, immediate children, and grandchildren. Etc.
'         Depth of 0 is the default and will count all nodes at all levels, up to 30 levels. Stack
'         overflow seems to happen around 75 nodes deep, so leave max depth at 30 so there is plenty
'         of room to spare.
' returns the number of children that the passed node has, including the passed node itself.
'
Function tubiNodeHelpers_countNodes(node, depth = 0)
  nodeCount = 0

  if (type(depth) <> "Integer" AND type(depth) <> "roInt") or depth <= 0 or depth > 30
    depth = 30
  end if

  if type(node) = "roSGNode"
    nodeCount = 1
    depth --

    if depth > 0
      for i = 0 to node.getChildCount() - 1
        child = node.getChild(i)
        nodeCount += m.countNodes(child, depth)
      end for
    end if
  end if

  return nodeCount
End Function

