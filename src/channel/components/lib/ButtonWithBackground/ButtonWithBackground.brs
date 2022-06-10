Function init()
  m.constants = getConstantsFromGlobal()
  m.buttonBG = m.top.findNode("buttonBG")
  m.label = m.top.findNode("label")
  if m.constants.deviceInfo.scaledUi = true
    m.buttonBG.uri = "pkg:/images/menu-focus-hd.9.png"
  end if
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("itemHasFocus", "onItemHasFocus")
End Function


Function onContentChange()
  if m.top.itemContent <> invalid
    m.label.text = m.top.itemContent.title
  end if
End Function


Function onItemHasFocus()
  if m.top.itemHasFocus = true
    m.buttonBG.opacity = 1.0
    m.buttonBG.blendcolor = "0xFF501A"
  else if m.top.itemHasFocus = false
    m.buttonBG.opacity = 0.16
    m.buttonBG.blendcolor = "0x9699A3"
  end if
End Function
