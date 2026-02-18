' Initializes the HomeScreen component
' Sets up observers, node references, tracking, and initial UI state
Function init()
  tubiLog("HomeScreen.init")

  m._ = rodash()
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  topRef = m.top
  topRef.shouldShowSideNav = true

  m.dimMask = topRef.findNode("dimMask")
  m.PageGroup = topRef.findNode("PageGroup")
  m.PageGroup.translation = [m.constants.ui.translations.marginX, 0]
  m.ContentAreaParent = topRef.findNode("ContentAreaParent")
  m.maskUri = "pkg:/images/poster-mask.png"
  ' Note: maskUri will be updated when enableVideoTiles field is set
  m.ContentArea = topRef.findNode("ContentArea")
  m.ContentArea.maskUri = m.maskUri
  m.adContentGroup = topRef.findNode("adContentGroup")
  m.InfoPanel = topRef.findNode("InfoPanel")
  m.InfoPanelParent = topRef.findNode("InfoPanelParent")
  m.backButtonHint = topRef.findNode("backButtonHint")
  m.pivotContentArea = topRef.findNode("pivotContentArea")
  if m.constants.deviceInfo.scaledUi = true
    m.pivotContentArea.maskSize = [1106, 42]
  else
    m.pivotContentArea.maskSize = [1659, 63]
  end if
  m.pivotList = topRef.findNode("pivotList")
  m.pivotList.observeFieldScoped("pivotFocused", "onPivotFocusedChange")
  m.pivotList.observeFieldScoped("componentInteractionInfo", "onPivotComponentInteractionInfo")
  m.pivotList.observeFieldScoped("navigateWithinPageInfo", "onPivotNavigateWithinPageInfo")
  m.pivotList.observeFieldScoped("trackingComponentInfo", "onPivotTrackingComponentInfo")
  topRef.observeFieldScoped("showPivots", "onShowPivotsChange")

  topRef.observeField("focusedChild", "onScreenFocusChange")
  topRef.observeFieldScoped("signedIn", "onSignedInChange")
  topRef.observeFieldScoped("categoryMenuVisible", "onCategoryMenuVisible")
  topRef.observeFieldScoped("isLoading", "onLoadingChange")
  topRef.observeFieldScoped("resetContentAreaValues", "onResetContentAreaValues")
  topRef.observeFieldScoped("id", "onIDChange")
  topRef.observeFieldScoped("fullscreenCountdown", "onFullscreenCountdown")
  topRef.observeFieldScoped("transportVoiceRequest", "onTransportVoiceRequest")
  topRef.observeFieldScoped("personalizationId", "onPersonalizationIdChanged")
  topRef.observeFieldScoped("contentUpdated", "onContentUpdated")
  topRef.observeFieldScoped("batchAdResponse", "onBatchAdResponseChanged")
  topRef.observeFieldScoped("allowCarouselAutoRotate", "onAllowCarouselAutoRotateChange")
  topRef.observeFieldScoped("kidsMode", "onKidsModeChange")
  topRef.observeFieldScoped("enableVideoTiles", "onEnableVideoTilesChange")
  topRef.observeFieldScoped("isVideoPreviewOn", "onIsVideoPreviewOnChange")
  m.CategoryRefreshTimer = topRef.findNode("CategoryRefreshTimer")
  m.CategoryRefreshTimer.duration = m.constants.timers.categoryContentRefreshTimeout
  m.CategoryRefreshTimer.observeFieldScoped("fire", "onCategoryRefreshTimer")
  m.CategoryRefreshTimer.control = "start"

  '//The timer that is used to countdown when to send pixels after an ad campaign gains focus.
  m.adFocusTimer = CreateObject("roSGNode", "Timer")
  m.adFocusTimer.duration = m.constants.timers.adFocusPixelFire
  m.adFocusTimer.observeFieldScoped("fire", "onAdFocusTimer")

  'Content area
  m.CategoryGridList = topRef.findNode("CategoryGridList")
  m.CategoryGridList.observeFieldScoped("itemSelected", "onGridItemSelected")
  m.CategoryGridList.observeFieldScoped("itemSelectedFromRowList", "onFeaturedItemSelected")
  m.CategoryGridList.observeFieldScoped("reloadedItemToBeFocused", "onItemToBeFocusedChange")
  m.CategoryGridList.observeFieldScoped("rowFocused", "onRowFocused")
  m.CategoryGridList.observeFieldScoped("gridContentIsReady", "onGridContentIsReadyChange")
  m.CategoryGridList.observeFieldScoped("listHasFocus", "onListHasFocusChange")
  m.CategoryGridList.observeFieldScoped("rowFocusedItem", "onRowFocusedItemChange")
  m.CategoryGridList.observeFieldScoped("hideInfoPanel", "onHideInfoPanelChange")
  m.CategoryGridList.observeFieldScoped("rowListTranslation", "updateRowListTranslation")
  m.ContentAreaParent.observeFieldScoped("translation", "updateRowListTranslation")

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

  m.scrollDirection = "none"
  m.videoTilesListTranslation = m.constants.ui.videoTilesListTranslation

  setContentAreaState()
End Function


' Handles enable video tiles field changes
' Updates mask URI based on video tiles state
Function onEnableVideoTilesChange()
  if m.top.enableVideoTiles = true
    m.maskUri = ""
  else
    m.maskUri = "pkg:/images/poster-mask.png"
  end if
  m.ContentArea.maskUri = m.maskUri
  setContentAreaState()
End Function


' Sets the content area state based on video tiles experiment and focus state
' Animates or directly sets the content area parent translation
Function setContentAreaState()
  tubiLog("HomeScreen.setToRedesignContentArea")

  ' Check if user is not in video tiles
  notInExperiment = (m.top.enableVideoTiles = false)

  ' Check if skin ad exists and rowlist is not focused
  hasSkinAdNotFocused = false
  if m.top.listHasFocus = false AND m.CategoryGridList <> invalid
    skinAdExists = (m.top.skinAdContent <> invalid AND m.top.skinAdContent.getChildCount() > 0)
    rowListNotFocused = (m.CategoryGridList.lastFocusedList <> "rowList")
    hasSkinAdNotFocused = (skinAdExists AND rowListNotFocused)
  end if

  shouldAnimate = false
  if notInExperiment OR hasSkinAdNotFocused
    m.currentContentAreaTranslation = m.originalContentAreaTranslation
    shouldAnimate = true
  else
    m.currentContentAreaTranslation = m.videoTilesListTranslation
  end if

  if shouldAnimate = true
    m.contentAreaAnimation = slideTo(m.ContentAreaParent, m.currentContentAreaTranslation, 0.2)
  else
    m.ContentAreaParent.translation = m.currentContentAreaTranslation
  end if
  updateRowListTranslation()
End Function


' Moves the content area mask to fade out rows underneath the focused row
' @param nFocusRow - The row that is or will be in focus (negative for special top row)
' @param nFocusingPercent - Progress indicator from 0 to 1 when row is gaining focus
Function moveContentAreaMask(nFocusRow = -1, nFocusingPercent = 1)
  '//nMaskYNew will most likely be set to 0 w/ the following line unless the content rowList has been moved to make way for a special top row.
  nMaskYNew = m.CategoryGridList.rowListTranslation[1]
  rowHeights = m.CategoryGridList.rowHeights

  if nFocusRow >= 0 AND isNonEmptyArray(rowHeights) = true
    nMaxRowHeights = rowHeights.count()
    if nFocusRow > (nMaxRowHeights - 1)
      '//If the rowHeights array doesn't contain as many row heights as the passed nFocusRow, then assume the current height is associated with the last item in the rowHeights array
      nFocusRow = nMaxRowHeights - 1
    end if
    nCurrentFocusedRowHeight = rowHeights[nFocusRow]
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


' Handles screen ID changes and updates tracking info and screen level
Function onIDChange()
  '//Set the tracking based on the id of the homescreen
  '//::NOTE:: id should only be set after the instantiation of the HomeScreen, but before the screen is added to the stack
  newTrackingPageInfo = m.top.trackingPageInfo
  analyticsContentMode = m.Tracking.getAnalyticsHomePageContentMode(m.top.id)

  newTrackingPageInfo.pageType = "home_page"
  newTrackingPageInfo.pageValues = { content_mode: analyticsContentMode }

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
  m.CategoryGridList.parentScreenId = m.top.id
  m.CategoryGridList.parentScreenTrackingPageInfo = newTrackingPageInfo
  m.pivotList.trackingPageInfo = newTrackingPageInfo
  m.pivotList.parentScreenId = m.top.id
End Function


' Handles personalization ID changes and updates tracking page info
' @param msg - Message containing new personalization ID
Function onPersonalizationIdChanged(msg)
  personalizationId = msg.getData()
  trackingPageInfo = m.top.trackingPageInfo

  if isAA(trackingPageInfo) = true AND isAA(trackingPageInfo.pageValues) = true
    trackingPageInfo.pageValues.personalization_id = personalizationId
    m.top.trackingPageInfo = trackingPageInfo
    m.CategoryGridList.parentScreenTrackingPageInfo = trackingPageInfo
    m.pivotList.trackingPageInfo = trackingPageInfo
  end if

End Function


' Handles content updates and manages ad carousel component creation
' Updates content area mask position based on skin ad presence
Function onContentUpdated()
  if m.top.contentUpdated = true
    content = m.top.content
    setContentAreaState()

    deleteAdDisplayCarouselComponent() '//remove any existing ad carousel component before creating a new one

    if isAdDisplayCarouselAvailable() = false
      for i = 0 to content.getChildCount() - 1
        item = content.getChild(i)
        if item <> invalid AND item.type = m.constants.ui.contentTypes.adRowlistCarousel
          '//If there is a carousel, then preload the component so it is ready to be displayed
          createAdDisplayCarouselComponent(item)
          exit for
        end if
      end for
    end if

    '//the presence or absence of a 1st-Row will dictate the starting point of the peek row mask
    if m.top.kidsMode = false AND (m.top.skinAdContent <> invalid AND m.top.skinAdContent.getChildCount() > 0) AND (m.top.lastFocusedList = "skinAdRow" OR m.top.lastFocusedList = "")
      moveContentAreaMask(-1)
      fadeOutInfoPanel()
    else
      moveContentAreaMask(0)
    end if
  end if
End Function


' Handles batch ad response changes and creates/updates ad carousel components
' Processes skin ad impression tracking updates
' @param msg - Message containing array of ad response data
Function onBatchAdResponseChanged(msg)
  tubiLog("HomeScreen.onBatchAdResponseChanged")
  aResponse = msg.getData()
  if isNonEmptyArray(aResponse) = true
    for i = aResponse.Count() - 1 to 0 step -1
      adContent = aResponse[i]
      if adContent <> invalid
        sContentType = adContent.type
        if sContentType = m.constants.ui.contentTypes.adRowlistCarousel
          createAdDisplayCarouselComponent(adContent)
        else if sContentType = m.constants.ui.contentTypes.skinAd
          if m.CategoryGridList.skinAdContent <> invalid AND m.CategoryGridList.skinAdContent.id = adContent.id AND adContent.getChild(0) <> invalid AND m.CategoryGridList.skinAdContent.getChild(0) <> invalid
            '// If the updated skinAd wrapper is the same as the existing one, then just update the impression tracking info.
            '// We are not expecting a new skinAd content during the app's lifecycle.
            m.CategoryGridList.skinAdContent.getChild(0).imageImpTracking = adContent.getChild(0).imageImpTracking

            '//Once the skin ad is processed, remove it from the array so that it is not processed with the other ads when adResponseInBatch is set below.
            aResponse.delete(i)
          end if
        end if
      end if
    end for
  end if
  m.CategoryGridList.adResponseInBatch = aResponse
End Function


' Handles changes to allow carousel auto rotate setting
' @param msg - Message containing new auto rotate value
Function onAllowCarouselAutoRotateChange(msg)
  tubiLog("HomeScreen.onAllowCarouselAutoRotateChange")
  allowCarouselAutoRotate = msg.getData()
  if isAdDisplayCarouselAvailable() = true
    m.adRowlistCarouselComponent.allowCarouselAutoRotate = allowCarouselAutoRotate
  end if
End Function


' Handles video preview setting changes
' Updates carousel video preview state when setting changes
Function onIsVideoPreviewOnChange(msg)
  isVideoPreviewOn = msg.getData()
  if isAdDisplayCarouselAvailable() = true
    m.adRowlistCarouselComponent.isVideoPreviewOn = isVideoPreviewOn
  end if
End Function


' Handles loading state changes
' Clears content and resets UI when loading starts
Function onLoadingChange()
  tubiLog("HomeScreen.onLoadingChange")
  bLoaded = (m.top.isLoading = false)
  m.CategoryGridList.visible = bLoaded
  if m.top.isLoading = true
    m.adFocusTimer.control = "stop"
    m.top.contentFocused = invalid
    m.top.contentReady = false
    emptyContentNode = CreateObject("roSGNode", "TubiContentNode")
    populateInfoPanel(m.constants.ui.infoPanelModes.item, emptyContentNode) 'empties the info panel
    m.CategoryGridList.content = invalid ' should be all categories with initial amounts of content in them
    m.CategoryGridList.skinAdContent = invalid
    deleteAdDisplayCarouselComponent()
    m.top.adContent = invalid
    m.CategoryGridList.content = invalid
    m.CategoryGridList.skinAdContentUpdated = true
    m.top.content = invalid
    m.CategoryGridList.resetRowList = true

    ' Resetting the previous state variables.
    m.CategoryGridList.listCurrFocusRow = -1
    m.CategoryGridList.rowCurrFocusColumn = -1
    m.CategoryGridList.listScrollDirection = "none"
    m.CategoryGridList.rowFocusedItem = invalid
    m.CategoryGridList.listHasFocus = false

    ' Resetting last focus list when reloading the screen.
    ' To Cover cases where skin ad is shown and then gets removed.
    m.CategoryGridList.lastFocusedList = ""
    setContentAreaState()
  end if
End Function


' Handles screen focus changes
' Refreshes content if needed when screen gains focus
Function onScreenFocusChange()
  tubiLog("HomeScreen.onScreenFocusChange " + focusState(m.top))
  if m.top.hasFocus() = true
    'TODO: Revisit this if we ever use both.
    content = m.CategoryGridList.content
    if content <> invalid
      if shouldRefresh(content) = true
        m.top.loadAllCategories = true
      else 'check if any containers has expired
        refreshHomeScreenContainers()
      end if
    end if

    if m.pivotList.content <> invalid AND (m.top.lastFocusedList = "pivotList" OR m.top.sideNavFocusedPosition = 0)
      focusedContent = m.CategoryGridList.rowFocusedItem
      if focusedContent <> invalid AND focusedContent.gridItemType = m.constants.ui.gridItemTypes.skinAd
        m.top.contentFocused = focusedContent
      end if
      m.pivotList.setFocus(true)
      ' Fire NavigateWithinPage from side nav to pivot when coming from side nav
      if m.top.sideNavFocusedPosition = 0
        fireNavigateFromSideNavToPivotEvent()
        m.top.sideNavFocusedPosition = -1
      end if
    else
      setFocusOnCategoryGrid()
    end if

    m.top.shouldFocusWhenPushed = true
  else if m.top.isInFocusChain() = false
    m.adFocusTimer.control = "stop"
    m.top.focusLost = true
  end if
End Function


' Handles signed in state changes
' Updates CategoryGridList with new signed in status
Function onSignedInChange()
  tubiLog("HomeScreen.onSignedInChange")
  m.CategoryGridList.signedIn = m.top.signedIn
End Function


' Handles reset content area values request
Function onResetContentAreaValues()
  contractContentAreaToOriginal(1.0)
End Function


' Handles row focus changes in CategoryGridList
' Manages ad focus timer for sponsored and ad rows
' @param msg - Message containing newly focused row
Function onRowFocused(msg)
  tubiLog("HomeScreen.onRowFocused")
  row = msg.getData()
  oldRow = m.CategoryGridList.oldRowFocused
  isRowAdContainerContainer = false
  if row <> invalid
    if isSponsoredRow(row) = true
      m.top.sponsoredRowFocused = true
    else if oldRow = invalid OR row.id <> oldRow.id '//If the oldRow is the same as the new row, then do not check if the adFocusTimer should be started. This is to prevent sending too many pixel impressions.
      if (isAdDisplayContainerRow(row) = true OR isAdDisplayCarouselRow(row) = true OR isAdSkinRow(row) = true) AND isNonEmptyArray(row.imageImpTracking) = true
        isRowAdContainerContainer = true
      end if
    end if
  end if

  if isRowAdContainerContainer = false
    m.adFocusTimer.control = "stop"
  else
    m.adFocusTimer.control = "start"
  end if
End Function


' Checks if row is a sponsored row
' @param row - CategoryContentNode to check
' @return Boolean - True if row has sponsor images and pixels
Function isSponsoredRow(row)
  if row.sponsorImages <> invalid AND row.sponsorImages.pixels <> invalid AND row.sponsorImages.pixels["homescreen"] <> invalid
    return true
  end if

  return false
End Function


' Checks if row is an ad skin row
' @param row - CategoryContentNode to check
' @return Boolean - True if row is a skin ad type
Function isAdSkinRow(row)
  return (row <> invalid AND row.gridItemType = m.constants.ui.gridItemTypes.skinAd)
End Function


' Checks if row is an ad display carousel row
' @param row - CategoryContentNode to check
' @return Boolean - True if row is an ad carousel type
Function isAdDisplayCarouselRow(row)
  return (row <> invalid AND row.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel)
End Function


' Checks if row is an ad display container row
' @param row - CategoryContentNode to check
' @return Boolean - True if row is an ad spotlight type
Function isAdDisplayContainerRow(row)
  return (row <> invalid AND row.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight)
End Function


' Handles ad carousel content focus changes
' Updates background and content focused fields
' @param msg - Message containing focused content
Function onAdDisplayCarouselContentFocusedChanged(msg)
  contentFocused = msg.getData()
  if contentFocused <> invalid
    m.top.contentFocused = contentFocused
    m.top.backgroundUriList = contentFocused.backgrounds
  end if
End Function


' Handles manual navigation within ad carousel
' Fires navigate within page tracking event
' @param msg - Message from carousel tile navigation
Function onAdDisplayCarouselContentFocusedManually(msg)
  carouselComponent = msg.getRoSGNode()
  if carouselComponent <> invalid AND carouselComponent.itemFocused >= 0 AND carouselComponent.itemFocused <> carouselComponent.itemUnfocused AND carouselComponent.itemUnfocused >= 0
    nOldFocusCol = carouselComponent.itemUnfocused + 1
    nNewFocusCol = carouselComponent.itemFocused + 1
    categoryComponentInfo = {}
    categoryComponentInfo["category_slug"] = m.CategoryGridList.currCategoryId

    ' The rowIndexBoost is 1 based. And Roku row list index is 0 based.
    rowIndexBoost = m.CategoryGridList.rowIndexBoost + 1
    '//user starting at the following row/column
    categoryComponentInfo["category_row"] = m.CategoryGridList.cursorPosition[0] + rowIndexBoost 'all analytics are 1 based
    categoryComponentInfo["category_col"] = nOldFocusCol
    'row is hardcoded to 1 in the line below because the row represents the row within the category_component, not within the grid
    'and the current design only has one row per category
    tile = m.Tracking.getAnalyticsTile(m.CategoryGridList.itemFocused, nOldFocusCol, 1)
    categoryComponentInfo["content_tile"] = tile

    m.top.navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent("category_component", categoryComponentInfo)
      means_of_navigation: "BUTTON" 'MeansOfNavigation enum
      vertical_location: m.CategoryGridList.cursorPosition[0] + rowIndexBoost 'all analytics are 1 based
      horizontal_location: nNewFocusCol
    }
  end if
End Function


' Gradually contracts content area back to original position
' @param rowPercent - Percentage of row focus progress (0-1)
Function contractContentAreaToOriginal(rowPercent)
  tubiLog("HomeScreen.contractContentAreaToOriginal")

  if m.ContentAreaParent.translation[1] <> m.currentContentAreaTranslation[1]
    'gradually reset back to original position
    if rowPercent < 0.95
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


' Expands content area for sponsorship row display
' Adjusts row list position and info panel opacity
' @param rowPercent - Percentage of sponsorship row focus progress (0-1)
Function expandContentAreaForSponsorship(rowPercent)
  m.ContentAreaParent.translation = [m.ContentAreaParent.translation[0], m.currentContentAreaTranslation[1] - (m.sponsorSlideAmt * rowPercent)]

  if m.InfoPanel.opacity < 0
    '//gradually display the info panel as the sponsorship row comes into view
    if rowPercent < 0.95
      m.InfoPanel.opacity = rowPercent
    else
      m.InfoPanel.opacity = 1
    end if
  end if
End Function


' Expands content area for containers without info panel
' Hides info panel and brings content to top of screen
' @param rowPercent - Percentage of container focus progress (0-1)
Function expandContentAreaForContainersWithoutInfoPanel(rowPercent)
  nDiffHeight = m.originalContentAreaTranslation[1] - 102 '//bring this to the top of the screen
  if m.currentContentAreaTranslation[1] = m.videoTilesListTranslation[1]
    nDiffHeight = m.currentContentAreaTranslation[1] + 302 '//bring this to the top of the screen if the home redesign is enabled
  end if
  m.ContentAreaParent.translation = [m.ContentAreaParent.translation[0], m.currentContentAreaTranslation[1] - (nDiffHeight * rowPercent)]

  '//gradually hide the info panel as the adRowlistSpotlight comes into view
  stopAnimation(m.infoPanelFade)
  if rowPercent < 0.95
    m.InfoPanelParent.opacity = 1 - rowPercent
  else
    m.InfoPanelParent.opacity = 0
  end if
End Function


' Expands content area for ad display carousel
' Hides info panel and brings content to top of screen
' @param rowPercent - Percentage of carousel focus progress (0-1)
Function expandContentAreaForAdDisplayCarousel(rowPercent)
  nDiffHeight = m.originalContentAreaTranslation[1] - 102 '//bring this to the top of the screen
  if m.currentContentAreaTranslation[1] = m.videoTilesListTranslation[1]
    nDiffHeight = m.currentContentAreaTranslation[1] + 302 '//bring this to the top of the screen if the home redesign is enabled
  end if
  m.ContentAreaParent.translation = [m.ContentAreaParent.translation[0], m.currentContentAreaTranslation[1] - (nDiffHeight * rowPercent)]
  '//gradually hide the info panel as the adRowlistCarousel comes into view
  stopAnimation(m.infoPanelFade)
  if rowPercent < 0.95
    m.InfoPanelParent.opacity = 1 - rowPercent
  else
    m.InfoPanelParent.opacity = 0
  end if
End Function


' Populates info panel based on focused content type
' @param focusedContent - Content node to display in info panel
Function populateInfoPanelByContent(focusedContent)
  if focusedContent <> invalid
    sType = focusedContent.type

    if focusedContent.scheduleData <> invalid
      populateInfoPanel(m.constants.ui.infoPanelModes.item, focusedContent)
    else if sType = m.constants.ui.contentTypes.linear
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


' Handles list focus state changes
' Fades out info panel and updates content area state
' @param _msg - Message containing new focus state
Function onListHasFocusChange(_msg)
  setContentAreaState()
End Function


' Handles featured item selection from CategoryGridList
Function onFeaturedItemSelected()
  selectedItem = m.CategoryGridList.itemSelectedFromRowList
  handleItemSelected(selectedItem, m.top.selectedPosition)
End Function


' Handles row focused item changes
' Updates content, background, and info panel based on grid item type
' @param msg - Message containing newly focused item
Function onRowFocusedItemChange(msg) as Void
  focusedContent = msg.getData()

  ' Early returns for invalid states
  if m.CategoryGridList.isInFocusChain() = false OR m.top.isLoading = true OR focusedContent = invalid
    return
  end if

  if m.top.contentReady = false
    m.top.contentReady = true
  end if

  m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(focusedContent, m.categoryGridList.focusedPosition)
  ' Update focused content
  m.top.contentFocused = focusedContent

  ' Handle content based on grid item type
  gridItemType = focusedContent.gridItemType

  m.pivotList.visible = gridItemType <> m.constants.ui.gridItemTypes.adRowlistSpotlight AND gridItemType <> m.constants.ui.gridItemTypes.adRowlistCarousel AND m.pivotList.content <> invalid

  if gridItemType = m.constants.ui.gridItemTypes.skinAd OR gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight
    m.top.backgroundUriList = determineBackgroundImage(focusedContent)
  else if focusedContent.type = m.constants.ui.contentTypes.adRowlistCarousel
    displayAdDisplayCarousel()
  else
    if gridItemType <> m.constants.ui.gridItemTypes.videoTile AND m.top.enableVideoTiles <> true
      populateInfoPanelByContent(focusedContent)
      fadeInContentArea()
    end if
  end if

  fireNavigateWithinPageEvent()
End Function


' Deletes the ad display carousel component
' Removes observers and handles focus transfer
Function deleteAdDisplayCarouselComponent()
  tubiLog("HomeScreen.deleteAdDisplayCarouselComponent")
  if m.adRowlistCarouselComponent <> invalid
    m.adRowlistCarouselComponent.unobserveFieldScoped("contentFocused")
    m.adRowlistCarouselComponent.unobserveFieldScoped("tileManuallyNavigated")
    if m.adRowlistCarouselComponent.isInFocusChain() = true
      m.CategoryGridList.setFocus(true)
    end if
    m.adRowlistCarouselComponent.opacity = 0
    onCarouselFadeOutComplete()
    m.adContentGroup.removeChild(m.adRowlistCarouselComponent)
    '//NOTE:: do not set m.adRowlistCarouselComponent to invalid, as it may need to be reused later and the AnimationMixin may have a reference to the original component
  end if
End Function


' Checks if ad display carousel component is available and visible
' @return Boolean - True if carousel exists and has parent node
Function isAdDisplayCarouselAvailable()
  return (m.adRowlistCarouselComponent <> invalid AND m.adRowlistCarouselComponent.getParent() <> invalid)
End Function


' Creates or updates ad display carousel component
' @param content - Ad carousel content node
Function createAdDisplayCarouselComponent(content)
  tubiLog("HomeScreen.createAdDisplayCarouselComponent")
  if content.type = m.constants.ui.contentTypes.adRowlistCarousel

    if content.getChildCount() = 0 AND isAdDisplayCarouselAvailable() = true
      '//if the content is empty, then remove the adRowlistCarouselComponent
      deleteAdDisplayCarouselComponent()
    else if content.getChildCount() > 0
      bCarouselHasFocus = (isAdDisplayCarouselAvailable() = true AND m.adRowlistCarouselComponent.isInFocusChain() = true)
      if m.adRowlistCarouselComponent = invalid
        m.adRowlistCarouselComponent = CreateObject("roSGNode", "AdDisplayCarousel")
      else
        m.adRowlistCarouselComponent.unobserveFieldScoped("contentFocused")
        m.adRowlistCarouselComponent.unobserveFieldScoped("tileManuallyNavigated")
      end if

      m.adRowlistCarouselComponent.observeFieldScoped("contentFocused", "onAdDisplayCarouselContentFocusedChanged")
      m.adRowlistCarouselComponent.observeFieldScoped("tileManuallyNavigated", "onAdDisplayCarouselContentFocusedManually")
      m.adRowlistCarouselComponent.id = "adRowlistCarousel"
      m.adRowlistCarouselComponent.opacity = 0
      m.adRowlistCarouselComponent.isVideoPreviewOn = m.top.isVideoPreviewOn
      m.adRowlistCarouselComponent.content = content
      m.adRowlistCarouselComponent.updateContent = true
      m.adContentGroup.appendChild(m.adRowlistCarouselComponent)

      if bCarouselHasFocus = true
        displayAdDisplayCarousel()
      end if
    end if
  end if
End Function


' Fires navigate within page tracking event
' Tracks user navigation between grid items
Function fireNavigateWithinPageEvent()
  ' Set initial focus flag
  m.gridHasGainedInitialFocus = true

  ' Calculate analytics positions (1-based for analytics)
  rowIndexBoost = m.CategoryGridList.rowIndexBoost + 1
  oldAnalyticsRow = m.CategoryGridList.oldCursorPosition[0] + rowIndexBoost
  oldAnalyticsCol = m.CategoryGridList.oldCursorPosition[1] + 1
  newAnalyticsRow = m.CategoryGridList.cursorPosition[0] + rowIndexBoost
  newAnalyticsCol = m.CategoryGridList.cursorPosition[1] + 1

  ' Track navigation only if position changed and conditions are met
  shouldTrackNavigation = m.gridHasGainedInitialFocus = true AND oldAnalyticsRow > 0 AND oldAnalyticsCol > 0 AND m.top.isInFocusChain() = true
  positionChanged = oldAnalyticsRow <> newAnalyticsRow OR oldAnalyticsCol <> newAnalyticsCol

  if shouldTrackNavigation AND positionChanged
    oldFocusedContent = m.CategoryGridList.oldRowFocusedItem
    categoryComponentInfo = buildCategoryComponentInfo(oldFocusedContent, oldAnalyticsRow, oldAnalyticsCol)

    m.top.navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent("category_component", categoryComponentInfo)
      means_of_navigation: "BUTTON"
      vertical_location: newAnalyticsRow
      horizontal_location: newAnalyticsCol
    }
  end if

  ' Update tracking for rowList focus
  if m.CategoryGridList.lastFocusedList = "rowList"
    focusedContent = m.CategoryGridList.rowFocusedItem
    m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(focusedContent, m.CategoryGridList.cursorPosition)
  end if
End Function


' Builds category component info for tracking
' @param content - TubiContentNode that was focused
' @param analyticsRow - 1-based row position for analytics
' @param analyticsCol - 1-based column position for analytics
' @return Associative array with category component tracking information
Function buildCategoryComponentInfo(content, analyticsRow, analyticsCol)
  categoryComponentInfo = {
    "category_slug": m.CategoryGridList.oldCategoryId,
    "category_row": analyticsRow,
    "category_col": analyticsCol
  }

  ' Add tile information if content is valid
  ' Row is hardcoded to 1 because it represents the row within the category_component,
  ' not within the grid, and the current design only has one row per category
  if content <> invalid
    tileRowIndex = 1
    if content.type = m.constants.ui.contentTypes.channel
      tile = m.Tracking.getUtilityTile(content, analyticsCol, tileRowIndex)
      categoryComponentInfo["utility_tile"] = tile
    else if content.type <> "continue_watching_signed_out_user"
      tile = m.Tracking.getAnalyticsTile(content, analyticsCol, tileRowIndex)
      categoryComponentInfo["content_tile"] = tile
    end if
  end if

  return categoryComponentInfo
End Function


' Handles grid item selection
Function onGridItemSelected() as Void
  tubiLog("HomeScreen.onGridItemSelected")
  selectedItem = m.CategoryGridList.itemSelected
  handleItemSelected(selectedItem, m.top.selectedPosition)
End Function


' Handles item selection from grid
' Updates tracking and triggers content selection if not scrolling
' @param item - TubiContentNode that was selected
' @param position - 2D array with [x,y] grid coordinate
Function handleItemSelected(item, position)
  if m.top.isLoading <> true
    m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(item, position)

    ' Content controller observes contentSelected to populate/push the detail screen
    if item <> invalid then
      ' Use list scrolling status
      isScrolling = m.CategoryGridList.listScrollingStatus

      if isScrolling = false
        ' If the row is still scrolling, do not select the item.
        m.top.contentSelected = item
      end if
    end if
  end if
End Function


' Gets tracking component info for grid item
' @param gridItem - TubiContentNode to track
' @param itemPosition - 2D array with [x,y] grid coordinate
' @return Associative array with tracking component information
Function getTrackingComponentInfoOfCategoryGridList(gridItem, itemPosition)
  trackingComponentInfo = {}
  if gridItem <> invalid AND itemPosition <> invalid AND itemPosition.Count() = 2
    componentValues = {}
    componentValues["category_slug"] = m.top.currCategoryId
    ' The rowIndexBoost is 1 based. And Roku row list index is 0 based.
    rowIndexBoost = m.CategoryGridList.rowIndexBoost + 1

    componentValues["category_row"] = itemPosition[0] + rowIndexBoost 'all analytics are 1 based
    componentValues["category_col"] = itemPosition[1] + 1 'all analytics are 1 based
    if gridItem.type = m.constants.ui.contentTypes.channel
      tile = m.Tracking.getUtilityTile(gridItem, itemPosition[1] + 1)
      componentValues["utility_tile"] = tile
    else if gridItem.type <> "continue_watching_signed_out_user"
      tile = m.Tracking.getAnalyticsTile(gridItem, itemPosition[1] + 1)
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


' Handles item to be focused change when content loads without gaining focus
' Updates info panel and background for reloaded content
Function onItemToBeFocusedChange()
  tubiLog("HomeScreen.onItemToBeFocusedChange")
  if m.top.contentReady = false
    m.top.contentReady = true
  end if

  reloadedItemToBeFocused = m.CategoryGridList.reloadedItemToBeFocused
  'We are updating the infopanel for updated focused content, but not updating the contentFocused.
  'Here we are updating the contentFocused, so it will play correct video preview when the content is updated.
  m.top.contentFocused = reloadedItemToBeFocused

  if reloadedItemToBeFocused <> invalid AND reloadedItemToBeFocused.gridItemType <> m.constants.ui.gridItemTypes.skinAd AND reloadedItemToBeFocused.gridItemType <> m.constants.ui.gridItemTypes.adRowlistSpotlight
    ' Covers use cases where info panel was hidden but due to home screen container changes purple carpet is removed and info panel was reset.
    fadeInContentArea()
    populateInfoPanelByContent(reloadedItemToBeFocused)
  else
    ' Making sure the background is also updated
    m.top.backgroundUriList = determineBackgroundImage(reloadedItemToBeFocused)
  end if
End Function


' Populates info panel with content based on mode
' @param mode - Info panel mode (item, linearProgramHomescreen, continueWatching, sportsEvent)
' @param contentNode - Content node to display
Function populateInfoPanel(mode, contentNode)

  if contentNode <> invalid
    sType = contentNode.type
    if sType <> m.constants.ui.contentTypes.adRowlistCarousel AND sType <> m.constants.ui.contentTypes.adRowlistSpotlight
      ' The below is to ensure that there is slight delay in showing the info panel so that there is no overlap with any row that is gaining focus.
      if m.InfoPanel.visible = false
        slideFadeGeneral(m.InfoPanelParent, [0, 0], "in", 0.2)
      end if

      if mode = m.constants.ui.infoPanelModes.item
        if contentNode.scheduleData <> invalid
          populateInfoPanelForLiveEvent(contentNode, m.InfoPanel)
        else
          populateInfoPanelWithHomescreenStyleItemMode(contentNode, m.InfoPanel, true)
        end if
      else if mode = m.constants.ui.infoPanelModes.linearProgramHomescreen
        populateInfoPanelWithLinearProgramHomescreenMode(contentNode, m.InfoPanel) 'V4 api
      else if mode = m.constants.ui.infoPanelModes.continueWatching
        m.InfoPanel.mode = mode
        m.InfoPanel.title = contentNode.title
        m.InfoPanel.description = contentNode.description

        ' Always set needsLogin = false for linear content in infoPanel, regular content follows normal logic
        if contentNode.type = m.constants.ui.contentTypes.linear
          m.InfoPanel.needsLogin = false
        else if contentNode.needsLogin = true AND m.top.signedIn <> true
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
      m.infoPanelFade = slideFadeGeneral(m.InfoPanelParent, [0, -50], "out", 0.2)
    end if

  else
    m.infoPanelFade = slideFadeGeneral(m.InfoPanelParent, [0, -50], "out", 0.2)
    setContentAreaState()
  end if
End Function


' Handles fullscreen countdown changes
Function onFullscreenCountdown()
  m.InfoPanel.fullscreenCountdown = m.top.fullscreenCountdown
End Function


' Handles category refresh timer fire
' Triggers category reload via refresh timer
Function onCategoryRefreshTimer()
  tubiLog("HomeScreen.onCategoryRefreshTimer")
  m.top.loadAllCategoriesViaRefreshTimer = true
End Function


' Handles ad focus timer fire
' Triggers ad impression pixel firing for focused ad rows
Function onAdFocusTimer()
  tubiLog("HomeScreen.onAdFocusTimer")
  focusedContent = m.CategoryGridList.rowFocused

  if isAdDisplayContainerRow(focusedContent) = true OR isAdDisplayCarouselRow(focusedContent) = true OR isAdSkinRow(focusedContent) = true
    m.top.adTimerImpressionFire = true
  end if
End Function


' Sets focus on category grid and manages carousel/info panel visibility
Function setFocusOnCategoryGrid()
  tubiLog("Homescreen.setFocusOnCategoryGrid" + m.top.id)
  focusedContent = m.CategoryGridList.rowFocusedItem
  shouldPlaceFocusOnCategoryGridList = true
  if focusedContent <> invalid AND (focusedContent.gridItemType = m.constants.ui.gridItemTypes.skinAd OR focusedContent.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight OR focusedContent.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel)
    fadeOutInfoPanel()

    if focusedContent.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel AND isAdDisplayCarouselAvailable() = true
      shouldPlaceFocusOnCategoryGridList = false
      displayAdDisplayCarousel()
    else
      m.top.backgroundUriList = determineBackgroundImage(focusedContent)
    end if
  else
    fadeInContentArea()
  end if

  if shouldPlaceFocusOnCategoryGridList = true
    m.CategoryGridList.setFocus(true)
  end if
End Function


' Hides ad display carousel with fade out animation
Function hideAdDisplayCarousel()
  tubiLog("HomeScreen.hideAdDisplayCarousel")
  if isAdDisplayCarouselAvailable() = true
    '//There is a slight delay to the fade out, so the full-width carousel thumbnail does NOT get seen for a split second as another row gains focus.
    fade(m.adRowlistCarouselComponent, "out", 0.1, 0.1, 0, onCarouselFadeOutComplete)
  end if
End Function


' Displays ad display carousel and starts ad focus timer
Function displayAdDisplayCarousel()
  tubiLog("HomeScreen.displayAdDisplayCarousel")
  if isAdDisplayCarouselAvailable() = true
    m.adRowlistCarouselComponent.setFocus(true)
    if m.adRowlistCarouselComponent.content <> invalid AND isNonEmptyArray(m.adRowlistCarouselComponent.content.imageImpTracking) = true
      m.adFocusTimer.control = "start"
    end if

    if m.top.enableVideoTiles = true
      m.ContentArea.maskUri = "pkg:/images/poster-mask-ads-no-dim.png"
    else
      m.ContentArea.maskUri = "pkg:/images/poster-mask-ads.png"
    end if

    fade(m.adRowlistCarouselComponent, "in", 0.1)
  end if
End Function


' Handles carousel fade out completion
' Resets content area mask after carousel is hidden
Function onCarouselFadeOutComplete()
  tubiLog("HomeScreen.onCarouselFadeOutComplete")
  if isAdDisplayCarouselAvailable() = false OR m.adRowlistCarouselComponent.isInFocusChain() = false
    '//because onCarouselFadeOutComplete is sometimes called on a delay, we need to check if the component is still out of focus before resetting the mask
    m.ContentArea.maskUri = m.maskUri
  end if
End Function


' Fades in content area and info panel
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


' Fades out info panel
Function fadeOutInfoPanel()
  stopAnimation(m.infoPanelFade)
  m.infoPanelFade = fade(m.InfoPanelParent, "out", .4)
End Function


' Transitions focus from category grid to pivot list
' Resets category grid state, fires analytics, and sets focus on pivot list
' @param key - The key that triggered the focus change ("up" or "back")
Function focusPivotList(key as String) as Void
  if m.top.lastFocusedList = "rowList"
    m.CategoryGridList.resetCategoryGridState = true
  end if
  ' Fire ButtonComponent event for the key that triggered pivot focus
  fireButtonFocusPivotEvent(key)
  ' Fire toggle ON and navigate from category to pivot analytics
  onNavigatingToPivotMenu()
  m.top.lastFocusedList = "pivotList"
  m.top.pauseVideoPreview = true
  m.pivotList.setFocus(true)
End Function


' Animates the back button hint in and slides the pivot list to the right
Function showBackHint() as Void
  if m.isBackHintVisible = true then return
  m.isBackHintVisible = true
  fade(m.backButtonHint, "in", 0.3)
  slideTo(m.pivotList, [234, 0], 0.3)
End Function


' Animates the back button hint out and slides the pivot list back
Function hideBackHint() as Void
  if m.isBackHintVisible <> true then return
  m.isBackHintVisible = false
  fade(m.backButtonHint, "out", 0.3)
  slideTo(m.pivotList, [0, 0], 0.3)
End Function


' Handles key events for navigation and playback
' @param key - Key pressed (left, back, down, up, play)
' @param press - True if key is pressed, false if released
' @return Boolean - True if key was handled, false otherwise
Function onKeyEvent(key, press) as Boolean
  if press = true
    if key = "up" AND m.CategoryGridList.isInFocusChain() = true AND m.pivotList.content <> invalid
      focusPivotList("up")
      return true
    else if key = "down" AND m.pivotList.isInFocusChain() = true
      ' Fire TOGGLE_OFF when moving from pivot list back to category grid
      if m.pivotList.pivotFocusedNode <> invalid
        focusedPosition = m.pivotList.pivotFocused
        if isNonEmptyArray(focusedPosition) AND focusedPosition.count() >= 2
          firePivotComponentInteractionEvent(m.pivotList.pivotFocusedNode, focusedPosition[1], "TOGGLE_OFF")
        end if
      end if

      skinAdContent = m.top.skinAdContent
      if skinAdContent = invalid OR skinAdContent.getChildCount() = 0
        currentFocusRow = 0
        if isNonEmptyArray(m.top.cursorPosition) = true
          currentFocusRow = m.top.cursorPosition[0]
        end if
        m.CategoryGridList.requestFocusXOffsetUpdate = currentFocusRow
      end if
      ' Resetting the last focused so that category grid list decides where to set focus.
      m.top.lastFocusedList = ""
      m.CategoryGridList.setFocus(true)
      return true
    else if key = "left" OR key = "back"
      ' Fire TOGGLE_OFF and NavigateWithinPage when pressing Left from pivot to side nav
      if m.pivotList.isInFocusChain() = true AND m.pivotList.pivotFocusedNode <> invalid
        focusedPosition = m.pivotList.pivotFocused
        if isNonEmptyArray(focusedPosition) AND focusedPosition.count() >= 2
          firePivotComponentInteractionEvent(m.pivotList.pivotFocusedNode, focusedPosition[1], "TOGGLE_OFF")
          fireNavigateFromPivotToSideNavEvent()
        end if
      end if

      ' This is required to stop videoPreview
      itemFocused = m.CategoryGridList.itemFocused
      if m.top.isVideoPreviewOn = true OR (itemFocused <> invalid AND itemFocused.gridItemType = m.constants.ui.gridItemTypes.skinAd)
        m.top.pauseVideoPreview = true
      end if

      ' navigating to the side nav
      m.top.stopLinearVideoPlayer = true

      if m.pivotList.content <> invalid AND m.pivotList.content.getChildCount() > 0 AND m.pivotList.isInFocusChain() = false AND key = "back"
        focusPivotList("back")
        return true
      end if
    else if isAdDisplayCarouselAvailable() = true AND m.adRowlistCarouselComponent.isInFocusChain() = true
      if key = "down"
        nCurrentFocusRow = m.CategoryGridList.listCurrFocusRow
        '//Must set the focus before animating to the next item because CategoryGridList may call jumpToItem when focus changes.
        m.CategoryGridList.setFocus(true)
        m.CategoryGridList.animateToItem = nCurrentFocusRow + 1
        hideAdDisplayCarousel()
        return true
      else if key = "up"
        nCurrentFocusRow = m.CategoryGridList.listCurrFocusRow
        '//Must set the focus before animating to the next item because CategoryGridList may call jumpToItem when focus changes.
        m.CategoryGridList.setFocus(true)
        m.CategoryGridList.animateToItem = nCurrentFocusRow - 1
        hideAdDisplayCarousel()
        return true
      end if
    end if
  end if

  if key = "play" AND m.CategoryGridList.isInFocusChain() = true
    handlePlayInput()
    return true
  end if

  return false
End Function


' Handles transport voice request commands
' @param msg - Message containing voice command information
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


' Handles play input from remote or voice
' @return Boolean - True if action was taken, false otherwise
Function handlePlayInput()
  tubilog("HomeScreen.handlePlayInput")
  if m.top.isLoading <> true
    itemFocused = m.CategoryGridList.rowFocusedItem

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


' Refreshes expired home screen containers
' Checks featured, skin ad, and content containers for expiration
Function refreshHomeScreenContainers()
  tubilog("HomeScreen.refreshHomeScreenContainers")
  loadCategoryForIds = []

  if m.CategoryGridList.skinAdContent <> invalid
    skinAdContainer = m.CategoryGridList.skinAdContent.getChild(0)
    if shouldRefresh(skinAdContainer) = true AND isNonEmptyArray(skinAdContainer.imageImpTracking) = false
      '//if the content has expired AND the impression pixels have been fired, then get a new set of impression pixels
      loadCategoryForIds.push(skinAdContainer.id)
    end if
  end if

  if m.CategoryGridList.content <> invalid
    for i = 0 to m.CategoryGridList.content.getChildCount() - 1
      container = m.CategoryGridList.content.getChild(i)
      if shouldRefresh(container) = true
        loadCategoryForIds.push(container.id)
      end if
    end for
  end if

  if loadCategoryForIds.count() > 0
    m.top.loadCategoryForIds = loadCategoryForIds
  end if
End Function


' Handles grid content ready state changes
' Updates content ready flag and content area state
' @param msg - Message containing grid content ready status
Function onGridContentIsReadyChange(msg)
  ' Not using alias to avoid making the field gridContentIsReady is ready bi-directional since contentReady inside homescreen.brs on other use cases.
  if msg.getData() = true AND m.top.contentReady = false
    m.top.contentReady = true
    setContentAreaState()
  end if
End Function


' Handles hide info panel changes
' Fades info panel in or out based on visibility state
' @param msg - Message containing visibility state
Function onHideInfoPanelChange(msg)
  visible = msg.getData()
  if visible = true
    m.infoPanelFade = slideFadeGeneral(m.InfoPanelParent, [0, 0], "in", 0.2, 1)
  else
    m.infoPanelFade = slideFadeGeneral(m.InfoPanelParent, [0, -50], "out", 0.2)
  end if
End Function


' Updates row list translation field
' Adjusts translation based on content area parent position
Function updateRowListTranslation()
  if m.top.content <> invalid
    translation = m.CategoryGridList.rowListTranslation
    translation[1] = translation[1] + m.ContentAreaParent.translation[1]
    m.top.rowListTranslation = translation
  end if
End Function


' Handles kids mode changes
' Adjusts content area translation when entering or exiting kids mode
' @param msg - Message containing new kids mode state
Function onKidsModeChange(msg)
  kidsMode = msg.getData()
  if m.top.enableVideoTiles = false AND kidsMode = true
    m.ContentAreaParent.translation = m.originalContentAreaTranslation
  end if
End Function


' Handles navigation to pivot menu from category grid
' Stores source category info for later NavigateWithinPage event
Function onNavigatingToPivotMenu() as Void
  ' Store the current tracking component info for NavigateWithinPage event
  ' This will be used when the pivot list fires TOGGLE_ON
  ' The trackingComponentInfo is already built with proper content_tile/utility_tile
  if m.top.trackingComponentInfo <> invalid
    m.pendingPivotNavigation = m.top.trackingComponentInfo
  end if
End Function


' Handles showPivots changes - resets pivot list content when hidden
' @param msg - Message containing the showPivots boolean value
Function onShowPivotsChange(msg) as Void
  if msg.getData() = false
    m.pivotList.content = invalid
  end if
End Function


' Handles pivot focused changes - fires NavigateWithinPage when navigating from category to pivot
' @param msg - Message containing the focused pivot position [row, column]
Function onPivotFocusedChange(msg) as Void
  focusedPosition = msg.getData()
  if focusedPosition = invalid OR focusedPosition.count() < 2 then return

  ' Get pivot node from PivotList
  pivotContent = m.pivotList.pivotFocusedNode
  if pivotContent = invalid then return

  pivotCol = focusedPosition[1]

  ' Check if we have pending navigation from category grid
  if isNonEmptyAA(m.pendingPivotNavigation) = true
    pivotRow = 1 ' Pivot list is at row 1 for analytics

    ' Fire NavigateWithinPage from category to pivot
    fireNavigateFromCategoryToPivotEvent(m.pendingPivotNavigation, pivotRow, pivotContent, pivotCol + 1)

    ' Clear pending navigation
    m.pendingPivotNavigation = invalid
  end if

  ' Fire TOGGLE_ON when focusing on a pivot
  firePivotComponentInteractionEvent(pivotContent, pivotCol, "TOGGLE_ON")
End Function


' Forwards componentInteractionInfo from PivotList to HomeScreen
Function onPivotComponentInteractionInfo(msg) as Void
  m.top.componentInteractionInfo = msg.getData()
End Function


' Forwards navigateWithinPageInfo from PivotList to HomeScreen
Function onPivotNavigateWithinPageInfo(msg) as Void
  m.top.navigateWithinPageInfo = msg.getData()
End Function


' Forwards trackingComponentInfo from PivotList to HomeScreen
Function onPivotTrackingComponentInfo(msg) as Void
  m.top.trackingComponentInfo = msg.getData()
End Function


' ==================== ANALYTICS SECTION ====================


' Fires ComponentInteractionEvent for pivot interactions (TOGGLE_ON, TOGGLE_OFF, CONFIRM)
' @param pivotContent - The pivot ContentNode
' @param utilityTileCol - The column position of the focused pivot
' @param userInteraction - "TOGGLE_ON", "TOGGLE_OFF", or "CONFIRM"
Function firePivotComponentInteractionEvent(pivotContent as Dynamic, utilityTileCol as Integer, userInteraction as String) as Void
  if m.tracking = invalid OR pivotContent = invalid then return

  pageInfo = m.top.trackingPageInfo
  componentValues = m.tracking.getPivotCollectionComponent(pivotContent, utilityTileCol + 1, 1, "STICKY")

  ' Set componentInteractionInfo on HomeScreen field
  m.top.componentInteractionInfo = {
    pageOneof: m.tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
    componentOneof: m.tracking.getAnalyticsComponent("collection_component", componentValues)
    user_interaction: userInteraction
  }
End Function


' Fires ComponentInteractionEvent with ButtonComponent when user presses Up or Back to focus pivot menu
' @param key - The key that triggered the focus change ("up" or "back")
Function fireButtonFocusPivotEvent(key as String) as Void
  if m.tracking = invalid then return

  pageInfo = m.top.trackingPageInfo
  if pageInfo = invalid then return

  buttonValue = "UP_FOCUS_PIVOT"
  if key = "back"
    buttonValue = "BACK_FOCUS_PIVOT"
  end if

  componentValues = {
    button_value: buttonValue
    button_type: "IMAGE"
  }

  m.top.componentInteractionInfo = {
    pageOneof: m.tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
    componentOneof: m.tracking.getAnalyticsComponent("button_component", componentValues)
    user_interaction: "CONFIRM"
  }
End Function


' Returns focused pivot info as { pivotContent, pivotCol, pivotRow, componentValues } or invalid
Function getFocusedPivotInfo() as Dynamic
  pivotContent = m.pivotList.pivotFocusedNode
  if pivotContent = invalid then return invalid

  focusedPosition = m.pivotList.pivotFocused
  if focusedPosition = invalid OR focusedPosition.count() < 2 then return invalid

  pivotCol = focusedPosition[1] + 1
  pivotRow = 1

  return {
    pivotContent: pivotContent
    pivotCol: pivotCol
    pivotRow: pivotRow
    componentValues: m.tracking.getPivotCollectionComponent(pivotContent, pivotCol, pivotRow, "STICKY")
  }
End Function


' Fires NavigateWithinPageEvent when navigating FROM side nav TO pivot menu
Function fireNavigateFromSideNavToPivotEvent() as Void
  if m.tracking = invalid then return

  pageInfo = m.top.trackingPageInfo
  if pageInfo = invalid then return

  pivotInfo = getFocusedPivotInfo()
  if pivotInfo = invalid then return

  ' Build source: LeftSideNavComponent with left_nav_section
  sourceComponentValues = {
    left_nav_section: m.top.sideNavLeftNavSection
  }

  pageOneof = m.tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
  componentOneof = m.tracking.getAnalyticsComponent("left_side_nav_component", sourceComponentValues)
  destComponentOneof = m.tracking.getAnalyticsDestinationComponent("dest_collection_component", pivotInfo.componentValues)

  m.top.navigateWithinPageInfo = {
    pageOneof: pageOneof
    componentOneof: componentOneof
    dest_componentOneof: destComponentOneof
    means_of_navigation: "BUTTON"
    vertical_location: pivotInfo.pivotRow
    horizontal_location: pivotInfo.pivotCol
  }
End Function


' Fires NavigateWithinPageEvent when navigating FROM pivot menu TO side nav
Function fireNavigateFromPivotToSideNavEvent() as Void
  if m.tracking = invalid then return

  pageInfo = m.top.trackingPageInfo
  if pageInfo = invalid then return

  pivotInfo = getFocusedPivotInfo()
  if pivotInfo = invalid then return

  ' Build destination: LeftSideNavComponent with nav_section derived from screen ID
  sideNavId = m.constants.ui.screenIdToSideNavId[m.top.id]
  destComponentValues = {
    left_nav_section: m.tracking.sideNavPageMap[sideNavId]
  }

  pageOneof = m.tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
  componentOneof = m.tracking.getAnalyticsComponent("collection_component", pivotInfo.componentValues)
  destComponentOneof = m.tracking.getAnalyticsDestinationComponent("dest_left_side_nav_component", destComponentValues)

  m.top.navigateWithinPageInfo = {
    pageOneof: pageOneof
    componentOneof: componentOneof
    dest_componentOneof: destComponentOneof
    means_of_navigation: "BUTTON"
    vertical_location: pivotInfo.pivotRow
    horizontal_location: pivotInfo.pivotCol
  }
End Function


' Fires NavigateWithinPageEvent when navigating FROM category grid TO pivot menu
' @param sourceComponentInfo - Already-built component info from trackingComponentInfo (includes content_tile/utility_tile)
' @param pivotRow - The row position where pivot sits
' @param pivotContent - The destination pivot content node
' @param pivotCol - The column position of the destination pivot element
Function fireNavigateFromCategoryToPivotEvent(sourceComponentInfo as Object, pivotRow as Integer, pivotContent as Dynamic, pivotCol as Integer) as Void
  if m.tracking = invalid OR sourceComponentInfo = invalid then return

  pageInfo = m.top.trackingPageInfo
  if pageInfo = invalid then return

  ' Build destination component values using helper method
  destComponentValues = m.tracking.getPivotCollectionComponent(pivotContent, pivotCol, pivotRow, "STICKY")

  pageOneof = m.tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)

  ' Use the already-built source component info
  componentOneof = m.tracking.getAnalyticsComponent(sourceComponentInfo.componentType, sourceComponentInfo.componentValues)

  destComponentOneof = m.tracking.getAnalyticsDestinationComponent("dest_collection_component", destComponentValues)

  m.top.navigateWithinPageInfo = {
    pageOneof: pageOneof
    componentOneof: componentOneof
    dest_componentOneof: destComponentOneof
    means_of_navigation: "BUTTON"
    vertical_location: pivotRow
    horizontal_location: pivotCol
  }
End Function