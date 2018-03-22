Function init()
  m.categoryText = m.top.findNode("categoryText")
  m.categoryCountGroup = m.top.findNode("categoryCountGroup")
  m.categoryCountText = m.top.findNode("categoryCountText")
  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeField("listHasFocus", "onFocusChange")
  m.top.observeField("focusPercent", "onFocusChange")
End Function

''''''''''''''''''''
' onFocusChange
'
' Either list or item focus has changed
Function onFocusChange()
  if m.top.listHasFocus and m.top.itemContent.totalCount <> invalid and m.top.itemContent.totalCount > 0 then
    ' while the focus box is sliding, it looks funny to have this group be visible too early.
    ' slow it down by not doing linear fade
    if m.top.focusPercent > 0.75
      m.categoryCountGroup.opacity = m.top.focusPercent^3
    else
      m.categoryCountGroup.opacity = 0.0
    end if
  else
    m.categoryCountGroup.opacity = 0.0
  end if
End Function


''''''''''''''''''''
' onItemContentChange
'
' Set the label text on receiving the category name
Function onItemContentChange()
  tubiLog("CategoryListItem.onItemContentChange")
  if m.top.itemContent <> invalid then
    m.categoryText.text = m.top.itemContent.title
    if m.top.itemContent.totalCount <> invalid and m.top.itemContent.totalCount > 0 then
      m.categoryCountText.text = stri(m.top.itemContent.totalCount)
    end if
  end if
  onFocusChange()  ' to force a reset of the opacities
End Function
