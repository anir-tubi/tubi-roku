Function init()
  m.constants = m.global.constants
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m._ = rodash()

  m.top.observeField("updateContent", "onContentChange")
  m.top.observeField("focusedChild", "onComponentFocus")
  m.top.observeField("show", "onShow")
  m.top.observeField("hide", "onHide")
  m.top.observeField("stopAutoPlayTimer", "onStopAutoPlayTimer")
  m.top.observeField("resetContent", "onResetContent")
  m.top.observeField("unfocus", "onUnfocus")
  m.top.observeField("command", "onCommand")

  m.UpNextUI = m.top.findNode("UpNextUI")
  m.UpNextUI.observeField("opacity", "onUpNextUIOpacityChange")
  m.UpNextGradient = m.top.findNode("UpNextGradient")
  m.InfoMovie = m.top.findNode("InfoMovie")
  m.InfoSeries = m.top.findNode("InfoSeries")
  m.Timer = m.top.findNode("UpNextCountdownTimer")
  m.CountdownMovie = m.top.findNode("CountdownLabelMovie")
  m.CountdownMovie.color =  m.global.theme.highlightedText
  m.CountdownSeries = m.top.findNode("CountdownLabelSeries")
  m.CountdownSeries.color =  m.global.theme.highlightedText
  m.Timer.observeField("fire", "onCountdownTimer")
  m.MovieGroup = m.top.findNode("UpNextMovieGroup")
  m.SeriesGroup = m.top.findNode("UpNextSeriesGroup")
  m.GridMovie = m.top.findNode("GridMovie")
  m.GridMovie.observeField("itemFocused", "onMovieItemFocused")
  m.GridMovie.observeField("itemSelected", "onMovieItemSelected")
  m.GridSeries = m.top.findNode("GridSeries")
  m.GridSeries.observeField("itemFocused", "onSeriesItemFocused")
  m.GridSeries.observeField("itemSelected", "onSeriesItemSelected")
  BackLabel = m.top.findNode("BackLabel")
  BackLabel.text = getTranslation("goBack_videoPlayer_upNext")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment 
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if

  focusBox = m.top.findNode("FocusBox")
  if m.global.constants.deviceInfo.scaledUi = true then
    focusBox.uri = "pkg:/images/selector-hd.9.png"
    m.GridSeries.focusBitmapUri = "pkg:/images/selector-hd.9.png"
    focusBoxMargin = 4
    if m.UpNextGradient <> invalid
      m.UpNextGradient.uri = "pkg:/images/up-next-gradient-hd.9.png"
    end if
  else
    focusBoxMargin = 6
  end if
  focusBox.blendColor = m.global.theme.focused
  m.GridSeries.focusBitmapBlendColor = m.global.theme.focused

  focusBox.width = 210 + focusBoxMargin * 2
  focusBox.height = 300 + focusBoxMargin * 2
  focusBox.translation= [85 - focusBoxMargin, 688 - focusBoxMargin]


  targetSet = CreateObject("roSGNode", "TargetSet")
  targetSet.targetRects = [
    {
      x: -135
      y: 0
      width: 210
      height: 300
    },
    {
      x: 85
      y: 0
      width: 210
      height: 300
    },
    {
      x: 1405
      y: 0
      width: 210
      height: 300
    },
    {
      x: 1625
      y: 0
      width: 210
      height: 300
    },
    {
      x: 1845
      y: 0
      width: 210
      height: 300
    }
  ]
  targetSet.focusIndex = 1
  targetSet.color = "0x00202020AA"
  m.GridMovie.targetSet = targetSet

  ' The seconds remaining
  m.timeRemaining = m.constants.player.upNextCountdown

  ' Used to determine if navigate_within_page events should be sent. Only send when the Up Next content row already
  ' has focus, not when it gains focus.
  m.isUpNextFocused = false
End Function


Function onComponentFocus()
  if m.top.hasFocus()
    if m.MovieGroup.visible
      m.GridMovie.setFocus(true)
    else if m.SeriesGroup.visible
      m.GridSeries.setFocus(true)
    end if
  else if m.top.isInFocusChain() <> true
    m.isUpNextFocused = false
  end if
End Function


Function onResetContent()
  m.top.content = invalid
  m.top.contentFocused = invalid
  m.top.contentSelected = invalid
  m.top.autoplayMode = "none"
End Function


Function onContentChange()
  tubiLog("UpNext.onContentChange")
  if m.top.content <> invalid and m.top.content.getChildCount() > 0
    firstContent = m.top.content.getChild(0)
    if firstContent.seriesId <> invalid and firstContent.seriesId <> ""
      ' show the episode experience
      m.MovieGroup.visible = false
      m.SeriesGroup.visible = true
      singleContent = CreateObject("roSGNode", "ContentNode")
      singleContent.appendChild(firstContent.clone(false))
      m.GridSeries.content = singleContent
      m.timeRemaining = getExperimentResource("roku_postplayexp_aptimer_5sec", "roku_postplayexp_aptimer_5sec_v1",false).ap_timer
      drawCountdown(m.CountdownSeries, m.timeRemaining)
      updateInfoPanel(m.InfoSeries, m.GridSeries.content.getChild(0))
    else
      ' show the movie experience
      m.MovieGroup.visible = true
      m.SeriesGroup.visible = false
      m.GridMovie.content = m.top.content
      m.timeRemaining = m.constants.player.upNextCountdown
      drawCountdown(m.CountdownMovie, m.timeRemaining)
      updateInfoPanel(m.InfoMovie, m.GridMovie.content.getChild(0))
    end if
  else
    ' default hide both experiences
    m.MovieGroup.visible = false
    m.SeriesGroup.visible = false
  end if
End Function


' this method stops the countdown timer, when deeplinking during autoplay screen
Function onStopAutoPlayTimer()
  if m.Timer <> invalid
    stopTimer()
  end if
End Function


Function onKeyEvent(key, press) as Boolean
  tubiLog("UpNext.onKeyEvent")
  ' pass through back presses, but consume all other button presses
  if press
    if key = "back"
      stopTimer()
      return false
    else if key = "play" and m.top.invalidCommand = ""
      if m.MovieGroup.isInFocusChain() = true
        handleMovieItemSelected(m.GridMovie.itemFocused)
      else if m.SeriesGroup.isInFocusChain() = true
        handleSeriesItemSelected(m.GridSeries.itemFocused)
      end if
    end if
  end if

  'reset the value so as not to block subsequent valid key press events
  m.top.invalidCommand = ""

  return true
End Function


Function onCommand(msg)
  tubiLog("UpNext.onCommand")
  command = msg.getData()

  if command = "ok" or command = "play"
    if m.MovieGroup.isInFocusChain() = true
      handleMovieItemSelected(m.GridMovie.itemFocused)
    else if m.SeriesGroup.isInFocusChain() = true
      handleSeriesItemSelected(m.GridSeries.itemFocused)
    end if
  end if
End Function


Function onMovieItemFocused(msg)
  tubiLog("UpNext.onMovieItemFocused")
  itemFocused = m.GridMovie.itemFocused
  col = itemFocused + 1  '1 based index
  row = 1
  itemFocusedHelper(m.GridMovie, m.InfoMovie)  'updates m.top.contentFocused

  'Set the navigateWithinPageInfo value which will pass through to ContentController via videoHelpers.brs
  'to fire a navigate_within_page analytics event.
  if m.isUpNextFocused = true
    m.top.navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage("video_page", {video_id: m.top.videoId.toInt()})
      componentOneof: m.Tracking.getAnalyticsComponent("auto_play_component", m.oldAutoPlayComponent)
      means_of_navigation: "BUTTON"  'MeansOfNavigation enum
      vertical_location: row
      vertical_location_mode: "INDEX"  'LocationMode enum
      horizontal_location: col
      horizontal_location_mode: "INDEX"  'LocationMode enum
    }

    contentTile = m.Tracking.getAnalyticsTile(m.top.contentFocused, col, row)
    m.oldAutoPlayComponent = {content_tile: contentTile}
  else
    contentTile = m.Tracking.getAnalyticsTile(m.top.contentFocused, col, row)
    m.oldAutoPlayComponent = {content_tile: contentTile}
  end if
  m.isUpNextFocused = true
End Function


Function onMovieItemSelected()
  tubiLog("UpNext.onMovieItemSelected")
  handleMovieItemSelected(m.GridMovie.itemSelected)
End Function


' @position: integer, the position within the row of movie contents displayed
Function handleMovieItemSelected(position)
  m.top.autoplayMode = "deliberate"
  m.top.contentSelected = m.GridMovie.content.getChild(position)
End Function


Function itemFocusedHelper(grid, info)
  if grid.content <> invalid
    content = grid.content.getChild(grid.itemFocused)
    if content <> invalid
      updateInfoPanel(info, content)
      m.top.contentFocused = content
      m.top.itemFocused = grid.itemFocused
      ' reset countdown while user is interacting
      if content.seriesId <> invalid and content.seriesId <> ""
        m.timeRemaining = getExperimentResource("roku_postplayexp_aptimer_5sec", "roku_postplayexp_aptimer_5sec_v1", false).ap_timer
      else
        m.timeRemaining = m.constants.player.upNextCountdown
      end if
    end if
  end if
End Function


Function onSeriesItemFocused()
  tubiLog("UpNext.onSeriesItemFocused")
  itemFocusedHelper(m.GridSeries, m.InfoSeries)
End Function


Function onSeriesItemSelected()
  tubiLog("UpNext.onSeriesItemSelected")
  handleSeriesItemSelected(m.GridSeries.itemSelected)
End Function


Function handleSeriesItemSelected(position)
  m.top.autoplayMode = "deliberate"
  m.top.contentSelected = m.GridSeries.content.getChild(position)
End Function


Function onCountdownTimer()
  tubiLog("UpNext.onCountdownTimer")
  m.timeRemaining = m.timeRemaining - 1
  if m.timeRemaining = 0
    m.top.autoplayMode = "automatic"
    if m.MovieGroup.visible
      if m.GridMovie.content <> invalid
        m.top.contentSelected = m.GridMovie.content.getChild(m.GridMovie.itemFocused)
      else
        ' if contentSelected is invalid, it is handled by the callback in VideoHelpers
        ' via VideoPlayerScreen.onUpNextContentSelected
        m.top.contentSelected = invalid
      end if
    else
      if m.GridSeries.content <> invalid
        m.top.contentSelected = m.GridSeries.content.getChild(0)
      else
        ' if contentSelected is invalid, it is handled by the callback in VideoHelpers
        ' via VideoPlayerScreen.onUpNextContentSelected
        m.top.contentSelected = invalid
      end if
    end if
    stopTimer()
  else
    if m.MovieGroup.visible
      drawCountdown(m.CountdownMovie, m.timeRemaining)
    else
      drawCountdown(m.CountdownSeries, m.timeRemaining)
    end if
  end if
End Function


Function drawCountdown(labelNode, time)
  labelNode.text = getTranslation("screenEndCard_startingIn", {seconds: stri(time)}) 
End Function


Function updateInfoPanel(infoNode, content)
  infoNode.title = content.title
  infoNode.genres = content.genres


  lineOneData = {}
  if content.type = m.constants.ui.contentTypes.series
    lineOneData.type = m.constants.ui.contentTypes.series 
  end if
  lineOneData.releaseDate = content.releaseDate
  lineOneData.length = content.length
  lineOneData.hasCC = (content.hasSubtitles or not m._.empty(content.subtitleTracks))
  if content.availabilityEnds <> invalid
    lineOneData.availabilityEnds = content.availabilityEnds
  end if
  lineOneData.rating = content.rating
  lineOneData.partnerLogoUri = content.inlineLogoUri

  infoNode.lineOneData = lineOneData
  infoNode.description = content.description
  infoNode.directors = content.directors
  infoNode.starring = content.actors

  ' always have to do this
  infoNode.calculateHeight = true
End Function


Function onShow()
  tubiLog("UpNext.onShow")

  ' reset the countdown timer prior to fading in the up next content so that
  ' the timer doesn't flash an old time from the previous time the up next UI was visible.
  if m.MovieGroup.visible
    drawCountdown(m.CountdownMovie, m.timeRemaining)
  else
    getExperimentResource("roku_postplayexp_aptimer_5sec", "roku_postplayexp_aptimer_5sec_v1")
    drawCountdown(m.CountdownSeries, m.timeRemaining)
  end if

  fade(m.UpNextGradient, "in", 1.0)
  slideFade(m.UpNextUI, "right", "in", 1.0)
  m.Timer.control = "start"
End Function


Function onHide()
  tubiLog("UpNext.onHide")
  fade(m.UpNextGradient, "out", 0.75)
  fade(m.UpNextUI, "out", 0.75)
  m.isUpNextFocused = false
  m.GridMovie.jumpToItem = 0
End Function


' typically setting focus to false is not a good pattern, but it seems to be necessary
' in order to remove the focus from these components when the UpNext component is a child
' of the video player.
Function onUnfocus()
  tubiLog("UpNext.onUnfocus")
  m.GridMovie.setFocus(false)
  m.GridSeries.setFocus(false)
End Function


Function onUpNextUIOpacityChange()
  m.top.opacity = m.UpNextUI.opacity
End Function


Function stopTimer()
  m.Timer.control = "stop"
  m.timeRemaining = m.constants.player.upNextCountdown
End Function