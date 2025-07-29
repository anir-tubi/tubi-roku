Function init()
  topRef = m.top
  m.poster = topRef.findNode("Poster")
  m.progressBar = topRef.findNode("progressBar")
  m.progressBarGroup = topRef.findNode("progressBarGroup")
  m.timeLeftLabel = topRef.findNode("timeLeftLabel")
  m.gradient = topRef.findNode("gradient")
  topRef.observeFieldScoped("height", "onHeightChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.timeLeftLabel, typographyConstants.ids.bodyExtraSmall)

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
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    currentProgram = invalid
    if itemContent.type = "linear"
      currentProgram = getCurrentLiveProgram(itemContent)
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

  if isAA(itemContent.sotPosterLabels) = true AND itemContent.sotPosterLabels.count() > 0
    badgeUri = itemContent.sotPosterLabels.sotIcon
    badgeText =  itemContent.sotPosterLabels.sotLabelText
    setSotBadge(badgeUri, badgeText)
  end if

    m.progressBarGroup.visible = false
    m.gradient.visible = false
    categoryContent = itemContent.getParent()
    if categoryContent <> invalid AND categoryContent.id = "continue_watching"
      drawHistoryProgressBar()
    end if
  end if
End Function


Function setSotBadge(badgeUri, badgeText)
  if isNonEmptyString(badgeText) = true
    if m.sotBadge = invalid
      m.sotBadge = createObject("roSGNode", "Badge")
      m.sotBadge.id="sotBadge"
      m.sotBadge.translation=[6, 6]
    end if

    m.sotBadge.textColor = m.focusedTextColor
    m.sotBadge.iconUri = badgeUri
    m.sotBadge.maxWidth = m.poster.width - 12
    m.sotBadge.text = badgeText
    m.sotBadge.visible = true
    m.top.appendChild(m.sotBadge)

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
    m.timeLeftLabel.text = getDurationHoursString(duration - nowPos)
    m.progressBarGroup.visible = true
    m.gradient.visible = true
  end if
End Function


Function onHeightChange(msg)
  height = msg.getData()
  m.progressBarGroup.translation = [0, (height - 76)]
End Function


' helper function which returns the time left in the format 'x hour and y mins left' if time left is more than an hour.
Function getDurationHoursString(seconds As Integer) As String
  formattedString = ""

  if seconds <> invalid
    hourValue = Int(seconds / 3600)
    minValue = StrI((Int(seconds / 60) mod 60) + 1) 'increase the min by one so that we don't show 0 min

    ' Since h and m are same in all languages skipping translation for better performance.
    if hourValue > 0
      formattedString =  Substitute("{0}h {1}m", StrI(hourValue), minValue)
    else
      formattedString = Substitute("{0}m", minValue)
    end if
  end if

  return formattedString
End Function
