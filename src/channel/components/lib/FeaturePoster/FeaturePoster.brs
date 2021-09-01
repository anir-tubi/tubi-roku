Function init()
  m.Background = m.top.findNode("Background")
  m.Title = m.top.findNode("Title")
  if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
    m.Title.translation = [0,237]
  end if
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("width", "onWidthChange")
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


Function onWidthChange()
  m.Title.width = m.top.width - 20
End Function
