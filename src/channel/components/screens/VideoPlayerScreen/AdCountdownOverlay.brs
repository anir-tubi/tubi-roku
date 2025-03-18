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

  topRef.observeFieldScoped("adInfo", "onAdInfoChange")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  m.timer = CreateObject("roSGNode", "Timer")
  m.timer.observeFieldScoped("fire", "onTimerFired")
  m.adViewedDuration = 0

  ' To account for ad failure in mid of a individual ad.
  m.adViewedDurationAtPodStart = 0

  m.overlayType = getExperimentResource("roku_player_ui_refresh", "roku_ads_overlay_v1", false).overlay_type

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


Function onAdInfoChange(msg)
  adInfo = msg.getData()
  if adInfo <> invalid
    if m.overlayType = "variant1" OR m.overlayType = "variant2"
      countdownText = getTranslation("ad_countdown_text")
    else if m.overlayType = "variant3"
      countdownText = getTranslation("ad_countdown_title_resume_in")
    else
      countdownText = getTranslation("ad_countdown_current_ad_ends_in")
    end if

    if adInfo.type = "PodStart"
      m.adViewedDuration = 0
      m.timeRemainingText.text = ""
      m.timeRemainingBackground.visible = false
    end if

    if adInfo.type = "Start" AND isInteger(adInfo.adIndex) = true AND isInteger(adInfo.adCount) = true
      countdownText = Substitute(countdownText, adInfo.adIndex.toStr(), adInfo.adCount.toStr())
      m.countdownText.text = countdownText
      m.background.visible = true
    end if

    if adInfo.type = "Start" OR adInfo.type = "Resume"
      updateTimeRemaining()
      updateOverlayWidth()
      m.timer.control = "START"
    else
      m.timer.control = "STOP"
    end if

    ' This is needed for variation 2.
    if adInfo.type = "Complete" AND shouldUseTotalPodDuration() = false
      m.adViewedDuration = 0
    end if

    ' If we are using total pod duration, adjusting viewed duration on error.
    if adInfo.type = "Error" AND shouldUseTotalPodDuration() = true
      m.adViewedDuration = m.adViewedDurationAtPodStart + adInfo.duration
    end if

    if adInfo.type = "Complete" OR adInfo.type = "Error"
      m.adViewedDurationAtPodStart = m.adViewedDuration
    end if

  end if
End Function


Function onTimerFired()
  adInfo = m.top.adInfo
  if adInfo <> invalid AND isNumber(adInfo.totalAdDurationInCurrentPod) = true
    m.adViewedDuration = m.adViewedDuration + 1
    updateTimeRemaining()
    
    m.timer.control = "STOP"
    if adInfo.type = "Start" OR adInfo.type = "Resume"
      m.timer.control = "START"
    end if
  end if
End Function


Function updateTimeRemaining()
  adInfo = m.top.adInfo

  if shouldUseTotalPodDuration() = false
    totalDuration = adInfo.duration    
  else
    totalDuration = adInfo.totalAdDurationInCurrentPod
  end if

  if adInfo <> invalid AND isNumber(totalDuration) = true
    timeRemaining = totalDuration - m.adViewedDuration
    
    m.timeRemainingText.text = formatTime(timeRemaining)

    m.timeRemainingBackground.visible = true
  end if
End Function


Function updateOverlayWidth()
  ' Only increase the width if we need more space.
  timeRemainingTextWidth = m.timeRemainingText.boundingRect().width
  if timeRemainingTextWidth > m.timeRemainingBackground.width
    padding = 15
    m.timeRemainingBackground.width = timeRemainingTextWidth + padding
    m.timeRemainingText.width = timeRemainingTextWidth + padding
  end if

  m.background.width = m.elementsGroup.boundingRect().width + 16  
End Function


Function formatTime(seconds)
  minutes = seconds \ 60 ' Integer division to get minutes 
  remainingSeconds = seconds MOD 60 ' Get remaining seconds 
  ' Format as MM:SS with zero padding
  formattedTime = "-" + StrI(minutes) + ":" + Right("0" + remainingSeconds.toStr(), 2) 
  return formattedTime 
End Function


Function shouldUseTotalPodDuration()
  return m.overlayType = "variant1" OR m.overlayType = "variant3"
End Function
