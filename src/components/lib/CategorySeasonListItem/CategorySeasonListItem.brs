Function init()
  m.focusedText = m.top.findNode("categoryFocusedText")
  m.unfocusedText = m.top.findNode("categoryUnfocusedText")
  m.categoryCountGroup = m.top.findNode("categoryCountGroup")
  m.categoryCountText = m.top.findNode("categoryCountText")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("listHasFocus", "onFocusChange")
  m.top.observeField("focusPercent", "onFocusChange")
  m.top.width = 440
  m.top.height = 80
  m.top.color = m.global.constants.ui.colors.transparent
  m.unfocusedText.color = m.global.constants.ui.colors.unfocused
  m.focusedText.color = m.global.constants.ui.colors.shade
  m.categoryCountText.color = m.global.constants.ui.colors.focused
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
  if m.top.content.totalCount <> invalid and m.top.content.totalCount > 0 then
    ' while the focus box is sliding, it looks funny to have this group be visible too early.
    ' slow it down by not doing linear fade
    m.categoryCountGroup.opacity = m.top.focusPercent^3
  else
    m.categoryCountGroup.opacity = 0.0
  end if
End Function


''''''''''''''''''''
' onContentChange
'
' Set the label text on receiving the category name
Function onContentChange()
  tubiLog("CategoryListItem.onContentChange")
  if m.top.content <> invalid then
    m.focusedText.text = m.top.content.title
    m.unfocusedText.text = m.top.content.title
    if m.top.content.totalCount <> invalid and m.top.content.totalCount > 0 then
      m.categoryCountText.text = stri(m.top.content.totalCount)
      m.categoryCountGroup.opacity = m.top.focusPercent^3  ' in case of category being focused before content was set
    end if
  end if
End Function
