Function init()
  m.CountdownText = m.top.findNode("CountdownText")
  m.CountdownTimerParent = m.top.findNode("CountdownTimerParent")
  m.FullscreenIcon = m.top.findNode("FullscreenIcon")
  m.TextAndIconLayoutGroup = m.top.findNode("TextAndIconLayoutGroup")
  m.PlayerCountdownBground = m.top.findNode("PlayerCountdownBground")
  m.top.observeFieldScoped("seconds", "onSecondChange")
  m.top.observeFieldScoped("display", "onDisplayChange")
  m.top.observeFieldScoped("displayIcon", "onDisplayIconChange")
  m.top.observeFieldScoped("secondsTranslationId", "onSecondsTranslationIdChange")
  m.top.observeFieldScoped("typographyLabelId", "onTypographyLabelIdChange")

  setTypographyOfCountdownLabel()

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function setBackgroundWidth()
  '//Use a 2 digit number to determine and set the max width of the background.
  setSeconds(55)

  nFullScreenIconWidth = 0
  nodeFullscreenIconParent = m.FullscreenIcon.getParent()
  if nodeFullscreenIconParent <> invalid AND nodeFullscreenIconParent.id = m.TextAndIconLayoutGroup.id
    nFullScreenIconWidth = m.FullscreenIcon.width + m.TextAndIconLayoutGroup.itemSpacings[0]
  end if

  m.PlayerCountdownBground.width = (m.TextAndIconLayoutGroup.translation[0] * 2) + nFullScreenIconWidth +  m.CountdownText.boundingRect().width
  m.top.width = m.PlayerCountdownBground.width
  
  '//reset the seconds back to what they were before this function
  if m.top.seconds >= 0
    setSeconds(m.top.seconds)
  end if
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.CountdownText.color = theme.primaryTextColor
    m.PlayerCountdownBground.blendColor = theme.neutralColor
  end if
End Function


Function onSecondChange()
  setSeconds(m.top.seconds)
End Function


Function onDisplayChange()
  if m.top.display = true
    fade(m.CountdownTimerParent, "in", .5, .5)
  else
    fade(m.CountdownTimerParent, "out", 0)
  end if
End Function


' Display or hide the fullscreen icon
Function onDisplayIconChange()
  if m.top.displayIcon = true
    m.TextAndIconLayoutGroup.insertChild(m.fullscreenIcon, 0)
  else
    m.TextAndIconLayoutGroup.removeChild(m.fullscreenIcon)
  end if
  setBackgroundWidth()
End Function


Function onSecondsTranslationIdChange()
  '//Reset the background width when the text changes
  setBackgroundWidth()
End Function


Function onTypographyLabelIdChange(msg)
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.CountdownText, typographyConstants.ids.bodyMedium)
  setTypographyOfCountdownLabel(msg.getData())
End Function
  
  
Function setTypographyOfCountdownLabel(sTypographyId = "")
  typographyConstants = getTypographyConstants()
  if isNonEmptyString(sTypographyId) = false
    sTypographyId = typographyConstants.ids.bodyMedium
  end if
  
  setTypographyOfLabel(m.CountdownText, sTypographyId)

  '//Reset the background width when the text-size changes
  setBackgroundWidth()
End Function


Function setSeconds(nSeconds)
  if isNonEmptyString(m.top.secondsTranslationId) = true
    sTranslationId = m.top.secondsTranslationId
  else
    sTranslationId = "metadata_fullscreen_countdown_plural"
  end if

  m.CountdownText.text = getTranslation(sTranslationId, {seconds: nSeconds.toStr()})
End Function