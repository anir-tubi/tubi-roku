Function init()
  m.constants = getConstantsFromGlobal()
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
  m.top.observeField("command", "onCommand")

  '//::NOTE:: the translation of m.UpNextUI is modifed by AnimationMixin,
  '// so the translation of the UpNextUI element should not be changed directly.
  '// UpNextParent can be used if we need to change the translation of the up next component.
  m.UpNextUI = m.top.findNode("UpNextUI")
  m.UpNextUI.observeField("opacity", "onUpNextUIOpacityChange")
  m.UpNextParent = m.top.findNode("UpNextParent")
  m.UpNextParent.translation = [m.constants.ui.translations.marginX, m.UpNextParent.translation[1]]
  m.UpNextGradient = m.top.findNode("UpNextGradient")
  m.InfoMovie = m.top.findNode("InfoMovie")
  m.InfoSeries = m.top.findNode("InfoSeries")
  m.Timer = m.top.findNode("UpNextCountdownTimer")
  m.CountdownMovie = m.top.findNode("CountdownLabelMovie")
  m.CountdownSeries = m.top.findNode("CountdownLabelSeries")
  m.MovieGroup = m.top.findNode("UpNextMovieGroup")
  m.SeriesGroup = m.top.findNode("UpNextSeriesGroup")
  m.GridMovie = m.top.findNode("GridMovie")
  m.GridMovie.observeField("itemFocused", "onMovieItemFocused")
  m.GridMovie.observeField("itemSelected", "onMovieItemSelected")
  m.GridSeries = m.top.findNode("GridSeries")
  m.GridSeries.itemSize = m.constants.ui.imageSizes.largeLandscape
  m.InfoSeries.maxHeight = m.constants.ui.imageSizes.largeLandscape[1]

  m.GridSeries.observeField("itemFocused", "onSeriesItemFocused")
  m.GridSeries.observeField("itemSelected", "onSeriesItemSelected")

  focusBox = m.top.findNode("FocusBox")
  if m.constants.deviceInfo.scaledUi = true then
    focusBoxMargin = 4
  else
    focusBoxMargin = 6
  end if

  theme = getThemeFromGlobal()
  if theme <> invalid
    focusBox.blendColor = theme.focusedColor
    m.GridSeries.focusBitmapBlendColor = theme.focusedColor
    m.CountdownMovie.color = theme.highlightedTextColor
    m.CountdownSeries.color = theme.highlightedTextColor
  end if

  focusBox.width = m.constants.ui.imageSizes.largePoster[0] + focusBoxMargin * 2
  focusBox.height = m.constants.ui.imageSizes.largePoster[1] + focusBoxMargin * 2
  focusBox.translation = [- focusBoxMargin, - focusBoxMargin]
  m.InfoMovie.maxHeight = m.constants.ui.imageSizes.largePoster[1]


  targetSet = CreateObject("roSGNode", "TargetSet")
  nSpacing = 16
  nStartX = -m.constants.ui.imageSizes.largePoster[0] - nSpacing
  nArrayElements = 5
  aTargetRects = CreateObject("roArray", nArrayElements, true)
  for i = 0 to nArrayElements-1
    aaTargetRect = {
      x: nStartX
      y: 0
      width: m.constants.ui.imageSizes.largePoster[0]
      height: m.constants.ui.imageSizes.largePoster[1]
    }

    aTargetRects.push(aaTargetRect)

    '//New start position of the next poster image
    if i <> 1
      nStartX = nStartX + m.constants.ui.imageSizes.largePoster[0] + nSpacing
    else
      '//Move the images AFTER the 2nd image to the right of the upNext UI
      nStartX = 1071
    end if
  end for

  targetSet.targetRects = aTargetRects
  targetSet.focusIndex = 1
  targetSet.color = "0x00202020AA"
  m.GridMovie.targetSet = targetSet

  ' The seconds remaining
  m.timeRemaining = m.constants.player.upNextCountdown

  ' Used to determine if navigate_within_page events should be sent. Only send when the Up Next content row already
  ' has focus, not when it gains focus.
  m.isUpNextFocused = false

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.CountdownMovie, typographyConstants.ids.subheaderSmall)
  setTypographyOfLabel(m.CountdownSeries, typographyConstants.ids.subheaderSmall)

End Function


Function onComponentFocus()
  if m.top.hasFocus()

    'If the autoPlay is off, we don't need to show the count down timer.
    if m.top.isAutoPlayOff = false
      m.Timer.unobserveFieldScoped("fire")
      m.Timer.observeFieldScoped("fire", "onCountdownTimer")
    end if

    if m.MovieGroup.visible
      m.GridMovie.setFocus(true)
    else if m.SeriesGroup.visible = true
      m.GridSeries.setFocus(true)
    end if
  else if m.top.isInFocusChain() <> true
    m.isUpNextFocused = false
    m.GridMovie.setFocus(false)
    m.GridSeries.setFocus(false)
  end if
End Function


Function onResetContent()
  m.top.content = invalid
  m.top.contentFocused = invalid
  m.top.contentSelected = invalid
  m.top.autoplayMode = "unknown"
End Function


Function onContentChange()
  tubiLog("UpNext.onContentChange")
  if m.top.content <> invalid AND m.top.content.getChildCount() > 0
    firstContent = m.top.content.getChild(0)
    if firstContent.seriesId <> invalid AND firstContent.seriesId <> ""
      ' show the episode experience
      m.UpNextParent.translation = [m.UpNextParent.translation[0], 608]
      m.MovieGroup.visible = false
      m.SeriesGroup.visible = true
      singleContent = CreateObject("roSGNode", "ContentNode")
      singleContent.appendChild(firstContent.clone(false))
      m.GridSeries.content = singleContent
      m.timeRemaining = m.constants.player.upNextCountdownForSeries
      drawCountdown(m.CountdownSeries, m.timeRemaining)
      updateInfoPanel(m.InfoSeries, m.GridSeries.content.getChild(0))
    else
      ' show the movie experience
      m.UpNextParent.translation = [m.UpNextParent.translation[0], 540]
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
    else if key = "play" AND m.top.invalidCommand = ""
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

  if command = "ok" OR command = "play"
    if m.MovieGroup.isInFocusChain() = true
      handleMovieItemSelected(m.GridMovie.itemFocused)
    else if m.SeriesGroup.isInFocusChain() = true
      handleSeriesItemSelected(m.GridSeries.itemFocused)
    end if
  end if
End Function


Function onMovieItemFocused()
  tubiLog("UpNext.onMovieItemFocused")
  itemFocused = m.GridMovie.itemFocused
  col = itemFocused + 1 '1 based index
  row = 1
  itemFocusedHelper(m.GridMovie, m.InfoMovie) 'updates m.top.contentFocused

  'Set the navigateWithinPageInfo value which will pass through to ContentController via videoHelpers.brs
  'to fire a navigate_within_page analytics event.
  if m.isUpNextFocused = true
    m.top.navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage("video_page", {video_id: m.top.videoId.toInt()})
      componentOneof: m.Tracking.getAnalyticsComponent("auto_play_component", m.oldAutoPlayComponent)
      means_of_navigation: "BUTTON" 'MeansOfNavigation enum
      vertical_location: row
      horizontal_location: col
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
      if content.seriesId <> invalid AND content.seriesId <> ""
        m.timeRemaining = m.constants.player.upNextCountdownForSeries
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
  if m.top.isAutoPlayOff = false
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
  end if
End Function


Function drawCountdown(labelNode, time)
  if m.top.isAutoPlayOff = false
    labelNode.text = getTranslation("screenEndCard_startingIn", {seconds: stri(time)})
  end if
End Function


Function updateInfoPanel(infoNode, content)
  infoNode.title = content.title

  lineOneData = {}
  if content.type = m.constants.ui.contentTypes.series
    lineOneData.type = m.constants.ui.contentTypes.series
  end if
  lineOneData.releaseDate = content.releaseDate
  lineOneData.length = content.length
  lineOneData.hasCC = (content.hasSubtitles = true OR m._.empty(content.subtitleTracks) = false)
  lineOneData.hasAudioDescription = content.hasAudioDescription

  if content.highestRendition = m.constants.serverValues.tensorVideoRenditions.fourK
    lineOneData.has4k = true
  end if

  if content.availabilityEnds <> invalid
    lineOneData.availabilityEnds = content.availabilityEnds
  end if

  lineOneData.descriptorCode = content.descriptorCode
  lineOneData.rating = content.rating
  lineOneData.partnerLogoUri = content.inlineLogoUri

  lineTwoData = {
    genres: content.genres
  }

  infoNode.lineOneData = lineOneData
  infoNode.lineTwoData = lineTwoData
  infoNode.description = content.description
  infoNode.directors = content.directors
  infoNode.starring = content.actors
  infoNode.needsLogin = (content.needsLogin = true AND isLoggedinUser() = false)

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
    drawCountdown(m.CountdownSeries, m.timeRemaining)
  end if

  fade(m.UpNextGradient, "in", 1.0)
  slideFade(m.UpNextUI, "right", "in", 1.0)

  if m.top.isAutoPlayOff = false
    m.Timer.control = "start"
  end if
End Function


Function onHide()
  tubiLog("UpNext.onHide")
  fade(m.UpNextGradient, "out", 0.75)
  fade(m.UpNextUI, "out", 0.75)
  m.isUpNextFocused = false
  m.GridMovie.jumpToItem = 0
End Function


Function onUpNextUIOpacityChange()
  m.top.opacity = m.UpNextUI.opacity
End Function


Function stopTimer()
  m.Timer.control = "stop"
  m.timeRemaining = m.constants.player.upNextCountdown
End Function
