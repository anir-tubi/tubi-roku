' This function converts the associative array into RAF Structure
' @adInfo: assocArray, Ad information retrieved from API response
Function createRAFStructure(adInfo)
  currentAdUnitsList = []
  streams = []
  trackingPixels = []

  if isAA(adInfo) = true
    adId = adInfo.ad_id
    media = adInfo.media

    streamUrl = ""
    duration = 0
    trackingEvents = {}

    if isAA(media) = true
      streamUrl = media.streamUrl
      duration = media.duration

      if isAA(media.trackingEvents) = true
        trackingEvents = media.trackingEvents
      end if
    end if

    streamAA = {
      id: adInfo.id
      mimetype: "video/mp4"
      provider: ""
      url: streamUrl
    }
    streams.push(streamAA)

    ' Handle error tracking
    error = adInfo.error
    if isNonEmptyString(error) = true
      trackingPixels.push(createTrackingPixel("Error", error))
    end if

    ' Handle impression tracking
    impTracking = adInfo.impTracking

    if isNonEmptyArray(impTracking) = true
      for each pixelUrl in impTracking
        trackingPixels.push(createTrackingPixel("Impression", pixelUrl, 0))
      end for
    end if

    ' Handle quartile tracking events
    trackingEventKeys = trackingEvents.Keys()
    for each key in trackingEventKeys
      for each pixelUrl in trackingEvents[key]
        details = getQuartileTrackingDetails(key, duration, pixelUrl)
        if details <> invalid
          trackingPixels.push(details)
        end if
      end for
    end for

    ' Build ad unit
    ads = []
    adUnit = {
      adid: adId
      adserver: "Tubi"
      creativeadid: adId
      duration: duration
      streamformat: "mp4"
      streams: streams
      tracking: trackingPixels
    }
    ads.push(adUnit)

    currentAdUnitsList.push({
      ads: ads
      duration: duration
      rendersequence: "preroll"
      rendertime: 0
      tracking: trackingPixels
      viewed: false
    })
  end if

  return currentAdUnitsList
End Function

' Helper: Creates a standard tracking pixel object
Function createTrackingPixel(eventType as String, url as String, time = 0 as Float) as Object
  return {
    event: eventType
    triggered: false
    url: replaceCachebusterMacro(url)
    time: time
  }
End Function

' Helper: Maps tracking event key to quartile details
' @key: String, tracking event key (e.g., "q25", "q50", etc.)
' @duration: Integer, total duration of the ad in seconds
' @pixelUrl: String, URL of the tracking pixel
'@returns: Object, tracking pixel object or invalid if key is unrecognized
Function getQuartileTrackingDetails(key as String, duration as Integer, pixelUrl as String) as Object
  pixelValue = key.split("q")[1]
  if pixelValue <> invalid
    iPixelPercent = pixelValue.toInt()
    pixelTypeMapping = {
      "0": "Impression"
      "25": "FirstQuartile"
      "50": "Midpoint"
      "75": "ThirdQuartile"
      "100": "Complete"
    }
    pixelType = pixelTypeMapping[pixelValue]
    time = duration * (iPixelPercent / 100)

    if isNonEmptyString(pixelType) = true
      return createTrackingPixel(pixelType, pixelUrl, time)
    end if
  end if

  return invalid
End Function


' the sStringToReplace is the agreed upon string that the backend will set to the param that is used for cachebusting.
' a cache busting string must be created within the Roku client and replace the sStringToReplace.
' @pixelURL: String, pixel urls needs to be updated
' @returns: String, the pixel URL with the cache buster string replaced.
Function replaceCachebusterMacro(pixelURL as String)
  sStringToReplace = "(ADRISE:CB)"
  sCacheBuster = createCacheBusterString()
  newPixelURL = pixelURL.replace(sStringToReplace, sCacheBuster)
  encodedUrl = ""

  if isNonEmptyString(newPixelURL) = true
    encodedUrl = newPixelURL.EncodeUri()
  end if

  return encodedUrl
End Function