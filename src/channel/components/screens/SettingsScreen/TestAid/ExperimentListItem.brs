Function init() as Void
  topRef = m.top

  ' Cache node references
  m.label = topRef.findNode("label")
  m.labelFocused = topRef.findNode("labelFocused")
  m.subtitle = topRef.findNode("subtitle")
  m.subtitleFocused = topRef.findNode("subtitleFocused")
  m.background = topRef.findNode("background")
  m.textContainer = topRef.findNode("textContainer")

  m.labelFocused.opacity = 0
  m.subtitleFocused.opacity = 0

  ' Set up observers
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("width", "onWidthChange")
  topRef.observeFieldScoped("gridHasFocus", "onGridHasFocusChange")
  topRef.observeFieldScoped("focusPercent", "onFocusPercentChange")

  ' Set typography once
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodySmallStrong)
  m.labelFocused.font = m.label.font
  setTypographyOfLabel(m.subtitle, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.subtitleFocused, typographyConstants.ids.bodyExtraSmall)

  ' Set up theme observer and apply initial theme
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.unfocusedThemeColor = theme.primaryTextColor
    m.focusedBgColor = "0xFFFF00FF"
    applyStyling()
  end if
End Function


Function onItemContentChange(msg) as Void
  itemContent = msg.getData()
  if itemContent <> invalid then
    m.label.text = itemContent.title
    m.labelFocused.text = itemContent.title
    m.subtitle.text = itemContent.layerId
    m.subtitleFocused.text = itemContent.layerId
  end if
End Function


Function onWidthChange(msg) as Void
  width = msg.getData()
  labelWidth = width - 40
  m.label.width = labelWidth
  m.labelFocused.maxWidth = labelWidth
  m.background.width = width
End Function


Function onFocusPercentChange(msg) as Void
  hasFocus = m.top.gridHasFocus

  if hasFocus = true
    focusPercent = msg.getData()
    ' Show yellow background and black text when focused
    m.background.opacity = focusPercent
    m.label.opacity = 1 - focusPercent
    m.labelFocused.opacity = focusPercent
    m.subtitle.opacity = 1 - focusPercent
    m.subtitleFocused.opacity = focusPercent
  else
    m.background.opacity = 0
    m.label.opacity = 1
    m.labelFocused.opacity = 0
    m.subtitle.opacity = 1
    m.subtitleFocused.opacity = 0
  end if
End Function


Function onGridHasFocusChange(_msg) as Void
  hasFocus = m.top.gridHasFocus

  if hasFocus = true AND m.top.itemHasFocus = true
    m.background.opacity = 1
    m.label.opacity = 0
    m.labelFocused.opacity = 1
    m.subtitle.opacity = 0
    m.subtitleFocused.opacity = 1
  else
    m.background.opacity = 0
    m.label.opacity = 1
    m.labelFocused.opacity = 0
    m.subtitle.opacity = 1
    m.subtitleFocused.opacity = 0
  end if
End Function


Function applyStyling() as Void
  m.label.color = m.unfocusedThemeColor
  m.labelFocused.color = "0x000000FF" ' Black text on yellow background
  m.subtitle.color = m.unfocusedThemeColor
  m.subtitleFocused.color = "0x000000FF" ' Black text on yellow background
End Function

