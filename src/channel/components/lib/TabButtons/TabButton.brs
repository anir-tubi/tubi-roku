Function init()
  m.tabLabelUnfocused = m.top.findNode("tabLabelUnfocused")
  m.tabLabelFocused = m.top.findNode("tabLabelFocused")


  m.top.observeFieldScoped("focusPercent", "onFocusPercentChange")
  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("gridHasFocus", "onGridHasFocus")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocus")

  m.typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.tabLabelUnfocused, m.typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.tabLabelFocused, m.typographyConstants.ids.bodyMediumStrong)


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
    m.tabLabelUnfocused.color = theme.primaryTextColor
    m.tabLabelFocused.color = theme.focusedTextColor
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()
  if itemContent <> invalid
    m.tabLabelUnfocused.text = itemContent.title
    m.tabLabelFocused.text = itemContent.title
  end if
End Function


Function onFocusPercentChange(msg)
  focusPercent = msg.getData()
  m.tabLabelUnfocused.opacity = 1 - focusPercent
  m.tabLabelFocused.opacity = focusPercent
End Function


Function onGridHasFocus(msg)
  gridHasFocus = msg.getData()
  if gridHasFocus = false
    m.tabLabelFocused.opacity = 0
    m.tabLabelUnfocused.opacity = 1
  end if
End Function


Function onItemHasFocus(msg)
  itemHasFocus = msg.getData()
  if itemHasFocus = true
    m.tabLabelFocused.opacity = 1
    m.tabLabelUnfocused.opacity = 0
  end if
End Function