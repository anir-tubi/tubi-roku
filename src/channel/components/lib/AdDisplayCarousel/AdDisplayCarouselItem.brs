Function init()
  tubiLog("AdDisplayCarouselItem.init")
  m.top.observeField("itemContent", "onContentChange")
  m.poster = m.top.findNode("Poster")
End Function

Function onContentChange()
  tubiLog("AdDisplayCarouselItem.onContentChange")
  item = m.top.itemContent
  if item <> invalid then
    m.poster.uri = item.hdgridposterurl
  end if
End Function