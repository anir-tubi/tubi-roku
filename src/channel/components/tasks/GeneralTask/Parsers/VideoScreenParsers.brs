Function parseVideoScreenSpritesSuccess(parsedResponse)
  spritesContentNode = invalid
  if parsedResponse <> invalid then
    spritesContentNode = CreateObject("roSGNode", "TubiContentNode")
    spritesContentNode.id = parsedResponse.id
    spritesContentNode.thumbnailUrls = parsedResponse.sprites
    spritesContentNode.thumbnailSpan = parsedResponse.count_per_sprite
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
