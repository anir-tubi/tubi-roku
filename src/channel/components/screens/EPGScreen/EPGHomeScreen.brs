Function init()
  tubiLog("EPGHomeScreen.init")
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.PageGroup = m.top.findNode("PageGroup")
  m.PageGroup.translation = [m.constants.ui.translations.marginX, 0]

  'infoPanel
  m.infoPanelParent = m.top.findNode("InfoPanelParent")
  m.infoPanel = m.top.findNode("InfoPanel")

  'clock
  m.clock = m.top.findNode("clock")

  'epgTimeGrid
  m.epgTimeGrid = m.top.findNode("programGuide")
  m.epgTimeGrid.observeField("linearChannelFocusedUpdated", "onLinearChannelFocused")
  m.epgTimeGrid.observeField("linearChannelToPlayUpdated", "onLinearChannelToPlay")
  m.epgTimeGrid.observeField("okPressed","onEPGTimegridOKPressed")
  m.epgTimeGrid.observeField("currFocusRow", "onCurrFocusRowChange")
  ' In this mode epg will expose the channel to Play only when uses presses/say "OK" or "PLAY"
  m.epgTimeGrid.EPGChannelPlayMode = m.constants.EPGChannelPlayMode.playItemOnSelect

  ' EPGFullMode is set to true so that epg has 4 rows as per epg design
  m.epgTimeGrid.EPGFullMode = true
  ' EPG Screen has requirement to start the videoplay as soon as it becomes visible. So play the first focused content, m.firstTime will be used.
  m.firstTime = true

  'm.top
  m.top.screenLevel = m.constants.ui.screenLevels.epgScreen
  m.top.observeField("updateTimeGridContent", "onTimeContentChange")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")
  m.top.observeField("id", "onIDChange")
  m.top.observeField("visible", "onVisibleChange")
  m.top.backgroundUriList = []
  m.top.handlesTransportVoiceRequests = true
  m.top.trackingPageInfo = {
    pageType : "linear_browse_page"
    pageValues : {}
  }
  m.epgTimeGrid.trackingPageInfo = m.top.trackingPageInfo
  'ChannelRefreshTimer
  m.channelRefreshTimer = m.top.findNode("channelRefreshTimer")
  'If channelRefreshTimer needs to be different than categoryContentRefreshTimeout then we need to add a constant
  m.channelRefreshTimer.duration = m.constants.timers.categoryContentRefreshTimeout
  m.channelRefreshTimer.observeField("fire", "onTimeGridRefreshTimer")
  m.channelRefreshTimer.control = "start"
End Function

Function onVisibleChange()
  if m.top.visible = true
    m.clock.control = "start"
  else
    m.clock.control = "stop"
  end if
End Function

Function onScreenFocusChange()
  tubiLog("EPGHomeScreen.onScreenFocusChange")
  if m.top.hasFocus() = true
    ' since epg main content node does not have valid Until, just findout the validUntil from first child
    ' This check might be necessary if user stay onsidenav for very long time.
    if m.epgTimeGrid.content <> invalid AND shouldRefresh(m.epgTimeGrid.content.getChild(0)) = true
      m.top.loadAllchannels = true
    end if

    setFocusOnEpgTimeGrid()

    m.top.shouldFocusWhenPushed = true

  else if m.top.isInFocusChain() = false
    m.top.refreshEPGScreenVideoPlay = true
    fadeInContentArea()
  end if

End Function


Function onLinearChannelFocused()
  tubiLog("EPGHomeScreen.onLinearChannelFocused")
  if m.epgTimeGrid <> invalid
    content = m.epgTimeGrid.linearChannelFocused
    if content <> invalid AND content.title <> invalid
      m.top.linearChannelFocused = content
      ' As per EPG requirement: if this is the first time content is focused after EPG started, then start playing the first content.
      ' all the other time, only selected content will get to play.
      ' if contentIdToFocusOnLoadComplete has been set, that would mean the content play has been requested from deeplink
      ' so do not play the first channel but play the focused channel.
      if m.firstTime = true AND m.top.contentIdToFocusOnLoadComplete = ""
        m.firstTime = false
        'TODO:: check if race condition happens.
        m.epgTimeGrid.setFocusedToPlay = true
        m.top.refreshEPGScreenVideoPlay = false
      else if m.top.contentIdToFocusOnLoadComplete <> ""
        m.firstTime = false
        contentIdToFocusOnLoadComplete = m.top.contentIdToFocusOnLoadComplete
        m.top.contentIdToFocusOnLoadComplete = ""
        m.top.jumpToRowItemByID = [contentIdToFocusOnLoadComplete, ""]
      end if
      populateInfoPanel(m.epgTimeGrid.linearChannelFocused)
    end if
  end if
End Function


'@contentNode: program content node
Function populateInfoPanel(contentNode)
  tubilog("EPGHomeScreen.populateInfoPanel")
  if contentNode <> invalid
    m.InfoPanel.mode = m.constants.ui.infoPanelModes.epg
    m.InfoPanel.title = contentNode.title
    m.InfoPanel.episodeTitle = contentNode.epgProgramTitle
    m.InfoPanel.width = 650
    m.InfoPanel.leftHeaderImageUri = contentNode.FHDPosterUrl

    lineOneData = {}
    lineOneData.hoursOfAiring = contentNode.hoursOfAiring
    lineOneData.rating = contentNode.rating
    lineOneData.hasCC = contentNode.hasSubtitles
    lineOneData.hasAudioDescription = contentNode.hasAudioDescription

    if contentNode.descriptors <> invalid AND contentNode.descriptors.Count() > 0
      lineOneData.descriptorCode = contentNode.descriptors.join(", ") ' To DO : When when we get real values into TAGS
    end if

    m.InfoPanel.lineOneData = lineOneData
    m.InfoPanel.description = contentNode.description

    if contentNode.needsLogin = true AND m.top.signedIn <> true
      m.InfoPanel.loginReason = contentNode.loginReason 'set login reason before setting needsLogin
      m.InfoPanel.needsLogin = true
    else
      m.InfoPanel.needsLogin = false
    end if

  end if

  m.InfoPanel.calculateHeight = true
End Function



Function onTimeContentChange()
  tubiLog("EPGHomeScreen.onTimeContentChange")
  if m.top.timeGridContent <> invalid
    m.epgTimeGrid.content = m.top.timeGridContent
    m.epgTimeGrid.contentUpdated = true
    m.top.contentReady = true
    m.InfoPanel.visible = true
  end if
End Function


Function onLinearChannelToPlay(msg)
  tubiLog("EPGHomeScreen.onLinearChannelToPlay")
  linearChannelupdated = msg.getData()
  if linearChannelupdated = true
    linearChannelToPlay = m.epgTimeGrid.linearChannelToPlay

    col = 1
    row = 1
    if m.epgTimeGrid <> invalid AND m.epgTimeGrid.rowItemFocused <> invalid AND m.epgTimeGrid.rowItemFocused.Count() > 0
      col = m.epgTimeGrid.rowItemFocused[1] + 1
      row = m.epgTimeGrid.rowItemFocused[0] + 1
    end if

    if linearChannelToPlay <> invalid
      m.top.trackingComponentInfo = {
        componentType : "epg_component"
        componentValues : {
          content_tile : m.Tracking.getAnalyticsTile(linearChannelToPlay, col, row)
          category_slug: linearChannelToPlay.parentId
        }
      }

      if m.top.linearChannelToPlay = invalid or (m.top.linearChannelToPlay <> invalid AND linearChannelToPlay <> invalid AND m.top.linearChannelToPlay.id <> linearChannelToPlay.id )
        m.top.linearChannelToPlay = linearChannelToPlay
        m.top.backgroundUriList = determineBackgroundImage(linearChannelToPlay)
      end if
    end if
  end if

End Function


' When OK has been pressed on EPG TimeGrid, maximize the player.
Function onEPGTimegridOKPressed()
  if m.top.linearChannelToPlay <> invalid AND m.epgTimeGrid.linearChannelFocused <> invalid AND m.epgTimeGrid.linearChannelFocused.id = m.top.linearChannelToPlay.id
    m.top.epgScreenOkPressed = true
  end if
End Function


Function onTransportVoiceRequest(msg)
  response = "unhandled"
  inputInfo = msg.getData()
  command = ""
  if inputInfo <> invalid AND inputInfo.command <> invalid
    command = inputInfo.command
  end if
  tubiLog("EPGHomeScreen.onTransportVoiceRequest " + command)

  if m.epgTimeGrid.isInFocusChain() = true
    if command = "play"
      handlePlayInput()
      response = "success"
    else if command = "ok"
      handlePlayInput()
      response = "success"
    end if
  end if

  inputInfo.response = response
  m.top.transportVoiceResponse = inputInfo
End Function


Function handlePlayInput()
  if m.epgTimeGrid.isInFocusChain() = true
    if m.epgTimeGrid.linearChannelFocused <> invalid
      m.epgTimeGrid.setFocusedToPlay = true
      'In EPG case both voice commands "play" and "ok" will play the content in full screen.
      onEPGTimegridOKPressed()
      m.top.trackingComponentInfo = getTrackingComponentInfoOfEPGGridList(m.epgTimeGrid.linearChannelFocused.getParent(), m.epgTimeGrid.rowItemfocused)
    end if
  end if
End Function



Function onKeyEvent(key As string, press As boolean) As boolean
  tubiLog("EPGHomeScreen.onKeyEvent")
  if press
    if key = "play" AND m.epgTimeGrid.isInFocusChain() = true
      handlePlayInput()
      return true
    end if
  end if
  return false
End Function


Function setFocusOnEpgTimeGrid()
  tubiLog("EPGHomeScreen.setFocusOnEpgTimeGrid ")
  'setting this field to false will trigger the focused channel to play in minimized window
  m.epgTimeGrid.setFocusedToPlay = true

  fadeInContentArea()
  m.epgTimeGrid.setFocus(true)
  m.top.refreshEPGScreenVideoPlay = false
End Function


Function onTimeGridRefreshTimer()
  tubiLog("EPGHomeScreen.onTimeGridRefreshTimer")
  m.top.loadAllChannels = true
End Function


Function onIDChange()
  '//Set the tracking based on the id of the homescreen
  '//::NOTE:: id should only be set after the instantiation of the HomeScreen, but before the screen is added to the stack
  newTrackingPageInfo = m.top.trackingPageInfo
  analyticsContentMode = m.Tracking.getAnalyticsHomePageContentMode(m.top.id)
  newTrackingPageInfo.pageValues = {content_mode: analyticsContentMode}

  m.top.trackingPageInfo = newTrackingPageInfo
End Function


' @timegridItem: roSGNode, TubiContentNode with metadata for an item in the grid
' @itemPosition: array, 2d array with [x,y] grid coordinate information
Function getTrackingComponentInfoOfEPGGridList(timegridItem, itemPosition)
  trackingComponentInfo = {}
  if timegridItem <> invalid AND itemPosition <> invalid AND itemPosition.Count() = 2
    componentValues = {}
    tile = m.Tracking.getAnalyticsTile(timegridItem, itemPosition[1] + 1)
    componentValues["content_tile"] = tile

    ' Set the tracking component of the timegridItem that was passed so it can be accessed as part of the navigateToPage event
    trackingComponentInfo = {
      componentType : "EPGComponent"
      componentValues : componentValues
    }
  end if

  return trackingComponentInfo
End Function


Function fadeOutContentArea()
  stopAnimation(m.gridFade)
  if m.epgTimeGrid.opacity > 0
    m.gridFade = fade(m.epgTimeGrid, "out", .4, 0.0, 0.4)
  end if

  stopAnimation(m.infoPanelFade)
  if m.InfoPanelParent.opacity > 0
    m.infoPanelFade = fade(m.InfoPanelParent, "out", .4, 0.0, 0.4)
  end if
End Function


Function fadeInContentArea()
  stopAnimation(m.gridFade)
  if m.epgTimeGrid.opacity < 1
    m.gridFade = fade(m.epgTimeGrid, "in", .4, 0.0, 1)
  end if

  stopAnimation(m.infoPanelFade)
  if m.InfoPanelParent.opacity < 1
    m.infoPanelFade = fade(m.InfoPanelParent, "in", .4, 0.0, 1)
  end if
End Function
