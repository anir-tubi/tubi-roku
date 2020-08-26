Function init()
  tubiLog("HomeScreen.init")
  m._ = rodash()
  m.constants = m.global.constants
  Request = TubiRequest(m.constants.settings.mode)
  Auth = TubiAuth(m.constants, Request)
  m.trackingLoggingTask = m.global.trackingLoggingTask
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.ContentArea = m.top.findNode("ContentArea")
  m.NavSection = m.top.findNode("nav")
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.HintGroup = m.top.findNode("UpHintGroup")
  fades = m.top.findNode("Fades")
  m.HintGroupFade = fades.findNode("HintGroupFade")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("categoryMenuVisible", "onCategoryMenuVisible")
  m.top.observeField("enabled", "onEnableChange")
  m.top.observeField("isLoading", "onLoadingChange")
  m.top.observeField("resetContentAreaValues", "onResetContentAreaValues")
  m.top.observeField("id", "onIDChange")
  
  m.CategoryRefreshTimer = m.top.findNode("CategoryRefreshTimer")
  m.CategoryRefreshTimer.duration = m.constants.timers.categoryContentRefreshTimeout
  m.CategoryRefreshTimer.observeField("fire", "onCategoryRefreshTimer")
  m.CategoryRefreshTimer.control = "start"
  
  'Content area
  m.CategoryGridList = m.top.findNode("CategoryGridList")
  m.CategoryGridList.observeField("itemSelected", "onGridItemSelected")
  m.CategoryGridList.observeField("itemFocused", "onGridFocusChange")
  m.CategoryGridList.observeField("categoryTotalCounts", "onTotalCountsChange")
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

  m.utilityMaskOffsetDiff = -100  'the diff in the amount the content area mask is offset in the up direction for utility
  
  ' Video in the grid constants
  m.vitgSlideAmt = 410  'the amount the grid slides up to fit the vitg content item
  m.vitgMaskOffsetDiff = 436  'the diff in the amount the content area mask is offset in the up direction for vitg
  m.originalContentAreaTranslation = m.ContentArea.translation
  m.vitgContentAreaTranslation = [m.ContentArea.translation[0], m.ContentArea.translation[1] - m.vitgSlideAmt]
  m.originalContentAreaMaskOffset = m.ContentArea.maskOffset

  ' utility row position experiment
  m.utilityRowPosition = -2
  experimentInfo = getExperimentResource("roku_discovery_v1", "roku_discovery_row_v1", false)
  if experimentInfo <> invalid and experimentInfo.position
    ' decreasing the position value by 1 in order to use it as index
    m.utilityRowPosition = experimentInfo.position - 1
  end if
  
  if m.global.authInfo <> invalid and m.global.authInfo.parentalrating <> invalid
    m.top.parentalRating = m.global.authInfo.parentalrating
  end if
  
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
  else
    newTrackingPageInfo.pageType = "home_page"
    m.top.screenLevel = m.constants.ui.screenLevels.homeScreen
  end if
  m.top.trackingPageInfo = newTrackingPageInfo
End Function


Function onLoadingChange()
  bLoaded = (m.top.isLoading = false)
  m.CategoryGridList.visible = bLoaded
  if m.top.isLoading = true
    m.CategoryGridList.content = invalid
    emptyContentNode = CreateObject("roSGNode", "TubiContentNode")
    populateInfoPanel("item", emptyContentNode) 'empties the info panel
  end if
  m.CategoryGridList.content = m.top.content  ' should be all categories with initial amounts of content in them
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
  if m.top.hasFocus()
    m.gridHasFocus = true
    m.CategoryGridList.setFocus(true)
    if m.CategoryGridList.content <> invalid and shouldRefresh(m.CategoryGridList.content) = true
      m.top.loadAllCategories = true
    end if
  else if m.top.isInFocusChain() = false
    m.gridHasFocus = false
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
    if rowEnteringFocus = m.utilityRowPosition
      m.CategoryGridList.getChild(0).focusBitmapUri = "pkg:/images/tab_component_alt_fhd.9.png"
      if m.constants.deviceInfo.scaledUi = true then
        m.CategoryGridList.getChild(0).focusBitmapUri = "pkg:/images/tab_component_alt_hd.9.png"
      end if
      m.CategoryGridList.getChild(0).drawFocusFeedbackOnTop = false
    else
      m.CategoryGridList.getChild(0).focusBitmapUri = "pkg:/images/selector-fhd.9.png"
      m.CategoryGridList.getChild(0).drawFocusFeedbackOnTop = true 
    end if
    ' calling getExperimentResource() automatically sends the exposure, and limits sending the exposure event to once per session.
    if rowEnteringFocus = 1 ' sending exposure event when the 2nd row gains focus
      getExperimentResource("roku_discovery_v1", "roku_discovery_row_v1")
    end if
  else
    m.CategoryGridList.getChild(0).focusBitmapUri = "pkg:/images/selector-fhd.9.png"
    m.CategoryGridList.getChild(0).drawFocusFeedbackOnTop = true
  end if

  if categoryEnteringFocus <> invalid and categoryEnteringFocus.gridItemType = m.constants.ui.gridItemTypes.utility
    expandMaskOffsetForUtility(rowPercent)
  else if categoryLosingFocus <> invalid and categoryLosingFocus.gridItemType = m.constants.ui.gridItemTypes.utility
    contractMaskOffsetForUtility(rowPercent)
  else if categoryEnteringFocus <> invalid and categoryEnteringFocus.gridItemType = m.constants.ui.gridItemTypes.vitg_large
    ' update contentArea translation, only when VITG gain focus
    expandContentAreaForLargeVitg(rowPercent)
  else if categoryLosingFocus <> invalid and categoryLosingFocus.gridItemType = m.constants.ui.gridItemTypes.vitg_large
    ' update contentArea translation, only when VITG lose focus
    contractContentAreaForLargeVitg(rowPercent)
  else if categoryEnteringFocus <> invalid and categoryEnteringFocus.gridItemType <> m.constants.ui.gridItemTypes.vitg_large
    if categoryLosingFocus <> invalid and categoryLosingFocus.gridItemType <> m.constants.ui.gridItemTypes.vitg_large
      ' In the case of fast scrolling many rows of the grid, across the large vitg row, the category grid list may
      ' not finish it's translation animation as the focus leaves the vitg row. We correct for that as the focus scolls
      ' through non video in the grid rows.
      if m.ContentArea.translation[1] <> m.originalContentAreaTranslation[1]
        translationDiffPercent = (m.originalContentAreaTranslation[1] - m.ContentArea.translation[1]) / m.vitgSlideAmt

        if rowPercent > (1 - translationDiffPercent)
          contractContentAreaForLargeVitg(rowPercent)
        end if
      end if
    end if
  end if
  
  ' update m.lastFocusPositioin or reset if we've concluded the scroll animation
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


'''''''''''''''''''''
' onGridFocusChange
'
' On grid focus change, update the info panel
Function onGridFocusChange() As Void
  tubiLog("HomeScreen.onGridFocusChange")
  m.top.contentReady = true

  if not m.CategoryGridList.isInFocusChain() or m.top.isLoading = true then return

  oldFocusedContent = m.CategoryGridList.oldItemFocused
  focusedContent = m.CategoryGridList.itemFocused
  
  if focusedContent <> invalid
    if focusedContent.type = m.constants.ui.categoryTypes.utility
      populateInfoPanel("utility", focusedContent)
    else
      populateInfoPanel("item", focusedContent)
    end if
  end if

  ' If focus is on an empty category, leave the background as is.  This helps avoid
  ' background jank and keeps CPU usage down while categories are being fetched.
  if focusedContent <> invalid
    m.top.backgroundUriList = determineBackgroundImage(focusedContent)
  end if

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
        pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, {})
        componentOneof: m.Tracking.getAnalyticsComponent("category_component", categoryComponentInfo)
        means_of_navigation: "BUTTON"  'MeansOfNavigation enum
        vertical_location: newAnalyticsRow
        vertical_location_mode: "INDEX"  'LocationMode enum
        horizontal_location: newAnalyticsCol
        horizontal_location_mode: "INDEX"  'LocationMode enum
      }
    end if
  end if
  m.gridHasFocus = true
End Function


Function onGridItemSelected() As Void
  tubiLog("HomeScreen.onGridItemSelected")
  if m.top.isLoading <> true
    selectedItem = m.CategoryGridList.itemSelected
    
    componentValues = {}
    componentValues["category_slug"] = m.top.currCategoryId
    componentValues["category_row"] = m.top.selectedPosition[0] + 1  'all analytics are 1 based
    tile = m.Tracking.getAnalyticsTile(selectedItem, m.top.selectedPosition[1] + 1)
    
    if selectedItem.type = m.constants.ui.categoryTypes.utility
      componentValues["utility_tile"] = tile
    else
      componentValues["content_tile"] = tile 
    end if
    
    ' Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
    m.top.trackingComponentInfo = {
      componentType: "category_component"
      componentValues: componentValues
    }

    ' Content controller observes contentSelected to populate/push the detail screen
    if selectedItem <> invalid then 
      m.top.contentSelected = selectedItem
      m.gridHasFocus = false
      m.listHasFocus = false
    end if
  end if
End Function


Function onTotalCountsChange(msg)
  tubiLog("HomeScreen.onTotalCountsChange")
  totalCountInfo = msg.getData()

  for i=totalCountInfo.count()-1 to 0 Step -1
    categoryInList = m.top.content.getChild(i)
    categoryInList.totalCount = totalCountInfo[i]

    'category has no content, so we delete it here
    if categoryInList.totalCount = -1
      m.top.content.removeChildIndex(i)
    end if
  end for

  m.CategoryGridList.content = m.top.content
End Function


' Is called when CategoryGridList has content loaded but did not gain focus, so we need to update the infoPanel
Function onItemToBeFocusedChange()
  m.top.contentReady = true
  populateInfoPanel("item", m.CategoryGridList.reloadedItemToBeFocused)
End Function


'@mode: string, one of the valid info panel modes (see InfoPanel.brs for details)
'@contentNode: content node
Function populateInfoPanel(mode, contentNode)
  if contentNode <> invalid
    if mode = "category"
      m.InfoPanel.mode = "category"
      m.InfoPanel.categoryContentCount = contentNode.totalCount
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description
      m.InfoPanel.titleLogoUri = contentNode.logoUri
    else if mode = "item"
      m.InfoPanel.mode = "item"
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
    else if mode = "utility"
      m.InfoPanel.mode = "utility"
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description
    end if

    m.InfoPanel.calculateHeight = true
  end if
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
