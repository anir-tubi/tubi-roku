' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_requestedNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseChannelGuideFetchSuccess(fullResponse, _requestNode)
  experiments = TubiExperiments(m.constants)
  translate = TubiMetadataTranslate(m.constants, experiments)
  parsedResponse = fullResponse.data
  channelGuide = translate.translateLinearChannelGuide(parsedResponse)
  return channelGuide
End Function
