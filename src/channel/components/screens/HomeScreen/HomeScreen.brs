Function init()
  tubiLog("HomeScreen.init")

  m._ = rodash()
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  m.PageGroup = m.top.findNode("PageGroup")
  m.PageGroup.translation = [m.constants.ui.translations.marginX, 0]
  m.ContentArea = m.top.findNode("ContentArea")
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.InfoPanelParent = m.top.findNode("InfoPanelParent")
  m.HintGroup = m.top.findNode("UpHintGroup")
  fades = m.top.findNode("Fades")
  m.HintGroupFade = fades.findNode("HintGroupFade")

  m.ContentArea.translation = [0, 516]

  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("signedIn", "onSignedInChange")
  m.top.observeField("categoryMenuVisible", "onCategoryMenuVisible")
  m.top.observeField("isLoading", "onLoadingChange")
  m.top.observeField("resetContentAreaValues", "onResetContentAreaValues")
  m.top.observeField("id", "onIDChange")
  m.top.observeField("fullscreenCountdown", "onFullscreenCountdown")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")
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
  m.CategoryGridList.observeFieldScoped("vertFocusDirection", "onVertFocusDirectionChange")
  m.CategoryGridList.observeFieldScoped("rowlistTranslation", "onRowlistTranslationChange")
  m.CategoryGridList.observeFieldScoped("eventCtaListItemSelected", "onEventCtaListItemSelectedChange")

  'used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.gridHasGainedInitialFocus = false

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: ""
    pageValues: {}
  }

  m.top.handlesTransportVoiceRequests = true

  m.top.screenLevel = m.constants.ui.screenLevels.homeScreen

  ' lastFocusPosition holds the state of currFocusRow the last time onCurrFocusRow() occurred.
  ' It is reset to -1 at the conclusion of a grid scroll animation.
  m.lastFocusPosition = -1

  ' initialize the currentColumn variable to keep track of the current focused column item. It is used in the helper to stop the linear video player, but it could be used for other things.
  m.currentColumn = -1

  m.sponsorSlideAmt = 29 'the amount the grid slides up to fit the sponsored header. This is the difference of the heights of the sponsored and normal row titles

  m.originalContentAreaTranslation = m.ContentArea.translation

  m.scrollDirection = "none"

  ' Holds the boolean indicating if the spotlight experiment is enabled for the user or not.
  m.isSpotlightRowEnabled = (getExperimentResource("roku_spotlight_carousel", "roku_spotlight_carousel_v1", false).enabled = true)
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
  if nFocusRow >= 0 AND m.CategoryGridList.rowHeights <> invalid
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
    m.CategoryGridList.spotlightContent = invalid
    m.CategoryGridList.purpleCarpetContent = invalid
    m.CategoryGridList.purpleCarpetContentUpdated = true
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

  if m.CategoryGridList.rowHeights <> invalid
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
  tubiLog("HomeScreen.contractContentAreaToOriginal")

  if m.ContentArea.translation[1] <> m.originalContentAreaTranslation[1]
    'gradually reset back to original position
    if rowPercent < .95
      '//while the rowPercent is less than .75, then gradually shift the visual elements back to default state
      nDiffContentAreaTranslation_y = m.originalContentAreaTranslation[1] - m.ContentArea.translation[1]

      m.ContentArea.translation = [m.originalContentAreaTranslation[0], m.ContentArea.translation[1] + nDiffContentAreaTranslation_y * rowPercent]
      if m.InfoPanel.opacity < 1 AND m.InfoPanel.opacity < rowPercent
        m.InfoPanel.opacity = rowPercent
      end if
    else
      '//once the rowPercent has reached a certain percent, then immediately set everything back to original numbers to ensure it happens
      m.ContentArea.translation = m.originalContentAreaTranslation
      m.InfoPanel.opacity = 1
    end if
    
  end if
End Function


' Adjust the RowList based on the difference of the normal and sponsored row title heights and relative to where the rowList already is.
'   So if a gridType already adjusted the rowList's position, then adjust it more but relative to where it already had been adjusted.
' @rowPercent: float, the percentage that the Sponsorship row is focused
Function expandContentAreaForSponsorship(rowPercent)
  m.ContentArea.translation = [m.ContentArea.translation[0], m.originalContentAreaTranslation[1] - (m.sponsorSlideAmt * rowPercent)]
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
    else if sType = m.constants.ui.contentTypes.purpleCarpetEvent
      populateInfoPanel(m.constants.ui.infoPanelModes.purpleCarpetBanner, focusedContent) 
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
    '//if the CategoryGridList is in focus, then alter the UI.  d
    if focusedContent <> invalid
      if focusedContent.type <> m.constants.ui.gridItemTypes.linear AND oldFocusedContent <> invalid AND oldFocusedContent.type = m.constants.ui.gridItemTypes.linear
        m.top.stopLinearVideoPlayer = true
      end if

      m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(focusedContent, m.CategoryGridList.focusedPosition)
      m.top.contentFocused = focusedContent
      ' Only proceed if row is not purple carpet.
      ' Only proceed if the spotlight row is disabled or if parent id is not featured if user has spotlight enabled.
      ' This is because the spotlight has seperate infopanel within category grid list.
      if focusedContent.gridItemType <> m.constants.ui.gridItemTypes.purpleCarpet AND (m.isSpotlightRowEnabled = false OR focusedContent.gridItemType <> m.constants.ui.gridItemTypes.spotlight)
        populateInfoPanelByContent(focusedContent)
      end if
      
      if focusedContent.gridItemType = m.constants.ui.gridItemTypes.purpleCarpet
        fadeOutInfoPanel()
        ' Since info panel always focus the information related to primary content and not the secondary rowlist item even if it gets focused.
        m.top.backgroundUriList = determineBackgroundImage(m.top.primaryEventContent)
      else if (m.isSpotlightRowEnabled = true AND focusedContent.gridItemType = m.constants.ui.gridItemTypes.spotlight)
        fadeOutInfoPanel()
        m.top.backgroundUriList = determineBackgroundImage(focusedContent)
      else
        fadeInContentArea()
      end if
      
    end if

  end if

  'Set up the navigateWithinPageInfo to send to ContentController via Homescreen. Need for when CategoryGridList is in focus
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

  reloadedItemToBeFocused = m.CategoryGridList.reloadedItemToBeFocused
  'We are updating the infopanel for updated focused content, but not updating the contentFocused.
  'Here we are updating the contentFocused, so it will play correct video preview when the content is updated.
  m.top.contentFocused = reloadedItemToBeFocused

  if reloadedItemToBeFocused <> invalid AND reloadedItemToBeFocused.gridItemType <> m.constants.ui.gridItemTypes.spotlight AND reloadedItemToBeFocused.gridItemType <> m.constants.ui.gridItemTypes.purpleCarpet
    ' Covers use cases where info panel was hidden but due to home screen container changes purple carpet or spotlight is removed and info panel was reset.
    fadeInContentArea()
    populateInfoPanelByContent(reloadedItemToBeFocused)
  else
    ' Making sure the background is also updated if a purple carpet or spotlight row is focused.
    m.top.backgroundUriList = determineBackgroundImage(reloadedItemToBeFocused)
  end if
End Function


'@mode: string, one of the valid constants.ui.infoPanelModes info panel modes (see InfoPanel.xml for details)
'@contentNode: content node
Function populateInfoPanel(mode, contentNode)
  if contentNode <> invalid
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
    else if mode = m.constants.ui.infoPanelModes.purpleCarpetBanner
      populateInfoPanelWithPurpleCarpetBannerMode(contentNode, m.InfoPanel)
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


Function setFocusOnCategoryGrid()
  tubiLog("Homescreen.setFocusOnCategoryGrid" + m.top.id)
  ' Only fade in content area if last focused was not spotlight or purple carept.
  focusedContent = m.categoryGridList.itemFocused
  if focusedContent <> invalid AND focusedContent.gridItemType = m.constants.ui.gridItemTypes.purpleCarpet
    fadeOutInfoPanel()
    ' Since info panel always focus the information related to primary content and not the secondary rowlist item even if it gets focused.
    m.top.backgroundUriList = determineBackgroundImage(m.top.primaryEventContent)
  else if focusedContent <> invalid AND (m.isSpotlightRowEnabled = true AND focusedContent.gridItemType = m.constants.ui.gridItemTypes.spotlight)
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
    m.infoPanelFade = fade(m.InfoPanelParent, "in", .4, 0.0, 1)
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
      if m.top.isVideoPreviewOn = true
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
  if m.top.isLoading <> true
    itemFocused = m.CategoryGridList.itemFocused
    positionFocused = m.top.cursorPosition
    m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(itemFocused, positionFocused)

    if m.top.isVideoPreviewOn = true
      m.top.stopVideoPreview = true
    end if

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
  '//Determine if the rowlist or a special row is in focus
  nRowInFocus = -1
  focusedContent = m.CategoryGridList.itemFocused
  if focusedContent <> invalid AND (focusedContent.gridItemType <> m.constants.ui.gridItemTypes.purpleCarpet) AND (m.isSpotlightRowEnabled = false OR focusedContent.gridItemType <> m.constants.ui.gridItemTypes.spotlight)
    if m.CategoryGridList.cursorPosition <> invalid
      nRowInFocus = m.CategoryGridList.cursorPosition[0]
    else
      nRowInFocus = 0
    end if
  end if
  moveContentAreaMask(nRowInFocus)

End Function


Function onEventCtaListItemSelectedChange(msg)
  buttonId = msg.getData()

  trackingPageInfo = m.top.trackingPageInfo
  if buttonId = "reminder" AND m.top.primaryEventContent <> invalid AND trackingPageInfo <> invalid
    componentValues = {
      video_id: m.top.primaryEventContent.id
    }
  
    if m.top.didUserSetReminderForEventContent = false
      userInteractionValue = "TOGGLE_ON"
    else
      userInteractionValue = "TOGGLE_OFF"
    end if
  
    pageOneof = m.Tracking.getAnalyticsPage(trackingPageInfo.pagetype, trackingPageInfo.pageValues)
    componentOneof = m.Tracking.getAnalyticsComponent("reminder_component", componentValues)
  
    m.top.componentInteractionInfo =  {
      pageOneof: pageOneof
      componentOneof: componentOneof
      user_interaction: userInteractionValue
    }
  end if
End Function