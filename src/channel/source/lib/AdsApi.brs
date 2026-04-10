' Thin wrapper for Ad Showcase API requests. Collected here to facilitate easy
' integration tests
' @param constants - Application constants
' @param apiUtilsLib - ApiUtils instance providing getCommonOptions
Function AdsApi(constants, apiUtilsLib)

  defaultValues = {
    ' dependencies
    constants: constants

    renderingCodes: {
      wrapper: "wrapper"
      wrapperVideo: "wrapper_video"
      hdcCarousel: "hdc_carousel"
      hdcSpotlight: "hdc_spotlight"
      sponsoredHub: "sponsored_hub"
      sponsoredHero: "sponsored_hero"
      thematicTakeover: "thematic_takeover_row"
      hubRowLockupAd: "sponsored_container"
      brandedScrubber: "branded_scrubber"
    }

    ' public
    createHomeScreenAdReqInfo: adsApi_createHomeScreenAdReqInfo
    createSponsoredHubAdReqInfo: adsApi_createSponsoredHubAdReqInfo
    createVideoPlayerScrubberShowcaseReqInfo: cmsApi_createVideoPlayerScrubberShowcaseReqInfo

    ' private
    getAdRequestHeaders: adsApi_getAdRequestHeaders
    getAdVideoResolution: adsApi_getAdVideoResolution
    getAdAppInfo: adsApi_getAdAppInfo
    getAdDeviceInfo: adsApi_getAdDeviceInfo
    buildAdReqInfo: adsApi_buildAdReqInfo
    generateAdUnitFromAdType: adsApi_generateAdUnitFromAdType
  }

  adsApiInstance = {}
  adsApiInstance.append(apiUtilsLib)
  adsApiInstance.append(defaultValues)
  return adsApiInstance

End Function


' ==================== PUBLIC ====================


' Creates request info for homescreen ad display container
' @param adTypes - Array of ad types to request (from constants.adTypes)
' @param appMode - App mode string: "DEFAULT_MODE", "KIDS_MODE", "LATINO_MODE"
' @param userId - User ID string
' @param bKidsMode - Whether kids mode is active (suppresses IFA)
Function adsApi_createHomeScreenAdReqInfo(adTypes = [], appMode = "DEFAULT_MODE", userId = "", bKidsMode = false)
  ifaValue = ""
  if bKidsMode = false
    ifaValue = m.constants.deviceInfo.deviceAdId
  end if

  adUnits = {}
  for each adType in adTypes
    adUnits = m.generateAdUnitFromAdType(adType, adUnits)
  end for

  body = {
    viewer: {
      viewer_id: userId
    }
    app: m.getAdAppInfo(ifaValue)
    device: m.getAdDeviceInfo()
    custom_kvps: {
      app_mode: appMode
    }
    ad_units: adUnits
  }

  return m.buildAdReqInfo(body)
End Function


' Creates request info for sponsored hub ads
' @param userId - User ID string for ad targeting
' @param bKidsMode - Whether kids mode is active (suppresses IFA)
Function adsApi_createSponsoredHubAdReqInfo(userId = "", bKidsMode = false)
  ifaValue = ""
  if bKidsMode = false
    ifaValue = m.constants.deviceInfo.deviceAdId
  end if

  body = {
    viewer: {
      viewer_id: userId
    }
    app: m.getAdAppInfo(ifaValue)
    device: m.getAdDeviceInfo()
    ad_units: {
      sponsored_hub: {
        sizes: {
          rendering_codes: [m.renderingCodes.sponsoredHub]
        }
      }
    }
  }

  return m.buildAdReqInfo(body)
End Function


' ==================== PRIVATE ====================


' Builds common headers for ad showcase requests
Function adsApi_getAdRequestHeaders() as Object
  headers = {}
  headers.append(m.getCommonOptions().headers)
  headers.append({
    "user-agent": m.constants.deviceInfo.userAgent
  })
  return headers
End Function


' Returns the video resolution string (e.g. "720p", "1080p") with fallback to 720p
Function adsApi_getAdVideoResolution() as String
  nResolution = m.constants.deviceInfo.videoMode.toInt()
  videoResolutionID = m.constants.player.videoResolution[nResolution.toStr()]
  if videoResolutionID = invalid OR videoResolutionID = m.constants.player.videoResolution.unknown OR videoResolutionID = m.constants.player.videoResolution["AUTO"]
    nResolution = 720
  end if
  return nResolution.toStr() + "p"
End Function


' Returns the common app info block for ad requests
' @param ifaValue - The IFA (identifier for advertising) value; empty string to omit
Function adsApi_getAdAppInfo(ifaValue = "") as Object
  return {
    app_install_id: m.constants.deviceInfo.deviceId
    ifa: ifaValue
    video_resoln: m.getAdVideoResolution()
  }
End Function


' Returns the common device info block for ad requests
Function adsApi_getAdDeviceInfo() as Object
  return {
    platform: UCase(m.constants.platform)
    os: m.constants.deviceInfo.operatingSystem
    os_version: m.constants.deviceInfo.firmwareVersion
    make: m.constants.deviceInfo.vendorName
    width: m.constants.deviceInfo.displayWidth
    height: m.constants.deviceInfo.displayHeight
  }
End Function


' Wraps a body AA into the standard ad showcase request info format
' @param body - The request body associative array
Function adsApi_buildAdReqInfo(body) as Object
  return {
    url: m.constants.urls.adShowcase
    options: {
      body: FormatJSON(body)
      headers: m.getAdRequestHeaders()
      method: m.constants.reqTypes.post
    }
    timeoutInMilliSec: 5000
  }
End Function


' Generates an ad unit based on the specified ad type
' @param sAdType - The ad type constant
' @param aaAdUnits - Accumulator for ad units
' @return - The updated ad units associative array
Function adsApi_generateAdUnitFromAdType(sAdType, aaAdUnits)
  adTypes = m.constants.adTypes

  if sAdType = adTypes.skinAd
    aaAdUnits.tubi_app_homepage = adsApi_adUnit([m.renderingCodes.wrapper])
    aaAdUnits.homepage_video = adsApi_adUnit([m.renderingCodes.wrapperVideo])
  else if sAdType = adTypes.adRowlistSpotlight OR sAdType = adTypes.adRowlistCarousel
    if sAdType = adTypes.adRowlistCarousel
      renderingCode = m.renderingCodes.hdcCarousel
    else
      renderingCode = m.renderingCodes.hdcSpotlight
    end if

    if aaAdUnits.hdc_row <> invalid
      aaAdUnits.hdc_row.sizes.rendering_codes.push(renderingCode)
    else
      aaAdUnits.hdc_row = adsApi_adUnit([renderingCode])
    end if
  else if sAdType = adTypes.thematicTakeover
    for i = 1 to 7
      ' This substitution is requirement because of a limitation in the Ads API where we need to provide them a ad slot code for returning a ad,
      ' since we can have multiple thematic takeovers on the same screen.
      aaAdUnits[substitute("thematic_takeover_{0}", i.toStr())] = adsApi_adUnit([m.renderingCodes.thematicTakeover])
    end for
  else if sAdType = adTypes.hubRowLockupAd
    aaAdUnits.sponsored_container = adsApi_adUnit([m.renderingCodes.hubRowLockupAd])
  else if sAdType = adTypes.sponsoredLiveEventsHero
    aaAdUnits.sponsored_hero = adsApi_adUnit([m.renderingCodes.sponsoredHero])
  else if sAdType = adTypes.brandedScrubber
    aaAdUnits.branded_scrubber = adsApi_adUnit([m.renderingCodes.brandedScrubber])
  end if

  return aaAdUnits
End Function


' Creates a standard ad unit structure with the given rendering codes
' @param renderingCodes - Array of rendering code strings
Function adsApi_adUnit(renderingCodes as Object) as Object
  return {
    sizes: {
      rendering_codes: renderingCodes
    }
  }
End Function


' Request body for video player scrubber showcase ads (branded_scrubber).
' @contentId: string or integer, current playback content id
' @appMode: string, the app mode for which the ad request is being made
' @userId: string, the user id for which the ad request is being made.
' @bKidsMode: boolean Are we in kids mode?
Function cmsApi_createVideoPlayerScrubberShowcaseReqInfo(contentId, appMode = "DEFAULT_MODE", userId = "", bKidsMode = false) as Object
  contentIdStr = ""
  if contentId <> invalid
    if isString(contentId) = true
      contentIdStr = contentId
    else
      contentIdStr = contentId.toStr()
    end if
  end if

  ifaValue = ""
  if bKidsMode = false
    ifaValue = m.constants.deviceInfo.deviceAdId
  end if

  adUnits = {}
  adUnits = m.generateAdUnitFromAdType(m.constants.adTypes.brandedScrubber, adUnits)

  body = {
    viewer: {
      viewer_id: userId
    }
    content_id: contentIdStr
    app: m.getAdAppInfo(ifaValue)
    device: m.getAdDeviceInfo()
    custom_kvps: {
      app_mode: appMode
    }
    ad_units: adUnits
  }

  return m.buildAdReqInfo(body)
End Function
