' Parsers for Ad API responses
' Handles homescreen ads (carousel, spotlight, skin) and sponsored hub ads
' API: POST /ads/showcase


' Parses ad response from endpoint and processes requested ad types.
' @param fullResponse: assocArray, The full ad response.
' @param reqInfo: assocArray, Request info containing ad types.
' @returns: Array, Parsed ad content nodes.
Function parseHomeScreenAdsSuccess(fullResponse, reqInfo) as Object
  tubiLog("AdParsers.parseHomeScreenAdsSuccess")
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
    ' Process thematic takeover ad units (thematic_takeover1 through thematic_takeover7)
    if arrayIncludes(aRequestedAdTypes, m.constants.adTypes.thematicTakeover) = true
      for i = 1 to 7
        sAdUnitKey = "thematic_takeover_" + i.toStr()
        adUnit = adUnits[sAdUnitKey]
        if adUnit <> invalid AND adUnit.rendering_code = "thematic_takeover_row"
          thematicContent = processThematicTakeoverContent(adUnit)
          if thematicContent <> invalid
            aParsedAds.push(thematicContent)
          end if
        end if
      end for
    end if
    ' Process sponsored_container ad unit
    if arrayIncludes(aRequestedAdTypes, m.constants.adTypes.hubRowLockupAd) = true
      hubRowLockupAd = parseSponsoredContainerAd(adUnits)
      if hubRowLockupAd <> invalid
        hubRowLockupAd.type = m.constants.ui.contentTypes.hubRowLockupAd
        aParsedAds.push(hubRowLockupAd)
      end if
    end if

    ' Process sponsored_hero ad unit (Sponsored Live Events Hero)
    if arrayIncludes(aRequestedAdTypes, m.constants.adTypes.sponsoredLiveEventsHero) = true
      liveEventsHeroAd = processSponsoredLiveEventsHeroAdContent(adUnits)
      if liveEventsHeroAd <> invalid
        aParsedAds.push(liveEventsHeroAd)
      end if
    end if
  end if

  screenId = ""
  if reqInfo.screenId <> invalid
    screenId = reqInfo.screenId
  end if

  return {
    screenId: screenId
    data: aParsedAds
  }
End Function


Function parseHomeScreenAdsError(fullResponse, reqInfo)
  tubiLog("AdParsers.parseHomeScreenAdsError")
  screenId = ""
  if reqInfo.screenId <> invalid
    screenId = reqInfo.screenId
  end if

  return {
    code: getErrorCodeFromResponse(fullResponse)
    screenId: screenId
  }
End Function


' Parses the sponsored hub ad response and extracts ad assets and trackers
' @param fullResponse - The full API response containing ads.ad_units.sponsored_hub
' @param _reqInfo - Request info (unused)
' @returns - AssocArray with ad data (assets, trackers, id, validDuration) or invalid
Function parseSponsoredHubAdsSuccess(fullResponse, _reqInfo) as Object
  tubiLog("AdParsers.parseSponsoredHubAdsSuccess")
  parsedResponse = fullResponse.data
  if parsedResponse = invalid OR isAA(parsedResponse.ads) = false OR isAA(parsedResponse.ads.ad_units) = false
    return invalid
  end if

  adUnit = parsedResponse.ads.ad_units.sponsored_hub
  if isValidAssetAdUnit(adUnit) = false
    return invalid
  end if

  assets = adUnit.ad.assets
  adId = getAdID(adUnit.ad.id)

  aImageTracking = []
  if adUnit.trackers <> invalid AND isNonEmptyArray(adUnit.trackers.imp) = true
    aImageTracking = adUnit.trackers.imp
  end if

  if adUnit.valid_duration <> invalid AND adUnit.valid_duration > 0
    validUntil = UpTime(0) + adUnit.valid_duration
  else
    validUntil = UpTime(0) + m.constants.cacheTimes.homescreenAd
  end if

  result = {
    adId: adId
    imageImpTracking: aImageTracking
    validDuration: adUnit.valid_duration
    validUntil: validUntil
    trackers: adUnit.trackers
  }

  if assets.small_logo_lockup <> invalid AND isNonEmptyString(assets.small_logo_lockup.url)
    result.smallLogoLockupUrl = assets.small_logo_lockup.url
  end if
  if assets.brand_background <> invalid AND isNonEmptyString(assets.brand_background.url)
    result.brandBackgroundUrl = assets.brand_background.url
  end if
  if assets.brand_graphic <> invalid AND isNonEmptyString(assets.brand_graphic.url)
    result.brandGraphicUrl = assets.brand_graphic.url
  end if

  return result
End Function


' Parses the sponsored_container ad unit from hub ads response
' @param adUnits - The ad_units AA from the response
' @returns - AA with adId, heroLogoUrl, brandBackgroundUrl, imageImpTracking or invalid
Function parseSponsoredContainerAd(adUnits) as Object
  adUnit = adUnits.sponsored_container
  if isValidAssetAdUnit(adUnit) = false
    return invalid
  end if

  assets = adUnit.ad.assets
  adId = getAdID(adUnit.ad.id)

  aImageTracking = []
  if adUnit.trackers <> invalid AND isNonEmptyArray(adUnit.trackers.imp) = true
    aImageTracking = adUnit.trackers.imp
  end if

  containerResult = {
    adId: adId
    imageImpTracking: aImageTracking
    trackers: adUnit.trackers
    validDuration: adUnit.valid_duration
  }

  if assets.hero_logo <> invalid AND isNonEmptyString(assets.hero_logo.url)
    containerResult.heroLogoUrl = assets.hero_logo.url
  end if

  if assets.brand_background <> invalid AND isNonEmptyString(assets.brand_background.url)
    containerResult.brandBackgroundUrl = assets.brand_background.url
  end if

  return containerResult
End Function


' Handles parse error for sponsored hub ads - returns generic error
Function parseSponsoredHubAdsError(fullResponse, _reqInfo) as Object
  return {
    code: getErrorCodeFromResponse(fullResponse)
  }
End Function


' ==================== SHARED HELPERS ====================


' Helper to validate ad unit structure
Function isValidAssetAdUnit(adUnit) as Boolean
  return adUnit <> invalid AND adUnit.ad <> invalid AND adUnit.ad.assets <> invalid
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


' ==================== HOMESCREEN AD PROCESSORS ====================


' Processes hdc_row ad unit for carousel or spotlight ads
Function processHdcRowAd(adUnit, aRequestedAdTypes, aParsedAds, isUserInVideoTilesExperiment = false) as Void
  assets = adUnit.ad.assets
  adID = adUnit.ad.id
  aImageTracking = []
  if adUnit.trackers <> invalid AND isNonEmptyArray(adUnit.trackers.imp) = true
    aImageTracking = adUnit.trackers.imp
  end if
  iValidUntil = UpTime(0) + m.constants.cacheTimes.homescreenAd

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


' Processes carousel ad content from response.
' @param adID: String, The ad ID.
' @param assets: assocArray, Ad assets.
' @param iValidUntil: Integer, Ad validity timestamp.
' @param aImageTracking: Array, Image tracking data (default: []).
' @isInVideoTilesFormat: boolean, optional Whether the ad is in video tiles format. Default is false.
' @returns: roSGNode, Processed carousel ad node or invalid.
Function processCarouselAdContent(adID, assets, iValidUntil, aImageTracking = [], isUserInVideoTilesExperiment = false) as Object
  tubiLog("AdParsers.processCarouselAdContent")
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

  aCarousel = []
  for each sKey in assets.keys()
    if sKey.startsWith("background_") = true
      sIndex = sKey.split("background_")[1]
      tile = assets["tile_" + sIndex]
      carouselTile = parseCarouselTile(assets[sKey], tile, isUserInVideoTilesExperiment)
      if carouselTile <> invalid
        carouselTile.adInfo = adInfo
        aCarousel.push(carouselTile)
      end if
    end if
  end for

  ' If no valid carousel tiles were found, skip this ad unit
  if aCarousel.Count() = 0
    return invalid
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
  tubiLog("AdParsers.processSpotlightAdContent")
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

  translatedThumb = CreateObject("roSGNode", "AdContentNode")
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
  translatedThumb.adInfo = adInfo

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
  tubiLog("AdParsers.processSkinAdRowContent")
  if not isValidAssetAdUnit(rowAdUnit) = true
    return invalid
  end if

  assets = rowAdUnit.ad.assets

  iValidUntil = UpTime(0) + m.constants.cacheTimes.homescreenAd

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
    rowContentNode.imageImpTracking = rowAdUnit.trackers.imp
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
  categoryContentNode.adInfo = adInfo
  categoryContentNode.type = m.constants.ui.contentTypes.skinAd
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


' Processes thematic takeover ad content from response.
' Thematic takeovers apply theme styling TO existing containers (not inserting new rows).
' @param adUnit: assocArray, The thematic takeover ad unit from response
' @returns: assocArray, Processed thematic takeover info or invalid.
'   {
'     id: string - unique ad id
'     containerId: string - the container this theme applies to
'     type: string - contentTypes.thematicTakeover
'     validUntil: integer - timestamp when this ad expires
'     imageImpTracking: array - impression tracking pixels
'     sponsorshipInfo: AA - info formatted for setSponsorshipInfo
'   }
Function processThematicTakeoverContent(adUnit) as Object
  tubiLog("AdParsers.processThematicTakeoverContent")

  if adUnit = invalid OR adUnit.ad = invalid
    return invalid
  end if

  assets = adUnit.ad.assets
  if assets = invalid
    return invalid
  end if

  adID = ""
  if adUnit.ad.id <> invalid
    adID = getAdID(adUnit.ad.id)
  end if

  containerId = ""
  if assets.container_id <> invalid AND isNonEmptyString(assets.container_id.text) = true
    containerId = assets.container_id.text
  end if

  ' container_id is required - without it we don't know which container to apply the theme to
  if containerId = ""
    return invalid
  end if

  iValidUntil = UpTime(0) + m.constants.cacheTimes.homescreenAd
  if adUnit.valid_duration <> invalid AND adUnit.valid_duration > 0
    iValidUntil = UpTime(0) + adUnit.valid_duration
  end if

  aImageTracking = []
  if adUnit.trackers <> invalid AND isNonEmptyArray(adUnit.trackers.imp) = true
    aImageTracking = adUnit.trackers.imp
  end if

  ' Build sponsorship info in same format as homescreen endpoint
  sponsorshipInfo = {
    spon_exp: adID
    image_urls: {
      brand_logo: invalid
      brand_graphic: invalid
    }
    pixels: aImageTracking
  }

  if assets.brand_logo <> invalid AND isNonEmptyString(assets.brand_logo.url) = true
    sponsorshipInfo.image_urls.brand_logo = assets.brand_logo.url
  end if

  if assets.brand_graphic <> invalid AND isNonEmptyString(assets.brand_graphic.url) = true
    sponsorshipInfo.image_urls.brand_graphic = assets.brand_graphic.url
  end if

  thematicTakeoverNode = CreateObject("roSGNode", "AdContentNode")
  thematicTakeoverNode.id = adID
  thematicTakeoverNode.type = m.constants.ui.contentTypes.thematicTakeover
  thematicTakeoverNode.validUntil = iValidUntil
  thematicTakeoverNode.imageImpTracking = aImageTracking

  ' Store container_id and sponsorship info as custom fields
  thematicTakeoverNode.addFields({
    containerId: containerId
    sponsorshipInfo: sponsorshipInfo
  })

  ' Store adInfo for pixel refresh tracking (same pattern as carousel/spotlight)
  thematicTakeoverNode.adInfo = {
    ad_id: adID
    id: adID
    impTracking: aImageTracking
    type: "thematic_takeover"
  }

  return thematicTakeoverNode
End Function


' Parses the sponsored_hero ad unit from the homescreen ads response.
' Repurposes AdContentNode.titleImageUrl to carry the brand logo image URL.
' The ad unit key in the API response is "sponsored_hero" (rendering_code also "sponsored_hero").
' @param adUnits - The ad_units AA from the response
' @returns - An AdContentNode with type=sponsoredLiveEventsHero, or invalid if the unit is absent/invalid
Function processSponsoredLiveEventsHeroAdContent(adUnits) as Object
  adUnit = adUnits.sponsored_hero
  if isValidAssetAdUnit(adUnit) = false
    return invalid
  end if

  assets = adUnit.ad.assets
  if assets = invalid OR assets.brand_logo = invalid OR isNonEmptyString(assets.brand_logo.url) = false
    return invalid
  end if

  adId = getAdID(adUnit.ad.id)
  iValidUntil = 0
  if adUnit.valid_duration <> invalid AND adUnit.valid_duration > 0
    iValidUntil = UpTime(0) + adUnit.valid_duration
  end if

  aImageTracking = []
  if adUnit.trackers <> invalid AND isNonEmptyArray(adUnit.trackers.imp) = true
    aImageTracking = adUnit.trackers.imp
  end if

  adNode = CreateObject("roSGNode", "AdContentNode")
  adNode.id = adId
  adNode.type = m.constants.ui.contentTypes.sponsoredLiveEventsHero
  ' titleImageUrl is repurposed here to carry the brand logo overlay URL
  adNode.titleImageUrl = assets.brand_logo.url
  adNode.imageImpTracking = aImageTracking
  adNode.validUntil = iValidUntil
  adNode.adInfo = {
    ad_id: adId
    id: adId
    impTracking: aImageTracking
    type: "sponsored_hero"
  }

  return adNode
End Function
