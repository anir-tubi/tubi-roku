Function init()
  m.top.observeField("content", "onContentChange")
  m.FocusedIcon = m.top.findNode("FocusedIcon")
  m.UnfocusedIcon = m.top.findNode("UnfocusedIcon")
  m.FocusedText = m.top.findNode("FocusedText")
  m.UnfocusedText = m.top.findNode("UnfocusedText")
  m.Progress = m.top.findNode("ResumeProgressBar")
  ' Force a static size, which ScrollingList will pick up since it internal uses LayoutGroup for spacing
  m.top.width = 440
  m.top.height = 80
  m.top.color = m.global.constants.ui.colors.transparent
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
  tubiLog("DetailMenuItem.onContenChange")
  if m.top.content <> invalid then
    m.FocusedText.text = m.top.content.title
    m.UnfocusedText.text = m.top.content.title
    m.FocusedIcon.uri = m.top.content.focusIconUrl
    m.UnfocusedIcon.uri = m.top.content.unfocusIconUrl
    if m.top.content.playstart <> invalid and m.top.content.playstart <> 0.0 and m.top.content.length <> invalid and m.top.content.length <> 0.0 then
      showProgressBar(m.top.content.playstart / m.top.content.length)
    else
      m.Progress.visible = false
    end if
  end if
End Function

Function showProgressBar(percentage As Double)
  tubiLog("DetailMenuItem.showProgressBar")
  if percentage > 1.0 then percentage = 1.0
  if percentage < 0.0 then percentage = 0.0
  ' width of menu item is 440, 4 pixel margin for progress bar
  m.Progress.width = (m.top.width - 8.0) * percentage
  m.Progress.visible = true
End Function
