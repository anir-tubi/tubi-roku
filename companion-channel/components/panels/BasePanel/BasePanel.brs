' Base panel currently just used to provide focus management
Function init()
  m.top.observeFieldScoped("focusedChild", "onFocusedChildChange")
End Function


Function onFocusedChildChange(msg)
  if m.top.hasFocus() = true then
    if m.focusControlLayoutGroup <> invalid then
      m.focusControlLayoutGroup.setFocus(true)
    else if m.lastFocusedNode <> invalid then
      m.lastFocusedNode.setFocus(true)
    end if
  end if
End Function
