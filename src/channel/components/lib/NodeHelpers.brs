' used to determine the index of the child with respect the parent
' returns the index or -1 if the passed in child does not belong to the parent
Function getChildIndex(parent, child)
  if parent.getChildCount() > 0
    for i=0 to parent.getChildCount()-1
      if parent.getChild(i).isSameNode(child)
        return i
      end if
    end for
    return -1
  else
    return -1
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

Function cloneDeep(source)
  root = clone(source)
  for i=0 to source.getChildCount()-1
    root.appendChild(clone(source.getChild(i)))
  end for
  return root
End Function