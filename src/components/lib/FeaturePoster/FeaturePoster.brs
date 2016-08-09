Function init()
  m.Background = m.top.findNode("Background")
  m.Title = m.top.findNode("Title")
  m.top.observeField("itemContent", "onContentChange")
End Function


''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange()
  print "FeaturePoster.onContentChange"
  m.Background.uri = m.top.itemContent.hdgridposterurl
  m.Title.text = m.top.itemContent.title
End Function