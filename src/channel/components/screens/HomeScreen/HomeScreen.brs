Function init()
  tubiLog("HomeScreen.init")

  m._ = rodash()
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  m.PageGroup = m.top.findNode("PageGroup")
  m.PageGroup.translation = [m.constants.ui.translations.marginX, 0]
  m.ContentAreaParent = m.top.findNode("ContentAreaParent")
  m.ContentArea = m.top.findNode("ContentArea")
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.InfoPanelParent = m.top.findNode("InfoPanelParent")

  topRef = m.top
  topRef.observeField("focusedChild", "onScreenFocusChange")
  topRef.observeFieldScoped("signedIn", "onSignedInChange")
  topRef.observeField("categoryMenuVisible", "onCategoryMenuVisible")
  topRef.observeField("isLoading", "onLoadingChange")
  topRef.observeField("resetContentAreaValues", "onResetContentAreaValues")
  topRef.observeField("id", "onIDChange")
  topRef.observeField("fullscreenCountdown", "onFullscreenCountdown")
  topRef.observeField("transportVoiceRequest", "onTransportVoiceRequest")
  topRef.observeFieldScoped("personalizationId", "onPersonalizationIdChanged")
  topRef.observeFieldScoped("contentUpdated", "onContentUpdated")
  m.CategoryRefreshTimer = topRef.findNode("CategoryRefreshTimer")
  m.CategoryRefreshTimer.duration = m.constants.timers.categoryContentRefreshTimeout
  m.CategoryRefreshTimer.observeFieldScoped("fire", "onCategoryRefreshTimer")
  m.CategoryRefreshTimer.control = "start"

  'Content area
  m.CategoryGridList = topRef.findNode("CategoryGridList")
  m.CategoryGridList.observeFieldScoped("itemSelected", "onGridItemSelected")
  m.CategoryGridList.observeFieldScoped("itemFocused", "onGridFocusChange")
  m.CategoryGridList.observeFieldScoped("featuredItemSelected", "onFeaturedItemSelected")
  m.CategoryGridList.observeFieldScoped("reloadedItemToBeFocused", "onItemToBeFocusedChange")
  m.CategoryGridList.observeFieldScoped("currFocusRow", "onCurrFocusRowChange")
  m.CategoryGridList.observeFieldScoped("currFocusColumn", "onCurrFocusColumnChange")
  m.CategoryGridList.observeFieldScoped("rowFocused", "onRowFocused")
  m.CategoryGridList.observeFieldScoped("vertFocusDirection", "onVertFocusDirectionChange")
  m.CategoryGridList.observeFieldScoped("rowlistTranslation", "onRowlistTranslationChange")
  m.CategoryGridList.observeFieldScoped("gridContentIsReady", "onGridContentIsReadyChange")
  m.CategoryGridList.observeFieldScoped("featuredListHasFocus", "onFeaturedListHasFocusChange")
  m.CategoryGridList.observeFieldScoped("featuredRowFocusedItem", "fireNavigateWithinPageEvent")
  m.CategoryGridList.observeFieldScoped("hideInfoPanel", "onHideInfoPanelChange")
  m.CategoryGridList.observeFieldScoped("featuredRowListTranslation", "updateFeaturedRowListTranslation")
  m.ContentAreaParent.observeFieldScoped("translation", "updateFeaturedRowListTranslation")

  'used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.gridHasGainedInitialFocus = false

  'set initial tracking values
  topRef.trackingPageInfo = {
    pageType: ""
    pageValues: {}
  }

  topRef.handlesTransportVoiceRequests = true

  topRef.screenLevel = m.constants.ui.screenLevels.homeScreen

  ' lastFocusPosition holds the state of currFocusRow the last time onCurrFocusRow() occurred.
  ' It is reset to -1 at the conclusion of a grid scroll animation.
  m.lastFocusPosition = -1

  ' initialize the currentColumn variable to keep track of the current focused column item. It is used in the helper to stop the linear video player, but it could be used for other things.
  m.currentColumn = -1

  m.sponsorSlideAmt = 29 'the amount the grid slides up to fit the sponsored header. This is the difference of the heights of the sponsored and normal row titles

  m.originalContentAreaTranslation = [0, 516]
  m.homeRedesignExpContentAreaTranslation = [0, 96]
  setContentAreaState()

  m.scrollDirection = "none"
End Function


Function setContentAreaState(state = invalid)
  tubiLog("HomeScreen.setToRedesignContentArea")

  isHomeScreenRedesignForFeaturedEnabled = (getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v3", false).design_type <> "none")

  shouldAnimate = false
  if isHomeScreenRedesignForFeaturedEnabled = false OR (m.top.featuredListHasFocus = false AND m.CategoryGridList.lastFocusedList = "skinAdRow") OR m.top.featuredRowContent = invalid
    m.currentContentAreaTranslation = m.originalContentAreaTranslation
    shouldAnimate = true
  else
    m.currentContentAreaTranslation = m.homeRedesignExpContentAreaTranslation
  end if

  if shouldAnimate = true
    slideTo(m.ContentAreaParent, m.currentContentAreaTranslation, 0.2)
  else
    m.ContentAreaParent.translation = m.currentContentAreaTranslation
  end if
  updateFeaturedRowListTranslation()
End Function


' Move the mask to right below the row that should be completely visible. The mask image will fade out the rows underneath the focused row.
' This assumes that up to one row is completely opaque - (unless nFocusRow is set to a row beyond the actual focused row.)
' This also assumes that the mask height is constant.
' If a special row is in focus, then setting nFocusRow to a negative number will make all rows of the rowlist translucent 
' @param nFocusRow Integer, The row that is or will be in focus. 
'     If nFocusRow < 0, then the mask will be placed on top of the 1st row
' @param nFocusingPercent Number, When the row is in the process of gaining focus, this is a number from 0 to 1 indicating 
'     how close the row is to its final state.
Function moveContentAreaMask(nFocusRow = -1, nFocusingPercent = 1)
  '//nMaskYNew will most likely be set to 0 w/ the following line unless the content rowList has been moved to make way for a special top row.
  nMaskYNew = m.CategoryGridList.rowlistTranslation[1]
  ' Since we have 2 full rows visible we are setting the mask offset to make sure the first row of the category grid is visible.
  if m.top.lastFocusedList = "featuredRowList"
    nMaskYNew = nMaskYNew + m.CategoryGridList.rowHeights[0]
  end if
  if nFocusRow >= 0 AND isNonEmptyArray(m.CategoryGridList.rowHeights) = true AND (m.top.lastFocusedList = "rowList" OR m.top.lastFocusedList = "")
    nMaxRowHeights = m.CategoryGridList.rowHeights.count()
    if nFocusRow > (nMaxRowHeights - 1)
      '//If the rowHeights array doesn't contain as many row heights as the passed nFocusRow, then assume the current height is associated with the last item in the rowHeights array
      nFocusRow = nMaxRowHeights - 1
    end if
    nCurrentFocusedRowHeight = m.CategoryGridList.rowHeights[nFocusRow]
    if nFocusingPercent < 1
      nOldMaskPositionY = m.ContentArea.maskOffset[1]
      nDiff = (nCurrentFocusedRowHeight - nOldMaskPositionY) * nFocusingPercent
      nMaskYNew = nMaskYNew + nOldMaskPositionY + nDiff
    else
      nMaskYNew = nMaskYNew + nCurrentFocusedRowHeight
    end if
  end if

  m.ContentArea.maskOffset = [0, nMaskYNew]
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
  m.categoryGridList.parentScreenId = m.top.id
  m.categoryGridList.parentScreenTrackingPageInfo = newTrackingPageInfo
End Function


Function onPersonalizationIdChanged(msg)
  personalizationId = msg.getData()
  trackingPageInfo = m.top.trackingPageInfo

  if isAA(trackingPageInfo) = true AND isAA(trackingPageInfo.pageValues) = true
    trackingPageInfo.pageValues.personalization_id = personalizationId
    m.top.trackingPageInfo = trackingPageInfo
  end if
End Function


Function onContentUpdated(msg)
  '//the presense or absense of a 1st-Row will dictate the starting point of the peek row mask
  if m.top.kidsMode = false AND (m.top.skinAdContent <> invalid AND m.top.skinAdContent.getChildCount() > 0)
    moveContentAreaMask(-1)
    fadeOutInfoPanel()
  else
    moveContentAreaMask(0)
  end if
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
    m.CategoryGridList.skinAdContent = invalid
    m.CategoryGridList.featuredRowContent = invalid
    m.CategoryGridList.skinAdContentUpdated = true
    ' Resetting last focus list when reloading the screen.
    ' To Cover cases where skin ad is shown and then gets removed.
    m.CategoryGridList.lastFocusedList = ""
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
    setFocusOnCategoryGrid()

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
  m.CategoryGridList.signedIn = m.top.signedIn
End Function


Function onResetContentAreaValues()
  contractContentAreaToOriginal(1.0)
End Function



' A new row has been focused in the CategoryGridList
Function onRowFocused(msg)
  tubiLog("HomeScreen.onRowFocused")
  row = msg.getData()

  if row <> invalid
    if isSponsoredRow(row) = true
      m.top.sponsoredRowFocused = true
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
  tubiLog("HomeScreen.onCurrFocusColumnChange")
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
  tubiLog("HomeScreen.onCurrFocusRowChange")
  'the focused row during the scroll as a float (ie. 2.3 is partially between 2nd and 3rd rows)
  currFocusRow = m.CategoryGridList.currFocusRow

  'the last row that was focused and settled as an integer
  lastFocusRow = m.CategoryGridList.cursorPosition[0]

  scrollDirection = m.scrollDirection

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

  if m.CategoryGridList.rowHeights <> invalid AND m.CategoryGridList.isInFocusChain() = true
    nEnteringFocusedRowHeight = m.CategoryGridList.rowHeights[rowEnteringFocus]
    nLosingFocusedRowHeight = m.CategoryGridList.rowHeights[rowLosingFocus]
    if nLosingFocusedRowHeight <> nEnteringFocusedRowHeight
      '//no need to move the mask if the previous and current rows have the same heights

      moveContentAreaMask(rowEnteringFocus, rowPercent)
    end if
  end if

  categoryEnteringFocus = invalid
  categoryLosingFocus = invalid
  if m.CategoryGridList.content <> invalid
    categoryEnteringFocus = m.CategoryGridList.content.getChild(rowEnteringFocus) 'TubiCategoryNode
    categoryLosingFocus = m.CategoryGridList.content.getChild(rowLosingFocus) 'TubiCategoryNode
  end if

  if categoryEnteringFocus <> invalid
    sSponsorBackgroundURL = ""

    if categoryEnteringFocus.sponsorImages <> invalid
      '//if the entering row is sponsored, then take into account the extra room that the sponsor artwork takes up in the row header
      if m.top.featuredRowContent = invalid
        expandContentAreaForSponsorship(rowPercent)
      end if
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
    m.top.currFocusRow = currFocusRow
  end if
End Function


' @rowPercent: float, the percentage that the row is focused
Function contractContentAreaToOriginal(rowPercent)
  tubiLog("HomeScreen.contractContentAreaToOriginal")

  if m.ContentAreaParent.translation[1] <> m.currentContentAreaTranslation[1]
    'gradually reset back to original position
    if rowPercent < .95
      '//while the rowPercent is less than .75, then gradually shift the visual elements back to default state
      nDiffContentAreaTranslation_y = m.currentContentAreaTranslation[1] - m.ContentAreaParent.translation[1]

      m.ContentAreaParent.translation = [m.currentContentAreaTranslation[0], m.ContentAreaParent.translation[1] + nDiffContentAreaTranslation_y * rowPercent]
      if m.InfoPanel.opacity < 1 AND m.InfoPanel.opacity < rowPercent
        m.InfoPanel.opacity = rowPercent
      end if
    else
      '//once the rowPercent has reached a certain percent, then immediately set everything back to original numbers to ensure it happens
      m.ContentAreaParent.translation = m.currentContentAreaTranslation
      m.InfoPanel.opacity = 1
    end if
    
  end if
End Function


' Adjust the RowList based on the difference of the normal and sponsored row title heights and relative to where the rowList already is.
'   So if a gridType already adjusted the rowList's position, then adjust it more but relative to where it already had been adjusted.
' @rowPercent: float, the percentage that the Sponsorship row is focused
Function expandContentAreaForSponsorship(rowPercent)
  m.ContentAreaParent.translation = [m.ContentAreaParent.translation[0], m.currentContentAreaTranslation[1] - (m.sponsorSlideAmt * rowPercent)]

  if m.InfoPanel.opacity < 0
    '//gradually display the info panel as the sponsorship row comes into view
    if rowPercent < .95
      m.InfoPanel.opacity = rowPercent
    else
      m.InfoPanel.opacity = 1
    end if
  end if
End Function


Function populateInfoPanelByContent(focusedContent)
  if focusedContent <> invalid
    sType = focusedContent.type
    if sType = m.constants.ui.contentTypes.linear
      populateInfoPanel(m.constants.ui.infoPanelModes.linearProgramHomescreen, focusedContent)
    else if sType = m.constants.ui.contentTypes.historySignedOutUser
      populateInfoPanel(m.constants.ui.infoPanelModes.continueWatching, focusedContent)
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


Function onFeaturedListHasFocusChange(msg)
  slideFadeGeneral(m.InfoPanelParent, [0, -50], "out", 0.2)
  setContentAreaState()
  'Make sure Content is in correct location
  moveContentAreaMaskBasedCurrentFocus()
End Function


Function onFeaturedItemSelected()
  selectedItem = m.CategoryGridList.featuredItemSelected
  handleItemSelected(selectedItem, m.top.selectedPosition)
End Function


'''''''''''''''''''''
' onGridFocusChange
'
' On grid focus change, update the info panel
Function onGridFocusChange() as void
  tubiLog("HomeScreen.onGridFocusChange")
  if m.top.contentReady = false
    m.top.contentReady = true
  end if

  '//if the screen is loading or if the grid is not in focus then exit out of this function
  if m.CategoryGridList.isInFocusChain() = false OR m.top.isLoading = true
    return
  end if
  oldFocusedContent = m.CategoryGridList.oldItemFocused
  focusedContent = m.CategoryGridList.itemFocused

  if m.CategoryGridList.isInFocusChain() = true
    '//if the CategoryGridList is in focus, then alter the UI.
    if focusedContent <> invalid
      if focusedContent.type <> m.constants.ui.gridItemTypes.linear AND oldFocusedContent <> invalid AND oldFocusedContent.type = m.constants.ui.gridItemTypes.linear
        m.top.stopLinearVideoPlayer = true
      end if

      m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(focusedContent, m.CategoryGridList.focusedPosition)
      m.top.contentFocused = focusedContent
      
      if focusedContent.gridItemType = m.constants.ui.gridItemTypes.skinAd
        fadeOutInfoPanel()
        m.top.backgroundUriList = determineBackgroundImage(focusedContent)
      else
        populateInfoPanelByContent(focusedContent)
        fadeInContentArea()
      end if
      
    end if

  end if

  '//Ensure the ContentArea Mask is at the proper location when new focus has changed.
  moveContentAreaMaskBasedCurrentFocus()

  fireNavigateWithinPageEvent()
  
End Function


Function fireNavigateWithinPageEvent()
  'Set up the navigateWithinPageInfo to send to ContentController via Homescreen. Need for when CategoryGridList is in focus
  rowIndexBoost = m.categoryGridList.rowIndexBoost
  
  experiment = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v3", false)
  isHomeScreenRedesignForFeaturedEnabled = m.top.kidsMode = false AND (m.top.featuredRowContent <> invalid AND (experiment.design_type = "withDescriptionPortraitSmall") AND m.CategoryGridList.oldCategoryId = experiment.container_id)

  if isHomeScreenRedesignForFeaturedEnabled = false
    rowIndexBoost = rowIndexBoost + 1
  end if

  oldAnalyticsRow = m.CategoryGridList.oldCursorPosition[0] + rowIndexBoost
  oldAnalyticsCol = m.CategoryGridList.oldCursorPosition[1] + 1
  newAnalyticsRow = m.CategoryGridList.cursorPosition[0] + rowIndexBoost
  newAnalyticsCol = m.CategoryGridList.cursorPosition[1] + 1
  oldFocusedContent = m.CategoryGridList.oldItemFocused

  if m.gridHasGainedInitialFocus = true AND oldAnalyticsRow > 0 AND oldAnalyticsCol > 0
    if oldAnalyticsRow <> newAnalyticsRow OR oldAnalyticsCol <> newAnalyticsCol

      categoryComponentInfo = {}
      categoryComponentInfo["category_slug"] = m.CategoryGridList.oldCategoryId
      categoryComponentInfo["category_row"] = oldAnalyticsRow
      categoryComponentInfo["category_col"] = oldAnalyticsCol
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

  if m.CategoryGridList.lastFocusedList = "featuredRowList"
    focusedContent = m.CategoryGridList.featuredRowFocusedItem
    m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(focusedContent, m.CategoryGridList.cursorPosition)
  end if
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

    rowIndexBoost = m.categoryGridList.rowIndexBoost
    experiment = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v3", false)
    isHomeScreenRedesignForFeaturedEnabled = m.top.kidsMode = false AND (m.top.featuredRowContent <> invalid AND (experiment.design_type = "withDescriptionPortraitSmall") AND m.top.currCategoryId = experiment.container_id)

    if isHomeScreenRedesignForFeaturedEnabled = false
      rowIndexBoost = rowIndexBoost + 1
    end if

    componentValues["category_row"] = itemPosition[0] + rowIndexBoost 'all analytics are 1 based
    componentValues["category_col"] = itemPosition[1] + 1 'all analytics are 1 based
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
  tubiLog("HomeScreen.onItemToBeFocusedChange")
  if m.top.contentReady = false
    m.top.contentReady = true
  end if

  reloadedItemToBeFocused = m.CategoryGridList.reloadedItemToBeFocused
  'We are updating the infopanel for updated focused content, but not updating the contentFocused.
  'Here we are updating the contentFocused, so it will play correct video preview when the content is updated.
  m.top.contentFocused = reloadedItemToBeFocused

  if reloadedItemToBeFocused <> invalid AND reloadedItemToBeFocused.gridItemType <> m.constants.ui.gridItemTypes.skinAd
    ' Covers use cases where info panel was hidden but due to home screen container changes purple carpet is removed and info panel was reset.
    fadeInContentArea()
    populateInfoPanelByContent(reloadedItemToBeFocused)
  else
    ' Making sure the background is also updated if a purple carpet row is focused.
    m.top.backgroundUriList = determineBackgroundImage(reloadedItemToBeFocused)
  end if
End Function


'@mode: string, one of the valid constants.ui.infoPanelModes info panel modes (see InfoPanel.xml for details)
'@contentNode: content node
Function populateInfoPanel(mode, contentNode)
  experiment = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v3", false)
  isHomeScreenRedesignForFeaturedEnabled = (m.top.featuredRowContent <> invalid AND (experiment.design_type = "withDescriptionPortraitSmall") AND contentNode.parentId = experiment.container_id)

  if contentNode <> invalid AND (isHomeScreenRedesignForFeaturedEnabled = false OR m.top.contentMode <> m.constants.ui.contentMode.homescreen)
    
    ' The below is to ensure that there is slight delay in showing the info panel so that there is no overlap with any row that is gaining focus.
    if m.InfoPanel.visible = false
      slideFadeGeneral(m.InfoPanelParent, [0, 0], "in", 0.2)
    end if
    
    if mode = m.constants.ui.infoPanelModes.item
      populateInfoPanelWithHomescreenStyleItemMode(contentNode, m.InfoPanel)
    else if mode = m.constants.ui.infoPanelModes.linearProgramHomescreen
      populateInfoPanelWithLinearProgramHomescreenMode(contentNode, m.InfoPanel) 'V4 api
    else if mode = m.constants.ui.infoPanelModes.continueWatching
      m.InfoPanel.mode = mode
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description

      if contentNode.needsLogin = true AND m.top.signedIn <> true

        m.InfoPanel.loginReason = contentNode.loginReason 'set login reason before needsLogin
        m.InfoPanel.needsLogin = true
      else
        m.InfoPanel.needsLogin = false
      end if

      m.InfoPanel.reminderIsSet = false

    else if mode = m.constants.ui.infoPanelModes.sportsEvent
      populateInfoPanelWithHomescreenStyleSportsMode(contentNode, m.InfoPanel)
    end if

    m.InfoPanel.calculateHeight = true
  else
    slideFadeGeneral(m.InfoPanelParent, [0, -50], "out", 0.2)
    setContentAreaState()
  end if
End Function


Function onFullscreenCountdown()
  m.InfoPanel.fullscreenCountdown = m.top.fullscreenCountdown
End Function


Function onCategoryRefreshTimer()
  tubiLog("HomeScreen.onCategoryRefreshTimer")
  m.top.loadAllCategories = true
End Function


Function setFocusOnCategoryGrid()
  tubiLog("Homescreen.setFocusOnCategoryGrid" + m.top.id)
  ' Only fade in content area if last focused was not purple carept.
  focusedContent = m.categoryGridList.itemFocused
  if focusedContent <> invalid AND focusedContent.gridItemType = m.constants.ui.gridItemTypes.skinAd
    fadeOutInfoPanel()
    m.top.backgroundUriList = determineBackgroundImage(focusedContent)
  else
    fadeInContentArea()
  end if
  m.CategoryGridList.setFocus(true)
End Function


Function fadeInContentArea()
  stopAnimation(m.gridFade)
  if m.CategoryGridList.opacity < 1
    m.gridFade = fade(m.CategoryGridList, "in", .4, 0.0, 1)
  end if

  stopAnimation(m.infoPanelFade)
  if m.InfoPanelParent.opacity < 1
    m.infoPanelFade = slideFadeGeneral(m.InfoPanelParent, [0, 0], "in", 0.2)
  end if
End Function


Function fadeOutInfoPanel()
  stopAnimation(m.infoPanelFade)
  m.infoPanelFade = fade(m.InfoPanelParent, "out", .4)
End Function


Function onKeyEvent(key, press) as boolean
  if press
    if key = "left" OR key = "back"
      ' This is required to stop videopreview
      itemFocused = m.CategoryGridList.itemFocused
      if m.top.isVideoPreviewOn = true OR (itemFocused <> invalid AND itemFocused.gridItemType = m.constants.ui.gridItemTypes.skinAd)
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
  tubilog("HomeScreen.handlePlayInput")
  if m.top.isLoading <> true
    if m.CategoryGridList.lastFocusedList = "featuredRowList"
      itemFocused = m.CategoryGridList.featuredRowFocusedItem
    else
      itemFocused = m.CategoryGridList.itemFocused
    end if

    positionFocused = m.top.cursorPosition
    m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(itemFocused, positionFocused)

    ' Content controller observes contentSelected to populate/push the detail screen
    if itemFocused <> invalid AND itemFocused.type <> m.constants.ui.contentTypes.linear
      m.top.contentToPlay = itemFocused
      return true
    end if
  end if
  return false
End Function


Function refreshHomeScreenContainers()
  tubilog("HomeScreen.refreshHomeScreenContainers")
  loadCategoryForIds = []

  if m.CategoryGridList.featuredRowContent <> invalid
    featuredContainer = m.CategoryGridList.featuredRowContent.getChild(0)
    if shouldRefresh(featuredContainer) = true
      loadCategoryForIds.push(featuredContainer.id)
    end if
  end if

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


' Observer that gets fired when the rowlist vertical focus direction field changes.
Function onVertFocusDirectionChange(msg)
  direction = msg.getData()
  ' Since the direction gets reset during the flow.
  ' The value of m.scrollDirection gets reset to none after the value changes to up or down during scrolling.
  ' This is the reason we are maintaining our own directional scope variable.
  if direction <> "none"
    m.scrollDirection = direction
  end if
End Function


' The content RowList within the categoryGridList is moving. 
' Usually that means a special row or the content rowList is gaining focus.
Function onRowlistTranslationChange(msg)
  moveContentAreaMaskBasedCurrentFocus()
End Function


'//Based on the current focused item, move the contentarea mask
Function moveContentAreaMaskBasedCurrentFocus()  '//Determine if the rowlist or a special row is in focus
  nRowInFocus = -1
  focusedContent = m.top.contentFocused
  if m.top.kidsMode = true OR (focusedContent <> invalid AND focusedContent.gridItemType <> m.constants.ui.gridItemTypes.skinAd)
    if m.CategoryGridList.cursorPosition <> invalid
      nRowInFocus = m.CategoryGridList.cursorPosition[0]
    else
      nRowInFocus = 0
    end if
  end if
  moveContentAreaMask(nRowInFocus)
End Function


Function onGridContentIsReadyChange(msg)
  ' Not using alias to avoid making the field gridContentIsReady is ready bi-directional since contentReady inside homescreen.brs on other use cases.
  if msg.getData() = true AND m.top.contentReady = false
    m.top.contentReady = true
    setContentAreaState()
  end if
End Function


Function onHideInfoPanelChange(msg)
  visible = msg.getData()
  if visible = true
    slideFadeGeneral(m.InfoPanelParent, [0, 0], "in", 0.2)
  else
    slideFadeGeneral(m.InfoPanelParent, [0, -50], "out", 0.2)
  end if
End Function


Function updateFeaturedRowListTranslation()
  translation = m.categoryGridList.featuredRowListTranslation
  translation[1] = translation[1] + m.ContentAreaParent.translation[1]
  m.top.featuredRowListTranslation = translation
end function