' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseEPGChannelIdsSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data
  epgChannelIdsResponse = m.metadataTranslate.translateEPGChannelIds(parsedResponse, reqInfo.requestorID, reqInfo.isSignedInUser)
  return epgChannelIdsResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseEPGChannelIdsError(fullResponse, reqInfo)
  return {
    code: getErrorCodeFromResponse(fullResponse)
    requestorID: reqInfo.requestorID
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to Array already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseEPGProgramsSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data

  isSignedInUser = false
  if reqInfo <> invalid
    isSignedInUser = reqInfo.isSignedInUser
  end if

  epgProgramsResponse = m.metadataTranslate.translateEPGPrograms(parsedResponse, reqInfo.requestorID, isSignedInUser)
  return epgProgramsResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseEPGProgramsError(fullResponse, reqInfo)
  contentId = ""
  if reqInfo.options <> invalid AND reqInfo.options.params <> invalid
    contentId = reqInfo.options.params.content_id
  end if
  return {
    code: getErrorCodeFromResponse(fullResponse)
    requestorID: reqInfo.requestorID
    contentID: contentId
  }
End Function
