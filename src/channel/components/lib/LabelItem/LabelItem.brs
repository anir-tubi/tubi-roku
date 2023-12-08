Function init()
  topRef = m.top
  m.label = topRef.findNode("label")

  topRef.observeFieldScoped("itemContent", "onItemContentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodySmall_Strong)

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
    m.label.color = theme.primaryTextColor
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()
  if itemContent <> invalid then
    m.label.text = itemContent.title
  end if
End Function
