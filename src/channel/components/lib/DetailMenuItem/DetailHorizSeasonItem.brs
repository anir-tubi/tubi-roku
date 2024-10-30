Function init()
  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("focusPercent", "onHandleFocus")
  m.top.observeFieldScoped("gridHasFocus", "onHandleFocus")
  m.top.observeFieldScoped("itemHasFocus", "onHandleFocus")

  m.titleFocused = m.top.findNode("MenuTextFocused")
  m.titleUnfocused = m.top.findNode("MenuTextUnfocused")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.titleFocused, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.titleUnfocused, typographyConstants.ids.bodySmallStrong)

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
    m.titleFocused.color = theme.primaryTextColor
    m.titleUnfocused.color = theme.backgroundcolor
  end if
End Function


Function onItemContentChange()

  if m.top.itemContent <> invalid
    item = m.top.itemContent
    padding = 36

    m.titleFocused.text = item.title
    m.titleUnfocused.text = item.title
    width = m.titleFocused.boundingRect().width
    m.top.calculatedTextWidth = padding + width + padding
  end if

End Function


Function onHandleFocus()
  focusPercent = m.top.focusPercent

  if focusPercent > 0.8 AND (m.top.gridHasFocus = true OR m.top.itemHasFocus = true)
    m.titleUnfocused.opacity = focusPercent
  else
    m.titleUnfocused.opacity = 0.0
  end if
End Function
