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
    returnResponse = reqInfo.options.body
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
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseRemoveFromQueueSuccess(fullResponse, _reqInfo)
  return fullResponse.data
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseRemoveFromQueueError(fullResponse, _reqInfo)
  return {
    code: fullResponse.code
  }
End Function
