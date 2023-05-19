' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseVideoScreenSpritesSuccess(fullResponse, _reqInfo)
  parsedResponse = fullResponse.data
  spritesContentNode = invalid
  if parsedResponse <> invalid then
    spritesContentNode = CreateObject("roSGNode", "TubiContentNode")
    spritesContentNode.id = parsedResponse.id
    spritesContentNode.thumbnailUrls = parsedResponse.sprites
    spritesContentNode.thumbnailSpan = parsedResponse.count_per_sprite
    if parsedResponse.rows <> invalid
      spritesContentNode.thumbnailRows = parsedResponse.rows
    end if
    if parsedResponse.columns <> invalid
      spritesContentNode.thumbnailColumns = parsedResponse.columns
    end if
    spritesContentNode.thumbnailSize = [parsedResponse.frame_width, parsedResponse.height]
  end if

  return spritesContentNode
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseVideoScreenUpNextSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data
  upNextContent = CreateObject("roSGNode", "ContentNode")

  isSignedInUser = false
  if reqInfo <> invalid
    isSignedInUser = reqInfo.isSignedInUser
  end if

  if parsedResponse.contents <> invalid
    for each content in parsedResponse.contents
      upNextItem = upNextContent.createChild("TubiContentNode")
      m.metadataTranslate.upNextTranslateRecursiveWrapper(content, upNextItem, isSignedInUser)
    end for
  end if
  return upNextContent
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseLiveVideoManifestSuccess(fullResponse, _reqInfo)
  return {
    res: fullResponse.data
    headers: fullResponse.headers
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
'
' @returns: a clone of the content that was used to make the request with updated history id
' and parentHistoryId (if original content was an episode), or invalid if response JSON does not
' contain the expected keys.
Function parseHistorySuccess(fullResponse, reqInfo)
  response = fullResponse.data

  if response.content_id = invalid or response.id = invalid or response.content_type = invalid then
    return invalid
  end if

  if reqInfo.content = invalid
    return invalid
  end if

  content = reqInfo.content.clone(true)
  nowPos = reqInfo.nowPos

  isResponseSeries = (response.content_type = m.constants.uapiContentTypes.series AND response.episodes <> invalid AND type(response.episodes) = "roArray" AND response.episodes.count() > 0)
  episode = invalid

  if isResponseSeries = true
    episodeIndex = 0
    if response.position <> invalid
      episodeIndex = response.position
    end if

    episode = response.episodes[episodeIndex]

    if episode = invalid or episode.content_id = invalid
      return invalid
    end if
  else if response.content_type <> m.constants.uapiContentTypes.movie  AND response.content_type <> m.constants.uapiContentTypes.sportsEvent
    ' the response is a series type, but missing some necessary information
    return invalid
  end if

  ' create a default content node in case one wasn't passed as part of the request input as expected
  mustCreateNewContent = false
  if type(content) <> "roSGNode"
    mustCreateNewContent = true
  else if isResponseSeries = true AND episode.content_id.toStr() <> content.id
    mustCreateNewContent = true
  else if isResponseSeries = false AND response.content_id.toStr() <> content.id
    mustCreateNewContent = true
  end if

  if mustCreateNewContent = true
    content = createObject("roSGNode", "TubiContentNode")

    if isResponseSeries = true
      content.id = episode.content_id.toStr()
      content.type = m.constants.uapiContentTypes.episode
    else if response.content_type = m.constants.uapiContentTypes.sportsEvent
      content.id = response.content_id.toStr()
      content.type = m.constants.uapiContentTypes.sportsEvent
    else
      content.id = response.content_id.toStr()
      content.type = m.constants.uapiContentTypes.movie
    end if
  end if

  position = -1
  if isResponseSeries = true
    content.historyId = episode.id.toStr()
    content.parentHistoryId = response.id.toStr()
    position = episode.position
  else
    content.historyId = response.id.toStr()
    position = response.position
  end if

  if position >= 0
    content.nowPos = position
  else
    content.nowPos = nowPos
  end if

  return content
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parsePauseAdSuccess(fullResponse, _reqInfo)
  parsedResponse = fullResponse.data
  content = invalid

  if parsedResponse <> invalid
    content = createObject("roSGNode", "PauseAdsContentNode")

    if parsedResponse.metadata <> invalid then
      content.requestId = parsedResponse.metadata.request_id
    end if

    creatives = parsedResponse.creatives

    if creatives <> invalid AND creatives.Count() > 0
      firstCreative = creatives[0]

      if firstCreative <> invalid AND firstCreative.creative <> invalid
        trackingEvents = firstCreative.creative.tracking_events

        if trackingEvents <> invalid

          if trackingEvents.start <> invalid AND trackingEvents.start.Count() > 0
            content.startPixel = trackingEvents.start[0]
          end if

          if trackingEvents.end <> invalid AND trackingEvents.end.Count() > 0
            content.endPixel = trackingEvents.end[0]
          end if

          if trackingEvents.not_used <> invalid AND trackingEvents.not_used.Count() > 0
            content.notUsedPixel = trackingEvents.not_used[0]
          end if
        end if
      end if

      if firstCreative <> invalid AND firstCreative.creative <> invalid

        media = firstCreative.creative.media

        if media <> invalid
          content.mediaUrl = media.url
          content.width = media.width
          content.height = media.height
        end if

        if firstCreative.imp_tracking <> invalid AND firstCreative.imp_tracking.Count() > 0
          content.impTrackingPixel = firstCreative.imp_tracking[0]
        end if

        if firstCreative.error <> invalid AND firstCreative.error.Count() > 0
          content.errorPixel = firstCreative.error[0]
        end if
      end if

    end if

  end if

  return content
End Function