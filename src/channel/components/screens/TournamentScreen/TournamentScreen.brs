Function init()
  tubiLog("TournamentScreen.init")
  m._ = rodash()
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.mask = m.top.findNode("mask")

  'infoPanel
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.InfoPanelParent = m.top.findNode("InfoPanelParent")

  'topNav
  m.TopNav = m.top.findNode("TopNav")
  m.topNav.selectedId = m.constants.ui.sideNavIds.tournament
  m.TopNav.observeFieldScoped("selected", "onTopNavSelection")
  m.TopNav.observeFieldScoped("backItemSelected", "onTopNavBackItemSelected")
  m.TopNav.observeFieldScoped("navigateWithinPageInfo", "onTopNavNavigateWithinPageInfoChange")
  m.topnav.doesSelectionNavigate = true

  'epgTimeGrid
  m.epgTimeGrid = m.top.findNode("programGuide")
  m.epgTimeGrid.observeFieldScoped("linearChannelFocusedUpdated", "onLinearChannelFocused")
  m.epgTimeGrid.observeFieldScoped("linearChannelToPlayUpdated", "onLinearChannelToPlay")
  m.epgTimeGrid.observeFieldScoped("okPressed","onEPGTimegridOKPressed")
  m.epgTimeGrid.EPGChannelPlayMode = m.constants.EPGChannelPlayMode.playItemOnFocus
  m.epgTimeGrid.EPGFullMode = true

  'categoryGridList
  m.categoryGridList = m.top.findNode("categoryGridList")
  m.categoryGridList.observeFieldScoped("itemSelected", "onGridItemSelected")
  m.categoryGridList.observeFieldScoped("itemFocused", "onGridItemFocused")
  m.categoryGridList.observeFieldScoped("currFocusRow", "onCurrFocusRow")
  'This variable will be used in animation of epg to category Grid list and visa versa.
  m.numRowsInCategoryGridList = 0

  'm.top
  m.top.observeFieldScoped("transportVoiceRequest", "onTransportVoiceRequest")
  m.top.observeFieldScoped("refreshTopNav", "onRefreshTopNav")
  m.top.observeFieldScoped("fullscreenCountdown", "onFullscreenCountdown")
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("contentUpdated", "onContentUpdated")
  m.top.observeFieldScoped("isPreTournament", "onPreTournament")
  m.top.observeFieldScoped("setForceRefreshCategoryContainers", "onForceRefreshCategoryContainers")
  m.top.screenLevel = m.constants.ui.screenLevels.tournamentScreen
  m.defaultBackgroundUri = "pkg:/images/art-blur-background.png"
  m.top.backgroundUriList = [m.defaultBackgroundUri]
  m.top.handlesTransportVoiceRequests = true
  'set initial tracking values and change thevalues once the document is ready
  m.top.trackingPageInfo = {
    pageType: "worldcup_browse_page"
    pageValues: {}
  }
  m.epgTimeGrid.trackingPageInfo = m.top.trackingPageInfo
  m.topNav.trackingPageInfo = m.top.trackingPageInfo

  'TournamentRefreshTimer : Not sure if needed depending on refreshtime discussion
  m.TournamentRefreshTimer = m.top.findNode("TournamentRefreshTimer")
  'If TournamentRefreshTimer needs to be different than categoryContentRefreshTimeout then we need to add a constant
  m.TournamentRefreshTimer.duration = m.constants.timers.categoryContentRefreshTimeout
  m.TournamentRefreshTimer.observeField("fire", "onTournamentRefreshTimer")
  m.TournamentRefreshTimer.control = "start"
End function


Function onPreTournament()
  tubilog("TournamentScreen.onPreTournament")
  if m.top.isPreTournament = true
    m.epgTimeGrid.translation = "[192,550]"
    m.categoryGridList.translation = "[192,880]"
    m.top.focusedComponent = m.constants.ui.tournamentScreen.focusItems.epgTimeGrid
  else
    m.epgTimeGrid.translation = "[192,938]"
    m.categoryGridList.translation ="[192,550]"
    m.top.focusedComponent = m.constants.ui.tournamentScreen.focusItems.categoryGridList
  end if

  m.originalEPGTranslation = m.epgTimeGrid.translation
  m.originalCategoryGridListTranslation = m.categoryGridList.translation
End Function


' The top nav has changed selection, so change the contentSelected so the helper can change things accordingly
Function onTopNavSelection()
  tubiLog("TournamentScreen.onTopNavSelection")

  '//Set trackingComponentInfo before setting contentSelected so the proper selected analytics is tracked within the screenStack
  m.top.trackingComponentInfo = m.TopNav.trackingComponentInfo
  m.top.topNavItemSelected = m.TopNav.selected
End Function


Function onRefreshTopNav()
  tubiLog("TournamentScreen.onRefreshTopNav")
  includeLinearTV = m.top.isLinearTVAllowedInTopNav
  m.topNav.content = generateTopNavContentItems(includeLinearTV)
  m.topNav.contentUpdated = true
  m.TopNav.uiState = "unfocusedNear"
End Function


' The top nav has changed selection, so change the contentSelected so the helper can change things accordingly
Function onTopNavBackItemSelected()
  tubiLog("TournamentScreen.onTopNavBackItemSelected")

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
  tubilog("TournamentScreen.generateTopNavContentItems")

  if includeLinearTV = true
    menuItemIds = [
      m.constants.ui.sideNavIds.home
      m.constants.ui.sideNavIds.movies
      m.constants.ui.sideNavIds.tv
      m.constants.ui.sideNavIds.linearEPG
      m.constants.ui.sideNavIds.tournament
    ]
  else
    menuItemIds = [
      m.constants.ui.sideNavIds.home
      m.constants.ui.sideNavIds.movies
      m.constants.ui.sideNavIds.tv
      m.constants.ui.sideNavIds.tournament
    ]
  end if

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
    else if id = m.constants.ui.sideNavIds.linearTV
      item.title = getTranslation("menu_livetv")
    else if id = m.constants.ui.sideNavIds.linearEPG
      item.title = getTranslation("menu_livetv")
    else if id = m.constants.ui.sideNavIds.tournament
      item.title = getTranslation("menu_tournament", {"tradeMark": chr(8482)})
      item.subText = getTranslation("text_new")
    end if
  end for

  return parent
End Function


Function onLinearChannelFocused()
  tubiLog("TournamentScreen.onLinearChannelFocused")

  if m.epgTimeGrid <> invalid
    content = m.epgTimeGrid.linearChannelFocused

    if content <> invalid AND content.title <> invalid
      m.top.linearChannelFocused = content
      populateInfoPanel(m.epgTimeGrid.linearChannelFocused)
    end if
  end if
End Function


'@focusedContent: node, focused content whose information to be displayed on infopanel
Function populateInfoPanel(focusedContent)
  tubiLog("TournamentScreen.populateInfoPanel")

  if focusedContent <> invalid
    if focusedContent.type = m.constants.ui.categoryTypes.linear
      m.InfoPanel.mode = m.constants.ui.infoPanelModes.linearTournament
      m.InfoPanel.title = focusedContent.title
      m.InfoPanel.description = focusedContent.description
      m.InfoPanel.width = 650

      lineOneData = {}
      lineOneData.rating = focusedContent.rating
      lineOneData.hasCC = focusedContent.hasSubtitles
      lineOneData.releaseDate = focusedContent.ReleaseDate
      lineOneData.hoursOfAiring = focusedContent.hoursOfAiring

      if focusedContent.highestRendition = m.constants.serverValues.tensorVideoRenditions.fourK
        lineOneData.has4k = true
      end if

      if focusedContent.descriptors <> invalid AND focusedContent.descriptors.Count() > 0
        lineOneData.descriptorCode = focusedContent.descriptors.join(", ") ' To DO : When when we get real values into TAGS
      end if

      m.InfoPanel.lineOneData = lineOneData
      m.InfoPanel.needsLogin = (focusedContent.needsLogin AND m.top.signedIn <> true)
      m.top.backgroundUriList = determineBackgroundImage(focusedContent.getparent())
    else if focusedContent.type = m.constants.ui.contentTypes.sportsEvent
      populateInfoPanelWithHomescreenStyleSportsMode(focusedContent, m.InfoPanel)
    else if focusedContent.type = m.constants.ui.contentTypes.video OR focusedContent.type = m.constants.ui.contentTypes.series
      populateInfoPanelWithHomescreenStyleItemMode(focusedContent, m.InfoPanel)
      m.top.backgroundUriList = determineBackgroundImage(focusedContent)
    else
      m.top.backgroundUriList = determineBackgroundImage(focusedContent)
    end if
    m.InfoPanel.calculateHeight = true
  end if
End Function


Function onFullscreenCountdown()
  m.InfoPanel.fullscreenCountdown = m.top.fullscreenCountdown
End Function


' When OK has been pressed on EPG TimeGrid, maximize the player.
Function onEPGTimegridOKPressed()
  tubilog("TournamentScreen.onEPGTimegridOKPressed")
  if m.top.linearChannelToPlay <> invalid AND m.epgTimeGrid.linearChannelFocused <> invalid AND m.epgTimeGrid.linearChannelFocused.id = m.top.linearChannelToPlay.id
    m.top.tournamentScreenEPGOkPressed = true
  end if
End Function


Function onGridItemFocused()
  tubilog("TournamentScreen.onGridItemFocused")

  if m.CategoryGridList.isInFocusChain() = true
    focusedContent = m.CategoryGridList.itemFocused

    if focusedContent <> invalid
      m.top.contentFocused = focusedContent
      sendNavigateWithinPageEvent()
      populateInfoPanel(focusedContent)
    end if
  end if
End Function


' Determine how far away the topNav is from the focus in the categoryGridList
'@row: integer, the row of the categoryGridList that is gaining focus
Function setTopNavFarAwayStatus(row)
  tubilog("TournamentScreen.setTopNavFarAwayStatus")

  if m.TopNav.visible = true AND (m.TopNav.hasFocus() = false AND m.TopNav.isInFocusChain() = false)
    setTopNavUi(row)
  end if
End Function


' The top nav will dispatch a navigateWithinPageInfo event which needs to be re-dispatched to the tournamentScreenHelpers
Function onTopNavNavigateWithinPageInfoChange()
  tubiLog("TournamentScreen.onTopNavNavigateWithinPageInfoChange")
  navigateWithinPageInfo = m.TopNav.navigateWithinPageInfo
  if navigateWithinPageInfo <> invalid AND navigateWithinPageInfo.means_of_navigation = "BUTTON"
    '//The navigateWithinPageInfo is caused by the user going from the video categoryGridList or EPG to the Top Nav.
    '// it can be categoryGridList or EPG depending on pretourament or during/post tournament.
    '//Before navigateWithinPageInfo is communicated to the outside helper, add info about the categoryGridList
    if m.top.focusedComponent = m.constants.ui.tournamentScreen.focusItems.categoryGridList
      categoryComponentInfo = getTrackingComponentInfoOfCategoryGridList(m.categoryGridList.itemFocused, m.categoryGridList.focusedPosition)

      if categoryComponentInfo <> invalid AND categoryComponentInfo.componentValues <> invalid
        navigateWithinPageInfo.componentOneof = m.Tracking.getAnalyticsComponent("category_component", categoryComponentInfo.componentValues)
      end if
    else if m.top.focusedComponent = m.constants.ui.tournamentScreen.focusItems.epgTimeGrid
      epgComponentInfo = getTrackingComponentInfoOfEPGGridList(m.epgTimeGrid.linearChannelFocused, m.epgTimeGrid.rowItemfocused)

      if epgComponentInfo <> invalid AND epgComponentInfo.componentValues <> invalid
        navigateWithinPageInfo.componentOneof = m.Tracking.getAnalyticsComponent("epg_component", epgComponentInfo.componentValues)
      end if
    end if
  end if
  m.top.navigateWithinPageInfo = navigateWithinPageInfo
End Function


' @isToggle: boolean, true if the user is toggling focus to the top nav from a different component.
'                     false if the user is focusing the default top nav option by pressing back
'                     while focused on the top nav of another page
Function setFocusOntoTopNav(isToggle)
  tubiLog("TorunamentScreen.setFocusOntoTopNav")
  if isToggle = true
    ' only send top nav toggle event if the top nav is gaining focus from the category grid list.
    ' Do not set top nav toggle event if the top nav is gaining focus from another page.
    m.top.topNavToggled = true
  else
    ' setting handlingFocusFromOtherTopNavBackButton to true before calling setTopNavUi() informs
    ' the top nav not to send a NavigateWithinPageEvent when jumping focus. We immediately
    ' reset the value back to false after setTopNavUi() is called so that the default value
    ' is in place as soon as possible, with the understanding that the top nav behavior will
    ' fully resolve before continuing on with further logic within this function.
    m.TopNav.handlingFocusFromOtherTopNavBackButton = true
  end if

  if getExperimentResource("roku_video_preview", "roku_video_preview_v2", false).enabled = true
    m.top.stopVideoPreview = true
  end if

  ' is necessary to set the uiState before the focus, so the topNav itemContents
  ' can have the appropriate color values set once they react to the focus change
  m.TopNav.uiState = "focused"

  m.TopNav.setFocus(true)
  m.TopNav.handlingFocusFromOtherTopNavBackButton = false

  m.top.refreshtournamentScreenVideoPlay = true
  fadeOutContentArea()
End Function


Function onLinearChannelToPlay(msg)
  tubiLog("TournamentScreen.onLinearChannelToPlay")
  linearChannelupdated = msg.getData()
  if linearChannelupdated = true
    linearChannelToPlay = m.epgTimeGrid.linearChannelToPlay

    'as per analytics doc
    col = 1
    row = 1

    if linearChannelToPlay <> invalid
      m.top.trackingComponentInfo = {
        componentType : "epg_component"
        componentValues : {
          content_tile : m.Tracking.getAnalyticsTile(linearChannelToPlay, col, row)
        }
      }

      m.top.linearChannelToPlay = linearChannelToPlay
      m.top.backgroundUriList = determineBackgroundImage(linearChannelToPlay)
    end if
  end if

End Function



' This function does not check for focus. Any checks needed to determine if top nav has
' focus or not should be done prior to calling this function.
'
' @focusRowIndex: integer, the 0 based index of the row that is focused
Function setTopNavUi(focusRowIndex)
  if focusRowIndex = 0
    m.topNav.uiState = "unfocusedNear"
  else
    m.topNav.uiState = "unfocusedFar"
  end if
End Function


Function onContentUpdated()
  tubilog("TournamentScreem.onContentUpdated")

  if m.top.content <> invalid

    if m.top.content.getChild(0) <> invalid
      epgRow = m.top.content.getChild(0).clone(true)
      timeGridContent = epgRow
      if timeGridContent <> invalid
        if timeGridContent.getChild(0) <> invalid
          timeGridContent.getChild(0).parentTitle = timeGridContent.getChild(0).channelName
        end if
        m.epgTimeGrid.content = timeGridContent
        m.epgTimeGrid.contentUpdated = true
      end if
    end if

    if m.top.content.getChild(1) <> invalid
      m.top.categoryContent = m.top.content.getChild(1).clone(true)
      m.numRowsInCategoryGridList = m.top.categoryContent.getChildCount() - 1
      m.categoryGridList.content = m.top.categoryContent
      m.categoryGridList.signedIn = m.top.signedIn
      m.categoryGridList.visible = true
      m.categoryGridList.contentUpdated = true
    end if

    m.infoPanel.visible = true
    m.top.contentReady = true
  end if

End Function


Function onScreenFocusChange()
  tubiLog("TournamentScreen.onScreenFocusChange")

  if m.top.hasFocus() = true
    if shouldRefresh(m.top.content) = true
      m.top.reloadTournamentScreen = true 'refresh entire screen
    else
      refreshCategoryContainers() 'just refresh the container which has expired
    end if

    if m.top.componentToFocus = m.constants.ui.tournamentScreen.focusItems.topNav
      setFocusOntoTopNav(false)
      'set previously playing channel's background
      if m.top.focusedComponent = m.constants.ui.tournamentScreen.focusItems.epgTimeGrid
        m.top.backgroundUriList = determineBackgroundImage(m.epgTimeGrid.linearChannelFocused)
      else
        m.top.backgroundUriList = determineBackgroundImage(m.top.contentFocused)
      end if

    else if m.top.focusedComponent = m.constants.ui.tournamentScreen.focusItems.epgTimeGrid then
      setFocusOnEPGTimeGrid()
    else
      setFocusOnCategoryGrid()
    end if

    if m.top.isPreTournament = true
      m.top.componentToFocus = m.constants.ui.tournamentScreen.focusItems.epgTimeGrid
    else
      m.top.componentToFocus = m.constants.ui.tournamentScreen.focusItems.categoryGridList
    end if

    m.top.shouldFocusWhenPushed = true

  else if m.top.isInFocusChain() = false
      m.top.refreshtournamentScreenVideoPlay = true
      fadeInContentArea()
  end if
End Function


Function setFocusOnEPGTimeGrid()
  tubiLog("TournamentScreen.setFocusOnEPGTimeGrid ")
  'setting this field to false will trigger the focused channel to play in minimized window
  if m.topNav.isInFocusChain() = true
    ' only send top nav toggle event if the top nav is losing focus
    m.top.topNavToggled = false
  end if

  ' is necessary to set the uiState before the focus, so the topNav itemContents
  ' can have the appropriate color values set once they react to the focus change
  if m.top.isPreTournament = true
    setTopNavUi(0)
  else
    setTopNavUi(1)
  end if

  fadeInContentArea()
  m.top.focusedComponent = m.constants.ui.tournamentScreen.focusItems.epgTimeGrid
  m.epgTimeGrid.setFocus(true)
  m.top.refreshtournamentScreenVideoPlay = false
  m.epgTimeGrid.opacity = 1
  m.categoryGridList.visible = true
End Function


Function componentDownAnimation()
  if m.top.isPreTournament = true
    slideTo(m.categoryGridList, m.originalEPGTranslation, 0.15,0)
    slideFade(m.epgTimeGrid, "above", "out", 0.15, 0)
  else
    slideTo(m.epgTimeGrid, m.originalCategoryGridListTranslation , 0.15, 0)
    slideFade(m.categoryGridList, "above", "out", 0.15, 0)
  end if
End Function


Function componentUPAnimation()
  if m.top.isPreTournament = true
    slideTo(m.categoryGridList, m.originalCategoryGridListTranslation, 0.15,0)
    slideFade(m.epgTimeGrid, "above", "in", 0.15, 0)
  else
    slideTo(m.epgTimeGrid, m.originalEPGTranslation, 0.15, 0)
    slideFade(m.categoryGridList, "above", "in", 0.15, 0)
  end if
End Function


Function setFocusOnCategoryGrid()
  tubiLog("TournamentScreen.setFocusOnCategoryGrid")
  if m.topNav.isInFocusChain() = true
    ' only send top nav toggle event if the top nav is losing focus
    m.top.topNavToggled = false
    m.topNav.losingFocusToComponentOnSamePage = true
    fadeInContentArea()
  end if

  if m.top.isPreTournament = true
    setTopNavUi(1)
  else
    setTopNavUi(int(m.categoryGridList.currFocusRow))
    m.topNav.losingFocusToComponentOnSamePage = false
  end if

  m.top.focusedComponent = m.constants.ui.tournamentScreen.focusItems.categoryGridList
  m.categoryGridList.setFocus(true)
  m.categoryGridList.opacity = 1
  m.top.refreshtournamentScreenVideoPlay = true
End Function


' @selectedContent: TubiContentNode with metadata for an item in the epg/game
Function determineBackgroundImage(selectedContent)
  if selectedContent <> invalid AND selectedContent.backgrounds <> invalid AND selectedContent.backgrounds.count() > 0
    return selectedContent.backgrounds
  else
    return [m.defaultBackgroundUri]
  end if
End Function


Function fadeInContentArea()
  stopAnimation(m.gridFade)
  if m.mask.opacity <> 0
    m.gridFade = fade(m.mask, "in", .4, 0.0, 0.1)
  end if

  stopAnimation(m.infoPanelFade)
  if m.InfoPanelParent.opacity < 1
    m.infoPanelFade = fade(m.InfoPanelParent, "in", .4, 0.0, 1)
  end if
End Function


Function fadeOutContentArea()
  stopAnimation(m.gridFade)
  if m.mask.opacity < 1
    m.gridFade = fade(m.mask, "out", .4, 0.0, 0.4)
  end if

  stopAnimation(m.infoPanelFade)
  if m.InfoPanelParent.opacity > 0
    m.infoPanelFade = fade(m.InfoPanelParent, "out", .4, 0.0, 0.4)
  end if
End Function


Function onGridItemSelected(msg)
  tubiLog("TournamentScreen.onGridItemSelected")
  itemSelected = msg.getData()
  if m.top.isLoading <> true
    m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(itemSelected, m.top.cursorPosition)
    if itemSelected <> invalid
      m.top.contentSelected = itemSelected
    end if
  end if
End function


Function onKeyEvent(key As string, press As boolean) As boolean
  tubiLog("TournamentScreen.onKeyEvent")
  if press
    if key = "back"
      if  m.TopNav.isInFocusChain() = false
        setFocusOntoTopNav(true)
        return true
      end if
    else if key = "up"
      if m.top.isPreTournament = true
        if m.epgTimeGrid.isInFocusChain() = true
          setFocusOntoTopNav(true)
          return true
        else if m.categoryGridList.isInFocusChain() = true
          componentUPAnimation()
          setFocusOnEPGTimeGrid()
          return true
        end if
      else
        if m.categoryGridList.isInFocusChain() = true
          setFocusOntoTopNav(true)
          setComponentInteractionEventForCategoryGrid("TOGGLE_OFF")
          return true
        else if m.epgTimeGrid.isInFocusChain() = true
          componentUPAnimation()
          setFocusOnCategoryGrid()
          setComponentInteractionEventForEPG("TOGGLE_OFF")
          setComponentInteractionEventForCategoryGrid("TOGGLE_ON")
          return true
        end if
      end if
    else if key = "down"
      if m.top.isPreTournament = true
        if m.TopNav.isInFocusChain() = true
          if m.top.focusedComponent = m.constants.ui.tournamentScreen.focusItems.epgTimeGrid
            setFocusOnEPGTimeGrid()
          else
            setFocusOnCategoryGrid()
          end if
          return true
        else if m.epgTimeGrid.isInFocusChain() = true
          componentDownAnimation()
          setFocusOnCategoryGrid()
          return true
        end if
      else
        if m.TopNav.isInFocusChain() = true
          if m.top.focusedComponent = m.constants.ui.tournamentScreen.focusItems.categoryGridList
            setFocusOnCategoryGrid()
            setComponentInteractionEventForCategoryGrid("TOGGLE_ON")
          else
            setFocusOnEPGTimeGrid()
            setComponentInteractionEventForEPG("TOGGLE_ON")
          end if
          return true
        else if m.categoryGridList.isInFocusChain() = true
          componentDownAnimation()
          setFocusOnEPGTimeGrid()
          setComponentInteractionEventForCategoryGrid("TOGGLE_OFF")
          setComponentInteractionEventForEPG("TOGGLE_ON")
          return true
        end if
      end if

    else if key = "left"
      ' navigating to the side nav
      if m.TopNav.isInFocusChain() = true
        ' navigating to the side nav from the top nav specifically
        m.top.topNavToggled = false
        m.top.navigatedAwayFromTopNav = true
      '  fadeInContentArea()
        return false
      end if
    end if
  end if

  if key = "play"
    handlePlayInput()
    return true
  end if

  return false
End Function


Function onCurrFocusRow(msg)
  'tubilog("TournamentScreen.onCurrFocusRow")
  if m.top.isPreTournament = false
    curRow = msg.getData()
    setTopNavFarAwayStatus(Int(curRow))
    if curRow > m.numRowsInCategoryGridList - 0.5
      m.epgTimeGrid.opacity = 1
    else if curRow < m.numRowsInCategoryGridList AND m.top.focusedComponent <> m.constants.ui.tournamentScreen.focusItems.epgTimeGrid
      m.epgTimeGrid.opacity = 0
    end if
  end if

End Function


' @gridItem: roSGNode, TubiContentNode with metadata for an item in the grid
' @itemPosition: array, 2d array with [x,y] grid coordinate information
Function getTrackingComponentInfoOfCategoryGridList(gridItem, itemPosition)
  tubilog("tournamentScreen.getTrackingComponentInfoOfCategoryGridList")
  trackingComponentInfo = {}
  if gridItem <> invalid AND itemPosition <> invalid AND itemPosition.Count() = 2
    componentValues = {}
    componentValues["category_slug"] = m.top.currCategoryId
    componentValues["category_row"] = itemPosition[0] + 1 'all analytics are 1 based
    tile = m.Tracking.getAnalyticsTile(gridItem, itemPosition[1] + 1)
    componentValues["content_tile"] = tile


    ' Set the tracking component of the gridItem that was passed so it can be accessed as part of the navigateToPage event
    trackingComponentInfo = {
      componentType: "category_component"
      componentValues: componentValues
    }
  end if

  return trackingComponentInfo
End Function


Function sendNavigateWithinPageEvent()
  tubilog("TournamentScreen.sendNavigateWithinPageEvent")

  if m.top.focusedComponent = m.constants.ui.tournamentScreen.focusItems.categoryGridList
    oldAnalyticsRow = m.CategoryGridList.oldCursorPosition[0] + 1
    oldAnalyticsCol = m.CategoryGridList.oldCursorPosition[1] + 1

    newAnalyticsRow = m.CategoryGridList.cursorPosition[0] + 1
    newAnalyticsCol = m.CategoryGridList.cursorPosition[1] + 1

    oldFocusedContent = m.CategoryGridList.oldItemFocused
    categorySlug = m.CategoryGridList.oldCategoryId

    if m.top.isPreTournament = true
      oldAnalyticsRow = m.CategoryGridList.oldCursorPosition[0] + 2 'epg is first row
      newAnalyticsRow = m.CategoryGridList.cursorPosition[0] + 2  ' epg is first row
      if oldAnalyticsCol = 0
        oldAnalyticsCol = 1
        if m.epgTimeGrid.linearChannelToPlay <> invalid
          oldFocusedContent = m.epgTimeGrid.linearChannelToPlay
          categorySlug = m.epgTimeGrid.linearChannelToPlay.channelName ' TODO ONCE We know what is epg slug going to be
        end if
      end if
    end if

    if oldAnalyticsRow > 0 AND oldAnalyticsCol > 0 AND (oldAnalyticsRow <> newAnalyticsRow OR oldAnalyticsCol <> newAnalyticsCol)

      categoryComponentInfo = {}
      categoryComponentInfo["category_slug"] = categorySlug
      categoryComponentInfo["category_row"] = oldAnalyticsRow
      tile = m.Tracking.getAnalyticsTile(oldFocusedContent, oldAnalyticsCol, 1)
      categoryComponentInfo["content_tile"] = tile

      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("category_component", categoryComponentInfo)
        means_of_navigation: "BUTTON" 'MeansOfNavigation enum
        vertical_location: newAnalyticsRow
        vertical_location_mode: "INDEX" 'LocationMode enum
        horizontal_location: newAnalyticsCol
        horizontal_location_mode: "INDEX" 'LocationMode enum
      }
    end if
  end if
End Function


Function onTransportVoiceRequest(msg)
  tubilog("TournamentScreen.onTransportVoiceRequest")
  response = "unhandled"
  inputInfo = msg.getData()
  command = ""
  if inputInfo <> invalid AND inputInfo.command <> invalid
    command = inputInfo.command
  end if
  tubiLog("TorunamentScreen.onTransportVoiceRequest " + command)
    ' Only replays/noteworty content and FIFA channel can be played.
  if m.epgTimeGrid.isInFocusChain() = true OR (m.categoryGridList.isInFocusChain() = true AND m.top.contentFocused.Type = "sports_event" AND m.top.contentFocused.availabilityType <> m.constants.ui.contentTimings.upcoming)
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
  tubilog("TournamentScreen.handlePlayInput ")
  if m.epgTimeGrid.isInFocusChain() = true
    if m.epgTimeGrid.linearChannelFocused <> invalid
      ' In EPG case both voice commands "play" and "ok" will play the content in full screen.
      onEPGTimegridOKPressed()
      'May not be required ?
    '  m.top.trackingComponentInfo = getTrackingComponentInfoOfEPGGridList(m.epgTimeGrid.linearChannelFocused.getParent(), m.epgTimeGrid.rowItemfocused)
    end if
  else if m.categoryGridList.isInFocusChain() = true
    if m.top.contentFocused <> invalid
      m.top.contentToPlay = m.top.contentFocused
      m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(m.top.contentFocused, m.top.cursorPosition)
    end if
  end if
End Function


' @timegridItem: roSGNode, TubiContentNode with metadata for an item in the grid
' @itemPosition: array, 2d array with [x,y] grid coordinate information
Function getTrackingComponentInfoOfEPGGridList(timegridItem, itemPosition)
  tubilog("tournamentScreen.getTrackingComponentInfoOfEPGGridList")
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


Function onTournamentRefreshTimer()
  tubiLog("TournamentScreen.onCategoryRefreshTimer")
  m.top.reloadTournamentScreen = true
End Function


Function setComponentInteractionEventForEPG(userInteraction)
  content = m.EPGTimeGrid.linearChannelToplay
  rowNum = 1 'as per document
  colNum = 1 'as per document

  if content <> invalid
    componentValues = {
      content_tile: m.Tracking.getAnalyticsTile(content, colNum, rowNum)
    }

    pageType = ""
    if m.top.trackingPageInfo <> invalid AND m.top.trackingPageInfo.pagetype <> invalid
      pageType = m.top.trackingPageInfo.pagetype
    end if

    pageValues = {}
    if m.top.trackingPageInfo <> invalid AND m.top.trackingPageInfo.pageValues <> invalid
      pageValues = m.top.trackingPageInfo.pageValues
    end if
    componentInteractionInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent("epg_component",  componentValues)
      user_interaction: userInteraction
    }

    m.top.componentInteractionInfo = componentInteractionInfo
  end if
End Function


Function setComponentInteractionEventForCategoryGrid(userInteraction)

  if m.CategoryGridList.itemFocused <> invalid AND m.categoryGridList.focusedPosition <> invalid

    componentInfo = getTrackingComponentInfoOfCategoryGridList(m.categoryGridList.itemFocused, m.categoryGridList.focusedPosition)

    pageType = ""
    if m.top.trackingPageInfo <> invalid AND m.top.trackingPageInfo.pagetype <> invalid
      pageType = m.top.trackingPageInfo.pagetype
    end if
    pageValues = {}
    if m.top.trackingPageInfo <> invalid AND m.top.trackingPageInfo.pageValues <> invalid
      pageValues = m.top.trackingPageInfo.pageValues
    end if

    componentInteractionInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent(componentInfo.componentType, componentInfo.componentValues)
      user_interaction: userInteraction
    }
    m.top.componentInteractionInfo = componentInteractionInfo
  end if
End Function


Function refreshCategoryContainers()
  tubilog("TournamentScreen.refreshCategoryContainers")
  if m.top.categoryContent <> invalid
    for i = 0 to m.top.categoryContent.getchildCount() - 1
      container = m.top.categoryContent.getChild(i)
      if shouldRefresh(container) = true
        m.top.reloadTournamentScreenContainerID = container.id
      end if
    end for
  end if

End Function


Function onForceRefreshCategoryContainers()
  refreshCategoryContainers()
End Function