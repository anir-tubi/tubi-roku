Function init()
  topRef = m.top
  m.poster = topRef.findNode("Poster")
  m.progressBar = topRef.findNode("progressBar")
  m.progressBarGroup = topRef.findNode("progressBarGroup")
  m.timeLeftLabel = topRef.findNode("timeLeftLabel")
  m.gradient = topRef.findNode("gradient")
  topRef.observeFieldScoped("height", "onHeightChange")

  typographyConstants = getTypographyConstants()
  m.bodySmall = typographyConstants.ids.bodySmall
  m.bodySmallStrong = typographyConstants.ids.bodySmallStrong
  setTypographyOfLabel(m.timeLeftLabel, m.bodySmall)

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "setThemeColors")
  end if

  setThemeColors()

End Function


Function setThemeColors(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.focusedTextColor = theme.focusedTextColor
    m.progressBar.focusColor = theme.focusedColor
    m.progressBar.trackColor = theme.neutralColor
    m.progressBar.unfocusColor = theme.focusedColor
    m.timeLeftLabel.color = theme.primaryTextColor
    m.primaryTextColor = theme.primaryTextColor
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    m.progressBarGroup.visible = false
    m.gradient.visible = false

    currentProgram = invalid
    if itemContent.type = "linear"
      currentProgram = getCurrentLiveProgram(itemContent)
      drawLinearProgressBar(currentProgram)
    end if
    if currentProgram <> invalid
      if isNonEmptyString(currentProgram.hdGridPosterUrl) = true
        m.poster.uri = currentProgram.hdGridPosterUrl
      else if isNonEmptyString(currentProgram.portrait) = true
        m.poster.uri = currentProgram.portrait
      end if
    else if isNonEmptyString(itemContent.hdGridPosterUrl) = true
      m.poster.uri = itemContent.hdGridPosterUrl
    else if isNonEmptyString(itemContent.portrait) = true
      m.poster.uri = itemContent.portrait
    end if

    ' this is to avoid rowlist reusing the same badge without adjusting for the new text.
    if m.sotBadge <> invalid
      m.top.removeChild(m.sotBadge)
      m.sotBadge = invalid
    end if

    sotPosterLabels = itemContent.sotPosterLabels
    if itemContent.isReplay <> true AND isAA(sotPosterLabels) = true AND sotPosterLabels.count() > 0

      badgeTextFont = m.bodySmall
      textColor = m.primaryTextColor
      translation = [12, 12]
      backgroundUri = "pkg:/images/rounded-background-$$RES$$.9.png"

      config = {
        badgeTextFont: badgeTextFont
        backgroundUri: backgroundUri
        textColor: textColor
        translation: translation
        maxWidth: m.poster.width - 12
      }
      m.sotBadge = createSotPosterLabels(sotPosterLabels, config)
      showPosterLabesls(m.sotBadge, m.top)
    end if

    categoryContent = itemContent.getParent()
    if categoryContent <> invalid AND categoryContent.id = "continue_watching"
      drawHistoryProgressBar()
    end if
  end if
End Function




Function drawHistoryProgressBar()
  itemContent = m.top.itemContent
  history = getHistory(itemContent.id)
  nowPos = 0
  if history <> invalid AND isNumber(history.nowPos) = true
    nowPos = history.nowPos
  end if
  duration = itemContent.length
  if nowPos > 0 AND isNumber(duration) = true AND duration > 0
    percentage = nowPos / duration
    m.progressBar.progress = (percentage * 100)
    m.timeLeftLabel.text = convertSecondsToTimeLeftString(duration - nowPos)
    m.progressBarGroup.visible = true
    m.gradient.visible = true
  end if
End Function


Function drawLinearProgressBar(currentProgram)
  progress = getLinearProgramProgress(currentProgram)
  if progress > 0
    m.progressBar.progress = progress
    m.timeLeftLabel.text = calculateProgramTime(currentProgram)
    m.progressBarGroup.visible = true
    m.gradient.visible = true
  end if
End Function


Function onHeightChange(msg)
  height = msg.getData()
  m.progressBarGroup.translation = [0, (height - 78)]
End Function


Function calculateProgramTime(program) as String
  programTimeString = ""
  now = getCurrentLocalTime()
  if isInt(program.endTime) AND program.endTime > now
    duration = program.endTime - now
    programTimeString = convertSecondsToTimeLeftString(duration)
  end if

  return programTimeString
End Function
