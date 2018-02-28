Function init()
  tubiLog("UpNextPoster.init")
  m.top.observeField("currRect", "onRectChange")
  m.top.observeField("itemContent", "onContentChange")
  m.Poster = m.top.findNode("Poster")
End Function

Function onRectChange()
  m.Poster.width = m.top.currRect.width
  m.Poster.height = m.top.currRect.height
End Function

Function onContentChange()
  tubiLog("UpNextPoster.onContentChange")
  if m.top.itemContent <> invalid then
    ' If series content, we show a 16:9 poster, otherwise a DVD-aspect poster
    if m.top.itemContent.seriesId <> invalid and m.top.itemContent.seriesId <> ""
      m.Poster.uri = m.top.itemContent.landscape
    else
      m.Poster.uri = m.top.itemContent.hdgridposterurl
    end if
  end if
End Function