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
  m.rowList = topRef.findNode("rowList")

  ' Configure RowList focus bitmap
  m.rowList.focusBitmapUri = "pkg:/images/selectorRoundedCorners-$$RES$$.9.png"

  ' Set typography for pivot title
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.pivotTitleLabel, typographyConstants.ids.subheaderLarge)

  ' Initialize cursor position tracking
  topRef.cursorPosition = [-1, -1]

  ' Set up observers
  m.rowList.observeFieldScoped("rowItemFocused", "onRowItemFocused")
  m.rowList.observeFieldScoped("rowItemSelected", "onRowItemSelected")
  m.rowList.observeFieldScoped("navigateWithinPageInfo", "onRowListNavigateWithinPageInfoChange")
  m.rowList.observeFieldScoped("trackingComponentInfo", "onRowListTrackingComponentInfoChange")
  topRef.observeFieldScoped("isLoading", "onLoadingChange")
  topRef.observeFieldScoped("pivotId", "onPivotIdChange")
  topRef.observeFieldScoped("trackingPageInfo", "onTrackingPageInfoChange")
  topRef.observeFieldScoped("containerAppendMoreTilesStatus", "onContainerAppendMoreTilesStatusChange")
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


' Handles pivotId field changes - triggers API call to fetch collection data
Function onPivotIdChange(msg = invalid) as Void
  pivotId = m.top.pivotId
  if isNonEmptyString(pivotId) = false then return

  fetchCollectionData(pivotId)
End Function


' Fetches collection data from the API
' @param pivotId - The pivot/collection ID to fetch
Function fetchCollectionData(pivotId) as Void
  if m.cmsApi = invalid
    apiUtilsLib = ApiUtils(m.constants, m.top.serverPersistentData)
    experimentsInterface = StatsigExperimentsInterface(getStatsigExperimentsInfoFromGlobal())
    m.cmsApi = CmsApi(m.constants, apiUtilsLib, invalid, experimentsInterface)
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
  m.pivotTitleLabel.visible = true
  m.rowList.update({
    parentScreenId: m.top.id
    parentScreenTrackingPageInfo: m.top.trackingPageInfo
    personalizationId: response.personalizationId
    shouldTrackViewableImpressionEvent: m.top.shouldTrackViewableImpressionEvent
  }, true)
  m.top.pageLoadComplete = true
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


' Handles container append more tiles status changes
' Manages focus position during tile appending to prevent focus reset issues
' @param msg - Message containing the status ("start", "complete")
Function onContainerAppendMoreTilesStatusChange(msg) as Void
  status = msg.getData()

  if status = "start" AND isNonEmptyArray(m.rowList.rowItemFocused) = true
    m.resetListPositionOnAppend = [m.rowList.rowItemFocused[0], m.rowList.rowItemFocused[1]]
  else if status = "complete" AND isNonEmptyArray(m.resetListPositionOnAppend) = true
    m.rowList.jumpToRowItem = m.resetListPositionOnAppend
    m.resetListPositionOnAppend = invalid
  end if
End Function


' Sets up row heights for the RowList based on content
' @param content - Content node with categories
Function setRowHeights(content) as Void
  if content = invalid then return

  rowItemSize = []
  rowHeights = []
  videoTilesPortraitSize = m.constants.ui.imageSizes.videoTilesPortrait

  for i = 0 to content.getChildCount() - 1
    category = content.getChild(i)
    rowItemSize.push([videoTilesPortraitSize[0], videoTilesPortraitSize[1]])
    rowHeights.push(getVideoTileRowHeight(category.sponsorImages))
  end for

  configureRowHeights(m.rowList, rowItemSize, rowHeights, content)
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
