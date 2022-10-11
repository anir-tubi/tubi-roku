Function init()
  m._ = rodash()

  m.poster = m.top.findNode("Poster")
  m.LinearPoster = m.top.findNode("LinearPoster")

  m.badgeGroup = m.top.findNode("badgeGroup")
  m.resumeProgressBar = m.top.findNode("ResumeProgressBar")
  m.top.observeField("itemContent", "onContentChange")
  m.resumeMargin = 4  'inset of resume bar
  m.title = m.top.findNode("Title")
  m.LinearTitle = m.top.findNode("LinearTitle")
  m.LinearSubTitle = m.top.findNode("LinearSubTitle")
  m.tVGuideNumberChannels = m.top.findNode("TVGuideNumberChannels")
  m.TVGuideNumberBground = m.top.findNode("TVGuideNumberBground")
  m.TVGuideNumberBground.blendColor = "0x9699A3FF"
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
  }

  '//recreate the contentTimings from constants so as not to access m.global.constants for every item on the home screen as they are created
  m.contentTimings = {
    replay: "replay"
    upcoming: "upcoming"
  }

  '//recreate the gridItemTypes (itemIDs) and uiResolution from constants so as not to access m.global.constants for every item on the home screen as they are created
  m.gridItemTypes = {
    portrait: "portrait"
    landscape: "landscape"
    linear: "linear"
    vitg: "vitg"
    historySignedOutUser: "continue_watching_signed_out_user"
  }
  m.itemIDs = {
    tvGuide: "tvGuide"
  }
  di = CreateObject("roDeviceInfo")
  m.top.observeFieldScoped("focusPercent", "onItemFocusPercentChange")
  m.top.observeFieldScoped("itemHasFocus", "onRowItemHasFocus")
  m.uiResolution = UCase(di.GetUiResolution().name)
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
  m.LinearPoster.visible = false
  m.title.visible = false
  m.LinearTitle.visible = false
  m.LinearSubTitle.visible = false
  m.tVGuideNumberChannels.visible = false

  gradientPoster =  m.poster.findNode("gradientPoster")
  if gradientPoster <> invalid
    m.poster.removeChild(gradientPoster)
    liveIconGroup = m.poster.findNode("liveIconGroup")
    if liveIconGroup <> invalid
      gradientPoster.removeChild(liveIconGroup)
    end if
  end if
  m.poster.opacity = 1

  ' next line shouldn't be necessary but is added in order to try and quell crashes as reported by roku crash logs
  if m.resumeProgressBar = invalid then m.resumeProgressBar = m.top.findNode("ResumeProgressBar")
  m.resumeProgressBar.visible = false

  ' settings continueWatchingLayout Group visibility false to avoid image caching issue.
  if m.continueWatchingLayout <> invalid
    m.continueWatchingLayout.visible = false
  end if
  ' settings poster visibility true to avoid image caching issue. if it is not set to true, seeing some blank posters
  m.poster.visible = true

  removeBadges()
  removeLockIcon()
  removeShowALlLabel()

  if m.top.itemContent <> invalid then

    hasVideoresources = m.top.itemContent.hasVideoresources
    airDatetime = m.top.itemContent.airDatetime

    info = getAvailabilityTypeBadgeAndMatchTimeValues(airDatetime, hasVideoresources)
    badgeText = info.badgeText
    if isNonEmptyString(badgeText) = true
      setReplayOrUpcomingBadge(badgeText)
    end if

    if m.top.itemContent.type <> invalid AND m.top.itemContent.type = m.contentTypes.navigate AND m.top.itemContent.title <> invalid
      setShowAllLabel(m.top.itemContent.title)
    end if

    if m.top.itemContent.needsLogin = true
      setLockIcon()
    end if

    categoryContent = m.top.itemContent.getParent()

    if categoryContent <> invalid AND itemContent.gridItemType <> invalid then
      m.poster.uri = itemContent.hdgridposterurl
      if itemContent.gridItemType = m.gridItemTypes.landscape
        m.title.visible = true
        m.title.text = itemContent.title
      else if isVitg(itemContent, m.gridItemTypes) = true
        setUpVitg()
      else if categoryContent.gridItemType = m.gridItemTypes.historySignedOutUser
        setUpSignedOutContinueWatching()
      else if categoryContent.id = "continue_watching"
        drawHistoryProgressBar()
      'itemContent.gridItemType is not an empty string on the home screen,
      'and we want this to set Live logo and text just on the search screen.
      else if (itemContent.gridItemType = "" AND itemContent.type = "linear")
        if getExperimentResource("roku_search_live_badge", "roku_search_live_badge_v1", true).enabled = true
          setLiveBadge()
        else
          setLiveIconAndText()
        end if
      end if
    else
      m.poster.uri = itemContent.hdgridposterurl
    end if
  end if
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
  m.resumeProgressBar.translation = [m.resumeMargin, m.top.height - m.resumeProgressBar.height - m.resumeMargin]
  m.resumeProgressBar.color = m.global.theme.focused
  m.resumeProgressBar.visible = true
End Function


Function onItemFocus()
  handleLocalFocusChange(m.top.itemHasFocus)
End Function


' @localFocus: boolean, the state of focus for the itemComponent
Function handleLocalFocusChange(newLocalFocus)
  if m.top.itemContent.id <> m.itemIDs.tvGuide
    if m.localFocus = false AND newLocalFocus = true
      ' item is gaining focus
      if isVitg(m.top.itemContent, m.gridItemTypes) = true
        if m.vitg = invalid
          '// create the video player when the vitig item gains focus
          m.vitg = createVitgVideo()
          if m.vitg <> invalid
            m.vitg.hasFocus = newLocalFocus
          end if
        end if
      end if
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

      ' destroy the video player
      if m.vitg <> invalid
        ' removing focus before destroying vitg lets finish_trailer events be fired from the vitg node
        m.vitg.hasFocus = newLocalFocus
        destroyVitgVideo()
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


Function onRowFocusPercentChange()
  if isVitg(m.top.itemContent, m.gridItemTypes) = true AND m.localFocus <> true
    m.poster.opacity = m._.max(m.poster.opacity, 1 - m.top.rowFocusPercent)
  end if
End Function


Function setUpLinear()
  m.top.unobserveField("itemHasFocus")
  m.top.observeField("itemHasFocus", "onItemFocus")
  m.top.observeField("rowListHasFocus", "onRowListHasFocus")
  m.top.unobserveField("focusPercent")
  m.top.observeField("focusPercent", "onFocusPercentChange")

  ' local focus state; becomes true when focusPercent = 1.0 or itemHasFocus = true
  ' becomes false when focusPercent < 1.0 or itemFocus = false
  if m.localFocus = invalid
    m.localFocus = false
  end if

  m.LinearPoster.visible = true
  m.LinearPoster.uri = m.top.itemContent.inlineLogoUri
  m.LinearPoster.width = 216
  m.LinearPoster.height = 216

  m.LinearTitle.visible = true
  m.LinearTitle.width = m.top.width
  nLinearTitlePlacement = m.top.height - m.LinearTitle.height - 36
  m.LinearTitle.translation = [0,nLinearTitlePlacement]


  if m.top.itemContent.id <> m.itemIDs.tvGuide
    m.poster.uri = "pkg:/images/gradientBground-linearItem-vertical.png"
    m.LinearTitle.text = m.top.itemContent.title
  else
    if m.uiResolution <> "FHD"
      m.poster.uri = "https://cdn.adrise.tv/image/roku_support_images/gradientBground-linearItem-tvGuide_hd.png"
    else
      m.poster.uri = "https://cdn.adrise.tv/image/roku_support_images/gradientBground-linearItem-tvGuide_fhd.png"
    end if
    '//Note: For the TV Guide item, the title is set to the subtitle component and the subtitle is set to the title component.
    m.LinearSubTitle.visible = true
    m.LinearSubTitle.width = m.top.width * .9
    nLinearSubTitle_X = (m.top.width - m.LinearSubTitle.width)/2
    m.LinearSubTitle.translation = [nLinearSubTitle_X, m.LinearSubTitle.translation[1]]
    m.LinearSubTitle.text = m.top.itemContent.title
    m.LinearTitle.text = getTranslation("screenHome_item_tvguide_subtitle")
    m.tVGuideNumberChannels.visible = true

    '//Set the X,Y coordinates of the tVGuideNumberChannels component
    nTVGuideNumberChannels_X = (m.top.width - m.TVGuideNumberBground.width)/2
    m.tVGuideNumberChannels.translation = [nTVGuideNumberChannels_X,nLinearTitlePlacement]

    '//Set the new Y position for the title text
    nLinearTitlePlacement = nLinearTitlePlacement - m.TVGuideNumberBground.height - 18
    m.LinearTitle.translation = [0, nLinearTitlePlacement]
  end if
  m.LinearPoster.translation = [381,198]

  ' It is possible when fast scrolling to the row, that the item can gain focus before setUpLinear() runs.
  ' since itemHasFocus is true in this case, the callback onItemFocus won't get triggered. so manually calling handleLocalFocusChange
  if m.top.itemHasFocus = true
    handleLocalFocusChange(m.top.itemHasFocus)
  end if
End Function


Function setUpVitg()
  m.top.observeField("rowFocusPercent", "onRowFocusPercentChange")
  m.top.observeField("itemHasFocus", "onItemFocus")
  m.top.observeField("rowListHasFocus", "onRowListHasFocus")
  m.top.unobserveField("focusPercent")
  m.top.observeField("focusPercent", "onFocusPercentChange")

  ' On various models, and due to long press horizontal scrolling, we cannot always count on
  ' m.top.itemHasFocus and m.top.focusPercent to fire as expected. In order to get around these issues,
  ' we maintain our own internal state and update it when we get info from the item component interface.

  ' local focus state; becomes true when focusPercent = 1.0 or itemHasFocus = true
  ' becomes false when focusPercent < 1.0 or itemFocus = false
  if m.localFocus = invalid
    m.localFocus = false
  end if

  m.top.id = m.top.itemContent.title

  title = m.top.itemContent.title
  if m.top.itemContent.gridItemType = "vitg"
    m.title.width = 1205
    title = title + " (" + m.top.itemContent.releaseDate + ") " + Chr(&hb7) + " " + formatLengthAsEnglish(m.top.itemContent.length)
  end if

  m.title.visible = true
  m.title.text = title

  ' It is possible when fast scrolling to the VITG row, that the item can gain focus before setUpVitg() runs.
  ' since itemHasFocus is true in this case, the callback onItemFocus won't get triggered. so manually calling handleLocalFocusChange to start trailer
  if m.top.itemHasFocus = true
    handleLocalFocusChange(m.top.itemHasFocus)
  end if

End Function


' returns a CategoryVideoPlayer node
Function createVitgVideo()
  vitg = invalid
  if m.top.itemContent.url <> ""
    vitg = CreateObject("roSGNode", "CategoryVideoPlayer")
    m.top.insertChild(vitg, 0)
    vitg.observeField("videoState", "onVideoStateChange")
    vitg.videoUrl = m.top.itemContent.url
    vitg.trailerId = m.top.itemContent.episodeNumber 'abusing content node by using episodeNumber to store the trailer id
    vitg.width = m.top.width
    vitg.height = m.top.height

    vitg.resumePos = m.top.itemContent.resumePos
    if m.top.itemContent.resumePos >= (m.top.itemContent.playDuration - 1)   ' playDuration holds the length of the trailer
      ' trailer has already been watched to completion, start it over again
      vitg.resumePos = 0
    end if

    drawProgressBar(m.top.itemContent.resumePos, m.top.itemContent.playDuration)
  end if

  return vitg
End Function


Function destroyVitgVideo()
  if m.vitg <> invalid
    m.vitg.control = "stop"
    m.vitg.unobserveField("videoState")
    m.top.removeChild(m.vitg)
    m.top.itemContent.resumePos = Int(m.vitg.nowPos / 1000)
    drawProgressBar(m.top.itemContent.resumePos, m.top.itemContent.playDuration)
    m.vitg = invalid
  end if
End Function


Function onVideoStateChange(msg)
  state = msg.getData()

  if state = "playing"
    if m.vitg <> invalid
      m.vitg.visible = true
    end if
    m.fadeOutAnimation = fade(m.poster, "out", m.posterFadeTime)
  else
    if m.vitg <> invalid
      m.vitg.visible = false
    end if

    if state = "stopped"
      vitgPosSeconds = m.vitg.nowPos / 1000
      m.top.itemContent.resumePos = vitgPosSeconds
      drawProgressBar(vitgPosSeconds, m.top.itemContent.playDuration)
      if m.localFocus = true
        'this only occurs when the video has played to completion
        if m.fadeInAnimation = invalid OR m.fadeInAnimation.state <> "running"
          m.fadeInAnimation = fade(m.poster, "in", m.posterFadeTime)
        end if
      end if
    end if
  end if
End Function


Function isVitg(itemContent, gridItemTypes)
  isVitg = false
  if itemContent.gridItemType = gridItemTypes.vitg
    isVitg = true
  end if
  return isVitg
End Function


Function setUpSignedOutContinueWatching()
  m.continueWatchingLayout = m.top.createChild("ContinueWatchingCategoryGridPoster")
  m.continueWatchingLayout.translation = [(m.top.width-m.continueWatchingLayout.width)/2, 57]
  m.continueWatchingLayout.visible = true
End Function


Function setLiveIconAndText()
  tubiLog("CategoryGridPoster.setLiveIconAndText")
  if m.poster <>invalid
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


Function setLiveBadge()
  tubiLog("CategoryGridPoster.setLiveBadge")
  badge = m.badgeGroup.createChild("Badge")
  badge.translation = [12,12]
  badge.backgroundColor = "0xCC090B"
  badge.textColor = "0xFFFFFF"
  badge.iconUri = "pkg:/images/live-icon.png"
  badge.text = UCase(getTranslation("screenSearch_liveText"))
End Function


Function removeBadges()
  tubiLog("CategoryGridPoster.removeBadges")
  childCount = m.badgeGroup.getChildCount()
  m.badgeGroup.removeChildrenIndex(childCount, 0)
End Function


Function setReplayOrUpcomingBadge(badgeText)
  tubiLog("CategoryGridPoster.setReplayOrUpcomingBadge")
  badge = m.badgeGroup.createChild("Badge")
  badge.translation = [12,12]
  if badgeText = m.contentTimings.replay
    badge.backgroundColor = "0xF0F1F5"
    badge.textColor = "0x1C1F29"
  else
    badge.backgroundColor = "0x585B66"
    badge.textColor = "0xF0F1F5"
  end if
  badge.text = UCase(badgeText)
End Function


Function setLockIcon()
  tubiLog("CategoryGridPoster.setLockIcon")
  m.lockIcon = m.top.createChild("Poster")
  m.lockIcon.opacity = 0.0
  m.lockIcon.width = 21
  m.lockIcon.height = 24
  m.lockIcon.uri = "pkg:/images/lock_icon.png"
  m.lockIcon.translation = [m.top.width-36, 14]
End Function


Function removeLockIcon()
  tubiLog("CategoryGridPoster.removeLockIcon")
  m.top.removeChild(m.lockIcon)
End Function


Function setShowAllLabel(text)
  tubiLog("CategoryGridPoster.setShowAllLabel")
  m.showAllLabel = m.top.createChild("Label")
  m.showAllLabel.text = text
  m.showAllLabel.color = "0xFFFFFFFF"
  m.showAllLabel.width = 380
  m.showAllLabel.height = 216
  m.showAllLabel.horizAlign = "center"
  m.showAllLabel.vertAlign = "center"
End Function


Function removeShowAllLabel()
  tubiLog("CategoryGridPoster.removeShowAllLabel")
  m.top.removeChild(m.showAllLabel)
End Function