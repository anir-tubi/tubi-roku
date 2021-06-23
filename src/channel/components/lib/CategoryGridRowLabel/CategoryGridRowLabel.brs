Function init()
  tubiLog("CategoryGridRowLabel.init")
  m.ItemCount = m.top.findNode("ItemCount")
  m.FocusIndex = m.top.findNode("FocusIndex")
  m.CategoryName = m.top.findNode("CategoryName")
  m.CategoryCount = m.top.findNode("CategoryCount")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("currentIndex", "onIndexChange")

  ' trying to access m.global can sometimes/rarely time out creating a run time error if we
  ' try to access m.global.theme directly, so use GlobalMixin.getThemeFromGlobal() which retries if issues arise.
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.FocusIndex.color = theme.focused
  end if

  if m.global <> invalid
    m.global.observeField("theme", "onThemeChange")
  end if
End Function

Function onThemeChange()
  m.FocusIndex.color = m.global.theme.focused
End Function

Function onContentChange()
  tubiLog("CategoryGridRowLabel.onContentChange")
  if m.top.content <> invalid then
    m.CategoryName.text = m.top.content.title
    drawItemCount()
    if m.top.content.gridItemType = "linear" or m.top.content.gridItemType = "continue_watching_signed_Out_User"
      m.CategoryCount.visible = false
    else 
      m.CategoryCount.visible = true
    end if
  end if
End Function

Function drawItemCount()
  cursorIndex = m.top.content.focusIndex
  if cursorIndex = invalid or cursorIndex = -1 then
    cursorIndex = 0
  end if
  ' show rowcounter except for utility rows
  if m.top.content.getChildCount() > 0 and m.top.content.gridItemType <> "utility"
    m.ItemCount.text = " " + Chr(&hb7) + " " + stri(m.top.content.getChildCount()).trim()
    m.FocusIndex.text = stri(cursorIndex + 1).trim()
  else 
    ' It's odd to see '0 of 0' so we hide the counter
    m.ItemCount.text = ""
    m.FocusIndex.text = ""
  endif
End Function


Function onIndexChange(msg)
  tubiLog("CategoryGridRowLabel.onIndexChange")
  focusIndex = msg.GetData()
  if focusIndex >= 0
    m.FocusIndex.text = stri(focusIndex + 1).trim()
  end if
End Function