' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseCategoryDetailsSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data

  isSignedInUser = false
  if reqInfo <> invalid
    isSignedInUser = reqInfo.isSignedInUser
  end if

  convertedMetadata = m.metadataTranslate.translateCategoryDetails(parsedResponse, isSignedInUser)
  return convertedMetadata  'may return an empty container
End Function
