Function init()
  tubiLog("ContentGridItem.init")
  m.poster = m.top.findNode("Poster")
  m.top.observeField("itemContent", "onContentChange")
  m.poster.observeField("loadStatus", "onLoadStatusChange")
  m.loadTimer = CreateObject("roTimespan")
  m.delayTimer = CreateObject("roTimespan")
End Function


'''''''''''''''''''
' onContentChange
'
' Update the poster uri on content change, or use a 
' default image if content is not valid.
Function onContentChange()
  tubiLog("ContentGridItem.onContentChange")
  if m.top.itemContent <> invalid and m.top.itemContent.portrait <> invalid then
    m.poster.uri = m.top.itemContent.portrait
    m.delayTimer.Mark()
  else
    m.poster.uri = "pkg:/images/placeholder.png"
  end if
End Function

Function onLoadStatusChange()
  if m.poster.loadStatus = "loading" then 
    m.loadTimer.Mark()
    'print "Poster load delayed by " + stri(m.delayTimer.TotalMilliseconds()) + "ms"
  end if
  if m.poster.loadStatus = "ready" then
    'print "Poster loaded in " + stri(m.loadTimer.TotalMilliseconds()) + "ms"
  end if
  if m.poster.loadStatus = "failed" then m.top.content = m.top.content
End Function