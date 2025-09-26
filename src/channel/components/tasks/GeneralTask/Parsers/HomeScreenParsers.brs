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

  'AdSkin
  ads = parsedResponse.ads
  if ads <> invalid AND ads.Count() > 0
    convertedMetadata.ads = m.metadataTranslate.translateAds(ads)
  end if

  if headers <> invalid AND headers["last-modified"] <> invalid
    convertedMetadata.update({
      lastModified: headers["Last-Modified"]
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


Function parseHomeScreenAdsSuccess(fullResponse, reqInfo)
  tubiLog("HomeScreenParsers.parseHomeScreenAdsSuccess")
  parsedResponse = fullResponse.data
  requestedAdTypes = []
  if reqInfo.adTypes <> invalid
    requestedAdTypes = reqInfo.adTypes
  end if
  aReturnAds = []
  if isNonEmptyArray(requestedAdTypes) AND parsedResponse <> invalid AND isAA(parsedResponse.ads) AND isAA(parsedResponse.ads.ad_units)
    ad_units = parsedResponse.ads.ad_units
    adUnit = ad_units.hdc_row

    if adUnit <> invalid AND adUnit.ad <> invalid AND adUnit.ad.assets <> invalid

      assets = adUnit.ad.assets
      adID = adUnit.ad.id
      aImageTracking = []
      if adUnit.trackers <> invalid AND isNonEmptyArray(adUnit.trackers.imp) = true
        aImageTracking = adUnit.trackers.imp
      end if
      if adUnit.valid_duration <> invalid AND isInt(adUnit.valid_duration) = true
        validUntil = UpTime(0) + adUnit.valid_duration
      else
        validUntil = UpTime(0) + m.constants.cacheTimes.homescreenAd
      end if


      for each adType in requestedAdTypes
        if adType = m.constants.adTypes.adRowlistCarousel AND adUnit.rendering_code = m.constants.ui.categoryIds.adRowlistCarousel
          ' If the rendering code matches the constants.ui.categoryIds.adRowlistCarousel, we can create a carousel ad node
          carouselNode = CreateObject("roSGNode", "AdDisplayCarouselContentNode")
          carouselNode.rowPlacement = 2 '//::NOTE:: this is hardcoded until the backend supports row_placement for ads
          carouselNode.id = adUnit.rendering_code
          carouselNode.type = m.constants.ui.contentTypes.adRowlistCarousel
          carouselNode.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel
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

          carousel = []
          ' Loop through the assets and see how many corresponding background/tile combos are returned for the carousel
          keys = assets.keys()
          for each key in keys
            if key.startsWith("background_") = true
              background = assets[key]
              index = key.split("background_")[1]
              tile = assets["tile_" + index.toStr()]
              carouselTile = parseCarouselTile(background, tile)
              if carouselTile <> invalid
                carousel.push(carouselTile)
              end if
            end if
          end for

          if carousel.Count() = 0
            ' If no valid carousel tiles were found, skip this ad unit
            continue for
          end if

          '//::NOTE:: quartile pixels are currently not being returned, but if they ever do, they will be supported.
          ' Add the ad info to the carousel node
          adInfo = invalid
          if videoData <> invalid
            adInfo = {
              ad_id: adID
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

          carouselNode.carousel = carousel

          translatedThumb = CreateObject("roSGNode", "TubiContentNode")
          translatedThumb.id = m.constants.ui.categoryIds.adRowlistCarousel
          translatedThumb.slug = adID
          translatedThumb.type = m.constants.ui.contentTypes.adRowlistCarousel
          translatedThumb.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel

          '//Round the corners on thumbnail that is displayed in homescreen rowList
          if assets.poster_image <> invalid AND isNonEmptyString(assets.poster_image.url) = true
            sRowThumbnailURL = m.metadataTranslate.getRoundedCornersURL(assets.poster_image.url, 18)
          else
            sRowThumbnailURL = m.metadataTranslate.getRoundedCornersURL(carousel[0].backgrounds[0], 18)
          end if
          translatedThumb.hdgridposterurl = sRowThumbnailURL

          if isNonEmptyArray(aImageTracking) = true
            carouselNode.imageImpTracking = aImageTracking
          end if

          carouselNode.validUntil = validUntil
          translatedThumb.validUntil = validUntil

          carouselNode.appendChild(translatedThumb)

          carouselNode.adInfo = adInfo
          aReturnAds.push(carouselNode)
        else if adType = m.constants.adTypes.adRowlistSpotlight AND adUnit.rendering_code = m.constants.ui.categoryIds.adRowlistSpotlight
          '//process the spotlight ad response
          aReturnAds.push(processSpotlightAdContent(adID, assets, validUntil, aImageTracking))
        end if
      end for
    end if

  end if

  return buildAdContentMap(aReturnAds)
End Function


' Helper function of parseHomeScreenAdsSuccess() to process the spotlight ad content from the ad response.
'
' @sAdID: string, The ID of the spotlight ad.
' @assets: assocArray, The assets associated with the ad.
' @validUntil: Integer, The time that the ad is valid until.
' @returnedImageTracking: Array, optional Image tracking data. Default is an empty array.
'
' @returns: object, An object containing processed spotlight ad content.
Function processSpotlightAdContent(sAdID, assets, validUntil, returnedImageTracking = []) as Object

  returnedAssetBgroundImage = assets.background_image
  returnedAssetPosterImage = assets.poster_image
  returnedAssetBrandText = assets.brand_text
  returnedAssetVideo = assets.video

  translatedThumb = CreateObject("roSGNode", "TubiContentNode")
  rowContentNode = CreateObject("roSGNode", "AdContentNode")
  rowContentNode.rowPlacement = 2
  rowContentNode.id = m.constants.ui.categoryIds.adRowlistSpotlight
  rowContentNode.type = m.constants.ui.contentTypes.adRowlistSpotlight
  rowContentNode.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight

  translatedThumb.id = m.constants.ui.categoryIds.adRowlistSpotlight
  translatedThumb.slug = sAdID
  translatedThumb.type = m.constants.ui.contentTypes.adRowlistSpotlight
  translatedThumb.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight

  if returnedAssetBgroundImage <> invalid AND isNonEmptyString(returnedAssetBgroundImage.url) = true
    translatedThumb.backgrounds = [returnedAssetBgroundImage.url]
  end if

  '//Round the corners on thumbnail that is displayed in homescreen rowList
  sRowThumbnailURL = ""
  if returnedAssetPosterImage <> invalid AND isNonEmptyString(returnedAssetPosterImage.url) = true
    sRowThumbnailURL = m.metadataTranslate.getRoundedCornersURL(returnedAssetPosterImage.url, 18)
  else if isNonEmptyArray(translatedThumb.backgrounds) = true
    sRowThumbnailURL = m.metadataTranslate.getRoundedCornersURL(translatedThumb.backgrounds[0], 18)
  end if
  translatedThumb.hdgridposterurl = sRowThumbnailURL

  if returnedAssetBrandText <> invalid AND isNonEmptyString(returnedAssetBrandText.text) = true
    rowContentNode.title = returnedAssetBrandText.text
  end if

  videoData = invalid
  if isNonEmptyArray(returnedAssetVideo) = true
    videoData = returnedAssetVideo[0]
    if isNonEmptyString(videoData.url) = true
      translatedThumb.videoPreviewUrl = videoData.url
    end if
  end if

  adInfo = invalid
  if videoData <> invalid
    adInfo = {
      ad_id: sAdID
      error: invalid
      id: sAdID
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

  if isNonEmptyArray(returnedImageTracking) = true
    rowContentNode.imageImpTracking = returnedImageTracking
  end if

  rowContentNode.validUntil = validUntil
  translatedThumb.validUntil = validUntil

  rowContentNode.appendChild(translatedThumb)

  return rowContentNode
End Function


' Helper function of parseHomeScreenAdsSuccess() to parse a carousel tile from the ad response.
Function parseCarouselTile(background, tile)
  ' Check if both background and tile are valid associative arrays with non-empty URLs
  if isAA(background) AND isNonEmptyString(background.url) AND isAA(tile) AND isNonEmptyString(tile.url)
    tileURL = m.metadataTranslate.getRoundedCornersURL(tile.url, 8)

    node = CreateObject("roSGNode", "AdContentNode")
    '//Create a unique ID for each node; this is important to ensure the video ad associated with this campaign can properly play
    node.id = CreateObject("roDeviceInfo").GetRandomUUID()
    node.type = m.constants.ui.contentTypes.adRowlistCarousel
    node.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel
    node.backgrounds = [background.url]
    imageURL = tileURL
    node.hdgridposterurl = imageURL

    return node
  else
    return invalid
  end if
End Function


' Helper function of parseHomeScreenAdsSuccess() to sort the ad content based on rowPlacement so that they are added in the correct order.
Function buildAdContentMap(response as Object) as Object
  ' Create an associative array to store nodes by rowPlacement
  contentMap = {}
  ' Create an array to store final sorted nodes
  sortedNodes = []

  ' Process each node
  for each node in response
    ' Check if rowPlacement exists, is set, and is >= 0
    if node <> invalid AND node.hasField("rowPlacement") AND node.rowPlacement <> invalid AND node.rowPlacement >= 0
      rowPlacement = node.rowPlacement
      rowKey = rowPlacement.toStr() ' Convert to string for assoc array key

      ' Check if rowPlacement already exists in map
      if contentMap.doesExist(rowKey)
        existingNode = contentMap[rowKey]
        ' Skip if existing node is adRowlistCarousel and current is adRowlistSpotlight
        if existingNode.type = m.constants.ui.contentTypes.adRowlistCarousel AND node.type = m.constants.ui.contentTypes.adRowlistSpotlight
          continue for
        end if
        ' Only replace if current is adRowlistCarousel and existing is adRowlistSpotlight
        if node.type = m.constants.ui.contentTypes.adRowlistCarousel AND existingNode.type = m.constants.ui.contentTypes.adRowlistSpotlight
          contentMap[rowKey] = node
        end if
        ' If types are the same, keep first node (do nothing)
      else
        ' Add new node to map
        contentMap[rowKey] = node
      end if
    end if
  end for

  ' Convert map values to array and sort by rowPlacement in descending order
  for each rowKey in contentMap
    sortedNodes.push(contentMap[rowKey])
  end for
  sortedNodes.sortBy("rowPlacement") ' Reverse sort by rowPlacement

  return sortedNodes
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
  return response
End Function