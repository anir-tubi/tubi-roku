Function init()
  m.icon = m.top.findNode("menuItemIcon")
  m.iconFocused = m.top.findNode("menuItemIconFocused")
  m.bottomItemText = m.top.findNode("bottomItemText")

  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("gridHasFocus", "onGridHasFocus")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocus")
  m.top.observeFieldScoped("focusPercent", "onFocusPercentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.bottomItemText, typographyConstants.ids.bodySmallStrong)

  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.icon.blendcolor = theme.primaryTextColor
    m.iconFocused.blendcolor = theme.focusedTextColor
    m.bottomItemText.color = theme.focusedColor
  end if

End Function


Function onItemContentChange(msg)
  tubiLog("IconWithLabel.onItemContentChange")
  itemContent = msg.getData()

  if itemContent <> invalid then
    m.bottomItemText.text = itemContent.title
    m.icon.uri = itemContent.HDPosterUrl
    m.iconFocused.uri = itemContent.HDPosterUrl
  end if
End Function


Function onItemHasFocus()
  m.bottomItemText.visible = m.top.itemHasFocus
End Function


Function onGridHasFocus(msg)
  gridHasFocus = msg.getData()
  if m.top.itemContent <> invalid
    if gridHasFocus = true AND m.top.itemHasFocus = true
      m.iconFocused.opacity = 1.0
      m.icon.opacity = 0
    else
      m.iconFocused.opacity = 0
      m.icon.opacity = 1.0
    end if
  end if
End Function


Function onFocusPercentChange(msg)
  focusPercent = msg.getData()
  if m.top.gridHasFocus = true
    m.icon.opacity = 1 - focusPercent
    m.iconFocused.opacity = focusPercent
  else
    m.iconFocused.opacity = 0
    m.icon.opacity = 1.0
  end if
End Function
