Function init()
  m.poster = m.top.findNode("Poster")
  m.top.observeFieldScoped("itemContent", "onItemContentChange")
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  currentProgram = invalid
  if itemContent.type = "linear"
    currentProgram = getCurrentLiveProgram(itemContent)
  end if
  if currentProgram <> invalid
    if isNonEmptyString(currentProgram.hdGridPosterUrl) = true
      m.poster.uri = currentProgram.hdGridPosterUrl
    else if isNonEmptyString(currentProgram.portrait) = true
      m.poster.uri = currentProgram.portrait
    end if
  else if isNonEmptyString(itemContent.hdGridPosterUrl) = true
    m.poster.uri = itemContent.hdGridPosterUrl
  else if isNonEmptyString(itemContent.portrait) = true
    m.poster.uri = itemContent.portrait
  end if
End Function
