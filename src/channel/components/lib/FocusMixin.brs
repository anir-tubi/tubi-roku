Function focusState(node As Object) As String
  if type(node) = "roSGNode" then
    return "id: " + node.id + " chain: " + node.isInFocusChain().toStr() + " self: " + node.hasFocus().toStr()
  else
    return ""
  end if
End Function