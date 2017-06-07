Function init()
  tubiLog("SignInPoster.init")

  m.top.observeField("content", "onContentChange")
  m.FocusedIcon = m.top.findNode("FocusedIcon")
  m.UnfocusedIcon = m.top.findNode("UnfocusedIcon")
  m.FocusedText = m.top.findNode("FocusedText")
  m.UnfocusedText = m.top.findNode("UnfocusedText")
  m.FocusedText.color = m.global.constants.ui.colors.shade
  m.UnfocusedText.color = m.global.constants.ui.colors.unfocused
  m.top.observeField("focusPercent", "onFocusChange")
  m.top.observeField("listHasFocus", "onFocusChange")
End Function

Function onFocusChange()
  if m.top.listHasFocus then
    m.FocusedText.color = m.global.constants.ui.colors.shade
  else
    ' This case only applies to Search & Sign In menu where the menu doesn't have focus, we don't
    ' call attention to the focused menu item
    m.FocusedText.color = m.global.constants.ui.colors.unfocused
  end if
  m.FocusedText.opacity = m.top.focusPercent
  m.UnfocusedText.opacity = 1.0 - m.top.focusPercent
  m.FocusedIcon.opacity = m.top.focusPercent
  m.UnfocusedIcon.opacity = 1.0 - m.top.focusPercent
End Function

Function onContentChange()
  tubiLog("SignInPoster.onContentChange")
  if m.top.content <> invalid then
    m.FocusedText.text = m.top.content.title
    m.UnfocusedText.text = m.top.content.title
    m.FocusedIcon.uri = m.top.content.focusIconUrl
    m.UnfocusedIcon.uri = m.top.content.unfocusIconUrl
  end if
End Function