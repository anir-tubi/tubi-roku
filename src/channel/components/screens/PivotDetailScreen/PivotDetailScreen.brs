' PivotDetailScreen - Video tiles view for pivot content
' Used with roku__pivots_v1 experiment
'
' Extends VideoTilesScreen for video tiles support.
Function init() as Void
  m.constants = getConstantsFromGlobal()
  m.tracking = TubiTrackingInfo(m.constants)
  experimentsInfo = getExperimentsInfoFromGlobal()
  m.experiments = TubiExperiments(experimentsInfo)
  m.soTStaticConfig = getSoTStaticConfigFromGlobal()
  statSigExperimentsInfo = getStatsigExperimentsInfoFromGlobal()
  m.metadataTranslate = TubiMetadataTranslate(m.constants, m.experiments, m.soTStaticConfig, StatsigExperimentsInterface(statSigExperimentsInfo))

  topRef = m.top
  topRef.enableVideoTiles = true

  ' Set screen level and ID
  topRef.screenLevel = m.constants.ui.screenLevels.pivotDetailScreen
  topRef.id = m.constants.ui.screenIds.pivotDetailScreen

  ' Cache node references
  m.pageGroup = topRef.findNode("PageGroup")
  m.pivotTitleLabel = topRef.findNode("pivotTitleLabel")
  m.titleGroup = topRef.findNode("titleGroup")
  m.pivotLogo = topRef.findNode("pivotLogo")
  m.backgroundPoster = topRef.findNode("backgroundPoster")
  m.sponsorshipPoster = topRef.findNode("sponsorshipPoster")
  m.rowList = topRef.findNode("rowList")
  ' Configure RowList focus bitmap
  m.rowList.focusBitmapUri = "pkg:/images/selectorRoundedCorners-$$RES$$.9.png"

  ' Set typography for pivot title
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.pivotTitleLabel, typographyConstants.ids.subheaderLarge)

  ' Initialize cursor position tracking
  topRef.cursorPosition = [-1, -1]

  ' Set up observers
  m.rowList.observeFieldScoped("currFocusRow", "onCurrFocusRowChange")
  m.rowList.observeFieldScoped("rowItemFocused", "onRowItemFocused")
  m.rowList.observeFieldScoped("rowItemSelected", "onRowItemSelected")
  m.rowList.observeFieldScoped("navigateWithinPageInfo", "onRowListNavigateWithinPageInfoChange")
  m.rowList.observeFieldScoped("trackingComponentInfo", "onRowListTrackingComponentInfoChange")
  topRef.observeFieldScoped("isLoading", "onLoadingChange")
  topRef.observeFieldScoped("pivotId", "onPivotIdChange")
  topRef.observeFieldScoped("trackingPageInfo", "onTrackingPageInfoChange")
  topRef.observeFieldScoped("refreshContent", "onContentRefreshNeeded")
  topRef.observeFieldScoped("focusedChild", "onPivotScreenFocusChange")
  topRef.enableContentRefresh = true
  topRef.enableContainerRefresh = true
  m.pageGroup.translation = [-3, 153]

  ' Initialize video tiles support using mixin
  ' We do not have a contentArea
  initVideoTilesScreen(m.pageGroup, m.rowList, invalid)

  ' Set up theme observer
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Handles theme changes and applies colors to UI elements
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.rowList.focusBitmapBlendColor = theme.focusedColor
    m.pivotTitleLabel.color = theme.primaryTextColor
  end if
End Function


' Handles content refresh signal from VideoTilesScreen
' Re-fetches collection data when content has expired
Function onContentRefreshNeeded(_msg) as Void
  fetchCollectionData(m.top.pivotId)
End Function


' Manages sponsored hub ad refresh on focus changes
' Re-fetches ad when screen gains focus and ad has expired (only if content
' itself isn't expired, since onFetchCollectionSuccess handles ad fetch after content refresh)
Function onPivotScreenFocusChange() as Void
  if m.top.hasFocus() = true
    contentExpired = m.top.content <> invalid AND shouldRefresh(m.top.content)
    if contentExpired = false AND shouldRefresh(m.top.sponsoredHubAdContent)
      fetchSponsoredHubAd()
    end if
  end if
End Function


' Handles pivotId field changes - triggers API call to fetch collection data
Function onPivotIdChange(msg = invalid) as Void
  pivotId = m.top.pivotId
  if isNonEmptyString(pivotId) = false then return

  m.top.containerRefreshAppId = pivotId
  fetchCollectionData(pivotId)
End Function


' Fetches collection data from the API
' @param pivotId - The pivot/collection ID to fetch
Function fetchCollectionData(pivotId) as Void
  if m.cmsApi = invalid
    apiUtilsLib = ApiUtils(m.constants, m.top.serverPersistentData)
    experimentsInterface = StatsigExperimentsInterface(getStatsigExperimentsInfoFromGlobal())
    m.cmsApi = CmsApi(m.constants, apiUtilsLib, invalid, experimentsInterface)
    m.adsApi = AdsApi(m.constants, apiUtilsLib)
  end if

  ' Build request options with pagination params
  options = {
    params: {
      group_start: 0
      group_size: m.constants.performance.categoryGridList.numContainers
      contents_limit: m.constants.performance.categoryGridList.initialBlockSize
      contentMode: ""
    }
  }

  imageParamTypes = [
    "poster"
    "landscape"
    "background"
    "title"
    "featured"
    "episodeLandscape"
  ]

  reqInfo = m.cmsApi.createGetCollectionInfo(pivotId, options, imageParamTypes)
  reqInfo.requestType = m.constants.reqNames.getPivotContainers
  reqInfo.responseType = "node"
  reqInfo.successCallback = onFetchCollectionSuccess
  reqInfo.errorCallback = onFetchCollectionError
  reqInfo.isSignedInUser = m.top.isSignedInUser
  reqInfo.uiMode = m.top.uiMode
  reqInfo.screenId = m.top.id

  m.top.isLoading = true
  makeNetworkRequest(reqInfo)
End Function


' Handles successful collection fetch response
' @param response - Parsed content node from the API
Function onFetchCollectionSuccess(response) as Void
  m.top.isLoading = false

  if response = invalid
    return
  end if
  setRowHeights(response)
  m.top.content = response
  m.titleGroup.visible = true

  m.rowList.update({
    parentScreenId: m.top.id
    parentScreenTrackingPageInfo: m.top.trackingPageInfo
    personalizationId: response.personalizationId
    shouldTrackViewableImpressionEvent: m.top.shouldTrackViewableImpressionEvent
  }, true)
  m.top.pageLoadComplete = true

  if m.top.rowCurrFocusColumn = -1 then
    m.top.rowCurrFocusColumn = 0
  end if

  fetchSponsoredHubAd()
End Function


' Sets app-level images from either ad data or the collection API response
' Priority: ad content > API response > event hub config fallback (when pivotId matches hub.id)
' @param adContent - Optional ad response AA with smallLogoLockupUrl, brandBackgroundUrl, brandGraphicUrl
Function setAppImages(adContent = invalid) as Void
  response = m.top.content
  if response = invalid then return

  hubConfig = getEventHubConfig()

  if adContent <> invalid AND isNonEmptyString(adContent.smallLogoLockupUrl)
    m.pivotLogo.uri = adContent.smallLogoLockupUrl
    m.pivotLogo.visible = true
  else if isNonEmptyString(response.titleArt)
    m.pivotLogo.uri = response.titleArt
    m.pivotLogo.visible = true
  else if hubConfig <> invalid AND isNonEmptyString(hubConfig.title_art)
    m.pivotLogo.uri = hubConfig.title_art
    m.pivotLogo.visible = true
  end if

  backgroundUrl = invalid
  if adContent <> invalid AND isNonEmptyString(adContent.brandBackgroundUrl)
    backgroundUrl = adContent.brandBackgroundUrl
  else if isNonEmptyString(response.background)
    backgroundUrl = response.background
  else if hubConfig <> invalid AND isNonEmptyString(hubConfig.background)
    backgroundUrl = hubConfig.background
  end if

  if backgroundUrl <> invalid
    m.backgroundPoster.opacity = 0.0
    m.backgroundPoster.unobserveFieldScoped("loadStatus")
    m.backgroundPoster.observeFieldScoped("loadStatus", "onBackgroundPosterLoaded")
    m.backgroundPoster.uri = backgroundUrl
  end if

  if adContent <> invalid AND isNonEmptyString(adContent.brandGraphicUrl)
    m.sponsorshipPoster.uri = adContent.brandGraphicUrl
    m.sponsorshipPoster.visible = true
  end if
End Function


' Fades in the background poster once the image has finished loading
Function onBackgroundPosterLoaded(msg) as Void
  if msg.getData() = "ready"
    m.backgroundPoster.visible = true
    fade(m.backgroundPoster, "in", 0.3)
  end if
End Function


' Returns the event hub config if the current pivotId matches the hub id, otherwise invalid
' This is specific to solar bear event hub.
Function getEventHubConfig() as Dynamic
  eventConfig = getExternalConfigValueFromGlobal("event", invalid)
  if eventConfig = invalid OR eventConfig.hub = invalid then return invalid

  hub = eventConfig.hub
  if hub.id = m.top.pivotId
    return hub
  end if
  return invalid
End Function


' Handles collection fetch error
' @param error - Error object from the API
Function onFetchCollectionError(error) as Void
  tubiLog("PivotDetailScreen.onFetchCollectionError", "warn")
  m.top.pageErrorInfo = {}
  m.top.isLoading = false
End Function


' Handles loading state changes
Function onLoadingChange() as Void
  if m.top.isLoading = true
    m.rowList.content = invalid
  end if
End Function


' Sets up row heights for the RowList based on content
' @param content - Content node with categories
Function setRowHeights(content) as Void
  if content = invalid then return

  rowItemSize = []
  rowHeights = []
  variableWidthItems = []
  imageSizes = m.constants.ui.imageSizes
  videoTilesPortraitSize = imageSizes.videoTilesPortrait

  for i = 0 to content.getChildCount() - 1
    category = content.getChild(i)
    gridItemType = category.gridItemType
    if gridItemType = m.constants.ui.gridItemTypes.landscapeSeries OR gridItemType = m.constants.ui.gridItemTypes.landscapeSeriesMultiple
      rowItemSize.push(imageSizes.episodeLandscape)
      rowHeights.push(648)
    else
      rowItemSize.push(videoTilesPortraitSize)
      rowHeights.push(getVideoTileRowHeight(category.sponsorImages))
    end if

    hasHubLockup = category.hasField("hasHubRowLockup") = true AND category.hasHubRowLockup = true
    variableWidthItems.push(hasHubLockup)
  end for

  configureRowHeights(m.rowList, rowItemSize, rowHeights, content, variableWidthItems)
End Function


' Hides focus feedback immediately on row change to prevent stale feedback
Function onCurrFocusRowChange(_msg) as Void
  m.rowList.drawFocusFeedback = false
End Function


' Handles row item focus changes
' @param msg - Message containing focus data [rowIndex, columnIndex]
Function onRowItemFocused(msg) as Void
  rowItemFocused = msg.getData()
  if rowItemFocused = invalid OR rowItemFocused.count() < 2 then return

  rowIndex = rowItemFocused[0]
  columnIndex = rowItemFocused[1]

  m.top.cursorPosition = [rowIndex, columnIndex]

  ' Get fully parsed TubiContentNode
  tubiContentNode = getTubiContentNodeFromRowItem(rowItemFocused, m.metadataTranslate, m.top.isSignedInUser)
  if tubiContentNode = invalid then return

  m.top.contentFocused = tubiContentNode
  m.top.contentFocusedUpdated = true

  category = m.top.content.getChild(rowIndex)
  gridItemType = invalid
  if category <> invalid then gridItemType = category.gridItemType
  m.rowList.drawFocusFeedback = (gridItemType = m.constants.ui.gridItemTypes.landscapeSeries OR gridItemType = m.constants.ui.gridItemTypes.landscapeSeriesMultiple)

  updateFocusForItem(m.rowList, rowIndex)
End Function


' Handles row item selection
' @param msg - Message containing selection data [rowIndex, columnIndex]
Function onRowItemSelected(msg) as Void
  rowItemSelected = msg.getData()
  if rowItemSelected = invalid OR rowItemSelected.count() < 2 then return

  m.top.contentSelectedIndex = rowItemSelected
End Function


' Handles key events for navigation
' @param key - The key that was pressed
' @param press - True if key was pressed, false if released
' @return Boolean - True if key was handled
Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = false then return false

  if key = "back"
    ' Fire back to home page event
    fireBackToHomePageEvent()

    m.top.backButtonPressed = true
    return true
  end if

  return false
End Function


' Fetches sponsored hub ad content for the pivot detail screen
Function fetchSponsoredHubAd() as Void
  authInfo = TubiAuth(m.constants).getAuthInfo()
  userId = ""
  if authInfo <> invalid AND authInfo.userId <> invalid
    userId = authInfo.userId.toStr()
  end if

  adReqInfo = m.adsApi.createSponsoredHubAdReqInfo(userId, m.top.isKidsMode)
  reqInfo = {
    url: adReqInfo.url
    requestType: m.constants.reqNames.getSponsoredHubAds
    options: adReqInfo.options
    successCallback: onSponsoredHubAdSuccess
    errorCallback: onSponsoredHubAdError
    responseType: "assocarray"
    screenId: m.top.id
    timeoutInMilliSec: adReqInfo.timeoutInMilliSec
  }
  makeNetworkRequest(reqInfo)
End Function


' Handles successful sponsored hub ad response
' Overrides app images with ad assets when present
' Fires sponsored_hub impression pixels on load
' validUntil is set at the parser level (AdParsers.parseSponsoredHubAdsSuccess)
' @param response - Parsed ad data with assets, trackers, ad ID, and validUntil
Function onSponsoredHubAdSuccess(response) as Void
  if response = invalid then return

  m.top.sponsoredHubAdContent = response
  setAppImages(response)

  if isNonEmptyArray(response.imageImpTracking) = true
    fireSponsoredHubPixels(response.imageImpTracking)
  end if
End Function


' Fires impression pixels for the sponsored_hub ad
' @param aPixelURLs - Array of impression pixel URLs to fire
Function fireSponsoredHubPixels(aPixelURLs) as Void
  if isNonEmptyArray(aPixelURLs) = false then return

  for each pixelURL in aPixelURLs
    encodedUrl = replaceCacheBusterMacro(pixelURL)
    if isNonEmptyString(encodedUrl) = true
      makeNetworkRequest({
        url: encodedUrl
        requestType: m.constants.reqNames.generic
        responseType: "assocarray"
        silenceCallbackWarnings: true
      })
    end if
  end for
End Function


' Handles error when fetching sponsored hub ad — falls back to collection images
Function onSponsoredHubAdError(_error) as Void
  tubiLog("PivotDetailScreen.onSponsoredHubAdError")
  setAppImages()
End Function


' ==================== ANALYTICS SECTION ====================

' Fires NavigateToPageEvent when user presses back from pivot page to home
' Returns to the pivot menu on home page
Function fireBackToHomePageEvent() as Void
  trackingPageInfo = m.top.trackingPageInfo
  if trackingPageInfo = invalid OR m.top.content = invalid then return

  ' Get current focused item for component context
  cursorPosition = m.top.cursorPosition
  if cursorPosition = invalid OR cursorPosition.count() < 2 then return

  rowIndex = cursorPosition[0]
  columnIndex = cursorPosition[1]

  content = m.top.content
  category = content.getChild(rowIndex)
  if category = invalid then return

  item = category.getChild(columnIndex)
  if item = invalid then return

  ' Build destination component (pivot menu on home page)
  destComponentValues = {
    utility_tile__id: m.top.pivotId
  }

  ' Build page and component oneofs
  pageOneof = m.tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
  destPageOneof = m.tracking.getAnalyticsPage("home_page", {})
  destComponentOneof = m.tracking.getAnalyticsDestinationComponent("collection_component", destComponentValues)

  ' Fire navigate to page event
  m.top.navigateToPageInfo = {
    pageOneof: pageOneof
    componentOneof: m.top.trackingComponentInfo
    destPageOneof: destPageOneof
    dest_componentOneof: destComponentOneof
  }
End Function


' Handles navigate within page info changes from row list
' @param msg - Message containing navigate within page info
Function onRowListNavigateWithinPageInfoChange(msg) as Void
  m.top.navigateWithinPageInfo = msg.getData()
End Function


' Handles tracking component info changes from row list
' @param msg - Message containing tracking component info
Function onRowListTrackingComponentInfoChange(msg) as Void
  ' Cannot use alias since trackingComponentInfo is defined at base screen level
  m.top.trackingComponentInfo = msg.getData()
End Function


' Handles tracking page info changes
' @param msg - Message containing tracking page info
Function onTrackingPageInfoChange(msg) as Void
  m.rowList.trackingPageInfo = msg.getData()
End Function
