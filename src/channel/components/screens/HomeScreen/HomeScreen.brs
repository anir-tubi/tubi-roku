Function init()
  tubiLog("HomeScreen.init")

  m._ = rodash()
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.ContentArea = m.top.findNode("ContentArea")
  m.NavSection = m.top.findNode("nav")
  m.TopNav = m.top.findNode("TopNav")
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.InfoPanelParent = m.top.findNode("InfoPanelParent")
  m.HintGroup = m.top.findNode("UpHintGroup")
  fades = m.top.findNode("Fades")
  m.HintGroupFade = fades.findNode("HintGroupFade")

  if getExperimentResource("roku_see_all_container", "roku_show_all_floating_education_v1", false).enabled = true
    m.seeAllNotificationGroup = m.top.findNode("seeAllNotificationGroup")
  end if

  m.experimentName = ""
  experimentResult = getExperimentResult("roku_see_all_container", "roku_see_all_container_first_v1")
  if experimentResult <> invalid
    m.experimentName = experimentResult.experiment_name
  end if

  experimentResult = getExperimentResult("roku_see_all_container", "roku_see_all_container_seventeen_v1")
  if experimentResult <> invalid
    m.experimentName = experimentResult.experiment_name
  end if

  experimentResult = getExperimentResult("roku_see_all_container", "roku_show_all_floating_education_v1")
  if experimentResult <> invalid
    m.experimentName = experimentResult.experiment_name
  end if

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
    '//REMOVE uiMode observer once the roku_see_all_container experiment is graduated
    m.global.observeFieldScoped("uiMode", "onUIMode")
  end if

  onThemeChange()
  '//REMOVE onUIMode() once the roku_see_all_container experiment is graduated
  onUIMode()

  ' this variable helps to identify whether the seeAll exposure event was fired or not.
  ' the reason for maintaining this variable is the 'onFireExposureEvent' function will be trigerred many times,
  ' but we don't want to fire exposure all times
  m.wasExposureEventForSeeAllFired = false

  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("signedIn", "onSignedInChange")
  m.top.observeField("categoryMenuVisible", "onCategoryMenuVisible")
  m.top.observeField("enabled", "onEnableChange")
  m.top.observeField("isLoading", "onLoadingChange")
  m.top.observeField("resetContentAreaValues", "onResetContentAreaValues")
  m.top.observeField("id", "onIDChange")
  m.top.observeField("fullscreenCountdown", "onFullscreenCountdown")
  m.top.observeField("enableTopNav", "onEnableTopNavChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")
  m.top.observeField("refreshTopNav", "onRefreshTopNav")

  m.TopNav.observeField("selected", "onTopNavSelection")
  m.TopNav.observeField("backItemSelected", "onTopNavBackItemSelected")
  m.TopNav.observeField("navigateWithinPageInfo", "onTopNavNavigateWithinPageInfoChange")

  m.CategoryRefreshTimer = m.top.findNode("CategoryRefreshTimer")
  m.CategoryRefreshTimer.duration = m.constants.timers.categoryContentRefreshTimeout
  m.CategoryRefreshTimer.observeField("fire", "onCategoryRefreshTimer")
  m.CategoryRefreshTimer.control = "start"

  'Content area
  m.CategoryGridList = m.top.findNode("CategoryGridList")
  m.CategoryGridList.observeField("itemSelected", "onGridItemSelected")
  m.CategoryGridList.observeField("itemFocused", "onGridFocusChange")
  m.CategoryGridList.observeField("reloadedItemToBeFocused", "onItemToBeFocusedChange")
  m.CategoryGridList.observeField("currFocusRow", "onCurrFocusRowChange")
  m.CategoryGridList.observeField("currFocusColumn", "onCurrFocusColumnChange")
  m.CategoryGridList.observeField("rowFocused", "onRowFocused")
  ' //REMOVE below observeField once the roku_see_all_container experiment is graduated
  m.CategoryGridList.observeField("fireExposureEventSeeAllExp", "onFireExposureEvent")

  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  'used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.gridHasGainedInitialFocus = false

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: ""
    pageValues: {}
  }

  m.topnav.doesSelectionNavigate = true

  m.top.handlesTransportVoiceRequests = true

  BackLabel = m.top.findNode("callToAction")
  BackLabel.text = getTranslation("goBack_menu")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if

  m.top.screenLevel = m.constants.ui.screenLevels.homeScreen

  ' lastFocusPosition holds the state of currFocusRow the last time onCurrFocusRow() occurred.
  ' It is reset to -1 at the conclusion of a grid scroll animation.
  m.lastFocusPosition = -1

  ' initialize the currentColumn variable to keep track of the current focused column item. It is used in the helper to stop the linear video player, but it could be used for other things.
  m.currentColumn = -1

  m.sponsorSlideAmt = 29 'the amount the grid slides up to fit the sponsored header. This is the difference of the heights of the sponsored and normal row titles
  m.sponsorMaskOffsetDiff = 29 'the diff in the amount the content area mask is offset in the up direction for sponsored rows. This is the difference of the heights of the sponsored and normal row titles
  m.linearSlideAmt = -115 'the amount the grid slides up to fit the linear content item
  m.linearMaskOffsetDiff = -99 'the diff in the amount the content area mask is offset in the up direction for the linear news container

  m.originalContentAreaTranslation = m.ContentArea.translation
  m.linearContentAreaTranslation = [m.ContentArea.translation[0], m.ContentArea.translation[1] - m.linearSlideAmt]
  m.originalContentAreaMaskOffset = m.ContentArea.maskOffset

  authInfo = m.global.authInfo

  if authInfo <> invalid AND authInfo.parentalrating <> invalid
    m.top.parentalRating = authInfo.parentalrating
  end if
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid AND m.seeAllNotificationGroup <> invalid
    m.seeAllNotificationGroup.blendColor = theme.neutralSolidColor2
    m.seeAllNotificationGroup.textColor = theme.backgroundColorLight
  end if
End Function


'//REMOVE onUIMode function once the roku_see_all_container experiment is graduated
Function onUIMode(msg = invalid)
  if msg <> invalid
    m.uiMode = msg.getData()
  else
    m.uiMode = getFieldFromGlobal("uiMode")
  end if
End Function


Function onEnableTopNavChange()
  tubiLog("HomeScreen.onEnableTopNavChange")
  if m.top.enableTopNav = true
    m.InfoPanel.translation = [m.InfoPanel.translation[0], 180]
    m.NavSection.visible = false
    m.TopNav.visible = true
  else
    m.InfoPanel.translation = [m.InfoPanel.translation[0], 133]
    m.NavSection.visible = true
    m.TopNav.visible = false
  end if
End Function


' The top nav has changed selection, so change the contentSelected so the helper can change things accordingly
Function onTopNavSelection()
  tubiLog("HomeScreen.onTopNavSelection")

  ' stop the video preview when user selects any item from topnav
  if isVideoPreviewEnabled() = true
    m.top.stopVideoPreview = true
  end if

  '//Set trackingComponentInfo before setting contentSelected so the proper selected analytics is tracked within the screenStack
  m.top.trackingComponentInfo = m.TopNav.trackingComponentInfo
  m.top.topNavItemSelected = m.TopNav.selected
End Function


Function onRefreshTopNav()
  tubiLog("Homescreen.onRefreshTopNav")
  includeLinearTV = m.top.isLinearTVAllowedInTopNav
  m.topNav.content = generateTopNavContentItems(includeLinearTV)
  m.topNav.contentUpdated = true
  m.TopNav.uiState = "unfocusedNear"
End Function


' The top nav has changed selection, so change the contentSelected so the helper can change things accordingly
Function onTopNavBackItemSelected()
  tubiLog("HomeScreen.onTopNavBackItemSelected")

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
  ]
  if includeLinearTV = true
    menuItemIds.push(m.constants.ui.sideNavIds.linearEPG)
    isTournamentTime = tournamentTimeFrame()
    if isTournamentTime = "duringTournament" OR isTournamentTime = "preTournament"
      menuItemIds.push(m.constants.ui.sideNavIds.tournament)
    end if
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
    else if id = m.constants.ui.sideNavIds.linearEPG
      item.title = getTranslation("menu_livetv")
    else if id = m.constants.ui.sideNavIds.tournament
      item.title = "FIFA World Cup 2022" + chr(8482)
      item.subText = getTranslation("text_new")
    end if
  end for

  return parent
End Function


Function onIDChange()
  '//Set the tracking based on the id of the homescreen
  '//::NOTE:: id should only be set after the instantiation of the HomeScreen, but before the screen is added to the stack
  newTrackingPageInfo = m.top.trackingPageInfo
  analyticsContentMode = m.Tracking.getAnalyticsHomePageContentMode(m.top.id)

  newTrackingPageInfo.pageType = "home_page"
  newTrackingPageInfo.pageValues = {content_mode: analyticsContentMode}

  if m.top.id = m.constants.ui.screenIds.movieScreen
    m.top.screenLevel = m.constants.ui.screenLevels.movieScreen
  else if m.top.id = m.constants.ui.screenIds.tvScreen
    m.top.screenLevel = m.constants.ui.screenLevels.tvScreen
  else if m.top.id = m.constants.ui.screenIds.espanolScreen
    m.top.screenLevel = m.constants.ui.screenLevels.espanolScreen
  else
    m.top.screenLevel = m.constants.ui.screenLevels.homeScreen
  end if

  m.top.trackingPageInfo = newTrackingPageInfo
  m.topNav.trackingPageInfo = newTrackingPageInfo
End Function


Function onLoadingChange()
  tubiLog("HomeScreen.onLoadingChange")
  bLoaded = (m.top.isLoading = false)
  m.CategoryGridList.visible = bLoaded
  if m.top.isLoading = true
    m.top.contentFocused = invalid
    m.top.contentReady = false
    emptyContentNode = CreateObject("roSGNode", "TubiContentNode")
    populateInfoPanel(m.constants.ui.infoPanelModes.item, emptyContentNode) 'empties the info panel
    m.CategoryGridList.content = invalid ' should be all categories with initial amounts of content in them
  else
    m.CategoryGridList.content = m.top.content ' should be all categories with initial amounts of content in them
  end if
End Function


Function onEnableChange()
  if m.top.enabled = true
    fade(m.NavSection, "in", 0.3)
  else
    fade(m.NavSection, "out", 0.3)
  end if
End Function


''''''''''''''''''''
' onScreenFocusChange
'
' Set focus back to category list or component group if the
' screen has lost focus, usually due to another screen or dialog
' being shown.
Function onScreenFocusChange()
  tubiLog("HomeScreen.onScreenFocusChange " + focusState(m.top))

  if m.top.hasFocus() = true
    if m.CategoryGridList.content <> invalid
      if shouldRefresh(m.CategoryGridList.content) = true
        m.top.loadAllCategories = true
      else 'check if any containers has expired
        refreshHomeScreenContainers()
      end if
    end if

    if m.top.componentToFocus = m.constants.ui.homescreen.focusItems.topNav
      setFocusOntoTopNav(false)
      if m.top.contentFocused <> invalid
        m.top.backgroundUriList = determineBackgroundImage(m.top.contentFocused)
      end if
    else
      setFocusOnCategoryGrid()
    end if

    ' reset the default value
    m.top.componentToFocus = m.constants.ui.homescreen.focusItems.contentGrid

    m.top.shouldFocusWhenPushed = true
  end if
End Function


'''''''''''''''''''''''''''
' onSignedInChange
'
' When signed in/out changes, we need to reload all categories to
' reflect changes in parental controls between guest and signed-in
' users
Function onSignedInChange()
  tubiLog("HomeScreen.onSignedInChange")
  onRefreshTopNav()
  m.CategoryGridList.signedIn = m.top.signedIn
End Function


Function onResetContentAreaValues()
  contractContentAreaToOriginal(1.0)
End Function


' Determine how far away the topNav is from the focus in the CategoryGridList
'@row: integer, the row of the categoryGridList that is gaining focus
Function setTopNavFarAwayStatus(row)
  if m.TopNav.visible = true AND (m.TopNav.hasFocus() = false AND m.TopNav.isInFocusChain() = false)
    setTopNavUi(row)
  end if
End Function


' A new row has been focused in the CategoryGridList
Function onRowFocused(msg)
  row = msg.getData()

  if row <> invalid
    if isSponsoredRow(row) = true
      m.top.sponsoredRowFocused = true
    end if
  end if
End Function


' @currentFocusRow: roSGNode, a CategoryContentNode
Function updateRowFocusedForSeeAll(currentFocusRow)
  if isCurrentRowHasSeeAll(currentFocusRow) = true
    m.top.rowFocusedForSeeAll = currentFocusRow
  else
    m.top.rowFocusedForSeeAll = invalid
  end if
End Function


' @currentFocusRow: roSGNode, a CategoryContentNode
Function isCurrentRowHasSeeAll(currentFocusRow)
  result = false
  row = currentFocusRow

  if row <> invalid
    rowCount = row.totalCount
    'TODO:Create a gridItemType for channels and check against m.constants.ui.gridItemTypes.channel.
    'categoryTypes are values passed by the backend, we should be checking against values that we set within the app.
    'checking gridItemType to handle linear rows and row type to handle channel rows.
    if (m.uiMode = m.constants.ui.modes.standard OR m.uiMode = m.constants.ui.modes.latino) AND rowCount >= 24 AND row.gridItemType <> m.constants.ui.gridItemTypes.linear AND row.type <> m.constants.ui.categoryTypes.channel
      result = true
    end if
  end if

  return result
End Function


' @currentFocusRow: roSGNode, a CategoryContentNode
Function updateFloatingSeeAll(currentFocusRow)
  row = currentFocusRow

  if row <> invalid
    if m.seeAllNotificationGroup <> invalid AND m.constants.deviceInfo.showFirmwareCcWhenVideoNotFullScreen = false
      if isCurrentRowHasSeeAll(row) = true
        m.seeAllNotificationGroup.text = getTranslation("screenHome_showAllNotification", {"containerTitle": row.title})
        m.seeAllNotificationGroup.visible = true
      else
        m.seeAllNotificationGroup.visible = false
      end if
    end if
  end if
End Function


' @row: roSGNode, a CategoryContentNode
Function isSponsoredRow(row)
  if row.sponsorImages <> invalid AND row.sponsorImages.pixels <> invalid AND row.sponsorImages.pixels["homescreen"] <> invalid
    return true
  end if

  return false
End Function


' When the column changes focus, then report to any observers.
Function onCurrFocusColumnChange(msg)
  column = msg.getData()
  newColumn = Int(column)
  if newColumn <> invalid AND newColumn <> m.currentColumn
    '//make sure we only report the new column for a whole integer
    m.currentColumn = newColumn

    m.top.columnFocused = m.currentColumn
  end if
End Function


' fires when the RowList is in the process of scrolling between rows
Function onCurrFocusRowChange()
  'the focused row during the scroll as a float (ie. 2.3 is partially between 2nd and 3rd rows)
  currFocusRow = m.CategoryGridList.currFocusRow

  'the last row that was focused and settled as an integer
  lastFocusRow = m.CategoryGridList.cursorPosition[0]

  scrollDirection = ""
  if m.lastFocusPosition >= 0
    if currFocusRow > m.lastFocusPosition
      scrollDirection = "down"
    else if currFocusRow < m.lastFocusPosition
      scrollDirection = "up"
    end if
  else
    ' this is the first time onCurrFocusRowChange has run during this grid scroll animation so we can
    ' use lastFocusRow as a reference for finding the scroll direction.
    if currFocusRow > lastFocusRow
      scrollDirection = "down"
    else if currFocusRow < lastFocusRow
      scrollDirection = "up"
    end if
  end if

  ' If a user quickly presses the up and down buttons quickly, before the
  ' rowList can set rowList.rowItemFocused, we need to correct lastFocusRow to be accurate
  if m.lastFocusPosition >= 0
    if currFocusRow > m.lastFocusPosition AND scrollDirection = "up"
      ' currFocusRow > lastFocusRow indicates the user is scrolling down, but if scrollDirection = "up"
      ' it indicates a user did a down/up fast button press, so we need to update lastFocusRow
      lastFocusRow += 1
    else if currFocusRow < m.lastFocusPosition AND scrollDirection = "down"
      ' currFocusRow > lastFocusRow indicates the user is scrolling up, but if scrollDirection = "down"
      ' it indicates a user did a up/down fast button press, so we need to update lastFocusRow
      lastFocusRow -= 1
    else if currFocusRow = lastFocusRow
      ' currFocusRow = lastFocusRow indicates the user concluded an up/down or down/up fast button press
      ' and we need to update lastFocusRow
      if scrollDirection = "up"
        lastFocusRow += 1
      else if scrollDirection = "down"
        lastFocusRow -= 1
      end if
    end if
  end if

  rowPercent = -1
  rowEnteringFocus = -1
  rowLosingFocus = -1

  ' There are 4 options when focusing a new category
  ' 1) Both old and new focused categories are not vitg: do nothing
  ' 2) Both old and new focused categories are vitg: do nothing
  ' 3) Old category is vitg, new category is not vitg: shrink the CategoryGridList
  ' 4) Old category is not vitg, new category is vitg: expand the CategoryGridList
  ' Determine if the category being entered is vitg
  if currFocusRow > lastFocusRow
    ' scrolling down
    rowEnteringFocus = Fix(currFocusRow) + 1
    rowLosingFocus = Fix(currFocusRow)
    if rowLosingFocus = currFocusRow
      'when the scroll completes
      rowEnteringFocus = Fix(currFocusRow)
      rowLosingFocus = currFocusRow - 1
    end if
    rowPercent = currFocusRow - rowLosingFocus
  else if currFocusRow < lastFocusRow
    ' scrolling up
    rowEnteringFocus = Fix(currFocusRow)
    rowLosingFocus = Fix(currFocusRow) + 1
    if rowEnteringFocus = currFocusRow
      'when the scroll completes
      rowEnteringFocus = Fix(currFocusRow)
      rowLosingFocus = currFocusRow + 1
    end if
    rowPercent = Abs(currFocusRow - rowLosingFocus)
  else if currFocusRow = lastFocusRow
    ' this block should never happen since lastFocus is updated above in the case where there is a fast scroll
    rowEnteringFocus = Fix(currFocusRow)
    rowLosingFocus = lastFocusRow
    rowPercent = 1
  end if

  setTopNavFarAwayStatus(rowEnteringFocus)

  categoryEnteringFocus = invalid
  categoryLosingFocus = invalid
  if m.CategoryGridList.content <> invalid
    categoryEnteringFocus = m.CategoryGridList.content.getChild(rowEnteringFocus) 'TubiCategoryNode
    categoryLosingFocus = m.CategoryGridList.content.getChild(rowLosingFocus) 'TubiCategoryNode
  end if

  if categoryEnteringFocus <> invalid
    if isNonEmptyString(m.experimentName) = true AND getExperimentResource("roku_see_all_container", m.experimentName, false).enabled = true
      updateRowFocusedForSeeAll(categoryEnteringFocus)
      updateFloatingSeeAll(categoryEnteringFocus)
    end if

    sSponsorBackgroundURL = ""

    if categoryEnteringFocus.gridItemType = m.constants.ui.gridItemTypes.linear
      ' update contentArea translation, only when linear gain focus
      expandContentAreaForLinear(rowPercent)
    else
      ' In the case of fast scrolling many rows of the grid, across the large vitg or linear rows, the category grid list may
      ' not finish it's translation animation as the focus leaves the vitg or linear rows. We correct for that as the focus scrolls
      ' through non video in the grid rows.
      contractContentAreaToOriginal(rowPercent)
    end if

    if categoryEnteringFocus.sponsorImages <> invalid
      '//if the entering row is sponsored, then take into account the extra room that the sponsor artwork takes up in the row header
      expandContentAreaForSponsorship(rowPercent)
      if m.constants.deviceInfo.limitedUi = false AND categoryEnteringFocus.sponsorImages.brandBackground <> ""
        sSponsorBackgroundURL = categoryEnteringFocus.sponsorImages.brandBackground
      else if categoryEnteringFocus.sponsorImages.brandColor <> ""
        sSponsorBackgroundURL = categoryEnteringFocus.sponsorImages.brandColor
      end if
    end if

    m.top.sponsorshipBackground = sSponsorBackgroundURL

  else if categoryLosingFocus <> invalid
    tubiLog("HomeScreen.onCurrFocusRowChange, elseIf categoryLosingFocus <> invalid ")
    '//::QUESTION:: When does this elseIF block ever get triggered. If never, then consider getting rid of this block

    contractContentAreaToOriginal(rowPercent)

  end if

  ' update m.lastFocusPosition or reset if we've concluded the scroll animation
  m.lastFocusPosition = currFocusRow
  if rowPercent = 1
    m.lastFocusPosition = -1
  end if
End Function


' @rowPercent: float, the percentage that the row is focused
Function contractContentAreaToOriginal(rowPercent)
  if m.ContentArea.translation[1] <> m.originalContentAreaTranslation[1]
    'gradually reset back to original position
    if rowPercent < .95
      '//while the rowPercent is less than .75, then gradually shift the visual elements back to default state
      nDiffContentAreaTranslation_y = m.originalContentAreaTranslation[1] - m.ContentArea.translation[1]
      nDiffContentAreaMaskOffset_y = m.originalContentAreaMaskOffset[1] - m.ContentArea.maskOffset[1]

      m.ContentArea.translation = [m.originalContentAreaTranslation[0], m.ContentArea.translation[1] + nDiffContentAreaTranslation_y * rowPercent]
      m.ContentArea.maskOffset = [m.originalContentAreaMaskOffset[0], m.ContentArea.maskOffset[1] + nDiffContentAreaMaskOffset_y * rowPercent]
      if m.InfoPanel.opacity < 1 AND m.InfoPanel.opacity < rowPercent
        m.InfoPanel.opacity = rowPercent
      end if
    else
      '//once the rowPercent has reached a certain percent, then immediately set everything back to original numbers to ensure it happens
      m.ContentArea.translation = m.originalContentAreaTranslation
      m.ContentArea.maskOffset = m.originalContentAreaMaskOffset
      m.InfoPanel.opacity = 1
    end if
  end if
End Function


' Adjust the RowList based on the difference of the normal and sponsored row title heights and relative to where the rowList already is.
'   So if a gridType already adjusted the rowList's position, then adjust it more but relative to where it already had been adjusted.
' @rowPercent: float, the percentage that the Sponsorship row is focused
Function expandContentAreaForSponsorship(rowPercent)
  m.ContentArea.translation = [m.ContentArea.translation[0], m.ContentArea.translation[1] - (m.sponsorSlideAmt * rowPercent)]
  m.ContentArea.maskOffset = [m.ContentArea.maskOffset[0], m.ContentArea.maskOffset[1] + (m.sponsorMaskOffsetDiff * rowPercent)]
End Function


Function expandContentAreaForLinear(rowPercent)
  m.ContentArea.translation = [m.originalContentAreaTranslation[0], m.originalContentAreaTranslation[1] - (m.linearSlideAmt * rowPercent)]
  m.ContentArea.maskOffset = [m.ContentArea.maskOffset[0], m.originalContentAreaMaskOffset[1] + (m.linearMaskOffsetDiff * rowPercent)]
End Function


Function populateInfoPanelByContent(focusedContent)
  if focusedContent <> invalid
    sType = focusedContent.type
    if sType = m.constants.ui.contentTypes.linear
      '// TODO: Currently we can not use focusedContent.parentType to differenciate between linear and non-linear rows.
      if focusedContent.parentId = "featured" 'linearContent in featured row
        populateInfoPanel(m.constants.ui.infoPanelModes.programHomescreen, focusedContent)
      else
        populateInfoPanel(m.constants.ui.infoPanelModes.linearHomeScreen, focusedContent)
      end if
    else if sType = m.constants.ui.contentTypes.historySignedOutUser
      populateInfoPanel(m.constants.ui.infoPanelModes.continueWatching, focusedContent)
    else if sType = m.constants.ui.contentTypes.seeAll
      populateInfoPanel(m.constants.ui.infoPanelModes.seeAll, focusedContent)
    '// REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
    else if sType = m.constants.ui.contentTypes.navigate
      populateInfoPanel(m.constants.ui.infoPanelModes.navigateSports, focusedContent)
    '// REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
    else if sType = m.constants.ui.contentTypes.sportsEvent
      populateInfoPanel(m.constants.ui.infoPanelModes.sportsEvent, focusedContent)
    else
      populateInfoPanel(m.constants.ui.infoPanelModes.item, focusedContent)
    end if
  end if

  ' If focus is on an empty category, leave the background as is.  This helps avoid
  ' background jank and keeps CPU usage down while categories are being fetched.
  if focusedContent <> invalid
    m.top.backgroundUriList = determineBackgroundImage(focusedContent)
  end if
End Function


' //REMOVE onFireExposureEvent function and its reference once the roku_see_all_container experiment is graduated
' callback when seeAll tile or floating seeAll is shown to the user
Function onFireExposureEvent(msg)
  categoryGridList = msg.getRoSGNode()
  fireExposureEventForSeeAll(categoryGridList)
End Function


' //REMOVE fireExposureEventForSeeAll function and its reference once the roku_see_all_container experiment is graduated
' Fires exposure event only once per session
'
' @categoryGridList: roSGNode, CategoryGridList node
Function fireExposureEventForSeeAll(categoryGridList = invalid)

  if m.wasExposureEventForSeeAllFired = false AND categoryGridList <> invalid AND categoryGridList.focusedPosition <> invalid AND categoryGridList.content <> invalid

    rowIndex = categoryGridList.focusedPosition[0]
    colIndex = categoryGridList.focusedPosition[1]
    content = categoryGridList.content

    if rowIndex <> invalid AND colIndex <> invalid

      if doesContentHaveChild(content, rowIndex, colIndex) = true AND content.getChild(rowIndex).getChildCount() >= 24 AND isContentMovieOrSeriesOrSeeAll(content.getChild(rowIndex).getChild(colIndex)) = true
        if m.experimentName = "roku_see_all_container_first_v1" OR m.experimentName = "qa.roku_see_all_container_first_v1"
          getExperimentResource("roku_see_all_container", m.experimentName, true)
          m.wasExposureEventForSeeAllFired = true
        else if m.experimentName = "roku_show_all_floating_education_v1" OR m.experimentName = "qa.roku_show_all_floating_education_v1"
          getExperimentResource("roku_see_all_container", m.experimentName, true)
          m.wasExposureEventForSeeAllFired = true
        else if m.experimentName = "roku_see_all_container_seventeen_v1" OR m.experimentName = "qa.roku_see_all_container_seventeen_v1"
          if colIndex >= 15 ' at this point the SeeAll tile will be visible to user, so firing exposure event
            getExperimentResource("roku_see_all_container", m.experimentName, true)
            m.wasExposureEventForSeeAllFired = true
          end if
        end if

      end if

      if m.wasExposureEventForSeeAllFired = false AND doesContentHaveChild(content, rowIndex + 1, 0) = true AND content.getChild(rowIndex + 1).getChildCount() >= 24 AND isContentMovieOrSeriesOrSeeAll(content.getChild(rowIndex + 1).getChild(0)) = true
        if m.experimentName = "roku_see_all_container_first_v1" OR m.experimentName = "qa.roku_see_all_container_first_v1"
          getExperimentResource("roku_see_all_container", m.experimentName, true)
          m.wasExposureEventForSeeAllFired = true
        end if
      end if

    end if

  end if

End Function


' //REMOVE isContentMovieOrSeriesOrSeeAll function and its reference once the roku_see_all_container experiment is graduated
Function isContentMovieOrSeriesOrSeeAll(content)
  result = false
  contentTypes = m.constants.ui.contentTypes

  if content.type = contentTypes.video OR content.type = contentTypes.series OR content.type = contentTypes.seeAll
    result = true
  end if

  return result
End Function


' //REMOVE doesContentHaveChild function and its reference once the roku_see_all_container experiment is graduated
'
' @content: roSGNode, CategoryContentNode for HomeScreen.
' @rowIndex: integer, the index of row, 0 based index
' @colIndex: integer, the index of column, 0 based index
Function doesContentHaveChild(content, rowIndex, colIndex)
  result = false

  if content <> invalid AND content.getChild(rowIndex) <> invalid
    if content.getChild(rowIndex).getChild(colIndex) <> invalid
      result = true
    end if
  end if

  return result
End Function


'''''''''''''''''''''
' onGridFocusChange
'
' On grid focus change, update the info panel
Function onGridFocusChange() as void
  ' //REMOVE below block once the roku_see_all_container experiment is graduated
  fireExposureEventForSeeAll(m.CategoryGridList)

  tubiLog("HomeScreen.onGridFocusChange")
  if m.top.contentReady = false
    m.top.contentReady = true
  end if

  if isNonEmptyString(m.experimentName) = true AND getExperimentResource("roku_see_all_container", m.experimentName, false).enabled = true
    updateRowFocusedForSeeAll(m.CategoryGridList.rowFocused)
    updateFloatingSeeAll(m.CategoryGridList.rowFocused)
  end if

  '//if the screen is loading or if the grid is not in focus or the topnav is not in focus, then exit out of this function
  if not (m.TopNav.isInFocusChain() = true OR m.CategoryGridList.isInFocusChain() = true) OR m.top.isLoading = true
    return
  end if
  oldFocusedContent = m.CategoryGridList.oldItemFocused
  focusedContent = m.CategoryGridList.itemFocused

  if m.CategoryGridList.isInFocusChain() = true
    '//if the CategoryGridList is in focus, then alter the UI. No need to do this for topnav as it may cause the linear video player
    '// to start to play when the top nav is in focus because there is a delay of reporting of the focused item by the CategoryGridList
    if focusedContent <> invalid
      if focusedContent.type <> m.constants.ui.gridItemTypes.linear AND oldFocusedContent <> invalid AND oldFocusedContent.type = m.constants.ui.gridItemTypes.linear
        m.top.stopLinearVideoPlayer = true
      end if

      m.top.contentFocused = focusedContent
    end if

    populateInfoPanelByContent(focusedContent)
  end if

  'Set up the navigateWithinPageInfo to send to ContentController via Homescreen. Need for when CategoryGridList or topNav are in focus
  oldAnalyticsRow = m.CategoryGridList.oldCursorPosition[0] + 1
  oldAnalyticsCol = m.CategoryGridList.oldCursorPosition[1] + 1
  newAnalyticsRow = m.CategoryGridList.cursorPosition[0] + 1
  newAnalyticsCol = m.CategoryGridList.cursorPosition[1] + 1

  if m.gridHasGainedInitialFocus = true AND oldAnalyticsRow > 0 AND oldAnalyticsCol > 0
    if oldAnalyticsRow <> newAnalyticsRow OR oldAnalyticsCol <> newAnalyticsCol

      categoryComponentInfo = {}
      categoryComponentInfo["category_slug"] = m.CategoryGridList.oldCategoryId
      categoryComponentInfo["category_row"] = oldAnalyticsRow
      'row is hardcoded to 1 in the line below because the row represents the row within the category_component, not within the grid
      'and the current design only has one row per category
      tile = m.Tracking.getAnalyticsTile(oldFocusedContent, oldAnalyticsCol, 1)
      categoryComponentInfo["content_tile"] = tile

      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("category_component", categoryComponentInfo)
        means_of_navigation: "BUTTON" 'MeansOfNavigation enum
        vertical_location: newAnalyticsRow
        horizontal_location: newAnalyticsCol
      }
    end if
  end if
  m.gridHasGainedInitialFocus = true

End Function


' The top nav will dispatch a navigateWithinPageInfo event which needs to be re-dispatched to the HomescreenHelpers
Function onTopNavNavigateWithinPageInfoChange()
  tubiLog("Homescreen.onTopNavNavigateWithinPageInfoChange")
  navigateWithinPageInfo = m.TopNav.navigateWithinPageInfo
  if navigateWithinPageInfo <> invalid AND navigateWithinPageInfo.means_of_navigation = "BUTTON"
    '//The navigateWithinPageInfo is caused by the user going from the video CategoryGridList to the Top Nav.
    '//Before navigateWithinPageInfo is communicated to the outside helper, add info about the CategoryGridList
    categoryComponentInfo = getTrackingComponentInfoOfCategoryGridList(m.CategoryGridList.itemFocused, m.CategoryGridList.focusedPosition)

    if categoryComponentInfo <> invalid AND categoryComponentInfo.componentValues <> invalid
      navigateWithinPageInfo.componentOneof = m.Tracking.getAnalyticsComponent("category_component", categoryComponentInfo.componentValues)
    end if
  end if
  m.top.navigateWithinPageInfo = navigateWithinPageInfo
End Function


Function onGridItemSelected() as void
  tubiLog("HomeScreen.onGridItemSelected")
  selectedItem = m.CategoryGridList.itemSelected
  handleItemSelected(selectedItem, m.top.selectedPosition)
End Function


' @item: roSGNode, TubiContentNode with metadata for an item in the grid
' @position: array, 2d array with [x,y] grid coordinate information
Function handleItemSelected(item, position)
  if m.top.isLoading <> true
    m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(item, position)

    ' Content controller observes contentSelected to populate/push the detail screen
    if item <> invalid then
      m.top.contentSelected = item
    end if
  end if
End Function


' @gridItem: roSGNode, TubiContentNode with metadata for an item in the grid
' @itemPosition: array, 2d array with [x,y] grid coordinate information
Function getTrackingComponentInfoOfCategoryGridList(gridItem, itemPosition)
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


' Is called when CategoryGridList has content loaded but did not gain focus, so we need to update the infoPanel
Function onItemToBeFocusedChange()
  if m.top.contentReady = false
    m.top.contentReady = true
  end if

  if isNonEmptyString(m.experimentName) = true AND getExperimentResource("roku_see_all_container", m.experimentName, false).enabled = true
    updateRowFocusedForSeeAll(m.CategoryGridList.rowFocused)
    updateFloatingSeeAll(m.CategoryGridList.rowFocused)
  end if

  populateInfoPanelByContent(m.CategoryGridList.reloadedItemToBeFocused)
End Function


'@mode: string, one of the valid constants.ui.infoPanelModes info panel modes (see InfoPanel.xml for details)
'@contentNode: content node
Function populateInfoPanel(mode, contentNode)
  if contentNode <> invalid
    if mode = m.constants.ui.infoPanelModes.item
      populateInfoPanelWithHomescreenStyleItemMode(contentNode, m.InfoPanel)
    else if mode = m.constants.ui.infoPanelModes.linearHomeScreen
      m.InfoPanel.mode = mode
      m.InfoPanel.topHeaderImageUri = m.constants.ui.uris.infoPanelEpgLiveIcon
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description
      m.InfoPanel.needsLogin = contentNode.needsLogin AND (m.top.signedIn <> true)
      m.InfoPanel.reminderIsSet = false
      m.InfoPanel.width = 650
    else if mode = m.constants.ui.infoPanelModes.continueWatching
      m.InfoPanel.mode = mode
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description
      m.InfoPanel.needsLogin = contentNode.needsLogin AND (m.top.signedIn <> true)
      m.InfoPanel.reminderIsSet = false
      m.InfoPanel.width = 960
    else if mode = m.constants.ui.infoPanelModes.programHomescreen
      populateInfoPanelWithProgramHomescreenMode(contentNode, m.InfoPanel)
    else if mode = m.constants.ui.infoPanelModes.seeAll
      m.InfoPanel.mode = mode
      m.InfoPanel.title = contentNode.title
      'Fifa Worldcup description and dates are constant when show all games is focused, so hardcoding it
      m.InfoPanel.description = contentNode.description
      lineOneData = {}

      if contentNode.movieAndTVShowCount <> invalid
        lineOneData.movieAndTVShowCount = contentNode.movieAndTVShowCount
      end if

      m.InfoPanel.lineOneData = lineOneData
      m.InfoPanel.width = 960
    '// REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
    else if mode = m.constants.ui.infoPanelModes.navigateSports
      m.InfoPanel.mode = mode
      m.InfoPanel.topHeaderImageUri = m.constants.ui.uris.infoPanelWorldCupLogo
      m.InfoPanel.title = contentNode.title
      'Fifa Worldcup description and dates are constant when show all games is focused, so hardcoding it
      m.InfoPanel.description = getTranslation("show_all_games_description")
      lineOneData = {}
      lineOneData.hoursOfAiring = getTranslation("show_all_games_gameInfo")
      'Showing 4k badge by default for show all CTA Infopanel
      lineOneData.has4k = true
      lineOneData.hasCC = contentNode.hasSubtitles
      m.InfoPanel.lineOneData = lineOneData
      m.InfoPanel.needsLogin = false
      m.InfoPanel.reminderIsSet = false
      m.InfoPanel.width = 960
    else if mode = m.constants.ui.infoPanelModes.sportsEvent
      populateInfoPanelWithHomescreenStyleSportsMode(contentNode, m.InfoPanel)
    end if

    m.InfoPanel.calculateHeight = true
  end if
End Function


Function onFullscreenCountdown()
  m.InfoPanel.fullscreenCountdown = m.top.fullscreenCountdown
End Function


Function onCategoryRefreshTimer()
  tubiLog("HomeScreen.onCategoryRefreshTimer")
  m.top.loadAllCategories = true
End Function


' @isToggle: boolean, true if the user is toggling focus to the top nav from a different component.
'                     false if the user is focusing the default top nav option by pressing back
'                     while focused on the top nav of another page
Function setFocusOntoTopNav(isToggle)
  tubiLog("Homescreen.setFocusOntoTopNav")

  ' setting rowFocusedForSeeAll as invalid, we have to disable "options" when focus is on topNav
  m.top.rowFocusedForSeeAll = invalid

  if m.seeAllNotificationGroup <> invalid
    'hide floating education modal when we press back to topNav
    m.seeAllNotificationGroup.visible = false
  end if

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

  m.top.stopLinearVideoPlayer = true
  if isVideoPreviewEnabled() = true
    m.top.pauseVideoPreview = true
  end if

  ' is necessary to set the uiState before the focus, so the topNav itemContents
  ' can have the appropriate color values set once they react to the focus change
  m.TopNav.uiState = "focused"

  m.TopNav.setFocus(true)
  m.TopNav.handlingFocusFromOtherTopNavBackButton = false

  fadeOutContentArea()
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


Function setFocusOnCategoryGrid()
  tubiLog("Homescreen.setFocusOnCategoryGrid" + m.top.id)
  if m.topNav.isInFocusChain()
    ' only send top nav toggle event if the top nav is losing focus
    m.top.topNavToggled = false

    ' setting losingFocusToComponentOnSamePage to true before calling setTopNavUi() informs
    ' the top nav not to send a NavigateWithinPageEvent when jumping focus. We immediately
    ' reset the value back to false after setTopNavUi() is called so that the default value
    ' is in place as soon as possible, with the understanding that the top nav behavior will
    ' fully resolve before continuing on with further logic within this function.
    m.topNav.losingFocusToComponentOnSamePage = true
  end if


  ' is necessary to set the uiState before the focus, so the topNav itemContents
  ' can have the appropriate color values set once they react to the focus change
  setTopNavUi(m.CategoryGridList.currFocusRow)
  m.topNav.losingFocusToComponentOnSamePage = false

  fadeInContentArea()
  m.CategoryGridList.setFocus(true)
  if m.seeAllNotificationGroup <> invalid
    'Showing floating education modal when we back to category from topNav or sideNav
    updateRowFocusedForSeeAll(m.CategoryGridList.rowFocused)
    updateFloatingSeeAll(m.CategoryGridList.rowFocused)
  end if
End Function


Function fadeInContentArea()
  stopAnimation(m.gridFade)
  if m.CategoryGridList.opacity < 1
    m.gridFade = fade(m.CategoryGridList, "in", .4, 0.0, 1)
  end if

  stopAnimation(m.infoPanelFade)
  if m.InfoPanelParent.opacity < 1
    m.infoPanelFade = fade(m.InfoPanelParent, "in", .4, 0.0, 1)
  end if
End Function


Function fadeOutContentArea()
  stopAnimation(m.gridFade)
  if m.CategoryGridList.opacity > 0
    m.gridFade = fade(m.CategoryGridList, "out", .4, 0.0, 0.4)
  end if

  stopAnimation(m.infoPanelFade)
  if m.InfoPanelParent.opacity > 0
    m.infoPanelFade = fade(m.InfoPanelParent, "out", .4, 0.0, 0.4)
  end if
End Function


Function onKeyEvent(key, press) as boolean
  if press
    if m.top.enableTopNav = true
      if key = "back"
        if m.TopNav.isInFocusChain() = false
          setFocusOntoTopNav(true)
          return true
        else
          if m.TopNav.selectedIndex = 0
            ' first item in top nav has focus, prepare for the side nav to gain focus
            m.top.topNavToggled = false
            m.top.navigatedAwayFromTopNav = true

            fadeInContentArea()

            ' setting losingFocusToExternalComponent to true before calling setTopNavUi() informs
            ' the top nav not to send a NavigateWithinPageEvent when jumping focus. We immediately
            ' reset the value back to false after setTopNavUi() is called so that the default value
            ' is in place as soon as possible, with the understanding that the top nav behavior will
            ' fully resolve before continuing on with further logic within this function.
            m.topNav.losingFocusToExternalComponent = true
            setTopNavUi(m.categoryGridList.currFocusRow)

            m.topNav.losingFocusToExternalComponent = false

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
      else if key = "up" AND m.TopNav.isInFocusChain() = false AND m.CategoryGridList.currFocusRow = 0
        setFocusOntoTopNav(true)
        return true
      else if key = "down" AND m.TopNav.isInFocusChain() = true
        setFocusOnCategoryGrid()
        return true
      else if key = "left"
        ' navigating to the side nav
        m.top.stopLinearVideoPlayer = true

        ' setting rowFocusedForSeeAll as invalid, we have to disable "options" when focus is on topNav
        m.top.rowFocusedForSeeAll = invalid

        if m.seeAllNotificationGroup <> invalid
          'hide floating education modal when we back focus to side nav
          m.seeAllNotificationGroup.visible = false
        end if

        if isVideoPreviewEnabled() = true
          m.top.pauseVideoPreview = true
        end if

        if m.TopNav.isInFocusChain() = true
          ' navigating to the side nav from the top nav specifically
          m.top.topNavToggled = false
          m.top.navigatedAwayFromTopNav = true

          setTopNavUi(m.categoryGridList.currFocusRow)
          fadeInContentArea()

          return false
        end if
      end if
    else
      if key = "left" OR key = "back"
        ' This is required because the homescreens without topNav will keep playing video Preview when focus is out of
        ' screen
        if isVideoPreviewEnabled() = true
          m.top.pauseVideoPreview = true
        end if

        ' navigating to the side nav
        m.top.stopLinearVideoPlayer = true
      end if
    end if

    if key = "play" AND m.CategoryGridList.isInFocusChain() = true
      handlePlayInput()
      return true
    end if

    if key = "options" AND m.seeAllNotificationGroup <> invalid AND m.top.rowFocusedForSeeAll <> invalid
      itemFocused = m.CategoryGridList.itemFocused
      positionFocused = m.top.cursorPosition
      m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(itemFocused, positionFocused)
      m.top.isSeeAllSelected = true
      return true
    end if

  end if
  return false
End Function


Function onTransportVoiceRequest(msg)
  response = "unhandled"
  inputInfo = msg.getData()
  if m.CategoryGridList.isInFocusChain() = true
    command = ""
    if inputInfo <> invalid AND inputInfo.command <> invalid
      command = inputInfo.command
    end if
    tubiLog("HomeScreen.onTransportVoiceRequest " + command)

    if command = "play"
      if handlePlayInput() = true
        response = "success"
      end if
    else if command = "ok"
      handleItemSelected(m.CategoryGridList.itemFocused, m.top.cursorPosition)
      response = "success"
    end if
  end if

  inputInfo.response = response
  m.top.transportVoiceResponse = inputInfo
End Function


' returns true if action was taken based on the "play" input and false if no action taken
Function handlePlayInput()
  if m.top.isLoading <> true
    itemFocused = m.CategoryGridList.itemFocused
    positionFocused = m.top.cursorPosition
    m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(itemFocused, positionFocused)

    if isVideoPreviewEnabled() = true
      m.top.stopVideoPreview = true
    end if

    ' Content controller observes contentSelected to populate/push the detail screen
    if itemFocused <> invalid AND itemFocused.type <> m.constants.ui.contentTypes.linear AND itemFocused.type <> m.constants.ui.contentTypes.navigate
      m.top.contentToPlay = itemFocused
      return true
    end if
  end if
  return false
End Function


Function refreshHomeScreenContainers()
  tubilog("HomeScreen.refreshHomeScreenContainers")
  loadCategoryForIds = []
  for i = 0 to m.CategoryGridList.content.getChildCount() - 1
    container = m.CategoryGridList.content.getChild(i)
    if shouldRefresh(container) = true
      loadCategoryForIds.push(container.id)
    end if
  end for
  if loadCategoryForIds.count() > 0
    m.top.loadCategoryForIds = loadCategoryForIds
  end if
End Function