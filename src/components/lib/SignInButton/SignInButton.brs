Function init()
  m.focusedText = m.top.findNode("focusedText")
  m.unfocusedText = m.top.findNode("unfocusedText")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusPercent", "onFocusChange")
  m.top.observeField("listHasFocus", "onFocusChange")
  m.top.width = 480
  m.top.height = 80
  m.top.color = m.global.constants.ui.colors.transparent
  m.unfocusedText.color = m.global.constants.ui.colors.unfocused
  m.focusedText.color = m.global.constants.ui.colors.shade
End Function


''''''''''''''''''''
' onFocusChange
'
' Either list or item focus has changed
Function onFocusChange()
  if m.top.listHasFocus then
    m.focusedText.color = m.global.constants.ui.colors.shade
  else
    m.focusedText.color = m.global.constants.ui.colors.focused
  end if
  m.focusedText.opacity = m.top.focusPercent
  m.unfocusedText.opacity = 1.0 - m.top.focusPercent
End Function


''''''''''''''''''
' onContentChange
Function onContentChange()
  if m.top.content <> invalid then
    m.focusedText.text = m.top.content.title
    m.unfocusedText.text = m.top.content.title
  end if
End Function