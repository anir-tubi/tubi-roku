Function init()

  m.icon = m.top.findNode("MenuItemIcon")
  m.title = m.top.findNode("MenuItemText")
  m.bottomItemText = m.top.findNode("BottomItemText")
  m.textGroup = m.top.findNode("textGroup")

  m.top.observeFieldScoped("itemContent", "onItemContentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.displayMedium, { fontSize: 48 })
  setTypographyOfLabel(m.bottomItemText, typographyConstants.ids.bodyLargeStrong, { fontSize: 34 })
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.title.color = theme.primaryTextColor
    m.bottomItemText.color = theme.primaryTextColor
  end if
End Function


Function onItemContentChange(msg)
  item = msg.getData()
  if item <> invalid then

    m.icon.uri = item.HDPosterUrl
    m.bottomItemText.text = item.title
    if item.title <> ""
      initial = UCase(item.title.left(1))
    else
      initial = ""
    end if

    m.title.text = Ucase(initial)


  end if
End Function
