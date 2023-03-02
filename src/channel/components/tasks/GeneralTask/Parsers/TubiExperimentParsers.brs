' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseTubiExperimentsNamespaceRequestSuccess(fullResponse, _reqInfo)
  experimentInfo = invalid
  data = fullResponse.data
  if isAA(data) = true AND data.namespace_results <> invalid
    experimentInfo = m.experiments.mapNamespaces(data.namespace_results)
  end if

  return experimentInfo
End Function
