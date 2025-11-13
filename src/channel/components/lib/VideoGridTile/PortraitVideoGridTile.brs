Function init()
  topRef = m.top
  m.poster = topRef.findNode("Poster")
  m.progressBar = topRef.findNode("progressBar")
  m.progressBarGroup = topRef.findNode("progressBarGroup")
  m.timeLeftLabel = topRef.findNode("timeLeftLabel")
  m.gradient = topRef.findNode("gradient")
  topRef.observeFieldScoped("height", "onHeightChange")
  topRef.observeFieldScoped("videoTilesVariant", "updateTileTranslation")
  topRef.observeFieldScoped("rowHasFocus", "updateTileTranslation")
  topRef.observeFieldScoped("rowListHasFocus", "updateTileTranslation")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.timeLeftLabel, typographyConstants.ids.bodySmall)

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "setThemeColors")
  end if

  setThemeColors()

  m.linearBadge = invalid
  m.badgeTypes = {
    live: "live"
    onNow: "onNow"
    sot: "sot"
  }
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
    m.backgroundColor = theme.neutralSolidColor

    m.primaryTextColor = theme.primaryTextColor
    m.focused2Color = theme.focused2Color
    m.blueBadgeColor = theme.blueBadgeColor
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    updateTileTranslation()
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

    if m.linearBadge <> invalid
      m.top.removeChild(m.linearBadge)
      m.linearBadge = invalid
    end if

    if isAA(itemContent.sotPosterLabels) = true AND itemContent.sotPosterLabels.count() > 0
      badgeUri = itemContent.sotPosterLabels.sotIcon
      badgeText = itemContent.sotPosterLabels.sotLabelText
      setSotBadge(badgeUri, badgeText)
    end if

    if itemContent.type = "linear"
      currentProgram = getCurrentLiveProgram(itemContent)
      ' Only add the onNow badge if there is no live program or the live program is not live.
      if currentProgram = invalid OR currentProgram.live = false
        setLinearBadge(m.badgeTypes.onNow)
      else
        setLinearBadge(m.badgeTypes.live)
      end if
    else if m.sotBadge = invalid
      if isNonEmptyString(itemContent.availabilityEnds)
        badgeInfo = getExpiresBadgeInfo(itemContent.availabilityEnds)
        if badgeInfo <> invalid
          setSotBadge("", badgeInfo.text)
        end if
      end if
    end if

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
      m.sotBadge.id = "sotBadge"
      m.sotBadge.translation = [6, 6]
    end if

    m.sotBadge.textColor = m.focusedTextColor
    m.sotBadge.iconUri = badgeUri
    m.sotBadge.maxWidth = m.poster.width - 12
    m.sotBadge.text = badgeText
    m.sotBadge.visible = true
    m.top.appendChild(m.sotBadge)

  end if
End Function


Function setLinearBadge(badgeType = "live", badgeInfo = {})
  badge = invalid
  if badgeType = m.badgeTypes.live
    badge = createObject("roSGNode", "Badge")
    badge.badgeTextWidth = 0.0
    badge.textColor = m.primaryTextColor
    badge.translation = [6, 6]
    badge.backgroundColor = m.focused2Color
    badge.iconUri = "pkg:/images/live-icon-filled.webp"
    badge.text = getTranslation("screenSearch_liveText")
  else if badgeType = m.badgeTypes.onNow
    badge = createObject("roSGNode", "Badge")
    badge.badgeTextWidth = 0.0
    badge.textColor = m.primaryTextColor
    badge.translation = [6, 6]
    badge.backgroundColor = m.blueBadgeColor
    badge.text = getTranslation("onNow")
    badge.borderUri = "pkg:/images/badge-border-dark-$$RES$$.9.png"
  end if
  if badge <> invalid
    m.linearBadge = badge
    m.top.appendChild(m.linearBadge)
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


Function updateTileTranslation()
  content = m.top.itemContent
  if content <> invalid
    parent = content.getParent()
    parentArrayGrid = m.top.parentArrayGrid
    if parentArrayGrid <> invalid AND m.top.rowListHasFocus = false
      parentArrayGrid = parentArrayGrid.getParent()
    end if
    ' TODO: Revisit this logic once we move the skins to the featuredRowList.
    ' Check if the last focused list is featuredRowList and the rowListHasFocus is false or the row has focus
    ' First condition covers the case where the featuredRowList was focused and then user moved to side nav.
    if m.top.videoTilesVariant = "billboard" AND parent <> invalid AND parent.id = "featured" AND ((m.top.rowListHasFocus = false AND parentArrayGrid <> invalid AND parentArrayGrid.currCategoryId = "featured") OR m.top.rowHasFocus = true)
      m.top.translation = [0, 120]
    else
      m.top.translation = [0, 0]
    end if
  end if
End Function
