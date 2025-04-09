Function init()
  m.poster = m.top.findNode("Poster")
  m.videoGridMetadata = m.top.findNode("videoGridMetadata")
  m.top.observeFieldScoped("itemContent", "onItemContentChange")
End Function

Function onItemContentChange(msg)
  itemContent = msg.getData()
  if isNonEmptyString(itemContent.hdGridPosterUrl) = true
    m.poster.uri = itemContent.hdGridPosterUrl
  end if
  m.videoGridMetadata.itemContent = itemContent
End Function
