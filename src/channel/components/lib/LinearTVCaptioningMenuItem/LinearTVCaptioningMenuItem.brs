Function init()
  m.top.observeField("itemContent", "onItemContentChange")
  m.EnabledIcon = m.top.findNode("EnabledIcon")
  m.MenuText = m.top.findNode("MenuText")
  m.Bground = m.top.findNode("Bground")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.MenuText, typographyConstants.ids.bodySmallStrong)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.Bground.blendColor = theme.neutralColor
    m.MenuText.color = theme.primaryTextColor
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