Function init()
  m.top.observeField("focusState", "onFocusUpdate")
End Function

Function onFocusUpdate()
  TubiLog("TransportButton.onFocusUpdate: " + m.top.id)
  if m.top.focusState = true
    m.top.uri = m.top.focusedUri
  else
    m.top.uri = m.top.unfocusedUri
  end if
End Function