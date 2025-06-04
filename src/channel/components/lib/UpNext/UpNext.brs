Function init()
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  m._ = rodash()

  m.top.observeField("updateContent", "onContentChange")
  m.top.observeField("focusedChild", "onComponentFocus")
  m.top.observeField("show", "onShow")
  m.top.observeField("hide", "onHide")
  m.top.observeField("stopAutoPlayTimer", "onStopAutoPlayTimer")
  m.top.observeField("resetContent", "onResetContent")
  m.top.observeField("command", "onCommand")

  '//::NOTE:: the translation of m.UpNextUI is modified by AnimationMixin,
  '// so the translation of the UpNextUI element should not be changed directly.
  '// UpNextParent can be used if we need to change the translation of the up next component.
  m.UpNextUI = m.top.findNode("UpNextUI")
  m.UpNextUI.observeField("opacity", "onUpNextUIOpacityChange")
  m.UpNextParent = m.top.findNode("UpNextParent")
  m.UpNextGradient = m.top.findNode("UpNextGradient")
  m.InfoMovie = m.top.findNode("InfoMovie")
  m.InfoSeries = m.top.findNode("InfoSeries")
  
  m.MovieContainerTitle = m.top.findNode("MovieContainerTitle")
  m.bgcolorParent = m.top.findNode("BgcolorParent")
  m.bgcolorOverlay = m.top.findNode("BgcolorOverlay")
  m.backgroundGroup = m.top.findNode("BackgroundGroup")
  m.countdownGroup = m.top.findNode("CountdownGroup")
  m.countdownGroup.secondsTranslationId = "screenEndCard_upNextIn"
  m.countdownGroup.maxSeconds = m.constants.player.upNextCountdownForSeries

  m.UpNextSeriesMenu = m.top.findNode("UpNextSeriesMenu")
  m.UpNextSeriesMenu.observeFieldScoped("itemSelected", "onSeriesItemSelected")
  upNextSeriesMenuButtonContent = m.top.findNode("UpNextSeriesMenuButtonContent")
  upNextSeriesMenuButtonContent.title = getTranslation("screenEndCard_nextEpisode")
  
  '//Resize the button based on the string length
  tempChannelMenuItem = CreateObject("roSGNode", "DetailMenuItem")
  tempChannelMenuItem.itemContent = upNextSeriesMenuButtonContent
  potentialWidth = tempChannelMenuItem.calculatedTextWidth + tempChannelMenuItem.leftTextPadding + tempChannelMenuItem.rightTextPadding
  m.UpNextSeriesMenu.itemSize = [potentialWidth, m.UpNextSeriesMenu.itemSize[1]]

  m.Timer = m.top.findNode("UpNextCountdownTimer")
  m.CountdownMovie = m.top.findNode("CountdownLabelMovie")
  m.CountdownSeries = m.top.findNode("CountdownLabelSeries")
  m.MovieGroup = m.top.findNode("UpNextMovieGroup")
  m.SeriesGroup = m.top.findNode("UpNextSeriesGroup")
  m.GridMovie = m.top.findNode("GridMovie")
  m.GridMovie.observeField("itemFocused", "onMovieItemFocused")
  m.GridMovie.observeField("itemSelected", "onMovieItemSelected")
  m.GridMovie.observeField("itemUnfocused", "onMovieItemUnFocused")
  m.GridSeries = m.top.findNode("GridSeries")

  m.isSeries = false 'keep track if this is a series or movie
  
  m.GridSeries.observeField("itemFocused", "onSeriesItemFocused")
  m.GridSeries.observeField("itemSelected", "onSeriesItemSelected")
  
  m.metadataSeries = m.top.findNode("metadataSeries")
  
  bAutoStartExperimentEnabled = (getExperimentResource("roku_video_autostart_ui_refresh", "roku_video_autostart_ui_refresh_v1", false).enabled = true)

  if bAutoStartExperimentEnabled = true
    nThumbnailWidth = m.constants.ui.imageSizes.landscape[0]
    nThumbnailHeight = m.constants.ui.imageSizes.landscape[1]
    m.metadata = m.top.findNode("metadata")
    m.metadata.translation = [0, 0]
    m.movieTiles = m.top.findNode("movieTiles")
    m.movieTiles.translation = [0, 0]
    m.UpNextGradient.visible = false
    m.CountdownMovie.visible = false
    m.CountdownSeries.visible = false
    m.MovieContainerTitle.text = getTranslation("screenEndCard_upNextTitles")
    m.InfoMovie.maxTitleLines = 1
    m.GridSeries.itemSize = m.constants.ui.imageSizes.largestLandscape
    m.InfoSeries.width = m.constants.ui.imageSizes.largestLandscape[0]
    m.InfoSeries.maxTitleLines = 1
  else
    nThumbnailWidth = m.constants.ui.imageSizes.largePoster[0]
    nThumbnailHeight = m.constants.ui.imageSizes.largePoster[1]
    m.InfoMovie.maxHeight = nThumbnailHeight

    m.GridSeries.itemSize = m.constants.ui.imageSizes.largeLandscape
    m.InfoSeries.maxHeight = m.constants.ui.imageSizes.largeLandscape[1]
  end if

  m.focusBox = m.top.findNode("FocusBox")
  if m.constants.deviceInfo.scaledUi = true then
    focusBoxMargin = 4
  else
    focusBoxMargin = 6
  end if

  m.focusBox.width = nThumbnailWidth + focusBoxMargin * 2
  m.focusBox.height = nThumbnailHeight + focusBoxMargin * 2
  m.focusBox.translation = [- focusBoxMargin, - focusBoxMargin]


  targetSet = CreateObject("roSGNode", "TargetSet")
  nSpacing = 16
  nStartX = -nThumbnailWidth - nSpacing
  if bAutoStartExperimentEnabled = true
    nArrayElements = 7
  else
    nArrayElements = 5
  end if
  aTargetRects = CreateObject("roArray", nArrayElements, true)
  
  for i = 0 to nArrayElements-1
    aaTargetRect = {
      x: nStartX
      y: 0
      width: nThumbnailWidth
      height: nThumbnailHeight
    }

    aTargetRects.push(aaTargetRect)

    '//New start position of the next poster image
    if i <> 1 OR bAutoStartExperimentEnabled = true
      nStartX = nStartX + nThumbnailWidth + nSpacing
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

  m.typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.CountdownMovie, m.typographyConstants.ids.subheaderSmall)
  setTypographyOfLabel(m.CountdownSeries, m.typographyConstants.ids.subheaderSmall)
  setTypographyOfLabel(m.MovieContainerTitle, m.typographyConstants.ids.subheaderMedium)
  m.countdownGroup.typographyLabelId = m.typographyConstants.ids.bodyMediumStrong

End Function


Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    isKidsMode = (theme.id = m.constants.ui.themeIDs.kidsMode)
    m.backgroundGroup.kidsMode = isKidsMode
    m.focusBox.blendColor = theme.focusedColor
    m.GridSeries.focusBitmapBlendColor = theme.focusedColor
    m.CountdownMovie.color = theme.highlightedTextColor
    m.CountdownSeries.color = theme.highlightedTextColor
    m.MovieContainerTitle.color = theme.primaryTextColor
    '//::TODO::JHAND - when there is a theme color for this background color, then use it instead of hardcoding the color.
    ' m.bgcolorOverlay.color = theme.backgroundColor
    m.bgcolorOverlay.color = "0x000000FF"

    m.countdownGroup.textColor = theme.textDarkColor
    m.countdownGroup.bgcolor = theme.backgroundColorLight2
  end if
End Function


Function onComponentFocus()
  if m.top.hasFocus()

    'If the autoPlay is off, we don't need to show the count down timer.
    if m.top.isAutoPlayOff = false
      m.Timer.unobserveFieldScoped("fire")
      m.Timer.observeFieldScoped("fire", "onCountdownTimer")
    end if

    if m.MovieGroup.visible = true
      m.GridMovie.setFocus(true)
    else if m.SeriesGroup.visible = true
      if getExperimentResource("roku_video_autostart_ui_refresh", "roku_video_autostart_ui_refresh_v1", false).enabled = true 
        m.UpNextSeriesMenu.setFocus(true)
      else
        m.GridSeries.setFocus(true)
      end if
    end if
    m.focusBox.visible = true
  else if m.top.isInFocusChain() <> true
    m.top.itemFocused = 0
    m.isUpNextFocused = false
    m.GridMovie.setFocus(false)
    m.GridSeries.setFocus(false)
    m.UpNextSeriesMenu.setFocus(false)
    m.focusBox.visible = false
    m.CountdownGroup.visible = true
  end if
End Function


Function onResetContent()
  m.top.content = invalid
  m.top.contentFocused = invalid
  m.top.contentSelected = invalid
  m.top.autoplayMode = "unknown"
  m.bgcolorParent.visible = false
End Function


Function onContentChange()
  tubiLog("UpNext.onContentChange")
  content = m.top.content
  if content <> invalid AND content.getChildCount() > 0
    setThemeColors()  '//Update the theme every time the content changes to ensure the correct theme is used.

    bAutoStartExperimentEnabled = (getExperimentResource("roku_video_autostart_ui_refresh", "roku_video_autostart_ui_refresh_v1", false).enabled = true)
    firstContent = content.getChild(0)
    if isNonEmptyString(firstContent.seriesId) = true
      ' show the episode experience
      m.MovieGroup.visible = false
      m.SeriesGroup.visible = true
      singleContent = CreateObject("roSGNode", "ContentNode")
      singleContent.appendChild(firstContent.clone(false))
      m.GridSeries.content = singleContent
      
      if bAutoStartExperimentEnabled = true
        m.UpNextParent.translation = [1068, 339]
        m.metadataSeries.translation = [0, m.GridSeries.translation[1] + m.GridSeries.itemSize[1] + 15]
        m.InfoSeries.translation = [0,0]
        m.CountdownGroup.translation = [454, 366]
        drawCountdown(m.CountdownGroup, m.timeRemaining)
        m.InfoSeries.titleTypography = m.typographyConstants.ids.subheaderSmall

        m.bgcolorParent.visible = true
        m.bgcolorOverlay.visible = false
        m.backgroundGroup.visible = true
        m.backgroundGroup.backgroundInfo = {
          type: m.constants.ui.backgroundTypes.fullScreen2
          uriList: []
        }
      else
        m.UpNextParent.translation = [m.constants.ui.translations.marginX, 608]
        drawCountdown(m.CountdownSeries, m.timeRemaining)
        m.metadataSeries.translation = [597,0]
        m.InfoSeries.translation = [0,58]
      end if

      m.timeRemaining = m.constants.player.upNextCountdownForSeries
      updateInfoPanel(m.InfoSeries, m.GridSeries.content.getChild(0))
    else

      if bAutoStartExperimentEnabled = true
        for i = 0 to content.getChildCount() - 1
          item = content.getChild(i)
          '//roku_video_autostart_ui_refresh_v1 - if this is graduated, then use the landscape URL instead of hdgridposterurl in UpNextPoster.brs. Get rid of this if/for loop.
          item.hdgridposterurl = item.landscape
        end for
      end if

      ' show the movie experience
      m.MovieGroup.visible = true
      m.SeriesGroup.visible = false
      m.GridMovie.content = content
      m.timeRemaining = m.constants.player.upNextCountdown
      updateInfoPanel(m.InfoMovie, m.GridMovie.content.getChild(0))
      if bAutoStartExperimentEnabled = true
        m.UpNextParent.translation = [m.constants.ui.translations.marginX, 729]
        m.CountdownGroup.translation = [177, 159]
        m.bgcolorParent.visible = true
        m.bgcolorOverlay.visible = true
        m.backgroundGroup.visible = true
        m.backgroundGroup.backgroundInfo = {
          type: m.constants.ui.backgroundTypes.fullScreen2
          uriList: []
        }

        sSpacingLabelFromGrid = 30
        sSpacingInfoFromLabel= 27
        m.MovieContainerTitle.translation = [0, -m.MovieContainerTitle.BoundingRect().height-sSpacingLabelFromGrid]
        m.InfoMovie.translation = [0, m.MovieContainerTitle.translation[1] -m.InfoMovie.calculatedHeight - sSpacingInfoFromLabel]

        drawCountdown(m.CountdownGroup, m.timeRemaining)
      else
        drawCountdown(m.CountdownMovie, m.timeRemaining)
        m.UpNextParent.translation = [m.constants.ui.translations.marginX, 540]
      end if
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
  handled = false
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
      handled = true
    end if
  end if

  'reset the value so as not to block subsequent valid key press events
  m.top.invalidCommand = ""

  return handled
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


Function onMovieItemUnFocused()
  ' hide the countdown when the movie item is unfocused
  m.CountdownGroup.display = false
  m.CountdownGroup.visible = false
End Function

Function onMovieItemFocused()
  tubiLog("UpNext.onMovieItemFocused")
  itemFocused = m.GridMovie.itemFocused
  col = itemFocused + 1 '1 based index
  row = 1
  itemFocusedHelper(m.GridMovie, m.InfoMovie) 'updates m.top.contentFocused
  drawCountdown(m.CountdownMovie, m.timeRemaining)
  m.CountdownGroup.visible = true

  if getExperimentResource("roku_video_autostart_ui_refresh", "roku_video_autostart_ui_refresh_v1", false).enabled = true AND m.GridMovie.content <> invalid
    content = m.GridMovie.content.getChild(m.GridMovie.itemFocused)
    m.backgroundGroup.visible = true
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.fullScreen2
      uriList: determineBackgroundImage(content)
    }
  end if

  'Set the navigateWithinPageInfo value which will pass through to ContentController via videoHelpers.brs
  'to fire a navigate_within_page analytics event.
  if m.isUpNextFocused = true
    m.top.navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage("video_player_page", {video_id: m.top.videoId.toInt()})
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

Function determineBackgroundImage(content)
  if isNode(content) = true AND isNonEmptyArray(content.backgrounds) = true then
    return content.backgrounds
  else
    return []
  end if
End Function


Function itemFocusedHelper(grid, info)
  if grid.content <> invalid
    content = grid.content.getChild(grid.itemFocused)
    if content <> invalid
      if isNonEmptyString(info.title) = false OR info.title <> content.title  '//only update if need be.
        updateInfoPanel(info, content)
        m.top.contentFocused = content
        m.top.itemFocused = grid.itemFocused
        ' reset countdown while user is interacting
        if isNonEmptyString(content.seriesId) = true
          m.timeRemaining = m.constants.player.upNextCountdownForSeries
        else
          m.timeRemaining = m.constants.player.upNextCountdown
        end if
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
  handleSeriesItemSelected(0) '//It can be assumed that there is only one item in the series
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
      if m.MovieGroup.visible = true
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
      if m.MovieGroup.visible = true
        drawCountdown(m.CountdownMovie, m.timeRemaining)
      else
        drawCountdown(m.CountdownSeries, m.timeRemaining)
      end if
    end if
  end if
End Function


Function drawCountdown(labelNode, time)
  bAutoStartExperimentEnabled = (getExperimentResource("roku_video_autostart_ui_refresh", "roku_video_autostart_ui_refresh_v1", false).enabled = true)
  if bAutoStartExperimentEnabled = true
    '//if the experiment gets graduated, then simplify this code so it only takes into account m.CountdownGroup
    labelNode = m.CountdownGroup
  end if
  if m.top.isAutoPlayOff = false

    if bAutoStartExperimentEnabled = true
      labelNode.seconds = time
      labelNode.display = true
    else
      labelNode.visible = true
      labelNode.text = getTranslation("screenEndCard_startingIn", {seconds: stri(time)})
    end if
  else
    if bAutoStartExperimentEnabled = true
      labelNode.display = false
    else
      labelNode.visible = false
    end if
  end if
End Function


Function updateInfoPanel(infoNode, content)
  infoNode.title = content.title
  bAutoStartExperimentEnabled = (getExperimentResource("roku_video_autostart_ui_refresh", "roku_video_autostart_ui_refresh_v1", false).enabled = true)
  lineOneData = {}
  isSeries = (isNonEmptyString(content.seriesId) = true)

  if isSeries = true
    lineOneData.type = m.constants.ui.contentTypes.series
  end if
  lineOneData.releaseDate = content.releaseDate
  lineOneData.length = content.length
  lineOneData.hasCC = (content.hasSubtitles = true OR m._.empty(content.subtitleTracks) = false)
  lineOneData.hasAudioDescription = content.hasAudioDescription

  lineOneData.has4k = (content.resolution = "2160")

  if content.availabilityEnds <> invalid
    lineOneData.availabilityEnds = content.availabilityEnds
  end if

  lineOneData.descriptorCode = content.descriptorCode
  lineOneData.rating = content.rating
  lineOneData.partnerLogoUri = content.inlineLogoUri

  lineTwoData = {
    genres: content.genres
  }
  description = content.description
  if bAutoStartExperimentEnabled = false
    infoNode.starring = content.actors
    infoNode.directors = content.directors
  else if isSeries = true
    '//if this part of the roku_video_autostart_ui_refresh_v1 experiment, then change what is passed to the info panel if this is a series
    description = ""
    lineTwoData = {}
  end if

  infoNode.lineOneData = lineOneData
  infoNode.lineTwoData = lineTwoData
  infoNode.description = description

  if content.needsLogin = true AND isLoggedinUser() = false
    infoNode.loginReason = content.loginReason 'set loginReason before needs login
    infoNode.needsLogin = true
  else
    infoNode.needsLogin = false
  end if

  ' always have to do this
  infoNode.calculateHeight = true
End Function


Function onShow()
  tubiLog("UpNext.onShow")

  '//fire the experiment event when the up next UI is shown
  getExperimentResource("roku_video_autostart_ui_refresh", "roku_video_autostart_ui_refresh_v1", true)

  ' reset the countdown timer prior to fading in the up next content so that
  ' the timer doesn't flash an old time from the previous time the up next UI was visible.
  if m.MovieGroup.visible = true
    drawCountdown(m.CountdownMovie, m.timeRemaining)
  else
    drawCountdown(m.CountdownSeries, m.timeRemaining)
  end if

  m.GridMovie.jumpToItem = 0
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
  stopTimer()
  m.isUpNextFocused = false
End Function


Function onUpNextUIOpacityChange()
  m.top.opacity = m.UpNextUI.opacity
End Function


Function stopTimer()
  m.Timer.control = "stop"
  m.timeRemaining = m.constants.player.upNextCountdown
End Function
