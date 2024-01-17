Function init()
  m.CountdownText = m.top.findNode("CountdownText")
  m.CountdownTimerParent = m.top.findNode("CountdownTimerParent")
  m.FullscreenIcon = m.top.findNode("FullscreenIcon")
  m.TextAndIconLayoutGroup = m.top.findNode("TextAndIconLayoutGroup")
  m.PlayerCountdownBground = m.top.findNode("PlayerCountdownBground")
  m.top.observeFieldScoped("seconds", "onSecondChange")
  m.top.observeFieldScoped("display", "onDisplayChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.CountdownText, typographyConstants.ids.bodyExtraSmall_strong)

  '//Use a 2 digit number to determine and set the max width of the background.
  setSeconds(55)
  m.PlayerCountdownBground.width = (m.TextAndIconLayoutGroup.translation[0] * 2) +  m.FullscreenIcon.width + m.TextAndIconLayoutGroup.itemSpacings[0] +  m.CountdownText.boundingRect().width
  m.top.width = m.PlayerCountdownBground.width

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


Function setSeconds(nSeconds)
  m.CountdownText.text = getTranslation("metadata_fullscreen_countdown_plural", {seconds: nSeconds.toStr()})
End Function