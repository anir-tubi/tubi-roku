Function init()
  topRef = m.top
  m.poster = topRef.findNode("Poster")
  m.sotBadge = topRef.findNode("sotBadge")
  m.progressBar = topRef.findNode("progressBar")
  m.progressBarGroup = topRef.findNode("progressBarGroup")
  topRef.observeFieldScoped("height", "onHeightChange")

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
    categoryContent = itemContent.getParent()
    if categoryContent <> invalid AND categoryContent.id = "continue_watching"
      drawHistoryProgressBar()
    end if
  end if
End Function


Function setSotBadge(badgeUri, badgeText)
  if isNonEmptyString(badgeUri) = true AND isNonEmptyString(badgeText) = true
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
    m.progressBarGroup.visible = true
  end if
End Function


Function onHeightChange(msg)
  height = msg.getData()
  m.progressBarGroup.translation = [0, (height - 76)]
End Function
