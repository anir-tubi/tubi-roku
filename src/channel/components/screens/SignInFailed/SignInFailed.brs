Function init()
  m.Buttons = m.top.findNode("TryAgainButtons")
  m.Buttons.observeField("itemSelected", "onButtonSelected")
  m.top.observeField("focusedChild", "onComponentFocus")
End Function

Function onComponentFocus()
  tubiLog("SignInFailed.onComponentFocus")
  if m.top.hasFocus()
    m.Buttons.setFocus(true)
  end if
End Function

Function onButtonSelected()
  tubiLog("SignInFailed.onButtonSelected")
  m.top.tryAgainButtonSelected = true
End Function