Function init()
  m.poster = m.top.findNode("Poster")
  m.videoGridMetadata = m.top.findNode("videoGridMetadata")
  m.top.observeFieldScoped("itemContent", "onItemContentChange")
End Function

Function onItemContentChange(msg)
  itemContent = msg.getData()

  currentProgram = invalid
  if itemContent.type = "linear"
    currentProgram = getCurrentLiveProgram(itemContent)
  end if

  if currentProgram <> invalid
    if isNonEmptyString(currentProgram.hdgridposterurl) = true
      m.poster.uri = currentProgram.hdgridposterurl
    else if isNonEmptyString(currentProgram.landscape) = true
      m.poster.uri = currentProgram.landscape
    end if
  else if isNonEmptyString(itemContent.hdGridPosterUrl) = true
    m.poster.uri = itemContent.hdGridPosterUrl
  else if isNonEmptyString(itemContent.landscape) = true
    m.poster.uri = itemContent.landscape
  end if

  m.videoGridMetadata.itemContent = itemContent

  if m.videoGridMetadata.width = 0 AND m.top.width > 0
    m.videoGridMetadata.width = m.top.width
  end if

  if m.videoGridMetadata.height = 0 AND m.top.height > 0
    m.videoGridMetadata.height = m.top.height
  end if
End Function
