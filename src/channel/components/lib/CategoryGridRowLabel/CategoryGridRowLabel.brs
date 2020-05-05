Function init()
  tubiLog("CategoryGridRowLabel.init")
  m.ItemCount = m.top.findNode("ItemCount")
  m.FocusIndex = m.top.findNode("FocusIndex")
  m.CategoryName = m.top.findNode("CategoryName")
  m.top.observeField("content", "onContentChange")
  m.FocusIndex.color = m.global.theme.focused
  m.global.observeField("theme", "onThemeChange")
End Function

Function onThemeChange()
  m.FocusIndex.color = m.global.theme.focused
End Function

Function onContentChange()
  tubiLog("CategoryGridRowLabel.onContentChange")
  if m.top.content <> invalid then
    m.CategoryName.text = m.top.content.title
    drawItemCount()
  end if
End Function

Function drawItemCount()
  cursorIndex = m.top.content.focusIndex
  if cursorIndex = invalid or cursorIndex = -1 then
    cursorIndex = 0
  end if
  if m.top.content.getChildCount() > 0
    m.ItemCount.text = " " + Chr(&hb7) + " " + stri(m.top.content.getChildCount()).trim()
    m.FocusIndex.text = stri(cursorIndex + 1).trim()
  else 
    ' It's odd to see '0 of 0' so we hide the counter
    m.ItemCount.text = ""
    m.FocusIndex.text = ""
  endif
End Function