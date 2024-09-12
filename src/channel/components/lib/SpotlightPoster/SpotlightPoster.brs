Function init()
  topRef = m.top
  m.poster = topRef.findNode("poster")
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("focusPercent", "updatePosterOpacity")
  topRef.observeFieldScoped("rowHasFocus", "updatePosterOpacity")
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    m.poster.uri = itemContent.hdGridPosterUrl
  end if
End Function


Function updatePosterOpacity()
  if m.top.rowHasFocus = false
    m.poster.opacity = 0.4
  else
    m.poster.opacity = 0.4 + m.top.focusPercent * 0.6
  end if
End Function
