Function init()
  topRef = m.top
  m.label = topRef.findNode("label")
  m.labelFocused = topRef.findNode("labelFocused")
  m.background = topRef.findNode("background")
  m.container = topRef.findNode("container")
  m.caret = topRef.findNode("caret")
  m.caretFocused = topRef.findNode("caretFocused")
  m.caretFocused.opacity = 0
  m.background.uri = "pkg:/images/menu-focus-$$RES$$.9.png"

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("height", "onHeightChange")
  topRef.observeFieldScoped("width", "onWidthChange")
  topRef.observeFieldScoped("listHasFocus", "onListHasFocusChange")
  topRef.observeFieldScoped("gridHasFocus", "onListHasFocusChange")
  topRef.observeFieldScoped("itemHasFocus", "onItemHasFocus")
  topRef.observeFieldScoped("focusPercent", "onFocusPercentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.labelFocused, typographyConstants.ids.bodySmallStrong)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  theme = getThemeFromGlobal()
  updateTheme(theme)
End Function


Function onThemeChange(msg)
  theme = msg.getData()
  updateTheme(theme)
End Function


Function updateTheme(theme)
  if theme <> invalid
    m.focusedThemeColor = theme.focusedTextColor
    m.unfocusedThemeColor = theme.primaryTextColor
    m.background.blendColor = theme.neutralSolidColor2
  end if
  applyStyling()
End Function


' Callback triggered when the itemContent field value changes.
Function onItemContentChange(msg)
  itemContent = msg.getData()
  if itemContent <> invalid then
    m.label.text = itemContent.title
    m.labelFocused.text = itemContent.title
    checked = itemContent.checked

    ' Setting the visibility of the check icon based on the checked value.
    hasSubmenu = itemContent.hasSubmenu
    m.caret.visible = (hasSubmenu = true)
    m.caretFocused.visible = (hasSubmenu = true)
    m.background.visible = (checked = true)

    ' Used in settings screen to calculate the list width dynamically based on the text width of each item.
    nBoundingTextWidth = m.label.boundingRect().width
    m.top.calculatedWidth = nBoundingTextWidth + getWidthMinusText()
  else
    m.label.text = ""
    m.labelFocused.text = ""
    m.caret.visible = false
    m.caretFocused.visible = false
  end if
End Function


' Callback triggered when the width field value gets updated.
Function onWidthChange(msg)
  width = msg.getData()
  labelWidth = width - getWidthMinusText()
  ' In the below we are reducing the label width to account for padding left and right also the width of the check icon.
  m.label.width = labelWidth
  m.labelFocused.width = labelWidth
End Function


' Callback triggered when the height field value gets updated.
Function onHeightChange(msg)
  height = msg.getData()
  m.container.translation = [m.container.translation[0], height / 2]
End Function


' Returns the width that needs to be subtracted from the width.
Function getWidthMinusText()
  ' The width include the checkbox, the space in between the checkbox and the label, and the space before the 1st and last elements of the checkbutton
  return m.caret.width + m.container.itemSpacings[0] + m.container.translation[0] * 2
End Function


Function onItemHasFocus()
  applyStyling()
End Function


Function onFocusPercentChange(msg)
  hasFocus = listHasFocus()

  if hasFocus = true
    focusPercent = msg.getData()
    m.background.opacity = 1 - focusPercent
    m.labelFocused.opacity = focusPercent
    m.caretFocused.opacity = focusPercent
  else
    m.labelFocused.opacity = 0
    m.caretFocused.opacity = 0
  end if
End Function


Function onListHasFocusChange()
  if m.top.itemHasFocus = true
    m.background.opacity = 0
  else
    m.background.opacity = 1
  end if

  hasFocus = listHasFocus()

  if hasFocus = true AND m.top.itemHasFocus = true
    m.labelFocused.opacity = 1
    m.caretFocused.opacity = 1
  else
    m.labelFocused.opacity = 0
    m.caretFocused.opacity = 0
  end if
End Function


Function applyStyling()
  m.label.color = m.unfocusedThemeColor
  m.labelFocused.color = m.focusedThemeColor
  m.caret.blendColor = m.unfocusedThemeColor
  m.caretFocused.blendColor = m.focusedThemeColor
End Function


Function listHasFocus()
  return m.top.listHasFocus OR m.top.gridHasFocus
End Function
