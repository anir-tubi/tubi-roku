Function init()
  m.constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusedChild", "onComponentFocus")
  m.top.observeField("stopAutoPlayTimer", "onStopAutoPlayTimer")

  m.InfoMovie = m.top.findNode("InfoMovie")
  m.InfoSeries = m.top.findNode("InfoSeries")
  m.Timer = m.top.findNode("CountdownTimer")
  m.CountdownMovie = m.top.findNode("CountdownLabelMovie")
  m.CountdownMovie.color =  m.global.theme.highlightedText
  m.CountdownSeries = m.top.findNode("CountdownLabelSeries")
  m.CountdownSeries.color =  m.global.theme.highlightedText
  m.Timer.observeField("fire", "onCountdownTimer")
  m.MovieGroup = m.top.findNode("MovieGroup")
  m.SeriesGroup = m.top.findNode("SeriesGroup")
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
    gradient = m.top.findNode("Gradient")
    gradient.uri = "pkg:/images/up-next-gradient-hd.9.png"
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
  
  m.top.screenLevel = m.constants.ui.screenLevels.upNextScreen
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

Function onContentChange()
  tubiLog("UpNextScreen.onContentChange")
  if m.top.content <> invalid and m.top.content.getChildCount() > 0
    firstContent = m.top.content.getChild(0)
    if firstContent.seriesId <> invalid and firstContent.seriesId <> ""
      ' show the episode experience
      m.MovieGroup.visible = false
      m.SeriesGroup.visible = true
      singleContent = CreateObject("roSGNode", "ContentNode")
      singleContent.appendChild(firstContent.clone(false))
      m.GridSeries.content = singleContent
      drawCountdown(m.CountdownSeries, m.timeRemaining)
      updateInfoPanel(m.InfoSeries, m.GridSeries.content.getChild(0))
    else
      ' show the movie experience
      m.MovieGroup.visible = true
      m.SeriesGroup.visible = false
      m.GridMovie.content = m.top.content
      drawCountdown(m.CountdownMovie, m.timeRemaining)
      updateInfoPanel(m.InfoMovie, m.GridMovie.content.getChild(0))
    end if
    m.Timer.control = "start"
  else
    ' default hide both experiences
    m.MovieGroup.visible = false
    m.SeriesGroup.visible = false
  end if
End Function

' this method stops the countdown timer, when deeplinking during autoplay screen
Function onStopAutoPlayTimer()
  if m.Timer <> invalid
    m.Timer.control = "stop"
  end if
End Function

Function onKeyEvent(key, press)
  tubiLog("UpNextScreen.onKeyEvent")
  if press and key = "back"
    m.Timer.control = "stop"
    m.top.backPressed = true
  end if
  return false
End Function

Function onMovieItemFocused()
  tubiLog("UpNextScreen.onMovieItemFocused")
  itemFocusedHelper(m.GridMovie, m.InfoMovie)  'updates m.top.contentFocused
  col = m.GridMovie.itemFocused + 1  '1 based index
  row = 1

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
  tubiLog("UpNextScreen.onMovieItemSelected")
  m.top.contentSelected = m.GridMovie.content.getChild(m.GridMovie.itemSelected)
End Function

Function itemFocusedHelper(grid, info)
  if grid.content <> invalid
    content = grid.content.getChild(grid.itemFocused)
    if content <> invalid
      updateInfoPanel(info, content)
      m.top.contentFocused = content
      ' reset countdown while user is interacting
      m.timeRemaining = m.global.constants.player.upNextCountdown
    end if
  end if
End Function

Function onSeriesItemFocused()
  tubiLog("UpNextScreen.onSeriesItemFocused")
  itemFocusedHelper(m.GridSeries, m.InfoSeries)
End Function

Function onSeriesItemSelected()
  tubiLog("UpNextScreen.onSeriesItemSelected")
  m.top.contentSelected = m.GridSeries.content.getChild(m.GridSeries.itemSelected)
End Function

Function onCountdownTimer()
  tubiLog("UpNextScreen.onCountdownTimer")
  m.timeRemaining = m.timeRemaining - 1
  if m.timeRemaining = 0
    m.top.timeout = true
    if m.MovieGroup.visible
      m.top.contentSelected = m.GridMovie.content.getChild(m.GridMovie.itemFocused)
    else
      m.top.contentSelected = m.GridSeries.content.getChild(0)
    end if
    m.Timer.control = "stop"
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
  infoNode.description = content.description
  infoNode.releaseDate = content.releaseDate
  infoNode.genres = content.genres
  infoNode.length = content.length
  infoNode.rating = content.rating
  infoNode.description = content.description
  infoNode.directors = content.directors
  infoNode.starring = content.actors

  if content <> invalid and content.subtitleTracks <> invalid
    infoNode.hasCC = true
  else
    infoNode.hasCC = false
  end if

  ' always have to do this
  infoNode.calculateHeight = true
End Function
