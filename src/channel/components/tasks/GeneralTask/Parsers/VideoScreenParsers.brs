' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseVideoScreenSpritesSuccess(fullResponse, requestNode)
  parsedResponse = fullResponse.data
  spritesContentNode = invalid
  if parsedResponse <> invalid then
    spritesContentNode = CreateObject("roSGNode", "TubiContentNode")
    spritesContentNode.id = parsedResponse.id
    spritesContentNode.thumbnailUrls = parsedResponse.sprites
    spritesContentNode.thumbnailSpan = parsedResponse.count_per_sprite
    if parsedResponse.rows <> invalid
      spritesContentNode.thumbnailRows = parsedResponse.rows
    end if
    if parsedResponse.columns <> invalid
      spritesContentNode.thumbnailColumns = parsedResponse.columns
    end if
    spritesContentNode.thumbnailSize = [parsedResponse.frame_width, parsedResponse.height]
  end if

  return spritesContentNode
End Function

   
' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseVideoScreenUpNextSuccess(fullResponse, requestNode)
  parsedResponse = fullResponse.data
  translate = TubiMetadataTranslate(m.constants)
  upNextContent = CreateObject("roSGNode", "ContentNode")
  for each content in parsedResponse
    upNextItem = upNextContent.createChild("TubiContentNode")
    translate.translateRecursive(content, upNextItem)
  end for
  return upNextContent
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseLiveVideoManifestSuccess(fullResponse, requestNode)
  return {
    res: fullResponse.data
    headers: fullResponse.headers
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseHistorySuccess(fullResponse, requestNode)
  return {
    parsedResponse: fullResponse.data
  }
End Function
