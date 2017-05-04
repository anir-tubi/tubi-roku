'used to determine if the node passed in as the child is actually a child node of the parent
Function doesChildExist(parent, child)
  if parent.getChildCount() > 0
    for i=0 to parent.getChildCount()-1
      if parent.getChild(i).isSameNode(child)
        return true
      end if
    end for
    return false
  else
    return false
  end if
End Function

Function rootNode()
  if m.top <> invalid then
    parent = m.top
    while true
      nextParent = parent.getParent()
      if nextParent = invalid then return parent
      parent = nextParent
    end while
  end if
  return invalid
End Function

Function clone(source)
  target = CreateObject("roSGNode", source.subType())
  fields = source.getFields()
  ' blacklisted fields
  fields.delete("change")
  fields.delete("focusedChild")
  target.setFields(fields)
  return target  
End Function