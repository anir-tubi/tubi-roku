' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseDetailScreenSingleContentSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data
  updatedContent = CreateObject("roSGNode", "TubiContentNode")
  m.metadataTranslate.translateRecursive(parsedResponse, updatedContent, reqInfo.issignedinuser)
  return updatedContent
End Function


' Remove once we figure out the root cause of series invalid for component interaction events.
' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseDetailScreenSingleContentError(fullResponse, reqInfo)
  returnResponse = {}
  if reqInfo <> invalid AND reqInfo.options <> invalid AND reqInfo.options.params <> invalid
    returnResponse.contentId = reqInfo.options.params.content_id
  end if

  if fullResponse <> invalid AND fullResponse.code <> invalid
    returnResponse.code = fullResponse.code
  end if

  return returnResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseDetailScreenRelatedContentSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data
  relatedContent = m.metadataTranslate.translateRelatedContent(parsedResponse, reqInfo.issignedinuser)
  relatedContent.id = reqInfo.contentId
  return relatedContent
End Function


' Success making changes to the like/dislike settings
Function parseContentRateSuccess(_fullResponse, reqInfo)
  returnResponse = {}
  if reqInfo <> invalid AND reqInfo.options <> invalid AND reqInfo.options.body <> invalid
    returnResponse = parseJSON(reqInfo.options.body)
  end if

  return returnResponse
End Function


' Error making changes to the like/dislike settings
Function parseContentRateError(fullResponse, reqInfo)
  returnParsed = {}
  if reqInfo <> invalid AND reqInfo.options <> invalid AND reqInfo.options.body <> invalid
    returnParsed = parseJSON(reqInfo.options.body)
  end if
  if fullResponse <> invalid AND fullResponse.code <> invalid
    returnParsed.code = fullResponse.code
  end if

  return returnParsed
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseDeleteFromHistorySuccess(_fullResponse, _reqInfo)
  return true
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseDeleteFromHistoryError(fullResponse, _reqInfo)
  return {
    code: fullResponse.code
  }
End Function



' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseAddToQueueSuccess(fullResponse, _reqInfo)
  return fullResponse.data
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseAddToQueueError(fullResponse, _reqInfo)
  return {
    code: fullResponse.code
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseRemoveFromQueueSuccess(fullResponse, reqInfo)
  return reqInfo.options.params
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseRemoveFromQueueError(fullResponse, _reqInfo)
  return {
    code: fullResponse.code
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseEpgListingSuccess(fullResponse, _reqInfo)
  return m.metadataTranslate.parseScheduleData(fullResponse.data)
End Function


' Parses season list response from series episodes API
' Transforms episodes_by_season array format into a more usable associative array
' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseSeasonListSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data

  returnObj = {
    seriesId: reqInfo.options.seriesId
    isRecurring: parsedResponse.is_recurring
    seasons: {}
    episodeSeasonMap: {}
    ' Contains the content node for season selector.
    seasonSelectorContent: invalid
  }

  seasonLabel = reqInfo.seasonLabel

  ' Transform episodes_by_season from array format to episodeId: episodeNum format
  if parsedResponse <> invalid AND parsedResponse.episodes_by_season <> invalid
    seasonSelectorContent = CreateObject("roSGNode", "ContentNode")
    episodesBySeason = parsedResponse.episodes_by_season
    seasonNumbers = []
    for each item in episodesBySeason
      seasonNum = item.season.toStr()
      episodesBySeasonArray = item.episodes
      episodes = []

      if isNonEmptyArray(episodesBySeasonArray)
        for each episode in episodesBySeasonArray
          if episode.id <> invalid AND episode.num <> invalid
            ' Create map with episodeId as key and episode number as value
            episodes.push({
              id: episode.id
              num: episode.num
            })
            returnObj.episodeSeasonMap[episode.id.toStr()] = {
              seasonNum: seasonNum
              episodeNum: episode.num
            }
          end if
        end for
      end if
      seasonNumbers.push({
        id: "season_" + seasonNum
        title: seasonLabel.replace("{seasonNumber}", seasonNum)
        seasonNumber: seasonNum
      })

      returnObj.seasons[seasonNum] = episodes
    end for
    seasonSelectorContent.update({
      children: [{
        type: "ContentNode"
        children: seasonNumbers
      }]
    }, true)
    returnObj.seasonSelectorContent = seasonSelectorContent
  end if

  return returnObj
End Function


' Parses series episodes by season response
' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseSeriesEpisodesBySeasonSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data
  seasonNode = CreateObject("roSGNode", "ContentNode")
  if reqInfo.options <> invalid AND reqInfo.options.params <> invalid AND reqInfo.options.params.content_id <> invalid
    params = reqInfo.options.params
    seasonNode.id = params.content_id
    seasonNode.titleSeason = params["pagination[season]"].toStr()
  end if

  episodesNode = CreateObject("roSGNode", "TubiContentNode")
  m.metadataTranslate.translateRecursive(parsedResponse, episodesNode, reqInfo.isSignedInUser)
  children = episodesNode.getChild(0).getChildren(-1, 0)
  seasonNode.appendChildren(children)

  content = episodesNode.getFields()
  if content <> invalid
    content.delete("change")
    content.delete("focusedChild")
  end if
  return {
    "seasonNode": seasonNode
    "content": content
  }
End Function