Function init()
  m.label = m.top.findNode("categoryText")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("listHasFocus", "onListFocusChange")
  m.top.width = 440
  m.top.height = 80
  m.top.color = m.global.constants.ui.colors.transparent
End Function


''''''''''''''''''''
' onListFocusChange
'
Function onListFocusChange()
  if m.top.listHasFocus then
    m.label.color = m.global.constants.ui.colors.unfocused
  else if m.top.focusPercent = 1.0 then
    m.label.color = m.global.constants.ui.colors.focused
  end if
End Function


''''''''''''''''''''
' onContentChange
'
' Set the label text on receiving the category name
Function onContentChange()
  tubiLog("CategoryListItem.onContentChange")
  m.label.text = m.top.content.title
End Function
