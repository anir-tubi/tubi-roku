' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseHomeScreenContentSuccess(fullResponse, reqInfo)
  headers = fullResponse.responseHeaders
  parsedResponse = fullResponse.response.data

  contentMode = invalid
  isKidsMode = invalid

  uiMode = "standard"

  if reqInfo <> invalid AND reqInfo.options <> invalid

    options = reqInfo.options
    if options <> invalid AND options.params <> invalid
      contentMode = options.params.contentMode

      if contentMode = invalid
        contentMode = options.params.content_mode
      end if

      isKidsMode = options.params.isKidsMode
    end if

    uiMode = reqInfo.uiMode

  end if

  isSignedInUser = false
  if reqInfo <> invalid
    isSignedInUser = reqInfo.isSignedInUser
  end if

  screenId = m.constants.ui.screenIds.homeScreen
  if reqInfo <> invalid AND reqInfo.screenId <> invalid
    screenId = reqInfo.screenId
  end if

  convertedMetadata = m.metadataTranslate.translateHomescreen(parsedResponse, contentMode, isKidsMode, uiMode, screenId, isSignedInUser)

  if headers <> invalid AND headers["last-modified"] <> invalid
    convertedMetadata.update({
      lastModified: headers["Last-Modified"]
    }, true)
  end if

  if reqInfo <> invalid AND reqInfo.screenId <> invalid
    convertedMetadata.update({
      screenId: reqInfo.screenId
    }, true)
  end if

  return convertedMetadata
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseCategoryContentSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data
  fullJson = fullResponse.fullJson

  orientation = ""
  bFullData = false
  contentMode = m.constants.ui.contentMode.homescreen
  isSignedInUser = false
  screenId = m.constants.ui.screenIds.homeScreen

  isKidsMode = false
  uiMode = "standard"
  requestContext = {
    totalDuplicates: 0
    childrenContentIDs: {}
  }

  if reqInfo <> invalid
    isSignedInUser = reqInfo.isSignedInUser

    options = reqInfo.options
    if options <> invalid AND options.params <> invalid
      contentMode = options.params.content_mode
      isKidsMode = options.params.is_kids_mode
    end if

    if reqInfo.screenId <> invalid
      screenId = reqInfo.screenId
    end if

    if reqInfo.uiMode <> invalid
      uiMode = reqInfo.uiMode
    end if

    if reqInfo.requestContext <> invalid
      requestContext = reqInfo.requestContext
    end if
  end if

  ' Noticed a small bug in tensor response that sometimes cursor is not returned from backend using our request information.
  if parsedResponse <> invalid AND parsedResponse.container <> invalid AND parsedResponse.container.cursor = invalid
    if reqInfo <> invalid AND reqInfo.options <> invalid AND reqInfo.options.params <> invalid AND reqInfo.options.params.cursor <> invalid AND reqInfo.options.params.contents_limit <> invalid
      parsedResponse.container.cursor = reqInfo.options.params.cursor + reqInfo.options.params.contents_limit
    end if
  end if

  convertedMetadata = m.metadataTranslate.translateContainer(parsedResponse, fullJson, orientation, bFullData, contentMode, screenId, isSignedInUser, isKidsMode, uiMode, requestContext)
  return convertedMetadata 'may return an empty container
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseCategoryContentError(fullResponse, reqInfo)
  httpStatusCode = -1
  if fullResponse <> invalid AND fullResponse.code <> invalid
    httpStatusCode = fullResponse.code
  end if
  return {
    code: getErrorCodeFromResponse(fullResponse)
    httpStatusCode: httpStatusCode
    categoryId: reqInfo.categoryId
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGetQueueIdsSuccess(fullResponse, _reqInfo)
  bookmarkLib = TubiBookmarks(m.constants)
  return bookmarkLib.translateQueueIds(fullResponse.data)
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGetHistoryIdsSuccess(fullResponse, _reqInfo)
  bookmarkLib = TubiBookmarks(m.constants)
  return bookmarkLib.translateHistoryIds(fullResponse.data)
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseSoTStaticConfigSuccess(fullResponse, reqInfo)
  response = fullResponse.data
  parsedResponse = {}
  newEpisode = {}
  onlyOnTubi = {}
  tubiPresents = {}

  if response <> invalid
    parsedResponse.customizations = response.customizations

    neContentIds = response.new_episode
    if neContentIds <> invalid then
      for each id in neContentIds
        if isString(id) = false
          id = id.toStr()
        end if
        newEpisode[id] = true
      end for
    end if

    onlyOnTubiContentIds = response.only_on_tubi
    if onlyOnTubiContentIds <> invalid then
      for each id in onlyOnTubiContentIds
        if isString(id) = false
          id = id.toStr()
        end if
        onlyOnTubi[id] = true
      end for
    end if

    tpContentIds = response.tubi_presents
    if tpContentIds <> invalid then
      for each id in tpContentIds
        if isString(id) = false
          id = id.toStr()
        end if
        tubiPresents[id] = true
      end for
    end if

    parsedResponse.newEpisode = newEpisode
    parsedResponse.onlyOnTubi = onlyOnTubi
    parsedResponse.tubiPresents = tubiPresents
    return parsedResponse
  end if

  return response
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseCollectionSuccess(fullResponse, reqInfo)
  gridContentNode = parseHomeScreenContentSuccess(fullResponse, reqInfo)

  appNode = invalid
  appAA = fullResponse.response.data.app

  ' Make sure we have everything we need to not crash so we don't need to check later
  if appAA = invalid then
    appAA = {}
  end if

  if isAA(appAA.images) = false then
    appAA.images = {}
  end if

  if isArray(appAA.images.hero) = false then
    appAA.images.hero = []
  end if

  if isArray(appAA.images.logo) = false then
    appAA.images.logo = []
  else if appAA.images.logo.Count() > 0 then
    ' Round the logo corners
    appAA.images.logo[0] = m.metadataTranslate.getRoundedCornersURL(appAA.images.logo[0], 999)
  end if

  if isString(appAA.description) = false then
    appAA.description = ""
  end if

  if isArray(appAA.genres) = false then
    appAA.genres = []
  end if

  if isString(appAA.title) = false then
    appAA.title = ""
  end if

  if isString(appAA.type) = false then
    appAA.type = ""
  end if

  appNode = createObject("roSGNode", "Node")
  appNode.update(appAA, true)

  collectionNode = createObject("roSGNode", "Node")
  collectionNode.update({
    "app": appNode
    "gridContent": gridContentNode
  }, true)

  return collectionNode
End Function

