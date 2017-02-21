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