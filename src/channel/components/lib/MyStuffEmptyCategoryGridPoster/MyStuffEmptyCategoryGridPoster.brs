Function init()
  m.Title = m.top.findNode("Title")
  m.SubTitle = m.top.findNode("SubTitle")
  
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.Title, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.SubTitle, typographyConstants.ids.bodyMedium)

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
    m.Title.color = theme.primaryTextColor
    m.SubTitle.color = theme.primaryTextColor
  end if
End Function