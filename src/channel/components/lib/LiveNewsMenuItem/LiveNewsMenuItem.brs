Function init()
  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeField("itemHasFocus", "onFocusChange")
  m.Icon = m.top.findNode("Icon")
  m.MenuText = m.top.findNode("MenuText")
  m.Bground_active = m.top.findNode("Bground_active")
  onFocusChange()
End Function


Function onFocusChange()
  '//::TODO:: For a refactor, it might be interesting to adjust the opacity of m.Bground_active as the focus percent changes, so it is a smoother transition. Not sure how to tackle the text color change though.
  if m.top.itemHasFocus = true
    m.MenuText.color = "0x000000FF"
    m.Bground_active.visible = true
  else 
    m.MenuText.color = "0xFFFFFFFF"
    m.Bground_active.visible = false
  end if
End Function


Function onItemContentChange()
  tubiLog("LiveNewsMenuItem.onItemContentChange")
  if m.top.itemContent <> invalid then
    if m.top.itemContent.title <> invalid
      m.MenuText.text = m.top.itemContent.title
    end if
    if m.top.itemContent.inlineLogoUri <> invalid and m.top.itemContent.inlineLogoUri <> ""
      m.Icon.uri = m.top.itemContent.inlineLogoUri
    end if
  end if
End Function