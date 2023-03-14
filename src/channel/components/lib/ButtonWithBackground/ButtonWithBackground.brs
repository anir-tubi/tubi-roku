Function init()
  m.constants = getConstantsFromGlobal()
  m.buttonBG = m.top.findNode("buttonBG")
  m.label = m.top.findNode("label")

  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("itemHasFocus", "onItemHasFocus")

  '//Make sure the colors are set properly, so call the onItemHasFocus() function
  onItemHasFocus()
End Function


Function onContentChange()
  if m.top.itemContent <> invalid
    m.label.text = m.top.itemContent.title
  end if
End Function


Function onItemHasFocus()
  theme = getThemeFromGlobal()
  if theme <> invalid
    if m.top.itemHasFocus = true
      m.buttonBG.blendcolor = theme.focusedColor
      m.label.color = theme.keyboardFocusedTextColor
    else if m.top.itemHasFocus = false
      m.buttonBG.blendcolor = theme.neutralColor3
      m.label.color = theme.primaryTextColor
    end if
  end if
End Function
