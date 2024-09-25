Function init()
  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("focusPercent", "onFocusPercentChange")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocus")

  m.icon = m.top.findNode("MenuItemIcon")
  m.title = m.top.findNode("MenuItemText")
  m.bottomItemText = m.top.findNode("bottomItemText")
  m.buttonBg = m.top.findNode("MenuItemBg")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.bottomItemText, typographyConstants.ids.bodySmallStrong)

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
    m.title.color = theme.primaryTextColor

    m.focusedColor = theme.focusedColor
    m.primaryTextColor = theme.primaryTextColor
    m.bgColor = theme.backgroundcolor
    m.buttonBg.blendcolor = theme.neutralColor2
    m.bottomItemText.color = theme.focusedColor
  end if
End Function


Function onItemContentChange()
  tubiLog("DetailMenuItem.onItemContentChange")
  if m.top.itemContent <> invalid then
    item = m.top.itemContent
    padding = 32

    m.icon.uri = item.iconUrl

    if item.isPrimaryButton = true
      m.title.text = item.title
      m.bottomItemText.text = ""
      width = m.title.boundingRect().width + 52 ' 36 icon size + 16 spacing between icon and text
      m.top.calculatedTextWidth = width
      m.buttonBg.visible = true
      m.buttonBg.width = padding + width + padding
    else
      m.bottomItemText.text = item.title
      m.title.text = ""
      m.top.calculatedTextWidth =  52
      m.buttonBg.visible = false
    end if

  end if
End Function


Function onItemHasFocus()

  if m.top.itemHasFocus = true
    m.icon.blendcolor = m.bgColor
    m.title.color = m.bgColor
    m.bottomItemText.color = m.focusedColor
  else
    m.icon.blendcolor = m.primaryTextColor
    m.title.color = m.primaryTextColor
    m.bottomItemText.color = m.primaryTextColor
  end if
End Function


Function onFocusPercentChange(msg)
  focusPercent = msg.getData()
  m.bottomItemText.opacity = focusPercent

  if focusPercent > 0.5
    m.icon.blendcolor = m.bgColor
    m.title.color = m.bgColor
    m.bottomItemText.color = m.focusedColor
  else
    m.icon.blendcolor = m.primaryTextColor
    m.title.color = m.primaryTextColor
    m.bottomItemText.color = m.primaryTextColor
  end if

End Function