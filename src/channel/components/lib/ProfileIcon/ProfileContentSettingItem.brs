Function init()
  m.unfocusedLabel = m.top.findNode("unfocusedLabel")
  m.focusedLabel = m.top.findNode("focusedLabel")
  m.labelParent = m.top.findNode("LabelParent")
  m.icon = m.top.findNode("Icon")

  m.menuItemText = m.top.findNode("menuItemText")
  m.kidsLogo = m.top.findNode("kidsLogo")
  m.kidsLogoFocused = m.top.findNode("kidsLogoFocused")
  m.kidsLogoGroup = m.top.findNode("kidsLogoGroup")

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("focusPercent", "onHandleFocus")
  m.top.observeFieldScoped("gridHasFocus", "onHandleFocus")
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.unfocusedLabel, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.focusedLabel, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.menuItemText, typographyConstants.ids.bodyMediumStrong)
  onThemeChange()

End Function

Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.unfocusedLabel.color = theme.primaryTextColor
    m.focusedLabel.color = theme.focusedTextColor
    m.menuItemText.color = theme.primaryTextColor
    m.kidsLogoFocused.blendcolor = theme.focusedTextColor
  end if
End Function


Function onItemContentChange(msg)
  item = msg.getData()
  if item <> invalid

    m.icon.uri = item.iconUrl
    m.icon.text = item.secondaryTitle
    m.icon.width = 64
    m.icon.height = 64
    m.icon.translation = [24, 16]
    m.icon.textFont = "bodyLargeStrong"

    if item.isKidsAccount = true
      if (m.kidsLogoGroup.getParent() = invalid)
        m.labelParent.appendChild(m.kidsLogoGroup)
      end if
    else
      m.labelParent.removeChild(m.kidsLogoGroup)
    end if

    m.unfocusedLabel.text = item.title
    m.focusedLabel.text = item.title

    transY = (m.top.height - m.labelParent.boundingRect().height) / 2
    m.labelParent.translation = [104, transY]

  end if
End Function


Function onHandleFocus()
  focusPercent = m.top.focusPercent

  if focusPercent > 0.1 AND m.top.gridHasFocus = true
    m.focusedLabel.opacity = focusPercent
    m.kidsLogoFocused.opacity = focusPercent
  else
    m.focusedLabel.opacity = 0.0
    m.kidsLogoFocused.opacity = 0.0
  end if
End Function