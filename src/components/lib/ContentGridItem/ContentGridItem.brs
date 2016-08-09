Function init()
  print "ContentGridItem.init"
  m.poster = m.top.findNode("Poster")
  m.top.observeField("itemContent", "onContentChange")
End Function


'''''''''''''''''''
' onContentChange
'
' Update the poster uri on content change, or use a 
' default image if content is not valid.
Function onContentChange()
  print "ContentGridItem.onContentChange"
  if m.top.itemContent <> invalid and m.top.itemContent.portrait <> invalid then
    m.poster.uri = m.top.itemContent.portrait
  else
    m.poster.uri = "pkg:/images/placeholder.png"
  end if
End Function
