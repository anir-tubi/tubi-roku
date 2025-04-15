Function init()
  m.description = m.top.findNode("description")
  m.VideoGridTile = m.top.findNode("VideoGridTile")
  m.top.observeFieldScoped("focusPercent", "onItemFocusPercentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.description, typographyConstants.ids.bodySmall)

  onThemeChange()

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.itemSpacings = [24]
End Function


Function onThemeChange()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.description.color = theme.secondaryTextColor
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()
  m.VideoGridTile.itemContent = itemContent

  currentProgram = invalid
  if itemContent.type = "linear"
    currentProgram = getCurrentLiveProgram(itemContent)
  end if

  if currentProgram <> invalid AND isNonEmptyString(currentProgram.description) = true
    m.description.text = currentProgram.description
  else
    m.description.text = itemContent.description
  end if
End Function


Function onItemFocusPercentChange(msg)
  focusPercent = msg.getData()
  m.description.opacity = focusPercent
End Function