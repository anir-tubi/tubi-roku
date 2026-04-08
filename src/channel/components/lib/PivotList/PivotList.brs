' PivotList - A RowList with variable-width EnhancedButton support
' Fetches pivot data from API and measures button widths


' Initializes the component
Function init() as Void
  topRef = m.top
  m.constants = getConstantsFromGlobal()
  m.tracking = TubiTrackingInfo(m.constants)
  m.nodeHelpers = TubiNodeHelpers()

  ' Configure RowList (rowItemSize set dynamically in buildAndSetContent)
  itemHeight = topRef.buttonHeight
  topRef.itemComponentName = "PivotItem"
  topRef.numRows = 1
  topRef.rowHeights = [itemHeight]
  topRef.rowItemSpacing = [[24, 0]]
  topRef.showRowLabel = [false]
  topRef.showRowCounter = [false]
  topRef.variableWidthItems = [true]
  topRef.drawFocusFeedback = false
  topRef.fadeFocusFeedbackWhenAutoScrolling = true
  topRef.rowFocusAnimationStyle = "fixedFocus"

  ' Set up observers
  topRef.observeFieldScoped("fetchData", "onFetchDataChange")
  topRef.observeFieldScoped("pivotContent", "onPivotContentChange")
  topRef.observeFieldScoped("rowItemSelected", "onRowItemSelected")
  topRef.observeFieldScoped("rowItemFocused", "onRowItemFocused")

  ' Track previous focused index for within-menu navigation analytics
  m.previousFocusedIndex = -1
End Function


' Handles fetchData field change - triggers API call
Function onFetchDataChange(msg) as Void
  if msg.getData() = true
    fetchPivots()
  end if
End Function


' Fetches pivot data from the apps API
Function fetchPivots() as Void
  if m.cmsApi = invalid
    apiUtilsLib = ApiUtils(m.constants, m.top.serverPersistentData)
    experimentsInterface = StatsigExperimentsInterface(getStatsigExperimentsInfoFromGlobal())
    m.cmsApi = CmsApi(m.constants, apiUtilsLib, invalid, experimentsInterface)
  end if

  reqInfo = m.cmsApi.createGetAllPivotsReqInfo()
  reqInfo.responseType = "node"
  reqInfo.successCallback = onFetchPivotsSuccess
  reqInfo.silenceCallbackWarnings = true

  makeNetworkRequest(reqInfo)
End Function


' Handles successful pivot fetch response
' @param response - ContentNode structure for RowList (rootContent → rowNode → itemNodes)
Function onFetchPivotsSuccess(response) as Void
  if response = invalid
    return
  end if

  m.top.pivotContent = response
End Function


' Handles pivotContent changes - measures widths and sets content
' Prepends a hub pivot if the event hub is active in external config
Function onPivotContentChange(_msg = invalid) as Void
  rootContent = m.top.pivotContent
  if rootContent = invalid then return

  hubPivotNode = createHubPivotNode()
  if hubPivotNode <> invalid
    rowNode = rootContent.getChild(0)
    if rowNode <> invalid
      rowNode.insertChild(hubPivotNode, 0)
    end if
  end if

  buildAndSetContent(rootContent)
End Function


' Sets content on RowList with calculated item widths
' @param rootContent - ContentNode tree from parser (rootContent → rowNode → itemNodes)
Function buildAndSetContent(rootContent) as Void
  topRef = m.top

  if rootContent = invalid
    return
  end if

  rowNode = rootContent.getChild(0)
  if rowNode = invalid OR rowNode.getChildCount() = 0
    return
  end if

  ' Create temporary PivotItem for measurement
  measureButton = CreateObject("roSGNode", "PivotItem")
  itemHeight = topRef.buttonHeight
  measureButton.height = itemHeight

  ' Calculate widths for each item and build rowItemSize array
  rowItemSizes = []
  for i = 0 to rowNode.getChildCount() - 1
    itemNode = rowNode.getChild(i)

    ' Measure width using PivotItem
    measureButton.itemContent = itemNode

    ' Get calculated width (text width + left/right padding of 24 each)
    buttonWidth = measureButton.calculatedTextWidth + 48
    itemNode.update({ FHDItemWidth: buttonWidth }, true)
    rowItemSizes.push([buttonWidth, itemHeight])
  end for

  ' Set rowItemSize with calculated widths
  topRef.rowItemSize = rowItemSizes

  ' Set content on RowList
  topRef.content = rootContent
  topRef.visible = true
  topRef.contentReady = true
End Function


' Creates a hub pivot node from the event.hub external config if the hub is
' currently active (within start_time / end_time). Returns a ContentNode or invalid.
Function createHubPivotNode() as Dynamic
  config = getExternalConfigInfoFromGlobal()
  if config = invalid OR config.event = invalid OR config.event.hub = invalid
    return invalid
  end if

  hub = config.event.hub
  if isNonEmptyString(hub.id) = false OR isNonEmptyString(hub.title) = false
    return invalid
  end if

  startTime = hub.start_time
  endTime = hub.end_time
  if isAA(hub.pivot_entry) = true
    if isNonEmptyString(hub.pivot_entry.start_time) then startTime = hub.pivot_entry.start_time
    if isNonEmptyString(hub.pivot_entry.end_time) then endTime = hub.pivot_entry.end_time
  end if

  if isNowWithinTimePeriod(startTime, endTime) = false
    return invalid
  end if

  images = {
    background: "pkg:/images/transparent.png"
  }
  if isNonEmptyString(hub.pill_background)
    images.pillBackground = hub.pill_background
  end if

  node = CreateObject("roSGNode", "ContentNode")
  node.update({
    id: hub.id
    title: hub.title
    description: hub.container_description
  }, true)
  node.addFields({
    type: "EXPLORER"
    genres: []
    tags: []
    images: images
    isPrimaryButton: true
    containerId: hub.container_id
  })

  return node
End Function


' Handles item selection
Function onRowItemSelected(msg) as Void
  topRef = m.top

  selectedIndex = msg.getData()
  if selectedIndex = invalid then return

  itemIndex = selectedIndex[1]

  ' Get the selected pivot node using helper
  pivotItem = m.nodeHelpers.getNodeFromPosition(topRef.content, selectedIndex)
  if pivotItem = invalid then return

  ' Fire ComponentInteraction CONFIRM event
  firePivotComponentInteractionEvent(pivotItem, itemIndex, "CONFIRM")

  ' Expose the selected pivot content node for easy access
  ' pivotSelected (array) is automatically set via alias to rowItemSelected
  topRef.pivotSelectedNode = pivotItem
  topRef.pivotSelected = selectedIndex
End Function


' Handles item focus changes
Function onRowItemFocused(msg) as Void
  topRef = m.top

  focusedIndex = msg.getData()
  if focusedIndex = invalid then return

  itemIndex = focusedIndex[1]

  ' Get the focused pivot node using helper
  focusedItem = m.nodeHelpers.getNodeFromPosition(topRef.content, focusedIndex)
  if focusedItem = invalid then return

  ' Set focused pivot position and node
  topRef.pivotFocusedNode = focusedItem
  topRef.pivotFocused = focusedIndex
  componentValues = m.tracking.getPivotCollectionComponent(focusedItem, itemIndex + 1, 1, "STICKY")
  topRef.trackingComponentInfo = {
    componentType: "collection_component"
    componentValues: componentValues
  }

  ' Fire navigate within menu analytics if focus changed from another pivot
  if m.previousFocusedIndex >= 0 AND m.previousFocusedIndex <> itemIndex
    ' Get the previous pivot node
    previousFocusedPosition = [focusedIndex[0], m.previousFocusedIndex]
    previousItem = m.nodeHelpers.getNodeFromPosition(topRef.content, previousFocusedPosition)
    if previousItem <> invalid
      firePivotNavigateWithinMenuEvent(previousItem, m.previousFocusedIndex, focusedItem, itemIndex)
    end if
  end if

  ' Update previous focused index
  m.previousFocusedIndex = itemIndex
End Function


' ==================== ANALYTICS SECTION ====================


' Fires ComponentInteractionEvent for pivot interactions (TOGGLE_ON, TOGGLE_OFF, CONFIRM)
' @param pivotContent - The pivot ContentNode
' @param utilityTileCol - The column position of the focused pivot
' @param userInteraction - "TOGGLE_ON", "TOGGLE_OFF", or "CONFIRM"
Function firePivotComponentInteractionEvent(pivotContent as Dynamic, utilityTileCol as Integer, userInteraction as String) as Void
  if m.tracking = invalid OR pivotContent = invalid then return

  pageInfo = m.top.trackingPageInfo
  if pageInfo = invalid then return

  componentValues = m.tracking.getPivotCollectionComponent(pivotContent, utilityTileCol + 1, 1, "STICKY")

  pageOneof = m.tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
  componentOneof = m.tracking.getAnalyticsComponent("collection_component", componentValues)

  ' Set componentInteractionInfo on PivotList field - will be piped up to HomeScreen
  m.top.componentInteractionInfo = {
    pageOneof: pageOneof
    componentOneof: componentOneof
    user_interaction: userInteraction
  }
End Function


' Fires NavigateWithinPageEvent when navigating between pivots
' @param sourcePivotContent - Source pivot content node
' @param sourceItemIndex - Source pivot column position
' @param destPivotContent - Destination pivot content node
' @param destItemIndex - Destination pivot column position
Function firePivotNavigateWithinMenuEvent(sourcePivotContent as Dynamic, sourceItemIndex as Integer, destPivotContent as Dynamic, destItemIndex as Integer) as Void
  if m.tracking = invalid then return

  pageInfo = m.top.trackingPageInfo
  if pageInfo = invalid then return

  pivotRow = 1
  componentValues = m.tracking.getPivotCollectionComponent(sourcePivotContent, sourceItemIndex + 1, pivotRow, "STICKY")
  destComponentValues = m.tracking.getPivotCollectionComponent(destPivotContent, destItemIndex + 1, pivotRow, "STICKY")

  pageOneof = m.tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
  componentOneof = m.tracking.getAnalyticsComponent("collection_component", componentValues)
  destComponentOneof = m.tracking.getAnalyticsDestinationComponent("dest_collection_component", destComponentValues)

  ' Set navigateWithinPageInfo on PivotList field - will be piped up to HomeScreen
  m.top.navigateWithinPageInfo = {
    pageOneof: pageOneof
    componentOneof: componentOneof
    dest_componentOneof: destComponentOneof
    means_of_navigation: "SCROLL"
    horizontal_location: pivotRow
    vertical_location: destItemIndex + 1
  }
End Function
