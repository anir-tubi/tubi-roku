Function init()
  topRef = m.top
  m.label = topRef.findNode("label")
  m.labelFocused = topRef.findNode("labelFocused")
  m.background = topRef.findNode("background")
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("focusPercent", "onFocusPercentChange")
  topRef.observeFieldScoped("gridHasFocus", "onGridHasFocusChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.labelFocused, typographyConstants.ids.bodySmallStrong)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    itemContent = m.top.itemContent
    if itemContent <> invalid then
      m.labelFocused.color = theme.primaryTextColor
      ' If the mode is light then using inverse or light mode colors.
      if itemContent.mode = "light"
        m.label.color = theme.inversePrimaryTextColor
        m.background.blendColor = theme.inverseNeutralColor2
      else
        m.label.color = theme.primaryTextColor
        m.background.blendColor = theme.neutralColor2
      end if
    end if
  end if
End Function


Function onItemContentChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid then

    if itemContent.fontSize <> invalid
      m.top.fontSize = itemContent.fontSize
    end if

    m.label.text = itemContent.title
    m.labelFocused.text = itemContent.title

    textWidth = m.label.boundingRect().width
    m.top.width = textWidth
    m.background.width = textWidth
    ' Adjust the width of the list if the text is too long for the default width
    m.top.calculatedWidth = textWidth
  end if
  onThemeChange()
End Function


Function onFocusPercentChange(msg)
  focusPercent = msg.getData()
  m.background.opacity = 1 - focusPercent

  if m.top.gridHasFocus = true
    m.labelFocused.opacity = focusPercent
  else
    m.labelFocused.opacity = 0
  end if
End Function


Function onGridHasFocusChange(msg)
  gridHasFocus = msg.getData()
  if gridHasFocus = false
    m.background.opacity = 1
  else if m.top.itemHasFocus = true
    m.background.opacity = 0
  end if
End Function
