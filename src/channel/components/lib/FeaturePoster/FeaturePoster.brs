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
  ' NOTE: This is to account for ContentGrid saving VRAM by setting load* fields. Since we 
  ' hardcode m.Background.width and m.Background.height, we don't want ContentGrid to set
  ' the loadWidth/loadHeight values for us.
  if m.top.loadDisplayMode <> "noScale"
    m.Background.loadWidth = m.Background.width
    m.Background.loadHeight = m.Background.height
  else
    m.Background.loadWidth = 0.0
    m.Background.loadHeight = 0.0
  end if
  if m.top.itemContent <> invalid then
    if m.top.itemContent.landscape <> invalid then
      m.Background.uri = m.top.itemContent.landscape
    else
      m.Background.uri = m.top.itemContent.hdgridposterurl
    end if
    m.Title.text = m.top.itemContent.title
  end if
End Function
