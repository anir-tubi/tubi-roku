Function init()
  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("focusPercent", "onFocusPercentChange")
  m.enabledIcon = m.top.findNode("EnabledIcon")
  m.unfocusedEnabledIcon = m.top.findNode("unfocusedEnabledIcon")
  m.menuText = m.top.findNode("MenuText")
  m.unFocusedMenuText = m.top.findNode("unFocusedMenuText")
  m.bground = m.top.findNode("Bground")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.MenuText, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.unFocusedMenuText, typographyConstants.ids.bodySmallStrong)

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
    m.bground.blendColor = theme.neutralColor2
    m.menuText.color = theme.focusedTextColor
    m.unFocusedMenuText.color = theme.unFocusedColor
    m.enabledIcon.blendColor = theme.focusedTextColor
    m.unfocusedEnabledIcon.blendColor = theme.unFocusedColor
  end if
End Function


Function onItemContentChange(msg)
  tubiLog("LinearTVCaptioningMenuItem.onItemContentChange")
  item = msg.getData()
  if item <> invalid then

    if item.language_label <> invalid
      m.menuText.text = item.language_label
      m.unFocusedMenuText.text = item.language_label
    end if

    if item.enabled <> invalid
      m.enabledIcon.visible = item.enabled
      m.unfocusedEnabledIcon.visible = item.enabled
    end if
  end if

End Function


Function onFocusPercentChange(msg)
  ' change the text colors and bg as soon as focus changes for smooth transitions.
  focusPercent = msg.getData()

  'show the background with off white color for unfocused item.
  'For focused item, hide the background to avoid focused color mixing with background color.
  m.bground.opacity = 1 - focusPercent
  m.menuText.opacity = focusPercent
  m.enabledIcon.opacity = focusPercent
  m.unfocusedEnabledIcon.opacity = 1 - focusPercent
End Function