' Initializes the HomeScreen component
' Sets up observers, node references, tracking, and initial UI state
Function init()
  tubiLog("HomeScreen.init")

  m._ = rodash()
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  experimentInfo = getStatsigExperimentResource("roku_video_tiles", "roku_video_tiles_1_7", false)
  m.isUserInVideoTilesExperiment = isAA(experimentInfo) AND experimentInfo.design_type = "videoTiles"
  m.dimMask = m.top.findNode("dimMask")

  m.PageGroup = m.top.findNode("PageGroup")
  m.PageGroup.translation = [m.constants.ui.translations.marginX, 0]
  m.ContentAreaParent = m.top.findNode("ContentAreaParent")
  m.maskUri = "pkg:/images/poster-mask.png"
  if m.isUserInVideoTilesExperiment = true
    m.maskUri = ""
  end if
  m.ContentArea = m.top.findNode("ContentArea")
  m.ContentArea.maskUri = m.maskUri
  m.adContentGroup = m.top.findNode("adContentGroup")
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
  topRef.observeFieldScoped("batchAdResponse", "onBatchAdResponseChanged")
  topRef.observeFieldScoped("allowCarouselAutoRotate", "onAllowCarouselAutoRotateChange")
  topRef.observeFieldScoped("kidsMode", "onKidsModeChange")
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


' Sets the content area state based on video tiles experiment and focus state
' Animates or directly sets the content area parent translation
Function setContentAreaState()
  tubiLog("HomeScreen.setToRedesignContentArea")

  shouldAnimate = false
  if m.isUserInVideoTilesExperiment = false OR (m.top.listHasFocus = false AND m.CategoryGridList <> invalid AND m.CategoryGridList.lastFocusedList = "skinAdRow") OR (m.top.kidsMode = true OR m.top.id <> m.constants.ui.screenIds.homeScreen)
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
  end if
End Function


' Handles content updates and manages ad carousel component creation
' Updates content area mask position based on skin ad presence
Function onContentUpdated()
  if m.top.contentUpdated = true
    content = m.top.content

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
    setFocusOnCategoryGrid()

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
  if gridItemType = m.constants.ui.gridItemTypes.skinAd OR gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight
    m.top.backgroundUriList = determineBackgroundImage(focusedContent)
  else if focusedContent.type = m.constants.ui.contentTypes.adRowlistCarousel
    displayAdDisplayCarousel()
  else if gridItemType <> m.constants.ui.gridItemTypes.videoTile AND (m.top.id <> m.constants.ui.screenIds.homeScreen OR m.top.kidsMode = true)
    populateInfoPanelByContent(focusedContent)
    fadeInContentArea()
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

    if m.isUserInVideoTilesExperiment = true
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


' Handles key events for navigation and playback
' @param key - Key pressed (left, back, down, up, play)
' @param press - True if key is pressed, false if released
' @return Boolean - True if key was handled, false otherwise
Function onKeyEvent(key, press) as Boolean
  if press = true
    if key = "left" OR key = "back"
      ' This is required to stop videoPreview
      itemFocused = m.CategoryGridList.itemFocused
      if m.top.isVideoPreviewOn = true OR (itemFocused <> invalid AND itemFocused.gridItemType = m.constants.ui.gridItemTypes.skinAd)
        m.top.pauseVideoPreview = true
      end if

      ' navigating to the side nav
      m.top.stopLinearVideoPlayer = true
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

  if m.CategoryGridList.content <> invalid
    featuredContainer = m.CategoryGridList.content.getChild(0)
    if shouldRefresh(featuredContainer) = true
      loadCategoryForIds.push(featuredContainer.id)
    end if
  end if

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
' Adjusts content area translation when entering kids mode
' @param msg - Message containing new kids mode state
Function onKidsModeChange(msg)
  kidsMode = msg.getData()
  if m.isUserInVideoTilesExperiment = true AND kidsMode = true
    m.ContentAreaParent.translation = m.originalContentAreaTranslation
  end if
End Function
