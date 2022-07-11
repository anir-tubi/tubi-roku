' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseEPGChannelIdsSuccess(fullResponse, reqInfo)
  translate = TubiMetadataTranslate(m.constants)

  parsedResponse = fullResponse.data
  epgChannelIdsResponse = translate.translateEPGChannelIds(parsedResponse, reqInfo.requestorID)
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
  translate = TubiMetadataTranslate(m.constants)
  parsedResponse = fullResponse.data
  epgProgramsResponse = translate.translateEPGPrograms(parsedResponse, reqInfo.requestorID )
  return epgProgramsResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseEPGProgramsError(fullResponse, reqInfo)
  contentId = ""
  if reqInfo.options <> invalid and reqInfo.options.params <> invalid
    contentId = reqInfo.options.params.content_id
  end if
  return {
    code: getErrorCodeFromResponse(fullResponse)
    requestorID: reqInfo.requestorID
    contentID: contentId
  }
End Function
