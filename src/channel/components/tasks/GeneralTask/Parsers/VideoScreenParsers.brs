Function parseVideoScreenSpritesSuccess(parsedResponse)
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


Function parseVideoScreenUpNextSuccess(parsedResponse)
  translate = TubiMetadataTranslate(m.constants)
  upNextContent = CreateObject("roSGNode", "ContentNode")
  for each content in parsedResponse
    upNextItem = upNextContent.createChild("TubiContentNode")
    translate.translateRecursive(content, upNextItem)
  end for
  return upNextContent
End Function


Function parseVideoScreenUpNextError(parsedResponse)
  return parsedResponse
End Function


Function parseLiveVideoManifestSuccess(stringResponse)
  return stringResponse
End Function

Function parseLiveVideoManifestError(stringResponse)
  return stringResponse
End Function
