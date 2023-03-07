Function init()
  tubiLog("KeyboardMenuItem.init")
  m.top.observeField("itemContent", "onContentChange")
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.top.color = theme.primaryTextColor
  end if
  m.top.observeField("gridHasFocus", "onFocusChange")
  m.top.observeField("focusPercent", "onFocusChange")
  m.top.vertAlign = "center"
  m.top.horizAlign = "center"
End Function

Function onFocusChange()
  theme = getThemeFromGlobal()
  if theme <> invalid
    if m.top.focusPercent = 1 and not m.top.gridHasFocus
      m.top.color = theme.highlightedTextColor
    else
      m.top.color = theme.focusColor
    end if
  end if
End Function

''''''''''''''''''''
' onContentChange
'
' Set the label text
Function onContentChange()
  tubiLog("KeyboardMenuItem.onContentChange")
  if m.top.itemContent <> invalid and m.top.itemContent.title <> invalid then
    m.top.text = m.top.itemContent.title
  else
    m.top.text = ""
  end if
End Function