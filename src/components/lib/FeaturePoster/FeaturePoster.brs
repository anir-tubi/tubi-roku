Function init()
  m.Background = m.top.findNode("Background")
  m.Title = m.top.findNode("Title")
  m.top.observeField("itemContent", "onContentChange")
  ' this is so we can enlarge the Shade but not overhang our rect
  m.top.clippingRect = [0.0, 0.0, 456.0, 295.0]
End Function


''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange()
  print "FeaturePoster.onContentChange"
  if m.top.itemContent.landscape <> invalid then
    m.Background.uri = m.top.itemContent.landscape
  else
    m.Background.uri = m.top.itemContent.hdgridposterurl
  end if
  m.Title.text = m.top.itemContent.title
End Function
