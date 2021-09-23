Function init()
  tubiLog("HomeScreen.init")
  m._ = rodash()
  m.constants = m.global.constants
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.trackingLoggingTask = m.global.trackingLoggingTask
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.ContentArea = m.top.findNode("ContentArea")
  m.NavSection = m.top.findNode("nav")
  m.TopNav = m.top.findNode("TopNav")
  m.topNavBG = m.top.findNode("topNavBG")
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.InfoPanelParent = m.top.findNode("InfoPanelParent")
  m.HintGroup = m.top.findNode("UpHintGroup")
  fades = m.top.findNode("Fades")
  m.HintGroupFade = fades.findNode("HintGroupFade")

  if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
    m.NavSection.findNode("ScreenNavigationHint").translation = [192,60]
    m.TopNav.translation = [192,48]
    m.InfoPanel.translation = [192,168]
    m.InfoPanel.maxHeight = 354
    m.ContentArea.translation = [192,561]
  end if
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("categoryMenuVisible", "onCategoryMenuVisible")
  m.top.observeField("enabled", "onEnableChange")
  m.top.observeField("isLoading", "onLoadingChange")
  m.top.observeField("resetContentAreaValues", "onResetContentAreaValues")
  m.top.observeField("id", "onIDChange")
  m.top.observeField("fullscreenCountdown", "onFullscreenCountdown")
  m.top.observeField("enableTopNav", "onTopNavEnableChange")
  m.top.observeField("focusOnTopNav", "onFocusOnTopNavChanged")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")

  m.TopNav.observeField("selected", "onTopNavSelection")
  m.TopNav.observeField("focusedChild", "onTopNavFocusChange")
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
  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()
  'used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.gridHasFocus = false

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: ""
    pageValues: {}
  }

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

  ' the animation nodes necessary for video in the grid (vitg)
  m.contentAreaSlideAnimation = invalid
  m.infoPanelFadeAnimation = invalid


  m.utilityMaskOffsetDiff = -100 'the diff in the amount the content area mask is offset in the up direction for utility

  ' Video in the grid constants
  m.vitgSlideAmt = 440 'the amount the grid slides up to fit the vitg content item
  m.vitgMaskOffsetDiff = 466 'the diff in the amount the content area mask is offset in the up direction for vitg
  m.landscapeSlideAmt = 0
  m.landscapeMaskOffsetDiff = 0
  m.linearSlideAmt = -86 'the amount the grid slides up to fit the linear content item
  m.linearMaskOffsetDiff = -70 'the diff in the amount the content area mask is offset in the up direction for the linear news container
  if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
    m.vitgSlideAmt = 326
    m.vitgMaskOffsetDiff = 352
    m.landscapeSlideAmt = -9
    m.landscapeMaskOffsetDiff = -4
    m.linearSlideAmt = -115 
    m.linearMaskOffsetDiff = -99
    m.landscapeAreaTranslation = [m.ContentArea.translation[0], m.ContentArea.translation[1] - m.landscapeSlideAmt]
  end if
  m.originalContentAreaTranslation = m.ContentArea.translation
  m.vitgContentAreaTranslation = [m.ContentArea.translation[0], m.ContentArea.translation[1] - m.vitgSlideAmt]
  m.linearContentAreaTranslation = [m.ContentArea.translation[0], m.ContentArea.translation[1] - m.linearSlideAmt] 
  m.originalContentAreaMaskOffset = m.ContentArea.maskOffset

  if m.global.authInfo <> invalid and m.global.authInfo.parentalrating <> invalid
    m.top.parentalRating = m.global.authInfo.parentalrating
  end if

End Function


Function onTopNavEnableChange()
  tubiLog("HomeScreen.onTopNavEnableChange")
  if m.top.enableTopNav = true    
    m.InfoPanel.translation = [m.InfoPanel.translation[0], 180]
    m.NavSection.visible = false
    m.TopNav.visible = true
    m.topNavBG.visible = true
  else
    m.InfoPanel.translation = [m.InfoPanel.translation[0], 133]
    m.NavSection.visible = true
    m.TopNav.visible = false
    m.topNavBG.visible = false
  end if
End Function


' The top nav has changed selection, so change the contentSelected so the helper can change things accordingly
Function onTopNavSelection()
  tubiLog("HomeScreen.onTopNavSelection")
  '//Set trackingComponentInfo before setting contentSelected so the proper selected analytics is tracked within the screenStack
  m.top.trackingComponentInfo = m.TopNav.trackingComponentInfo
  m.top.topNavItemSelected = m.TopNav.selected
End Function


' reset the top nav back to the category that is associated with this homeScreen: i.e. MovieScreen associated with Movies Top Nav item.
Function resetTopNavSelection()
  tubiLog("HomeScreen.resetTopNavSelection")
  m.TopNav.refresh = true

  if m.top.id <> invalid
    sTopNavID = ""
    if m.top.id = m.constants.ui.screenIds.homeScreen
      sTopNavID = m.constants.ui.sideNavIds.home
    else if m.top.id = m.constants.ui.screenIds.movieScreen
      sTopNavID = m.constants.ui.sideNavIds.movies
    else if m.top.id = m.constants.ui.screenIds.tvScreen
      sTopNavID = m.constants.ui.sideNavIds.tv
    else if m.top.id = m.constants.ui.screenIds.espanolScreen
      sTopNavID = m.constants.ui.sideNavIds.espanol
    else if m.top.id = m.constants.ui.screenIds.linearTVScreen
      sTopNavID = m.constants.ui.sideNavIds.linearTV
    end if

    if sTopNavID <> ""
      m.TopNav.jumpToID = sTopNavID
    end if
  end if

  m.TopNav.containerTrackingPageInfo = m.top.trackingPageInfo
End Function


Function onIDChange()
  '//Set the tracking based on the id of the homescreen
  '//::NOTE:: id should only be set after the instantiation of the HomeScreen, but before the screen is added to the stack
  newTrackingPageInfo = m.top.trackingPageInfo
  if m.top.id = m.constants.ui.screenIds.movieScreen
    newTrackingPageInfo.pageType = "movie_browse_page"
    m.top.screenLevel = m.constants.ui.screenLevels.movieScreen
  else if m.top.id = m.constants.ui.screenIds.tvScreen
    newTrackingPageInfo.pageType = "series_browse_page"
    m.top.screenLevel = m.constants.ui.screenLevels.tvScreen
  else if m.top.id = m.constants.ui.screenIds.espanolScreen
    newTrackingPageInfo.pageType = "latino_browse_page"
    m.top.screenLevel = m.constants.ui.screenLevels.espanolScreen
  else if m.top.id = m.constants.ui.screenIds.linearTVScreen
    newTrackingPageInfo.pageType = "news_browse_page"
    m.top.screenLevel = m.constants.ui.screenLevels.linearTVScreen
  else
    newTrackingPageInfo.pageType = "home_page"
    m.top.screenLevel = m.constants.ui.screenLevels.homeScreen
  end if

  m.top.trackingPageInfo = newTrackingPageInfo
  resetTopNavSelection()
End Function


Function onLoadingChange()
  bLoaded = (m.top.isLoading = false)
  m.CategoryGridList.visible = bLoaded
  if m.top.isLoading = true
    m.CategoryGridList.content = invalid
    emptyContentNode = CreateObject("roSGNode", "TubiContentNode")
    populateInfoPanel(m.constants.ui.infoPanelModes.item, emptyContentNode) 'empties the info panel
  end if
  m.CategoryGridList.content = m.top.content ' should be all categories with initial amounts of content in them
End Function


Function onEnableChange()
  if m.top.enabled = true
    fade(m.NavSection, "in", 0.3)
  else
    fade(m.NavSection, "out", 0.3)
  end if
End Function


Function onTopNavFocusChange()
  setTopNavFarAwayStatus() '//::NOTE:: this is also called at onGridFocusChange(), but calling it here ensures the UI change happens when the topNav loses Focus
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
    m.gridHasFocus = true
    m.CategoryGridList.setFocus(true)
    m.CategoryGridList.opacity = 1
    m.InfoPanelParent.opacity = 1
    ' calling getExperimentResource() automatically sends the exposure, and limits sending the exposure event to once per session.
    getExperimentResource("roku_discovery_v3", "roku_discovery_row_v3")
    if m.CategoryGridList.content <> invalid and shouldRefresh(m.CategoryGridList.content) = true
      m.top.loadAllCategories = true
    end if
    m.top.shouldFocusWhenPushed = true
  else if m.top.isInFocusChain() = false
    m.gridHasFocus = false
    m.top.topNavHasFocus = false
    '//If loses focus, then reset back to default topNav selection for this instance of the homescreen
    resetTopNavSelection()
    m.CategoryGridList.opacity = 1
    m.InfoPanelParent.opacity = 1
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
  m.top.loadAllCategories = true
End Function


Function onResetContentAreaValues()
  contractContentAreaForLargeVitg(1.0)
End Function


' Determine how far away the topNav is from the focus in the CategoryGridList
Function setTopNavFarAwayStatus()
  if m.TopNav.visible = true
    currFocusRow = m.CategoryGridList.currFocusRow
    if currFocusRow >= 1 and (m.TopNav.hasFocus() = false and m.TopNav.isInFocusChain() = false)
      m.TopNav.farAwayFromFocus = true
    else
      m.TopNav.farAwayFromFocus = false
    end if
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

  setTopNavFarAwayStatus() '//::NOTE:: this is also called at onTopNavFocusChange(), but calling it here is faster when navigating up and down the m.CategoryGridList rows


  ' If a user quickly presses the up and down buttons quickly, before the
  ' rowList can set rowList.rowItemFocused, we need to correct lastFocusRow to be accurate
  if m.lastFocusPosition >= 0
    if currFocusRow > m.lastFocusPosition and scrollDirection = "up"
      ' currFocusRow > lastFocusRow indicates the user is scrolling down, but if scrollDirection = "up"
      ' it indicates a user did a down/up fast button press, so we need to update lastFocusRow
      lastFocusRow += 1
    else if currFocusRow < m.lastFocusPosition and scrollDirection = "down"
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

  categoryEnteringFocus = m.CategoryGridList.content.getChild(rowEnteringFocus) 'TubiCategoryNode
  categoryLosingFocus = m.CategoryGridList.content.getChild(rowLosingFocus) 'TubiCategoryNode

  ' send experiment analytics (exposure event) only when
  ' kidsMode is not enabled and currentScreen is homescreen and parentalRating is Adult and kidsModeFeatureOn is check for countryCode = US or CA
  if m.top.shouldKidsModeBeSentToServer = false and m.top.id = "homeScreen" and m.top.parentalRating > 2 and m.top.kidsModeFeatureOn = true
    ' Hiding the focus rectangle when the focus is on Utility row
    if categoryEnteringFocus <> invalid and categoryEnteringFocus.gridItemType = m.constants.ui.gridItemTypes.utility
      m.CategoryGridList.getChild(0).focusBitmapUri = "pkg:/images/tab_component_alt_fhd.9.png"
      if m.constants.deviceInfo.scaledUi = true then
        m.CategoryGridList.getChild(0).focusBitmapUri = "pkg:/images/tab_component_alt_hd.9.png"
      end if
      m.CategoryGridList.getChild(0).drawFocusFeedbackOnTop = false
    else
      m.CategoryGridList.getChild(0).focusBitmapUri = "pkg:/images/selector-fhd.9.png"
      m.CategoryGridList.getChild(0).drawFocusFeedbackOnTop = true
    end if
  else
    m.CategoryGridList.getChild(0).focusBitmapUri = "pkg:/images/selector-fhd.9.png"
    m.CategoryGridList.getChild(0).drawFocusFeedbackOnTop = true
  end if

  if categoryEnteringFocus <> invalid
    if categoryEnteringFocus.gridItemType = m.constants.ui.gridItemTypes.utility
      expandMaskOffsetForUtility(rowPercent)
    else if categoryEnteringFocus.gridItemType = m.constants.ui.gridItemTypes.vitg_large
      ' update contentArea translation, only when VITG gain focus
      expandContentAreaForLargeVitg(rowPercent)
    else if categoryEnteringFocus.gridItemType = m.constants.ui.gridItemTypes.linear
      ' update contentArea translation, only when linear gain focus
      expandContentAreaForLinear(rowPercent)
    else if categoryEnteringFocus.gridItemType = m.constants.ui.gridItemTypes.landscape 
      ' update contentArea translation, only when Landscape gain focus
      expandContentAreaForLandscape(rowPercent)
    else
      ' In the case of fast scrolling many rows of the grid, across the large vitg or linear rows, the category grid list may
      ' not finish it's translation animation as the focus leaves the vitg or linear rows. We correct for that as the focus scolls
      ' through non video in the grid rows.
      if m.ContentArea.translation[1] <> m.originalContentAreaTranslation[1]
        if categoryLosingFocus <> invalid
          if categoryLosingFocus.gridItemType = m.constants.ui.gridItemTypes.vitg_large
            translationDiffPercent = (m.originalContentAreaTranslation[1] - m.ContentArea.translation[1]) / m.vitgSlideAmt

            if rowPercent > (1 - translationDiffPercent)
              contractContentAreaForLargeVitg(rowPercent)
            end if
          else if categoryLosingFocus.gridItemType = m.constants.ui.gridItemTypes.linear
            translationDiffPercent = (m.originalContentAreaTranslation[1] - m.ContentArea.translation[1]) / m.linearSlideAmt

            if rowPercent > (1 - translationDiffPercent)
              contractContentAreaForLinear(rowPercent)
            end if
          else if categoryLosingFocus.gridItemType = m.constants.ui.gridItemTypes.landscape
            if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
              translationDiffPercent = (m.originalContentAreaTranslation[1] - m.ContentArea.translation[1]) / m.landscapeSlideAmt

              if rowPercent > (1 - translationDiffPercent)
                contractContentAreaForLandscape(rowPercent)
              end if
            end if
          end if
        end if
      end if
    end if
  else if categoryLosingFocus <> invalid
    if categoryLosingFocus.gridItemType = m.constants.ui.gridItemTypes.utility
      contractMaskOffsetForUtility(rowPercent)
    else if categoryLosingFocus.gridItemType = m.constants.ui.gridItemTypes.vitg_large
      ' update contentArea translation, only when VITG lose focus
      contractContentAreaForLargeVitg(rowPercent)
    else if categoryLosingFocus.gridItemType = m.constants.ui.gridItemTypes.linear
      ' update contentArea translation, only when Linear lose focus
      contractContentAreaForLinear(rowPercent)
    else if categoryLosingFocus.gridItemType = m.constants.ui.gridItemTypes.landscape
      if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
        ' update contentArea translation, only when Landscape lose focus
        contractContentAreaForLandscape(rowPercent)
      end if
    end if
  end if

  ' update m.lastFocusPosition or reset if we've concluded the scroll animation
  m.lastFocusPosition = currFocusRow
  if rowPercent = 1
    m.lastFocusPosition = -1
  end if
End Function


' @rowPercent: float, the percentage that the Utility row is focused
Function expandMaskOffsetForUtility(rowPercent)
  m.ContentArea.maskOffset = [m.ContentArea.maskOffset[0], m.originalContentAreaMaskOffset[1] + (m.utilityMaskOffsetDiff * rowPercent)]
End Function


' @rowPercent: float, the percentage that the VITG row is focused
Function expandContentAreaForLargeVitg(rowPercent)
  m.ContentArea.translation = [m.originalContentAreaTranslation[0], m.originalContentAreaTranslation[1] - (m.vitgSlideAmt * rowPercent)]
  m.ContentArea.maskOffset = [m.ContentArea.maskOffset[0], m.originalContentAreaMaskOffset[1] + (m.vitgMaskOffsetDiff * rowPercent)]
  m.InfoPanel.opacity = 1 - rowPercent
End Function


' @rowPercent: float, the percentage that the non utility row is focused (ie. 1.0 means utility is not focused at all)
Function contractMaskOffsetForUtility(rowPercent)
  m.ContentArea.maskOffset = [m.ContentArea.maskOffset[0], m.originalContentAreaMaskOffset[1] - (m.utilityMaskOffsetDiff * (1 - rowPercent))]
End Function


' @rowPercent: float, the percentage that the non VITG row is focused (ie. 1.0 means VITG is not focused at all)
Function contractContentAreaForLargeVitg(rowPercent)
  m.ContentArea.translation = [m.vitgContentAreaTranslation[0], m.vitgContentAreaTranslation[1] + (m.vitgSlideAmt * rowPercent)]
  m.ContentArea.maskOffset = [m.ContentArea.maskOffset[0], m.originalContentAreaMaskOffset[1] - (m.vitgMaskOffsetDiff * (1 - rowPercent))]
  m.InfoPanel.opacity = rowPercent
End Function


Function expandContentAreaForLinear(rowPercent)
  m.ContentArea.translation = [m.originalContentAreaTranslation[0], m.originalContentAreaTranslation[1] - (m.linearSlideAmt * rowPercent)]
  m.ContentArea.maskOffset = [m.ContentArea.maskOffset[0], m.originalContentAreaMaskOffset[1] + (m.linearMaskOffsetDiff * rowPercent)]
End Function


Function contractContentAreaForLinear(rowPercent)
  m.ContentArea.translation = [m.linearContentAreaTranslation[0], m.linearContentAreaTranslation[1] + (m.linearSlideAmt * rowPercent)]
  m.ContentArea.maskOffset = [m.ContentArea.maskOffset[0], m.originalContentAreaMaskOffset[1] - (m.linearMaskOffsetDiff * (1 - rowPercent))]
End Function

Function contractContentAreaForLandscape(rowPercent)
  m.ContentArea.translation = [m.landscapeAreaTranslation[0], m.landscapeAreaTranslation[1] + (m.landscapeSlideAmt * rowPercent)]
  m.ContentArea.maskOffset = [m.ContentArea.maskOffset[0], m.originalContentAreaMaskOffset[1] - (m.landscapeMaskOffsetDiff * (1 - rowPercent))]
End Function

Function expandContentAreaForLandscape(rowPercent)
  m.ContentArea.translation = [m.originalContentAreaTranslation[0], m.originalContentAreaTranslation[1] - (m.landscapeSlideAmt * rowPercent)]
  m.ContentArea.maskOffset = [m.ContentArea.maskOffset[0], m.originalContentAreaMaskOffset[1] + (m.landscapeMaskOffsetDiff * rowPercent)]
End Function

Function populateInfoPanelByContent(focusedContent)
  if focusedContent <> invalid
    sType = focusedContent.type

    if sType = m.constants.ui.categoryTypes.utility
      populateInfoPanel(m.constants.ui.infoPanelModes.utility, focusedContent)
    else if sType = m.constants.ui.categoryTypes.linear
      populateInfoPanel(m.constants.ui.infoPanelModes.linear, focusedContent)
    else if sType = m.constants.ui.categoryTypes.historySignedOutUser
      populateInfoPanel(m.constants.ui.infoPanelModes.continue_watching, focusedContent)
    else if sType = m.constants.ui.categoryTypes.preview
      populateInfoPanel(m.constants.ui.infoPanelModes.vitg, focusedContent)
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


'''''''''''''''''''''
' onGridFocusChange
'
' On grid focus change, update the info panel
Function onGridFocusChange() as void
  tubiLog("HomeScreen.onGridFocusChange")
  m.top.contentReady = true

  '//if the screen is loading or if the grid is not in focus or the topnav is not in focus, then exit out of this function
  if not (m.TopNav.isInFocusChain() = true or m.CategoryGridList.isInFocusChain()) or m.top.isLoading = true then return

  oldFocusedContent = m.CategoryGridList.oldItemFocused
  focusedContent = m.CategoryGridList.itemFocused
  m.top.contentFocused = focusedContent

  populateInfoPanelByContent(focusedContent) 

  'Set up the navigateWithinPageInfo to send to ContentController via Homescreen
  oldAnalyticsRow = m.CategoryGridList.oldCursorPosition[0] + 1
  oldAnalyticsCol = m.CategoryGridList.oldCursorPosition[1] + 1
  newAnalyticsRow = m.CategoryGridList.cursorPosition[0] + 1
  newAnalyticsCol = m.CategoryGridList.cursorPosition[1] + 1

  if m.gridHasFocus = true and oldAnalyticsRow > 0 and oldAnalyticsCol > 0
    if oldAnalyticsRow <> newAnalyticsRow or oldAnalyticsCol <> newAnalyticsCol

      categoryComponentInfo = {}
      categoryComponentInfo["category_slug"] = m.CategoryGridList.oldCategoryId
      categoryComponentInfo["category_row"] = oldAnalyticsRow
      'row is hardcoded to 1 in the line below because the row represents the row within the category_component, not within the grid
      'and the current design only has one row per category
      tile = m.Tracking.getAnalyticsTile(oldFocusedContent, oldAnalyticsCol, 1)
      if oldFocusedContent.type = m.constants.ui.categoryTypes.utility
        categoryComponentInfo["utility_tile"] = tile
      else
        categoryComponentInfo["content_tile"] = tile
      end if

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
  m.gridHasFocus = true
End Function


' The top nav will dispatch a navigateWithinPageInfo event which needs to be re-dispatched to the HomescreenHelpers
Function onTopNavNavigateWithinPageInfoChange()
  navigateWithinPageInfo = m.TopNav.navigateWithinPageInfo
  if navigateWithinPageInfo <> invalid and navigateWithinPageInfo.means_of_navigation = "BUTTON"
    '//The navigateWithinPageInfo is caused by the user going from the video CategoryGridList to the Top Nav. 
    '//Before navigateWithinPageInfo is communicated to the outside helper, add info about the CategoryGridList    
    categoryComponentInfo = getTrackingComponentInfoOfCategoryGridList(m.CategoryGridList.itemFocused, m.CategoryGridList.focusedPosition)

    if categoryComponentInfo <> invalid and categoryComponentInfo.componentValues <> invalid
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
      m.gridHasFocus = false
      m.listHasFocus = false
    end if
  end if
End Function


' @gridItem: roSGNode, TubiContentNode with metadata for an item in the grid
' @itemPosition: array, 2d array with [x,y] grid coordinate information
Function getTrackingComponentInfoOfCategoryGridList(gridItem, itemPosition)
  trackingComponentInfo = {}
  if gridItem <> invalid and itemPosition <> invalid and itemPosition.Count() = 2
    componentValues = {}
    componentValues["category_slug"] = m.top.currCategoryId
    componentValues["category_row"] = itemPosition[0] + 1 'all analytics are 1 based
    tile = m.Tracking.getAnalyticsTile(gridItem, itemPosition[1] + 1)

    if gridItem.type = m.constants.ui.categoryTypes.utility
      componentValues["utility_tile"] = tile
    else
      componentValues["content_tile"] = tile
    end if

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
  m.top.contentReady = true
  populateInfoPanelByContent(m.CategoryGridList.reloadedItemToBeFocused)
End Function


'@mode: string, one of the valid constants.ui.infoPanelModes info panel modes (see InfoPanel.xml for details)
'@contentNode: content node
Function populateInfoPanel(mode, contentNode)
  if contentNode <> invalid
    if mode = m.constants.ui.infoPanelModes.category
      m.InfoPanel.mode = mode
      m.InfoPanel.categoryContentCount = contentNode.totalCount
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description
      m.InfoPanel.titleLogoUri = contentNode.logoUri
      if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
        m.InfoPanel.width = 960
      else
        m.InfoPanel.width = 1140
      end if
    else if mode = m.constants.ui.infoPanelModes.vitg
      m.InfoPanel.mode = mode
    else if mode = m.constants.ui.infoPanelModes.item
      m.InfoPanel.mode = mode
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description

      lineOneData = {}
      if contentNode.type = m.constants.ui.contentTypes.series
        lineOneData.type = m.constants.ui.contentTypes.series
        ' lineOneData.seasons =  '//If available, get the number of seasons and set the value here
      end if
      lineOneData.releaseDate = contentNode.releaseDate
      lineOneData.length = contentNode.length
      lineOneData.hasCC = (contentNode.hasSubtitles or not m._.empty(contentNode.subtitleTracks))
      if contentNode.availabilityEnds <> invalid
        lineOneData.availabilityEnds = contentNode.availabilityEnds
      end if
      lineOneData.rating = contentNode.rating
      lineOneData.partnerLogoUri = contentNode.inlineLogoUri

      m.InfoPanel.lineOneData = lineOneData
      m.InfoPanel.titleLogoUri = contentNode.titleLogoUri
      m.InfoPanel.genres = contentNode.genres
      if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
        m.InfoPanel.width = 960
      else 
        m.InfoPanel.width = 1140
      end if
    else if mode = m.constants.ui.infoPanelModes.utility
      m.InfoPanel.mode = mode
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description
      if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
        m.InfoPanel.width = 960
      else
        m.InfoPanel.width = 1140
      end if
    else if mode = m.constants.ui.infoPanelModes.continue_watching
      m.InfoPanel.mode = mode
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description
      if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
        m.InfoPanel.width = 960
      else
        m.InfoPanel.width = 1140
      end if
    else if mode = m.constants.ui.infoPanelModes.linear
      m.InfoPanel.mode = mode
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description
      m.InfoPanel.width = 650
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


Function determineBackgroundImage(focusedContent)
  if focusedContent <> invalid and focusedContent.backgrounds <> invalid and focusedContent.backgrounds.count() > 0
    return focusedContent.backgrounds
  else
    return [m.defaultBackgroundUri]
  end if
End Function


Function setFocusOntoTopNav()
  m.gridHasFocus = false
  m.top.topNavHasFocus = true
  m.TopNav.setFocus(true)
  m.CategoryGridList.opacity = .4
  m.InfoPanelParent.opacity = .4
End Function


Function setFocusOnCategoryGrid()
  m.gridHasFocus = true
  m.top.topNavHasFocus = false
  m.CategoryGridList.setFocus(true)
  m.CategoryGridList.opacity = 1
  m.InfoPanelParent.opacity = 1
End Function


' When the outside world tells you to focus on the topnav. This is used when, for example, when the user uses the BACK button to go from a top nav option to the 1st top nav option and select the 1st top nav option.
Function onFocusOnTopNavChanged()
  if m.top.focusOnTopNav = true
    setFocusOntoTopNav()
  else
    setFocusOnCategoryGrid()
  end if
End Function


Function onKeyEvent(key, press) as boolean
  if press
    if m.top.enableTopNav = true
      if key = "back" and m.TopNav.isInFocusChain() = false
        setFocusOntoTopNav()
        return true
      else if key = "up" and m.TopNav.isInFocusChain() = false and m.CategoryGridList.currFocusRow = 0
        setFocusOntoTopNav()
        return true
      else if key = "down" and m.TopNav.isInFocusChain() = true
        setFocusOnCategoryGrid()
        return true
      end if
    end if

    if key = "play" and m.CategoryGridList.isInFocusChain() = true
      handlePlayInput()
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
    if inputInfo <> invalid and inputInfo.command <> invalid
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

    ' Content controller observes contentSelected to populate/push the detail screen
    if itemFocused <> invalid and itemFocused.type <> m.constants.ui.contentTypes.linear
      m.top.contentToPlay = itemFocused
      m.gridHasFocus = false
      m.listHasFocus = false
      return true
    end if
  end if
  return false
End Function

