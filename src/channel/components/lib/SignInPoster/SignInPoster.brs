Function init()
  tubiLog("SignInPoster.init")
  m.top.observeField("itemContent", "onContentChange")
  m.Icon = m.top.findNode("Icon")
  m.ToolText = m.top.findNode("ToolText")
End Function

Function onContentChange()
  tubiLog("SignInPoster.onContentChange")
  if m.top.itemContent <> invalid then
    m.ToolText.text = m.top.itemContent.title
    m.Icon.uri = m.top.itemContent.hdgridposterurl
  end if
End Function