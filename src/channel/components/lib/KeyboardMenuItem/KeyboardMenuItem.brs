Function init()
  tubiLog("KeyboardMenuItem.init")
  m.top.observeField("itemContent", "onContentChange")
  constants = m.global.constants
  m.focusColor = constants.ui.colors.primaryText
  m.highlightColor = constants.ui.colors.highlightedText
  m.top.color = m.focusColor
  m.top.observeField("gridHasFocus", "onFocusChange")
  m.top.observeField("focusPercent", "onFocusChange")
  m.top.vertAlign = "center"
  m.top.horizAlign = "center"
End Function

Function onFocusChange()
  if m.top.focusPercent = 1 and not m.top.gridHasFocus
    m.top.color = m.highlightColor
  else
    m.top.color = m.focusColor
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