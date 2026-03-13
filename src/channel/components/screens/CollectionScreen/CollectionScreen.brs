Function init()
  m.constants = getConstantsFromGlobal()
  m.top.id = m.constants.ui.screenIds.collectionScreen
  m.top.screenLevel = m.constants.ui.screenLevels.collectionScreen

  m.backgroundPosterOpacityOnSubsequentRows = 0.3

  m.rowHeightEpisodeItemLatestEpisodes = 501
  m.rowHeightEpisodeItem = 573

  m.rowListTopRowVertTranslation = 339
  m.rowListSubsequentRowsVertTranslation = 222

  m.youMightAlsoLikeRowIndex = -1
  m.youMightAlsoLikeInfoTranslation = [195, 762]

  m.rowlistTranslationVertDifference = m.rowListTopRowVertTranslation - m.rowListSubsequentRowsVertTranslation

  m.background = m.top.findNode("background")
  m.backgroundPoster = m.top.findNode("backgroundPoster")
  m.creatorInfoPanel = m.top.findNode("creatorInfoPanel")
  m.tubiRowList = m.top.findNode("tubiRowList")
  m.creatorYMALInfo = m.top.findNode("creatorYMALInfo")
  m.creatorYMALInfo.translation = [4000, 4000] ' Start offscreen

  m.tubiRowList.observeFieldScoped("currFocusRow", "onCurrFocusRowChange")
  m.tubiRowList.observeFieldScoped("rowItemFocused", "onRowItemFocusedChange")
  m.tubiRowList.observeFieldScoped("navigateWithinPageInfo", "onRowListNavigateWithinPageInfoChange")
  m.tubiRowList.observeFieldScoped("trackingComponentInfo", "onRowListTrackingComponentInfoChange")
  m.top.observeFieldScoped("trackingPageInfo", "onTrackingPageInfoChange")
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("appId", "onAppIdChange")

  creatorScreenBackground = m.constants.ui.imageSizes.creatorScreenBackground
  m.backgroundPoster.width = creatorScreenBackground[0]
  m.backgroundPoster.height = creatorScreenBackground[1]

  m.tubiRowList.itemSize = [1920, 0] ' Height is dynamic based on content
  m.tubiRowList.rowSpacings = [32]
  m.tubiRowList.rowItemSpacing = [[16, 0]]
  m.tubiRowList.translation = [0, m.rowListTopRowVertTranslation]
  m.tubiRowList.showRowLabel = [true]
  m.tubiRowList.numRows = 3
  m.tubiRowList.focusXOffset = 192
  m.tubiRowList.rowLabelOffset = [[192, 0]]

  apiUtilsLib = ApiUtils(m.constants, m.pub_serverPersistentData)
  experimentsInfo = getExperimentsInfoFromGlobal()
  experiments = TubiExperiments(experimentsInfo)
  statSigExperimentsInfo = getStatsigExperimentsInfoFromGlobal()
  m.cmsApi = CmsApi(m.constants, apiUtilsLib, experiments, StatsigExperimentsInterface(statSigExperimentsInfo))

  m.global.observeFieldScoped("theme", "onThemeChange")
  onThemeChange()
End Function


Function onAppIdChange(msg)
  appId = msg.getData()
  getCollectionReqInfo = m.cmsApi.createGetCollectionInfo(appId)
  if getCollectionReqInfo <> invalid then
    getCollectionReqInfo["requestType"] = m.constants.reqNames.getCollection
    getCollectionReqInfo["responseType"] = "node"
    getCollectionReqInfo["isSignedInUser"] = isLoggedInUser()
    getCollectionReqInfo["screenId"] = m.constants.ui.screenIds.collectionScreen

    isKidsMode = false
    id = { "type": "app_id", "id": appId }
    relatedRequestInfo = m.cmsApi.createRelatedContentReqInfo(id, isKidsMode)
    relatedRequestInfo["requestType"] = m.constants.reqNames.getRelatedContent
    relatedRequestInfo["responseType"] = "node"
    relatedRequestInfo["isSignedInUser"] = isLoggedInUser()

    makeBatchNetworkRequest({
      "requests": [
        getCollectionReqInfo
        relatedRequestInfo
      ]
      "successCallback": onNetworkRequestsFinished
      "responseType": "array"
    })
  end if
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.background.color = theme.backgroundColor
  end if
End Function


Function onCurrFocusRowChange(msg) as Void
  currFocusRowValue = msg.getData()

  ' Handle YMAL info translation
  if m.youMightAlsoLikeRowIndex > 0 AND currFocusRowValue + 1 >= m.youMightAlsoLikeRowIndex then
    transitionPercentage = ((m.youMightAlsoLikeRowIndex - currFocusRowValue))
    m.creatorYMALInfo.translation = [m.youMightAlsoLikeInfoTranslation[0], m.youMightAlsoLikeInfoTranslation[1] + m.constants.ui.imageSizes.videoTilesPortrait[1] * transitionPercentage]
  end if

  if currFocusRowValue > 1 then
    ' Only care about animating between first two rows
    return
  end if

  m.tubiRowList.translation = [0, m.rowListTopRowVertTranslation - (m.rowlistTranslationVertDifference * currFocusRowValue)]

  m.backgroundPoster.opacity = 1 - ((1 - m.backgroundPosterOpacityOnSubsequentRows) * currFocusRowValue)

  m.creatorInfoPanel.firstRowFocusPercent = 1 - currFocusRowValue
End Function


Function onRowItemFocusedChange(msg) as Void
  rowItemFocused = msg.getData()
  if m.youMightAlsoLikeRowIndex < 0 OR isNonEmptyArray(rowItemFocused) = false OR m.tubiRowList.content = invalid then
    return
  end if

  if rowItemFocused[0] <> m.youMightAlsoLikeRowIndex then
    return
  end if

  ' First item in first row is focused, update creator YMAL info
  m.creatorYMALInfo.content = m.tubiRowList.content.getChild(rowItemFocused[0]).getChild(rowItemFocused[1])
End Function


Function onNetworkRequestsFinished(response) as Void
  ' If our main response fails then we consider the whole request a failure
  collectionResponse = response[0]
  if isNode(collectionResponse) = false then
    m.top.pageErrorInfo = {}
    return
  end if

  rowHeights = []
  content = collectionResponse.gridContent

  ' Check if related content succeeded or not
  relatedContent = response[1]
  if isNode(relatedContent) = true then
    relatedContent.title = getTranslation("screenDetails_relatedTitles")
    relatedContent.gridItemType = m.constants.ui.gridItemTypes.videoTile

    m.youMightAlsoLikeRowIndex = content.getChildCount()

    content.appendChild(relatedContent)

    ' Prepopulate for a smooth first experience
    m.creatorYMALInfo.content = relatedContent.getChild(0)
  end if

  rowItemSize = []
  for each item in content.getChildren(-1, 0)
    if item.gridItemType = m.constants.ui.gridItemTypes.episodeItemLatestEpisodes then
      rowHeights.push(m.rowHeightEpisodeItemLatestEpisodes)
      rowItemSize.push(m.constants.ui.imageSizes.largeLandscape)
    else if item.gridItemType = m.constants.ui.gridItemTypes.episodeItem then
      rowHeights.push(m.rowHeightEpisodeItem)
      rowItemSize.push(m.constants.ui.imageSizes.largeLandscape)
    else
      rowHeights.push(m.rowHeightEpisodeItem)
      rowItemSize.push(m.constants.ui.imageSizes.videoTilesPortrait)
    end if
  end for

  m.tubiRowList.rowItemSize = rowItemSize
  m.tubiRowList.rowHeights = rowHeights
  m.tubiRowList.content = content

  appResponse = collectionResponse.app
  m.creatorInfoPanel.content = appResponse
  m.backgroundPoster.uri = appResponse.images.hero[0]

  m.top.pageLoadComplete = true
End Function


Function onScreenFocusChange(msg)
  if m.top.hasFocus() = true
    m.tubiRowList.setFocus(true)
  end if
End Function


Function onRowListNavigateWithinPageInfoChange(msg)
  m.top.navigateWithinPageInfo = msg.getData()
End Function


Function onRowListTrackingComponentInfoChange(msg)
  trackingComponentInfo = msg.getData()

  ' Cannot use alias since trackingComponentInfo is defined at base screen level
  m.top.trackingComponentInfo = trackingComponentInfo
End Function


' Handles tracking page info changes
' Updates child containers with the new tracking page info
' @param msg - Message object containing tracking page info
Function onTrackingPageInfoChange(msg)
  trackingPageInfo = msg.getData()

  ' Cannot use alias since trackingPageInfo is defined at base screen level
  m.tubiRowList.trackingPageInfo = trackingPageInfo
End Function
