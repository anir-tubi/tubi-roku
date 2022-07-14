' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseDetailScreenSingleContentSuccess(fullResponse, _reqInfo)
  translate = TubiMetadataTranslate(m.constants)
  parsedResponse = fullResponse.data
  updatedContent = CreateObject("roSGNode", "TubiContentNode")
  translate.translateRecursive(parsedResponse, updatedContent)
  return updatedContent
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseDetailScreenRelatedContentSuccess(fullResponse, reqInfo)
  translate = TubiMetadataTranslate(m.constants)
  parsedResponse = fullResponse.data
  relatedContent = translate.translateRelatedContent(parsedResponse)
  relatedContent.id = reqInfo.contentId
  return relatedContent
End Function


' Success making changes to the like/dislike settings
Function parseContentRateSuccess(_fullResponse, reqInfo)
  returnResponse = {}
  if reqInfo <> invalid and reqInfo.options <> invalid and reqInfo.options.body <> invalid
    returnResponse = reqInfo.options.body
  end if

  return returnResponse
End Function


' Error making changes to the like/dislike settings
Function parseContentRateError(fullResponse, reqInfo)
  returnParsed = {}
  if reqInfo <> invalid and reqInfo.options <> invalid and reqInfo.options.body <> invalid
    returnParsed = parseJSON(reqInfo.options.body)
  end if
  if fullResponse <> invalid and fullResponse.code <> invalid
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
