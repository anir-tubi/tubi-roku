Function init()
  m.top.observeField("itemContent", "onItemContentChange")
  m.EnabledIcon = m.top.findNode("EnabledIcon")
  m.MenuText = m.top.findNode("MenuText")
  m.Bground = m.top.findNode("Bground")

  if m.global.constants.deviceInfo.scaledUi = true
    m.Bground.uri = "pkg://images/menu-focus-hd.9.png"
  end if
End Function


Function onItemContentChange()
  tubiLog("LinearTVCaptioningMenuItem.onItemContentChange")
  if m.top.itemContent <> invalid then
    if m.top.itemContent.isForeground = true
      if m.top.itemContent.title <> invalid
        m.MenuText.text = m.top.itemContent.language_label
      end if
      if m.top.itemContent.enabled <> invalid
        m.EnabledIcon.visible = m.top.itemContent.enabled
      end if
    else
      m.Bground.visible = true
      m.MenuText.visible = false
      m.EnabledIcon.visible = false
    end if
  end if
End Function