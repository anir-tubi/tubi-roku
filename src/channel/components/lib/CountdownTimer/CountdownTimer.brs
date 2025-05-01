Function init()
  m.CountdownText = m.top.findNode("CountdownText")
  m.CountdownSeconds = m.top.findNode("CountdownSeconds")
  m.CountdownTimerParent = m.top.findNode("CountdownTimerParent")
  m.FullscreenIcon = m.top.findNode("FullscreenIcon")
  m.TextAndIconLayoutGroup = m.top.findNode("TextAndIconLayoutGroup")
  m.TextAndIconParentGroup = m.top.findNode("TextAndIconParentGroup")
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


'//This helper function is only used in the setBackgroundWidth() function.
'//returns a string to be used to determine the width of the CountdownText textfield.
Function getIntegerToSetWidth()
  NumOfCharacters = 2

  maxSeconds = m.top.maxSeconds
  if maxSeconds > 0
    sMaxSeconds = maxSeconds.ToStr()
    nLength = sMaxSeconds.Len()
    NumOfCharacters = nLength
  end if

  sReturnNumber = ""
  for i = 0 to NumOfCharacters - 1
    '//Use a wide number like "5" to determine the max width of a character.
    sReturnNumber = sReturnNumber + "5"
  end for

  nReturnNumber = val(sReturnNumber)

  return nReturnNumber
End Function


Function setBackgroundWidth()
  '//Use a 2 digit number to determine and set the max width of the background.
  m.CountdownSeconds.width = 0
  setSeconds(getIntegerToSetWidth())
  m.CountdownSeconds.width = m.CountdownSeconds.boundingRect().width '//set the width of the seconds textfield so the seconds can be right aligned.

  '// Workaround for potential Roku rendering issue: Add 1 pixel to the width to ensure the seconds label remains 
  '// right-aligned when displaying fewer characters than the maximum (e.g., "5" vs. "55"). Without this, the text may appear 
  '// misaligned if the width matches the maximum character count exactly.'
  m.CountdownSeconds.width = m.CountdownSeconds.width + 1

  nItemSpacing = m.TextAndIconLayoutGroup.itemSpacings[0]
  nFullScreenIconWidth = 0
  nodeFullscreenIconParent = m.FullscreenIcon.getParent()
  if nodeFullscreenIconParent <> invalid AND nodeFullscreenIconParent.id = m.TextAndIconLayoutGroup.id
    nFullScreenIconWidth = m.FullscreenIcon.width + nItemSpacing
  end if

  m.PlayerCountdownBground.width = (m.TextAndIconParentGroup.translation[0] * 2) + nFullScreenIconWidth +  m.CountdownText.boundingRect().width + m.CountdownSeconds.boundingRect().width
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
    m.CountdownSeconds.color = theme.primaryTextColor
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
  setTypographyOfCountdownLabel(msg.getData())
End Function
  
  
Function setTypographyOfCountdownLabel(sTypographyId = "")
  typographyConstants = getTypographyConstants()
  if isNonEmptyString(sTypographyId) = false
    sTypographyId = typographyConstants.ids.bodyMedium
  end if
  
  '//vertically center the label and icon
  m.CountdownText.height = 0
  m.CountdownSeconds.height = 0
  setTypographyOfLabel(m.CountdownText, sTypographyId)
  setTypographyOfLabel(m.CountdownSeconds, sTypographyId)
  setSeconds(getIntegerToSetWidth())
  nLabelHeight = m.CountdownText.boundingRect().height

  m.PlayerCountdownBground.height = nLabelHeight + (m.TextAndIconParentGroup.translation[1] * 2)
  nMaxHeight = maxValue(nLabelHeight, m.FullscreenIcon.height)
  if nMaxHeight <> invalid
    m.TextAndIconLayoutGroup.translation = [m.TextAndIconLayoutGroup.translation[0], nMaxHeight/2]
  end if
  m.CountdownText.height = m.CountdownText.boundingRect().height
  m.CountdownSeconds.height = m.CountdownSeconds.boundingRect().height
  m.top.height = m.PlayerCountdownBground.height

  '//reset the seconds back to what they were before this function
  if m.top.seconds >= 0
    setSeconds(m.top.seconds)
  end if

  '//Reset the background width when the text-size changes
  setBackgroundWidth()
End Function


Function setSeconds(nSeconds)
  if isNonEmptyString(m.top.secondsTranslationId) = true
    sTranslationId = m.top.secondsTranslationId
  else
    sTranslationId = "metadata_fullscreen_countdown_no_seconds"
  end if

  m.CountdownText.text = getTranslation(sTranslationId)

  m.CountdownSeconds.horizAlign="right"
  m.CountdownSeconds.text = nSeconds.toStr()
End Function