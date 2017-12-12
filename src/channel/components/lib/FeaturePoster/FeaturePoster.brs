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
  tubiLog("FeaturePoster.onContentChange")
  if m.top.itemContent <> invalid then
    if m.top.itemContent.landscape <> invalid then
      m.Background.uri = m.top.itemContent.landscape
    else
      m.Background.uri = m.top.itemContent.hdgridposterurl
    end if
    m.Title.text = m.top.itemContent.title
  end if
End Function
