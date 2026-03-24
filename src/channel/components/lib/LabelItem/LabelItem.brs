Function init()
  topRef = m.top
  m.label = topRef.findNode("label")
  m.focusedLabel = topRef.findNode("focusedLabel")

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("focusPercent", "onFocusPercentChange")
  m.top.observeFieldScoped("gridHasFocus", "onGridHasFocus")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.focusedLabel, typographyConstants.ids.bodySmallStrong)

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

    ' Set colors for both labels
    m.label.color = theme.primaryTextColor

    m.focusedLabel.color = theme.focusedTextColor

  end if
End Function


Function onFocusPercentChange()
  ' Update label visibility/opacity based on focusPercent (like side nav)
  updateLabelVisibility()
End Function


Function onGridHasFocus()
  updateLabelVisibility()
End Function


Function updateLabelVisibility()
  if m.label <> invalid AND m.focusedLabel <> invalid
    if m.top.gridHasFocus = true
      focusPercent = m.top.focusPercent
      m.label.opacity = 1 - focusPercent
      m.focusedLabel.opacity = focusPercent
    else
      m.label.opacity = 1.0
      m.focusedLabel.opacity = 0
    end if
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()
  if itemContent <> invalid then
    m.label.text = itemContent.title
    m.focusedLabel.text = itemContent.title
  end if
End Function
