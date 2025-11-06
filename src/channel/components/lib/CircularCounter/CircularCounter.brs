Function init()
  topRef = m.top

  ' Get references to child nodes
  m.background = topRef.findNode("background")
  m.startsInLabel = topRef.findNode("startsInLabel")
  m.circleBackground = topRef.findNode("circleBackground")
  m.countdownLabel = topRef.findNode("countdownLabel")

  ' Initialize internal countdown variable
  m.currentCountdown = 0

  ' Create timer for countdown
  m.countdownTimer = createObject("roSGNode", "Timer")
  m.countdownTimer.duration = 1
  m.countdownTimer.repeat = true
  m.countdownTimer.observeField("fire", "onTimerFire")

  ' Set translated "Starts in" text
  m.startsInLabel.text = getTranslation("circular_counter_starts_in")

  ' Set typography/fonts
  typographyIds = getTypographyConstants().ids
  setTypographyOfLabel(m.startsInLabel, typographyIds.bodyExtraSmallStrong)
  setTypographyOfLabel(m.countdownLabel, typographyIds.bodyExtraSmallStrong)

  ' Observe field changes
  topRef.observeFieldScoped("start", "startCountdown")
  topRef.observeFieldScoped("stop", "stopCountdown")
  topRef.observeFieldScoped("countdownText", "onCountdownTextChanged")

  ' Initial layout calculation
  updateLayout()

  ' Observe theme changes
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
    ' Apply theme colors to labels
    m.startsInLabel.color = theme.primaryTextColor
    m.countdownLabel.color = theme.primaryTextColor
  end if
End Function


Function updateLayout()
  ' Calculate dynamic width based on text and icon
  leftPadding = 15
  iconSpacing = 9
  ' Get the actual text width from boundingRect
  textWidth = m.startsInLabel.boundingRect().width

  totalWidth = leftPadding + textWidth + iconSpacing + m.top.iconWidth

  ' Update background width
  m.background.width = totalWidth

  ' Position the circle and countdown label (vertically centered)
  circleX = leftPadding + textWidth + iconSpacing
  circleY = (m.top.height - m.top.iconHeight) / 2
  m.circleBackground.translation = [circleX, circleY]
  m.countdownLabel.translation = [circleX, circleY]
End Function


Function startCountdown()
  ' Reset internal countdown from m.top.startValue
  m.currentCountdown = m.top.startValue
  m.countdownLabel.text = m.currentCountdown.ToStr()

  m.countdownTimer.control = "start"
End Function


Function onTimerFire()
  if m.currentCountdown > 0
    m.currentCountdown = m.currentCountdown - 1
    ' Update label display
    m.countdownLabel.text = m.currentCountdown.ToStr()
  else
    ' Stop the timer when countdown reaches 0
    if m.countdownTimer <> invalid
      m.countdownTimer.control = "stop"
    end if
  end if
End Function


Function onCountdownTextChanged()
  ' When countdownText is updated from outside, parse it and update internal state
  countdownTextValue = m.top.countdownText
  if countdownTextValue <> ""
    m.currentCountdown = Val(countdownTextValue)
  end if
End Function




' Public method to stop the countdown
Function stopCountdown()
  if m.countdownTimer <> invalid
    m.countdownTimer.control = "stop"
  end if
End Function

