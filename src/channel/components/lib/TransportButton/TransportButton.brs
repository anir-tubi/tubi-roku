Function init()
  m.top.observeField("focusState", "onFocusUpdate")
  m.top.observeField("enabled", "onFocusUpdate")

  theme = getThemeFromGlobal()

  if theme <> invalid
    m.colors = {
      focusedText: theme.focusedColor
      unfocusedText: theme.unfocusedColor
    }
  end if

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.colors = {
      focusedText: theme.focusedColor
      unfocusedText: theme.unfocusedColor
    }
  end if
End Function


Function onFocusUpdate()
  TubiLog("TransportButton.onFocusUpdate: " + m.top.id)
  if m.top.focusState = true
    if m.colors <> invalid
      m.top.blendColor = m.colors.focusedText
    end if

    'skip trailer button is a special case where text color also needs to be updated
    if m.top.id = "SkipTrailerButton"
      if m.colors <> invalid
        label = m.top.findNode("SkipTrailerButtonLabel")
        if label <> invalid
          label.color = m.colors.focusedText
        end if
      end if
    end if

  else
    theme = getThemeFromGlobal()
    if theme <> invalid
      m.top.blendColor = theme.primaryTextColor
    end if

    'skip trailer button is a special case where text color also needs to be updated
    if m.top.id = "SkipTrailerButton"
      if m.colors <> invalid
        label = m.top.findNode("SkipTrailerButtonLabel")
        if label <> invalid
          label.color = m.colors.unfocusedText
        end if
      end if
    end if
  end if

  if m.top.enabled then
    m.top.opacity=1.0
  else
    m.top.opacity=0.3
  end if
End Function
