' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseChannelGuideFetchSuccess(fullResponse, _reqInfo)
  experiments = TubiExperiments(m.constants)
  translate = TubiMetadataTranslate(m.constants, experiments)
  parsedResponse = fullResponse.data
  channelGuide = translate.translateLinearChannelGuide(parsedResponse)
  return channelGuide
End Function
