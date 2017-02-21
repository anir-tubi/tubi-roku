Function init()
  m.top.observeField("focusState", "onFocusUpdate")
  m.top.observeField("focusedUri", "onFocusUpdate")
  m.top.observeField("unfocusedUri", "onFocusUPdate")

  m.colors = {
    focusedText: m.global.constants.ui.colors.focusedText
    unfocusedText: m.global.constants.ui.colors.unfocused
  }
End Function

Function onFocusUpdate()
  TubiLog("TransportButton.onFocusUpdate: " + m.top.id)
  if m.top.focusState = true
    m.top.uri = m.top.focusedUri

    'skip trailer button is a special case where text color also needs to be updated
    if m.top.id = "SkipTrailerButton"
      label = m.top.findNode("SkipTrailerButtonLabel")
      if label <> invalid
        label.color = m.colors.focusedText
      end if
    end if

  else
    m.top.uri = m.top.unfocusedUri

    'skip trailer button is a special case where text color also needs to be updated
    if m.top.id = "SkipTrailerButton"
      label = m.top.findNode("SkipTrailerButtonLabel")
      if label <> invalid
        label.color = m.colors.unfocusedText
      end if
    end if
  end if

End Function