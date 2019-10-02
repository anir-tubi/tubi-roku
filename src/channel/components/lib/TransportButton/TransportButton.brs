Function init()
  m.top.observeField("focusState", "onFocusUpdate")
  m.top.observeField("enabled", "onFocusUpdate")

  constants = m.global.constants
  theme = m.global.theme
  m.global.observeField("theme", "onThemeChange")

  if constants <> invalid
    m.colors = {
      focusedText: theme.focused
      unfocusedText: constants.ui.colors.unfocused
    }
  end if
End Function

Function onThemeChange()
  m.colors.focusedText = m.global.theme.focused 
End Function


Function onFocusUpdate()
  TubiLog("TransportButton.onFocusUpdate: " + m.top.id)
  if m.top.focusState = true
    m.top.blendColor = m.colors.focusedText

    'skip trailer button is a special case where text color also needs to be updated
    if m.top.id = "SkipTrailerButton"
      label = m.top.findNode("SkipTrailerButtonLabel")
      if label <> invalid
        label.color = m.colors.focusedText
      end if
    end if

  else
    m.top.blendColor = "0xffffffff"

    'skip trailer button is a special case where text color also needs to be updated
    if m.top.id = "SkipTrailerButton"
      label = m.top.findNode("SkipTrailerButtonLabel")
      if label <> invalid
        label.color = m.colors.unfocusedText
      end if
    end if
  end if
  if m.top.enabled then
    m.top.opacity=1.0
  else
    m.top.opacity=0.3
  end if
End Function
