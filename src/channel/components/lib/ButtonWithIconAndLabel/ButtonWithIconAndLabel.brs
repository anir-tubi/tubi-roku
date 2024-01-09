Function init()
  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocus")

  m.IconAndLabelGroup = m.top.findNode("IconAndLabelGroup")
  m.ButtonBG = m.top.findNode("ButtonBG")
  m.ButtonIcon = m.top.findNode("ButtonIcon")
  m.ButtonText = m.top.findNode("ButtonText")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.buttonText, typographyConstants.ids.bodyMediumStrong)

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
    m.ButtonBG.blendColor = theme.neutralColor
    m.focusedColor = theme.focusedColor
    m.neutralColor = theme.neutralColor
  end if
End Function


Function onItemContentChange(msg)
  item = msg.getData()

  if item <> invalid then
    m.ButtonIcon.uri = item.HDPosterUrl
    m.ButtonText.text = item.title
    padding = 36
    spacing = 12
    calculatedWidth = padding + m.IconAndLabelGroup.boundingRect().width + spacing + padding
    m.top.calculatedWidth = calculatedWidth
    m.ButtonBG.width = calculatedWidth
  end if
End Function


Function onItemHasFocus()
  if m.top.itemHasFocus = true
    m.ButtonBG.blendcolor = m.focusedColor
  else
    m.ButtonBG.blendcolor = m.neutralColor
  end if
End Function
