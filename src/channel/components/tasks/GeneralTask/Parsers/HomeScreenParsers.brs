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

  convertedMetadata = m.metadataTranslate.translateHomescreen(parsedResponse, contentMode, isKidsMode, uiMode, "homeScreen", isSignedInUser)

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


' Parses ad response from endpoint and processes requested ad types.
' @param fullResponse: assocArray, The full ad response.
' @param reqInfo: assocArray, Request info containing ad types.
' @returns: Array, Parsed ad content nodes.
Function parseHomeScreenAdsSuccess(fullResponse, reqInfo) as Object
  tubiLog("HomeScreenParsers.parseHomeScreenAdsSuccess")
  aParsedAds = []
  parsedResponse = fullResponse.data
  aRequestedAdTypes = []
  if reqInfo.adTypes <> invalid
    aRequestedAdTypes = reqInfo.adTypes
  end if
  isUserInVideoTilesExperiment = reqInfo.isUserInVideoTilesExperiment
  if isNonEmptyArray(aRequestedAdTypes) = true AND parsedResponse <> invalid AND isAA(parsedResponse.ads) = true AND isAA(parsedResponse.ads.ad_units) = true
    adUnits = parsedResponse.ads.ad_units
    if isValidAssetAdUnit(adUnits.hdc_row) = true
      processHdcRowAd(adUnits.hdc_row, aRequestedAdTypes, aParsedAds, isUserInVideoTilesExperiment)
    end if
    if isValidAssetAdUnit(adUnits.tubi_app_homepage) = true AND adUnits.homepage_video <> invalid
      content = processSkinAdRowContent(adUnits.tubi_app_homepage, adUnits.homepage_video)
      if content <> invalid
        aParsedAds.push(content)
      end if
    end if
  end if

  return aParsedAds
End Function


' Helper to validate ad unit structure
Function isValidAssetAdUnit(adUnit) as Boolean
  return adUnit <> invalid AND adUnit.ad <> invalid AND adUnit.ad.assets <> invalid
End Function


' Processes hdc_row ad unit for carousel or spotlight ads
Function processHdcRowAd(adUnit, aRequestedAdTypes, aParsedAds, isUserInVideoTilesExperiment = false) as Void
  assets = adUnit.ad.assets
  adID = adUnit.ad.id
  aImageTracking = []
  if adUnit.trackers <> invalid AND isNonEmptyArray(adUnit.trackers.imp) = true
    aImageTracking = adUnit.trackers.imp
  end if
  iValidUntil = UpTime(0) + m.constants.cacheTimes.homescreenAd
  if adUnit.valid_duration <> invalid AND isInt(adUnit.valid_duration) = true
    iValidUntil = UpTime(0) + adUnit.valid_duration
  end if

  for each adType in aRequestedAdTypes
    if adType = m.constants.adTypes.adRowlistCarousel AND adUnit.rendering_code = m.constants.ui.categoryIds.adRowlistCarousel
      carouselRowContent = processCarouselAdContent(adID, assets, iValidUntil, aImageTracking, isUserInVideoTilesExperiment)
      if carouselRowContent <> invalid
        aParsedAds.push(carouselRowContent)
      end if
    else if adType = m.constants.adTypes.adRowlistSpotlight AND adUnit.rendering_code = m.constants.ui.categoryIds.adRowlistSpotlight
      aParsedAds.push(processSpotlightAdContent(adID, assets, iValidUntil, aImageTracking, isUserInVideoTilesExperiment))
    end if
  end for
End Function


' Converts ad ID to string
Function getAdID(id) as String
  if isNonEmptyString(id) = true
    return id
  else if isNumber(id) = true
    return id.toStr()
  end if
  return ""
End Function


' Processes carousel ad content from response.
' @param adID: String, The ad ID.
' @param assets: assocArray, Ad assets.
' @param iValidUntil: Integer, Ad validity timestamp.
' @param aImageTracking: Array, Image tracking data (default: []).
' @isInVideoTilesFormat: boolean, optional Whether the ad is in video tiles format. Default is false.
' @returns: roSGNode, Processed carousel ad node or invalid.
Function processCarouselAdContent(adID, assets, iValidUntil, aImageTracking = [], isUserInVideoTilesExperiment = false) as Object
  tubiLog("HomeScreenParsers.processCarouselAdContent")
  carouselNode = CreateObject("roSGNode", "AdDisplayCarouselContentNode")
  carouselNode.rowPlacement = 2 ' Hardcoded until backend supports row_placement
  carouselNode.id = m.constants.ui.categoryIds.adRowlistCarousel
  carouselNode.type = m.constants.ui.contentTypes.adRowlistCarousel
  carouselNode.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel
  carouselNode.validUntil = iValidUntil
  carouselNode.imageImpTracking = aImageTracking
  if assets.brand_logo <> invalid AND isNonEmptyString(assets.brand_logo.url) = true
    carouselNode.titleImageUrl = assets.brand_logo.url
  end if
  if assets.brand_text <> invalid AND isNonEmptyString(assets.brand_text.text) = true
    carouselNode.title = assets.brand_text.text
  end if

  videoData = invalid
  if isNonEmptyArray(assets.video) = true
    videoData = assets.video[0]
    carouselNode.videoPreviewUrl = videoData.url
  end if

  aCarousel = []
  for each sKey in assets.keys()
    if sKey.startsWith("background_") = true
      sIndex = sKey.split("background_")[1]
      tile = assets["tile_" + sIndex]
      carouselTile = parseCarouselTile(assets[sKey], tile, isUserInVideoTilesExperiment)
      if carouselTile <> invalid
        aCarousel.push(carouselTile)
      end if
    end if
  end for

  ' If no valid carousel tiles were found, skip this ad unit
  if aCarousel.Count() = 0
    return invalid
  end if

  '//::NOTE:: quartile pixels are currently not being returned, but if they ever do, they will be supported.
  ' Add the ad info to the carousel node
  adInfo = invalid
  if videoData <> invalid
    ad_id = getAdID(adID) '// Ensure ad_id is a string or else there is a mismatch issue with RAF
    adInfo = {
      ad_id: ad_id
      error: invalid
      id: adID
      impTracking: ""
      media: {
        duration: videoData.duration
        streamUrl: videoData.url
        trackingEvents: {}
      }
      type: "video"
    }
  end if

  translatedThumb = CreateObject("roSGNode", "TubiContentNode")
  translatedThumb.id = m.constants.ui.categoryIds.adRowlistCarousel
  translatedThumb.slug = adID
  translatedThumb.type = m.constants.ui.contentTypes.adRowlistCarousel
  translatedThumb.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel
  translatedThumb.validUntil = iValidUntil

  '//Round the corners on thumbnail that is displayed in homescreen rowList
  if assets.poster_image <> invalid AND isNonEmptyString(assets.poster_image.url) = true
    sRowThumbnailURL = m.metadataTranslate.getRoundedCornersURL(assets.poster_image.url, 18)
  else
    sRowThumbnailURL = m.metadataTranslate.getRoundedCornersURL(aCarousel[0].backgrounds[0], 18)
  end if
  translatedThumb.hdgridposterurl = sRowThumbnailURL

  carouselNode.carousel = aCarousel
  carouselNode.adInfo = adInfo
  carouselNode.appendChild(translatedThumb)

  return carouselNode
End Function


' Processes spotlight ad content from response.
' @param adID: String, The ad ID.
' @param assets: assocArray, Ad assets.
' @param iValidUntil: Integer, Ad validity timestamp.
' @param aImageTracking: Array, Image tracking data (default: []).
' @isInVideoTilesFormat: boolean, optional Whether the ad is in video tiles format. Default is false.
'
' @returns: roSGNode, Processed spotlight ad node or invalid.
Function processSpotlightAdContent(adID, assets, iValidUntil, aImageTracking = [], isUserInVideoTilesExperiment = false) as Object
  tubiLog("HomeScreenParsers.processSpotlightAdContent")
  rowContentNode = CreateObject("roSGNode", "AdContentNode")
  rowContentNode.rowPlacement = 2
  rowContentNode.id = m.constants.ui.categoryIds.adRowlistSpotlight
  rowContentNode.type = m.constants.ui.contentTypes.adRowlistSpotlight
  rowContentNode.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight
  rowContentNode.validUntil = iValidUntil
  rowContentNode.imageImpTracking = aImageTracking

  if assets.brand_text <> invalid AND isNonEmptyString(assets.brand_text.text) = true
    rowContentNode.title = assets.brand_text.text
  end if

  translatedThumb = CreateObject("roSGNode", "TubiContentNode")
  translatedThumb.id = m.constants.ui.categoryIds.adRowlistSpotlight
  translatedThumb.slug = adID
  translatedThumb.type = m.constants.ui.contentTypes.adRowlistSpotlight
  translatedThumb.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight
  translatedThumb.validUntil = iValidUntil

  videoData = invalid
  if isNonEmptyArray(assets.video) = true
    videoData = assets.video[0]
    translatedThumb.videoPreviewUrl = videoData.url
  end if

  adInfo = invalid
  if videoData <> invalid
    ad_id = getAdID(adID) '// Ensure ad_id is a string or else there is a mismatch issue with RAF
    adInfo = {
      ad_id: ad_id
      error: invalid
      id: adID
      impTracking: ""
      media: {
        duration: videoData.duration
        streamUrl: videoData.url
        trackingEvents: {}
      }
      type: "video"
    }
  end if
  rowContentNode.adInfo = adInfo

  aBackgrounds = []
  if assets.background_image <> invalid AND isNonEmptyString(assets.background_image.url) = true
    aBackgrounds = [assets.background_image.url]
  end if
  translatedThumb.backgrounds = aBackgrounds

  '//Round the corners on thumbnail that is displayed in homescreen rowList
  sRowThumbnailURL = ""
  if assets.poster_image <> invalid AND isNonEmptyString(assets.poster_image.url) = true
    sRowThumbnailURL = m.metadataTranslate.getRoundedCornersURL(assets.poster_image.url, 18)
  else if isNonEmptyArray(translatedThumb.backgrounds) = true
    sRowThumbnailURL = m.metadataTranslate.getRoundedCornersURL(translatedThumb.backgrounds[0], 18)
  end if

  translatedThumb.hdgridposterurl = sRowThumbnailURL

  rowContentNode.update({
    useVideoTilesFormat: isUserInVideoTilesExperiment
  }, true)

  rowContentNode.appendChild(translatedThumb)
  return rowContentNode
End Function


' Processes skin ad row and video ad units for home screen UI.
' @param rowAdUnit: assocArray, The row ad unit.
' @param videoAdUnit: assocArray, The video ad unit.
' @returns: roSGNode, Processed skin ad node or invalid.
Function processSkinAdRowContent(rowAdUnit, videoAdUnit) as Object
  tubiLog("HomeScreenParsers.processSkinAdRowContent")
  if not isValidAssetAdUnit(rowAdUnit) = true
    return invalid
  end if

  assets = rowAdUnit.ad.assets

  iValidUntil = UpTime(0) + m.constants.cacheTimes.homescreenAd
  if rowAdUnit.valid_duration <> invalid AND isInt(rowAdUnit.valid_duration) = true
    iValidUntil = UpTime(0) + rowAdUnit.valid_duration
  end if

  id = ""
  sPosterURL = ""
  adInfo = invalid
  if isValidAssetAdUnit(videoAdUnit) = true
    id = videoAdUnit.ad.id

    videoAssets = videoAdUnit.ad.assets
    videoTrackers = videoAdUnit.trackers
    if videoAssets.poster_image <> invalid AND isNonEmptyString(videoAssets.poster_image.url) = true
      sPosterURL = videoAssets.poster_image.url
    end if
    if isNonEmptyArray(videoAssets.video) = true
      videoData = videoAssets.video[0]
      aImpTracking = []
      if isNonEmptyArray(videoTrackers.imp) = true
        aImpTracking = videoTrackers.imp
      end if
      if videoData <> invalid
        ad_id = getAdID(id) '// Ensure ad_id is a string or else there is a mismatch issue with RAF
        adInfo = {
          ad_id: ad_id
          error: invalid
          id: id
          impTracking: aImpTracking
          media: {
            duration: videoData.duration
            streamUrl: videoData.url
            trackingEvents: videoTrackers
          }
          type: "video"
        }
      end if
    end if
  end if

  categoryContentNode = CreateObject("roSGNode", "AdContentNode")
  rowContentNode = CreateObject("roSGNode", "SkinAdContentNode")
  rowContentNode.validUntil = iValidUntil
  categoryContentNode.validUntil = iValidUntil
  rowContentNode.type = m.constants.ui.contentTypes.skinAd
  rowContentNode.gridItemType = m.constants.ui.gridItemTypes.skinAd
  rowContentNode.id = id
  rowContentNode.adInfo = adInfo
  if assets.color <> invalid AND isNonEmptyString(assets.color.text) = true
    rowContentNode.bgColor = assets.color.text
  end if

  skinAdContent = CreateObject("roSGNode", "SkinAdContentNode")
  skinAdContent.gridItemType = m.constants.ui.gridItemTypes.skinAd
  skinAdContent.type = m.constants.ui.contentTypes.skinAd
  skinAdContent.id = id
  skinAdContent.adInfo = adInfo
  if assets.brand_name <> invalid AND isNonEmptyString(assets.brand_name.text) = true
    rowContentNode.title = assets.brand_name.text
    skinAdContent.title = assets.brand_name.text
  end if
  if assets.logo_url <> invalid AND isNonEmptyString(assets.logo_url.url) = true
    rowContentNode.titleImageUrl = assets.logo_url.url
    skinAdContent.titleImageUrl = assets.logo_url.url
  end if
  if assets.title <> invalid AND isNonEmptyString(assets.title.text) = true
    rowContentNode.titlePrefix = assets.title.text
    skinAdContent.titlePrefix = assets.title.text
  end if
  if assets.body <> invalid AND isNonEmptyString(assets.body.text) = true
    rowContentNode.description = assets.body.text
    skinAdContent.description = assets.body.text
  end if
  if assets.call_to_action <> invalid AND isNonEmptyString(assets.call_to_action.text) = true
    rowContentNode.subDescription = assets.call_to_action.text
    skinAdContent.subDescription = assets.call_to_action.text
  end if
  if assets.landing_page <> invalid AND isNonEmptyString(assets.landing_page.url) = true
    rowContentNode.qrCodeUrl = assets.landing_page.url
    skinAdContent.qrCodeUrl = assets.landing_page.url
  end if
  if rowAdUnit.trackers <> invalid AND isNonEmptyArray(rowAdUnit.trackers.imp) = true
    categoryContentNode.imageImpTracking = rowAdUnit.trackers.imp
  end if
  if assets.main_image <> invalid AND isNonEmptyString(assets.main_image.url) = true
    skinAdContent.backgrounds = [assets.main_image.url]
  end if
  if isNonEmptyArray(assets.video) = true AND assets.video[0] <> invalid AND isNonEmptyString(assets.video[0].url) = true
    skinAdContent.videoPreviewUrl = assets.video[0].url
  end if
  if isNonEmptyString(sPosterURL) = true
    sWidth = m.constants.ui.imageSizes.skinAdLandscape[0].toStr()
    sPosterURL = replaceURLParameter(sPosterURL, "w", sWidth, true)
    skinAdContent.HDGRIDPOSTERURL = m.metadataTranslate.getRoundedCornersURL(sPosterURL, 8)
  end if

  categoryContentNode.id = m.constants.ui.categoryIds.skinAd
  categoryContentNode.gridItemType = m.constants.ui.gridItemTypes.skinAd
  categoryContentNode.appendChild(skinAdContent)
  rowContentNode.appendChild(categoryContentNode)

  '//proceed if the wrapper response has the mandatory fields
  if (isNonEmptyString(rowContentNode.title) = true OR isNonEmptyString(rowContentNode.titleImageUrl) = true) AND isNonEmptyString(rowContentNode.id) = true AND (isNonEmptyString(skinAdContent.videoPreviewUrl) = true OR (isNonEmptyArray(skinAdContent.backgrounds) = true AND isNonEmptyString(skinAdContent.backgrounds[0]) = true)) AND isNonEmptyString(skinAdContent.HDGRIDPOSTERURL) = true
    if m.constants.settings.disableSkinAds = false
      return rowContentNode
    end if
  end if
  return invalid
End Function


' Parses a carousel tile from ad response.
' @param background: assocArray, Background asset.
' @param tile: assocArray, Tile asset.
' @param isInVideoTilesFormat: boolean, optional Whether the ad is in video tiles format. Default is false.
' @returns: roSGNode, Processed tile node or invalid.
Function parseCarouselTile(background, tile, isUserInVideoTilesExperiment = false) as Object
  if isAA(background) = true AND isNonEmptyString(background.url) = true AND isAA(tile) = true AND isNonEmptyString(tile.url) = true
    sTileURL = m.metadataTranslate.getRoundedCornersURL(tile.url, 8)
    node = CreateObject("roSGNode", "AdContentNode")
    '//Create a unique ID for each node; this is important to ensure the video ad associated with this campaign can properly play
    node.id = CreateObject("roDeviceInfo").GetRandomUUID()
    node.type = m.constants.ui.contentTypes.adRowlistCarousel
    node.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel
    node.backgrounds = [background.url]
    node.hdgridposterurl = sTileURL

    node.update({
      useVideoTilesFormat: isUserInVideoTilesExperiment
    }, true)

    return node
  end if
  return invalid
End Function


Function parseHomeScreenAdsError(fullResponse, reqInfo)
  tubiLog("HomeScreenParsers.parseHomeScreenAdsError")
  screenId = ""
  if reqInfo.screenId <> invalid
    screenId = reqInfo.screenId
  end if

  return {
    code: getErrorCodeFromResponse(fullResponse)
    screenId: screenId
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseSoTStaticConfigSuccess(fullResponse, reqInfo)
  response = fullResponse.data
  parsedResponse = {}
  newEpisode = {}
  tubiPresents = {}

  if response <> invalid
    parsedResponse.customizations = response.customizations

    neContentIds = response.new_episode
    for each id in neContentIds
      if isString(id) = false
        id = id.toStr()
      end if
      newEpisode[id] = true
    end for

    tpContentIds = response.tubi_presents
    for each id in tpContentIds
      if isString(id) = false
        id = id.toStr()
      end if
      tubiPresents[id] = true
    end for

    parsedResponse.newEpisode = newEpisode
    parsedResponse.tubiPresents = tubiPresents
    return parsedResponse
  end if

  return response
End Function