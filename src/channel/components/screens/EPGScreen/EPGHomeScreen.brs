Function init()
  tubiLog("EPGHomeScreen.init")
  m.constants = m.global.constants
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  '//Send the experiment exposure event when the EPG homescreen is created
  getExperimentResource("roku_linear_epg", "roku_linear_epg_v2", true)

  'infoPanel
  m.infoPanelParent = m.top.findNode("InfoPanelParent")
  m.infoPanel = m.top.findNode("InfoPanel")

  'clock
  m.clock = m.top.findNode("clock")

  'topNav
  m.topNav = m.top.FindNode("topNav")
  m.topNav.selectedId = m.constants.ui.sideNavIds.linearEPG
  m.topNavBG = m.top.FindNode("topNavBG")
  m.topNav.observeField("selected", "onTopNavSelection")
  m.topNav.observeField("backItemSelected", "onTopNavBackItemSelected")
  m.topNav.observeField("navigateWithinPageInfo", "onTopNavNavigateWithinPageInfoChange")
  m.topnav.doesSelectionNavigate = true

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
  m.defaultBackgroundUri = "pkg:/images/art-blur-background.png"
  m.top.screenLevel = m.constants.ui.screenLevels.epgScreen
  m.top.observeField("updateTimeGridContent", "onTimeContentChange")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")
  m.top.observeField("refreshTopNav", "onRefreshTopNav")
  m.top.observeField("visible", "onVisibleChange")
  m.top.backgroundUriList = [m.defaultBackgroundUri]
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
    ' This check might be necessary if user stay on topnav/sidenav for very long time.
    if m.epgTimeGrid.content <> invalid and shouldRefresh(m.epgTimeGrid.content.getChild(0)) = true
      m.top.loadAllchannels = true
    end if

    if m.top.componentToFocus = m.constants.ui.epgScreen.focusItems.topNav
      setFocusOntoTopNav(false)
      'set previously playing channel's background
      if m.top.linearChannelToPlay <> invalid
        m.top.backgroundUriList = determineBackgroundImage(m.top.linearChannelToPlay)
      end if
    else
      setFocusOnEPGTimeGrid()
    end if

    m.top.componentToFocus = m.constants.ui.epgScreen.focusItems.epgTimeGrid
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
    if content <> invalid and content.title <> invalid
      m.top.linearChannelFocused = content
      ' As per EPG requirement: if this is the first time content is focused after EPG started, then start playing the first content.
      ' all the other time, only selected content will get to play.
      if m.firstTime = true
        m.firstTime = false
        'TODO:: check if race condition happens.
        m.epgTimeGrid.setFocusedToPlay = true
        m.top.refreshEPGScreenVideoPlay = false
      end if
      populateInfoPanel(m.epgTimeGrid.linearChannelFocused)
    end if
  end if
End Function


'@contentNode: program content node
Function populateInfoPanel(contentNode)
  if contentNode <> invalid
    m.InfoPanel.mode = m.constants.ui.infoPanelModes.epg
    m.InfoPanel.title = contentNode.title
    m.InfoPanel.description = contentNode.description
    m.InfoPanel.width = 650
    m.InfoPanel.headerImageUri = contentNode.FHDPosterUrl
    lineOneData = {}
    lineOneData.rating = contentNode.rating
    lineOneData.hasCC = contentNode.hasSubtitles
    if contentNode.descriptors <> invalid and contentNode.descriptors.Count() > 0
      lineOneData.descriptorCode = contentNode.descriptors.join(", ") ' To DO : When when we get real values into TAGS
    end if
    lineOneData.releaseDate = contentNode.ReleaseDate
    lineOneData.hoursOfAiring = contentNode.hoursOfAiring
    m.InfoPanel.lineOneData = lineOneData
    m.InfoPanel.genres = [contentNode.genre]
  end if
  m.InfoPanel.calculateHeight = true
End Function



Function onTimeContentChange()
  tubiLog("EPGHomeScreen.onTimeContentChange")
  if m.top.timeGridContent <> invalid
    m.epgTimeGrid.content = m.top.timeGridContent
    m.epgTimeGrid.contentUpdated = true
    m.top.contentReady = true
  end if
End Function


Function onLinearChannelToPlay(msg)
  tubiLog("EPGHomeScreen.onLinearChannelToPlay")
  linearChannelupdated = msg.getData()
  if linearChannelupdated = true
    linearChannelToPlay = m.epgTimeGrid.linearChannelToPlay

    col = 1
    row = 1
    if m.epgTimeGrid <> invalid and m.epgTimeGrid.rowItemFocused <> invalid and m.epgTimeGrid.rowItemFocused.Count() > 0
      col = m.epgTimeGrid.rowItemFocused[1] + 1
      row = m.epgTimeGrid.rowItemFocused[0] + 1
    end if

    if linearChannelToPlay <> invalid
      m.top.trackingComponentInfo = {
        componentType : "epg_component"
        componentValues : {
          content_tile : m.Tracking.getAnalyticsTile(linearChannelToPlay, col, row)
        }
      }

      if m.top.linearChannelToPlay = invalid or (m.top.linearChannelToPlay <> invalid and linearChannelToPlay <> invalid and m.top.linearChannelToPlay.id <> linearChannelToPlay.id )
        m.top.linearChannelToPlay = linearChannelToPlay
        m.top.backgroundUriList = determineBackgroundImage(linearChannelToPlay)
      end if
    end if
  end if

End Function


' When OK has been pressed on EPG TimeGrid, maximize the player.
Function onEPGTimegridOKPressed()
  if m.top.linearChannelToPlay <> invalid and m.epgTimeGrid.linearChannelFocused <> invalid and m.epgTimeGrid.linearChannelFocused.id = m.top.linearChannelToPlay.id
    m.top.epgScreenOkPressed = true
  end if
End Function



' @selectedContent: TubiContentNode with metadata for an item in the epg
Function determineBackgroundImage(selectedContent)
  if selectedContent <> invalid and selectedContent.backgrounds <> invalid and selectedContent.backgrounds.count() > 0
    return selectedContent.backgrounds
  else
    return [m.defaultBackgroundUri]
  end if
End Function


Function onTransportVoiceRequest(msg)
  response = "unhandled"
  inputInfo = msg.getData()
  command = ""
  if inputInfo <> invalid and inputInfo.command <> invalid
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
    if m.top.enableTopNav = true
      if key = "back"
        if  m.TopNav.isInFocusChain() = false
        setFocusOntoTopNav(true)
        return true
      else
        if m.TopNav.selectedIndex = 0
          ' first item in top nav has focus, prepare for the side nav to gain focus
          m.top.topNavToggled = false
          m.top.navigatedAwayFromTopNav = true

          setTopNavUi(m.epgTimeGrid.currFocusRow)
          fadeInContentArea()

          ' return false so contentController screen stack can use the back button press
          ' to focus on the side nav
          return false
        else
          m.top.topNavItemSelected = m.TopNav.content.getChild(0)

          ' return false so contentController can use the back button press to trigger
          ' screen stack functionality
          return false
          end if
        end if
      else if key = "up" and m.TopNav.isInFocusChain() = false
        setFocusOntoTopNav(true)
        return true
      else if key = "down" and m.TopNav.isInFocusChain() = true
        setFocusOnepgTimeGrid()
        return true
      else if key = "left"
        ' navigating to the side nav
        if m.TopNav.isInFocusChain() = true
          ' navigating to the side nav from the top nav specifically
          m.top.topNavToggled = false
          m.top.navigatedAwayFromTopNav = true

          setTopNavUi(m.epgTimeGrid.currFocusRow)
          fadeInContentArea()

          return false
        end if
      end if
    end if
    if key = "play" and m.epgTimeGrid.isInFocusChain() = true
      handlePlayInput()
      return true
    end if
  end if
  return false
End Function



Function setFocusOntoTopNav(isToggle)
  tubiLog("EPGHomeScreen.setFocusOntoTopNav")
  if isToggle = true
    m.top.topNavToggled = true
  else
    m.TopNav.handlingFocusFromOtherTopNavBackButton = true
  end if

  m.top.refreshEPGScreenVideoPlay = true
  m.topNav.uiState = "focused"
  m.topNav.setFocus(true)
  fadeOutContentArea()
End Function


Function setFocusOnepgTimeGrid()
  tubiLog("EPGHomeScreen.setFocusOnepgTimeGrid ")
  'setting this field to false will trigger the focused channel to play in minimized window
  if m.topNav.isInFocusChain()
    ' only send top nav toggle event if the top nav is losing focus
    m.top.topNavToggled = false
  end if

  ' is necessary to set the uiState before the focus, so the topNav itemContents
  ' can have the appropriate color values set once they react to the focus change
  setTopNavUi(m.epgTimeGrid.currFocusRow)
  m.epgTimeGrid.setFocusedToPlay = true

  fadeInContentArea()
  m.epgTimeGrid.setFocus(true)
  m.top.refreshEPGScreenVideoPlay = false
End Function


' The top nav has changed selection, so change the contentSelected so the helper can change things accordingly
Function onTopNavSelection()
  tubiLog("EPGHomeScreen.onTopNavSelection")
  m.top.trackingComponentInfo = m.TopNav.trackingComponentInfo
  m.top.topNavItemSelected = m.TopNav.selected
End Function



Function onRefreshTopNav()
  tubiLog("EPGHomeScreen.onRefreshTopNav")
  m.topNav.content = generateTopNavContentItems()
  m.topNav.contentUpdated = true
  m.TopNav.uiState = "unfocusedNear"
End Function


' This function does not check for focus. Any checks needed to determine if top nav has
' focus or not should be done prior to calling this function.
'
' @focusRowIndex: integer, the 0 based index of the row that is focused
Function setTopNavUi(focusRowIndex)
  tubilog("EPGHomeScreen.setTopNavUi")
  if focusRowIndex = 0
    m.topNav.uiState = "unfocusedNear"
  else
    m.topNav.uiState = "unfocusedFar"
  end if
End Function


' The top nav has changed selection, so change the contentSelected so the helper can change things accordingly
Function onTopNavBackItemSelected()
  tubiLog("EPGHomeScreen.onTopNavBackItemSelected")

  '//Set trackingComponentInfo before setting contentSelected so the proper selected analytics is tracked within the screenStack
  if m.TopNav.backItemSelected <> invalid
    m.top.trackingComponentInfo = m.TopNav.trackingComponentInfo
  end if

  ' so that any adjustments to the menu item don't trigger callbacks. We want m.top.topNavbackItemSelected
  ' to also be set to invalid for the same reason.
  m.top.topNavbackItemSelected = m.TopNav.backItemSelected
End Function


' @includeLinearTV: boolean, true if a linear TV item should be included
Function generateTopNavContentItems(includeLinearTV = false)
  menuItemIds = [
    m.constants.ui.sideNavIds.home
    m.constants.ui.sideNavIds.movies
    m.constants.ui.sideNavIds.tv
    m.constants.ui.sideNavIds.linearEPG
  ]

  parent = CreateObject("roSGNode", "ContentNode")
  for each id in menuItemIds
    item = parent.createChild("TopNavContentNode")
    item.id = id

    if id = m.constants.ui.sideNavIds.home
      item.title = getTranslation("menu_foryou")
    else if id = m.constants.ui.sideNavIds.movies
      item.title = getTranslation("menu_movies")
    else if id = m.constants.ui.sideNavIds.tv
      item.title = getTranslation("menu_tv")
    else if id = m.constants.ui.sideNavIds.linearEPG
      item.title = getTranslation("menu_livetv")
    end if
  end for

  return parent
End Function


' Determine how far away the topNav is from the focus in the EPGGrid
'@row: integer, the row of the epgTimeGrid that is gaining focus
Function setTopNavFarAwayStatus(row)
  if m.TopNav.visible = true and (m.TopNav.hasFocus() = false and m.TopNav.isInFocusChain() = false)
    setTopNavUi(row)
  end if
End Function


Function onCurrFocusRowChange()
  'set the faraway focus for top nav
  setTopNavFarAwayStatus(m.epgTimeGrid.currFocusRow)
End Function


Function onTimeGridRefreshTimer()
  tubiLog("EPGHomeScreen.onTimeGridRefreshTimer")
  m.top.loadAllChannels = true
End Function


' The top nav will dispatch a navigateWithinPageInfo event which needs to be re-dispatched to the epgscreenHelpers
Function onTopNavNavigateWithinPageInfoChange()
  navigateWithinPageInfo = m.topNav.navigateWithinPageInfo
  if navigateWithinPageInfo <> invalid and navigateWithinPageInfo.means_of_navigation = "BUTTON"
    '//The navigateWithinPageInfo is caused by the user going from the EPG to the Top Nav.
    '//Before navigateWithinPageInfo is communicated to the outside helper, add info about the EPG
    epgComponentInfo = getTrackingComponentInfoOfEPGGridList(m.epgTimeGrid.itemFocused, m.epgTimeGrid.rowItemfocused)

    if epgComponentInfo <> invalid and epgComponentInfo.componentValues <> invalid
      navigateWithinPageInfo.componentOneof = m.Tracking.getAnalyticsComponent("category_component", epgComponentInfo.componentValues)
    end if
  end if
  ' this field is inherited by basescreen
  m.top.navigateWithinPageInfo = navigateWithinPageInfo

End Function


' @timegridItem: roSGNode, TubiContentNode with metadata for an item in the grid
' @itemPosition: array, 2d array with [x,y] grid coordinate information
Function getTrackingComponentInfoOfEPGGridList(timegridItem, itemPosition)
  trackingComponentInfo = {}
  if timegridItem <> invalid and itemPosition <> invalid and itemPosition.Count() = 2
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
