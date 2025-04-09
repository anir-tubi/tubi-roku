Function init()
  m.description = m.top.findNode("description")
  m.VideoGridTile = m.top.findNode("VideoGridTile")
  m.top.observeFieldScoped("focusPercent", "onItemFocusPercentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.description, typographyConstants.ids.bodySmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.itemSpacings = [24]
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.description.color = theme.secondaryTextColor
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()
  m.VideoGridTile.itemContent = itemContent
  m.description.text = itemContent.description
End Function


Function onItemFocusPercentChange(msg)
  focusPercent = msg.getData()
  m.description.opacity = focusPercent
End Function