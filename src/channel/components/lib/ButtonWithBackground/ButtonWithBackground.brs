Function init()
  m.constants = getConstantsFromGlobal()
  m.buttonBG = m.top.findNode("buttonBG")
  m.label = m.top.findNode("label")
  if m.constants.deviceInfo.scaledUi = true
    m.buttonBG.uri = "pkg:/images/menu-focus-hd.9.png"
  end if
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
  if m.top.itemHasFocus = true
    m.buttonBG.blendcolor = m.constants.ui.colors.focused
  else if m.top.itemHasFocus = false
    m.buttonBG.blendcolor = m.constants.ui.colors.neutralColor3
  end if
End Function
