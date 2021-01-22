' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseDetailScreenSingleContentSuccess(fullResponse, requestNode)
  translate = TubiMetadataTranslate(m.constants)
  parsedResponse = fullResponse.data
  updatedContent = CreateObject("roSGNode", "TubiContentNode")
  translate.translateRecursive(parsedResponse, updatedContent)
  return updatedContent
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseDetailScreenSingleContentError(fullResponse, requestNode)
  ' default code
  errCode = -1235
  
  if fullResponse <> invalid and fullResponse.code <> invalid
    ' HTTP or Curl code
    errCode = fullResponse.code
  end if

  deviceInfo = CreateObject("roDeviceInfo")
  if deviceInfo.GetLinkStatus() = false
    ' firmware thinks the device does not have internet access
    errCode = -1236
  end if

  return {
    code: errCode
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to Array already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseDetailScreenRelatedContentSuccess(fullResponse, requestNode)
  translate = TubiMetadataTranslate(m.constants)
  parsedResponse = fullResponse.data
  relatedContent = translate.translateRelatedContent(parsedResponse)
  relatedContent.id = requestNode.input.contentId
  return relatedContent
End Function
