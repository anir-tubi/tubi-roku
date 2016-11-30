Function init()
  m.focusedText = m.top.findNode("categoryFocusedText")
  m.unfocusedText = m.top.findNode("categoryUnfocusedText")
  m.categoryCountGroup = m.top.findNode("categoryCountGroup")
  m.categoryCountText = m.top.findNode("categoryCountText")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("listHasFocus", "onFocusChange")
  m.top.observeField("focusPercent", "onFocusChange")
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
  if m.top.listHasFocus and m.top.content.totalCount <> invalid and m.top.content.totalCount > 0 then
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
    end if
  end if
  onFocusChange()  ' to force a reset of the opacities
End Function
