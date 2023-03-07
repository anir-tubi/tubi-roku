Function init()
  tubiLog("SignInPoster.init")
  m.top.observeField("itemContent", "onContentChange")
  m.Icon = m.top.findNode("Icon")
  m.ToolText = m.top.findNode("ToolText")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if
  
  if theme <> invalid
    m.ToolText.color = theme.primaryTextColor
  end if
End Function


Function onContentChange()
  tubiLog("SignInPoster.onContentChange")
  if m.top.itemContent <> invalid then
    m.ToolText.text = m.top.itemContent.title
    m.Icon.uri = m.top.itemContent.hdgridposterurl
  end if
End Function