Function init()
  m.poster = m.top.findNode("Poster")
  m.sotBadge = m.top.findNode("sotBadge")
  m.top.observeFieldScoped("itemContent", "onItemContentChange")

  setThemeColors()
End Function


Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.focusedTextColor = theme.focusedTextColor
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

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

  if isAA(itemContent.sotPosterLabels) = true AND itemContent.sotPosterLabels.count() > 0
    badgeUri = itemContent.sotPosterLabels.sotIcon
    badgeText =  itemContent.sotPosterLabels.sotLabelText
    setSotBadge(badgeUri, badgeText)
  end if

End Function


Function setSotBadge(badgeUri, badgeText)
  m.sotBadge.textColor = m.focusedTextColor
  m.sotBadge.iconUri = badgeUri
  m.sotBadge.maxWidth = m.poster.width - 12
  m.sotBadge.text = badgeText
  m.sotBadge.visible = true
End Function
