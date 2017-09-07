Function init()
  tubiLog("SignInPoster.init")
  m.top.observeField("content", "onContentChange")
  m.FocusedIcon = m.top.findNode("FocusedIcon")
  m.UnfocusedIcon = m.top.findNode("UnfocusedIcon")
  m.ToolText = m.top.findNode("ToolText")
  m.top.observeField("focusPercent", "onFocusChange")
  m.top.observeField("listHasFocus", "onFocusChange")
End Function

Function onFocusChange(evt)
  if m.FocusedIcon.uri <> m.UnfocusedIcon.uri
    m.FocusedIcon.opacity = m.top.focusPercent
    m.UnfocusedIcon.opacity = 1.0 - m.top.focusPercent
  end if
  ' if, in the future, we want to change the color of the text here or maybe in the ToolsMenu.brs,
  ' we can use the color change animation from the animationMixin
End Function

Function onContentChange()
  tubiLog("SignInPoster.onContentChange")
  if m.top.content <> invalid then
    m.ToolText.text = m.top.content.title
    m.FocusedIcon.uri = m.top.content.focusIconUrl
    m.UnfocusedIcon.uri = m.top.content.unfocusIconUrl
  end if
End Function