Function init()
  m.label = m.top.findNode("categoryText")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("listHasFocus", "onFocusChange")
  m.top.observeField("focusPercent", "onFocusChange")
  m.top.width = 440
  m.top.height = 80
  m.top.color = m.global.constants.ui.colors.transparent
End Function


''''''''''''''''''''
' onFocusChange
'
' Either list or item focus has changed
Function onFocusChange()
  if m.top.listHasFocus then
    ' all text is white when there is a focus image
    m.label.color = m.global.constants.ui.colors.unfocused
  else 
    if m.top.focusPercent = 1.0 then
      ' text color changes to indicate focused item when list is not focused
      m.label.color = m.global.constants.ui.colors.focused
    else
      m.label.color = m.global.constants.ui.colors.unfocused
    end if
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
