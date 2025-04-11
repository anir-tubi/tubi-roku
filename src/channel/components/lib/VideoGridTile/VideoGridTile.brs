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

  if m.videoGridMetadata.width = 0 AND m.top.width > 0
    m.videoGridMetadata.width = m.top.width
  end if

  if m.videoGridMetadata.height = 0 AND m.top.height > 0
    m.videoGridMetadata.height = m.top.height
  end if
End Function
