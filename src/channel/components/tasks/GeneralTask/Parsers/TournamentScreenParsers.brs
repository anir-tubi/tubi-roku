' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to Array already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseTournamentSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data

  isSignedInUser = false
  if reqInfo <> invalid
    isSignedInUser = reqInfo.isSignedInUser
  end if

  tournamentResponse = m.metadataTranslate.translateTournamentScreen(parsedResponse, reqInfo.requestorID, isSignedInUser)
  return tournamentResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseTournamentError(fullResponse, reqInfo)
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