Function init()
  m.poster = m.top.findNode("Poster")
  m.InnerTitle = m.top.findNode("InnerTitle")
  m.InnerLayout = m.top.findNode("InnerLayout")
  m.TimeRemaining = m.top.findNode("TimeRemaining")

  m.badgeGroup = m.top.findNode("badgeGroup")
  m.resumeProgressBar = m.top.findNode("ResumeProgressBar")
  m.DurationBar = m.top.findNode("DurationBar")
  m.top.observeField("itemContent", "onContentChange")
  m.resumeMargin = 4  'inset of resume bar
  m.title = m.top.findNode("Title")
  m.posterFadeTime = 0.5

  '//recreate the contentTypes from constants so as not to access m.global.constants for every item on the home screen as they are created
  m.contentTypes = {
    series: "series"
    video: "video"
    episode: "episode"
    season: "season"
    category: "category"
    channel: "channel"
    linear: "linear"
    historySignedOutUser: "continue_watching_signed_out_user"
    epg: "epg"
    live: "live"
    sportsEvent: "sports_event"
    navigate: "navigate"
    viewMore: "viewMore"
  }

  '//recreate the contentTimings from constants so as not to access m.global.constants for every item on the home screen as they are created
  m.contentTimings = {
    replay: "replay"
    upcoming: "upcoming"
  }

  '//recreate the gridItemTypes (itemIDs) from constants so as not to access m.global.constants for every item on the home screen as they are created
  m.gridItemTypes = {
    portrait: "portrait"
    landscape: "landscape"
    landscapeNoTitle: "landscapeNoTitle"
    landscapeInnerMetadata: "landscapeInnerMetadata"
    linear: "linear"
    historySignedOutUser: "continue_watching_signed_out_user"
    emptyContainer: "emptyContainer"
  }

  m.top.observeFieldScoped("focusPercent", "onItemFocusPercentChange")
  m.top.observeFieldScoped("itemHasFocus", "onRowItemHasFocus")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.InnerTitle, typographyConstants.ids.bodySmall_strong)
  setTypographyOfLabel(m.Title, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.TimeRemaining, typographyConstants.ids.bodyExtraSmall)
  
  onThemeChange()
End Function


Function onThemeChange()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.InnerTitle.color = theme.primaryTextColor
    m.TimeRemaining.color = theme.primaryTextColor
    m.DurationBar.color = theme.primaryTextColor
    m.Title.color = theme.primaryTextColor
    if m.showAllLabel <> invalid
      m.showAllLabel.color = theme.primaryTextColor
    end if
  end if
End Function


Function onRowItemHasFocus()

  if m.top.itemHasFocus = false
    if m.lockIcon <> invalid then m.lockIcon.opacity = 0.0
  else
    if m.lockIcon <> invalid then m.lockIcon.opacity = 1.0
  end if

End Function


''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange(msg)
  itemContent = msg.getData()
  ' set some defaults
  m.title.visible = false
  m.InnerTitle.visible = false
  m.TimeRemaining.visible = false
  m.resumeMargin = 6

  gradientPoster =  m.poster.findNode("gradientPoster")
  if gradientPoster <> invalid
    m.poster.removeChild(gradientPoster)
  end if

  liveIconGroup =  m.poster.findNode("liveIconGroup")
  if liveIconGroup <> invalid
    liveIconGroup.removeChild(liveIconGroup)
  end if

  m.poster.opacity = 1

  ' next line shouldn't be necessary but is added in order to try and quell crashes as reported by roku crash logs
  if m.resumeProgressBar = invalid then m.resumeProgressBar = m.top.findNode("ResumeProgressBar")
  if m.DurationBar  = invalid then m.DurationBar  = m.top.findNode("m.DurationBar")

  m.resumeProgressBar.visible = false
  m.DurationBar.visible = false

  ' settings continueWatchingLayout and myStuffEmptyLayout Group visibility false to avoid image caching issue.
  if m.continueWatchingLayout <> invalid
    m.continueWatchingLayout.visible = false
  end if

  if m.myStuffEmptyLayout <> invalid
    m.myStuffEmptyLayout.visible = false
  end if

  ' settings poster visibility true to avoid image caching issue. if it is not set to true, seeing some blank posters
  m.poster.visible = true

  removeBadges()
  removeLockIcon()
  removeShowALlLabel()

  if itemContent <> invalid then

    hasVideoresources = itemContent.hasVideoresources
    airDatetime = itemContent.airDatetime

    info = getAvailabilityTypeBadgeAndMatchTimeValues(airDatetime, hasVideoresources)
    badgeText = info.badgeText
    if isNonEmptyString(badgeText) = true
      setReplayOrUpcomingBadge(badgeText)
    end if

    if itemContent.type <> invalid AND (itemContent.type = m.contentTypes.navigate OR itemContent.type = m.contentTypes.viewMore) AND itemContent.showAllText <> invalid

      griditemtype = itemContent.griditemtype
      if griditemtype = invalid
        gridItemType = "portrait"
      end if

      setShowAllLabel(itemContent.showAllText, gridItemType)
    end if

    if itemContent.needsLogin = true
      setLockIcon()
    end if

    categoryContent = itemContent.getParent()

    if categoryContent <> invalid AND itemContent.gridItemType <> invalid then
      m.poster.uri = itemContent.hdgridposterurl
      ' do not show title below the poster for featured row & show All poster
      if itemContent.gridItemType = m.gridItemTypes.landscape AND itemContent.type <> m.contentTypes.navigate
        m.title.visible = true
        m.title.text = itemContent.title
      else if categoryContent.gridItemType = m.gridItemTypes.historySignedOutUser
        setUpSignedOutContinueWatching()
      else if categoryContent.gridItemType = m.gridItemTypes.emptyContainer
        setUpEmptyContainer()
      else if categoryContent.gridItemType = m.gridItemTypes.historySignedOutUser
        setUpSignedOutContinueWatching()
      else if categoryContent.id = "continue_watching"
        if itemContent.gridItemType = m.gridItemTypes.landscapeInnerMetadata
          m.InnerTitle.text = itemContent.title
          m.InnerTitle.visible = true
          setInnerGradient()
          m.TimeRemaining.text = ""
          m.resumeMargin = 24
        end if
        drawHistoryProgressBar()
      else if itemContent.type = m.contentTypes.linear
        if (categoryContent.gridItemType = m.gridItemTypes.landscape OR categoryContent.gridItemType = m.gridItemTypes.landscapeNoTitle) 'linear content on landscape row
          currentProgram = getCurrentLiveProgram(itemContent)

          if currentProgram <> invalid AND isNonEmptyString(currentProgram.hdgridposterurl)
            m.poster.uri = currentProgram.hdgridposterurl
          end if

          setLiveBadge()
        else if itemContent.gridItemType = "" OR categoryContent.gridItemType <> m.gridItemTypes.linear
           'itemContent.gridItemType is not an empty string on the home screen,
          'and we want this to set Live logo and text just on the search screen.
          setLiveBadge()
        end if
      end if
    else
      m.poster.uri = itemContent.hdgridposterurl
    end if
  end if
End Function


' Make sure the assets within the inner part of the poster like the resume Progress bar
' is located towards the bottom of the poster based on the current dimensions of the poster.
Function moveInnerAssets()
  m.InnerLayout.translation = [m.resumeMargin, m.top.height - m.resumeProgressBar.height - m.resumeMargin - m.InnerTitle.height - m.TimeRemaining.height - (m.InnerLayout.itemSpacings[0] * 2) ]
End Function


Function onItemFocusPercentChange()
  if m.top.itemContent <> invalid AND m.top.itemContent.needsLogin = true
    if m.lockIcon <> invalid then m.lockIcon.opacity = m.top.focusPercent
  end if
End Function


Function drawHistoryProgressBar()
  history = getHistory(m.top.itemContent.id)

  if m.top.itemContent <> invalid AND history <> invalid AND history.nowPos <> invalid AND history.nowPos <> 0 AND m.top.itemContent.length <> invalid AND m.top.itemContent.length <> 0 then
    drawProgressBar(history.nowPos, m.top.itemContent.length)
  else
    moveInnerAssets()
  end if
End Function


Function drawProgressBar(nowPos, duration)
  if duration <= 0
    percentage = 0
  else
    percentage = nowPos / duration
  end if
  if percentage > 1.0 then percentage = 1.0
  if percentage < 0.0 then percentage = 0.0
  m.resumeProgressBar.width = (m.top.width - (2 * m.resumeMargin)) * percentage

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.resumeProgressBar.color = theme.focusedColor
  end if

  m.resumeProgressBar.visible = true
  m.DurationBar.width = (m.top.width - (2 * m.resumeMargin))
  m.DurationBar.visible = true

  if m.top.itemContent.gridItemType = m.gridItemTypes.landscapeInnerMetadata
    m.TimeRemaining.visible = true
    m.TimeRemaining.text = getTranslation("epg_minutes_left", {minutes: toStr(convertSecondsToMins(duration - nowPos))})
  end if

  moveInnerAssets()
End Function


Function onItemFocus()
  handleLocalFocusChange(m.top.itemHasFocus)
End Function


' @localFocus: boolean, the state of focus for the itemComponent
Function handleLocalFocusChange(newLocalFocus)

  if m.localFocus = false AND newLocalFocus = true
    'Do nothing for now. But we can add logic here when needed
  else if m.localFocus = true AND newLocalFocus = false
    ' item is losing focus - so fade the poster in (as necessary) and destroy the video player
    if m.poster.opacity < 1.0
      ' stop any fade out animations that might be running
      if m.fadeOutAnimation <> invalid
        m.fadeOutAnimation.control = "stop"
      end if

      ' fade in the poster, but if there is already a fade in animation running, let it run
      if m.fadeInAnimation = invalid OR m.fadeInAnimation.state <> "running"
        m.fadeInAnimation = fade(m.poster, "in", m.posterFadeTime)
      end if
    end if

  end if

  m.localFocus = newLocalFocus
End Function


Function onRowListHasFocus()
  ' fade the poster in when focusing side nav or leaving the page
  if m.top.rowListHasFocus = false
    handleLocalFocusChange(false)
  end if
End Function


Function onFocusPercentChange()
  if m.top.focusPercent < 1.0 AND m.localFocus = true
    handleLocalFocusChange(false)
  else if m.top.focusPercent = 1.0 AND m.localFocus = false AND m.top.rowListHasFocus = true
    handleLocalFocusChange(true)
  end if
End Function


Function setUpSignedOutContinueWatching()
  m.continueWatchingLayout = m.top.createChild("ContinueWatchingCategoryGridPoster")
  m.continueWatchingLayout.translation = [(m.top.width-m.continueWatchingLayout.width)/2, 57]
  m.continueWatchingLayout.visible = true
End Function


Function setUpEmptyContainer()
  m.myStuffEmptyLayout = m.top.createChild("MyStuffEmptyCategoryGridPoster")
  m.myStuffEmptyLayout.translation = [(m.top.width-m.myStuffEmptyLayout.width)/2, 40]
  m.myStuffEmptyLayout.title = m.top.itemContent.title
  m.myStuffEmptyLayout.subtitle = m.top.itemContent.description
  m.myStuffEmptyLayout.iconUri = m.top.itemContent.iconUrl
  m.myStuffEmptyLayout.visible = true
End Function


Function setLiveIconAndText()
  tubiLog("CategoryGridPoster.setLiveIconAndText")
  if m.poster <> invalid
    gradientPoster = m.poster.createChild("Poster")
    gradientPoster.width = m.poster.width
    gradientPoster.height = m.poster.height
    gradientPoster.uri = "pkg:/images/linear_search_gradient_overlay.png"
    gradientPoster.id = "gradientPoster"
    livePoster = gradientPoster.createChild("LiveIconGroup")
    livePoster.id = "liveIconGroup"
    livePoster.translation = [59, 225]
    livePoster.shouldAnimate = false
  end if
End Function


Function setInnerGradient()
  tubiLog("CategoryGridPoster.setInnerGradient")
  if m.poster <> invalid
    gradientPoster = m.poster.createChild("Poster")
    m.poster.insertChild(gradientPoster, 0)
    gradientPoster.width = m.poster.width
    gradientPoster.height = m.poster.height
    gradientPoster.uri = "pkg:/images/categoryGridPosterInnerGradient.webp"
    gradientPoster.id = "gradientPoster"
  end if
End Function


Function setLiveBadge()
  tubiLog("CategoryGridPoster.setLiveBadge")
  badge = m.badgeGroup.createChild("Badge")
  theme = getThemeFromGlobal()
  badge.translation = [12,12]
  if theme <> invalid
    badge.backgroundColor = theme.focused2Color
    badge.textColor = theme.primaryTextColor
  end if
  badge.iconUri = "pkg:/images/live-icon.webp"
  badge.text = UCase(getTranslation("screenSearch_liveText"))
End Function


Function removeBadges()
  tubiLog("CategoryGridPoster.removeBadges")
  childCount = m.badgeGroup.getChildCount()
  m.badgeGroup.removeChildrenIndex(childCount, 0)
End Function


Function setReplayOrUpcomingBadge(badgeText)
  tubiLog("CategoryGridPoster.setReplayOrUpcomingBadge")
  theme = getThemeFromGlobal()
  badge = m.badgeGroup.createChild("Badge")
  badge.translation = [12,12]
  if theme <> invalid
    if badgeText = m.contentTimings.replay
      badge.backgroundColor = theme.backgroundColorLight
      badge.textColor = theme.neutralColor2
    else
      badge.backgroundColor = theme.neutralColor
      badge.textColor = theme.primaryText
    end if
  end if
  badge.text = UCase(badgeText)
End Function


Function setLockIcon()
  tubiLog("CategoryGridPoster.setLockIcon")
  m.lockIcon = m.top.createChild("Poster")
  m.lockIcon.opacity = 0.0
  m.lockIcon.width = 21
  m.lockIcon.height = 24
  m.lockIcon.uri = "pkg:/images/icon-lock.webp"
  m.lockIcon.translation = [m.top.width-36, 14]
End Function


Function removeLockIcon()
  tubiLog("CategoryGridPoster.removeLockIcon")
  m.top.removeChild(m.lockIcon)
End Function


' setShowAllLabel is to set text/label inside poster. Currently this feature is available only for landscape & portrait gridTypes.
' if we need to support any other gridTypes, then add the width & height to support those inside this function.
'
'@text: String, a text to be displayed inside viewMore poster
'@gridType: String, default is portrait. possible values are constants.ui.gridItemTypes
Function setShowAllLabel(text, gridType = "portrait")
  tubiLog("CategoryGridPoster.setShowAllLabel")
  theme = getThemeFromGlobal()
  m.showAllLabel = m.top.createChild("Label")
  m.showAllLabel.text = text

  if theme <> invalid
    m.showAllLabel.color = theme.primaryTextColor
  end if

  if gridType = "portrait"
    m.showAllLabel.width = 186
    m.showAllLabel.height = 267
  else
    m.showAllLabel.width = 380
    m.showAllLabel.height = 216
  end if

  m.showAllLabel.horizAlign = "center"
  m.showAllLabel.vertAlign = "center"
  font = CreateObject("roSGNode", "Font")
  font.uri = "pkg:/fonts/Vaud-Bold.ttf"
  font.size = 27
  m.showAllLabel.font = font
End Function


Function removeShowAllLabel()
  tubiLog("CategoryGridPoster.removeShowAllLabel")
  m.top.removeChild(m.showAllLabel)
End Function
