Function init()
  topRef = m.top
  m.background = topRef.findNode("background")
  m.countdownText = topRef.findNode("countdownText")
  m.timeRemainingBackground = topRef.findNode("timeRemainingBackground")
  m.timeRemainingText = topRef.findNode("timeRemainingText")
  m.elementsGroup = topRef.findNode("elementsGroup")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.countdownText, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.timeRemainingText, typographyConstants.ids.bodyMediumStrong)

  m.countdownText.text = getTranslation("videoPlayer_adBreakStartsIn")

  topRef.observeFieldScoped("timeRemaining", "onTimeRemainingChange")

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
    m.countdownText.color = theme.backgroundColor
    m.timeRemainingText.color = theme.primaryTextColor
    m.timeRemainingBackground.blendColor = theme.shadeColor
    m.background.blendColor = theme.tertiaryTextColor
  end if
End Function


Function onTimeRemainingChange(msg)
  timeRemaining = msg.getData()
  m.timeRemainingText.text = Int(timeRemaining).toStr() + "s"

  if m.top.reCalculateWidth = true
    ' Only increase the width if we need more space.
    timeRemainingTextWidth = m.timeRemainingText.boundingRect().width
    if timeRemainingTextWidth > m.timeRemainingBackground.width
      padding = 12
      m.timeRemainingBackground.width = timeRemainingTextWidth + padding
      m.timeRemainingText.width = timeRemainingTextWidth + padding
    end if

    m.background.width = m.elementsGroup.boundingRect().width + 16
    m.top.reCalculateWidth = false
    m.timeRemainingBackground.visible = true
  end if
End Function
