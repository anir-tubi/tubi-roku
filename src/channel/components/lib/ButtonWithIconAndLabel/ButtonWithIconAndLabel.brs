Function init()
  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocus")
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.IconAndLabelGroup = m.top.findNode("IconAndLabelGroup")
  m.ButtonBG = m.top.findNode("ButtonBG")
  m.ButtonIcon = m.top.findNode("ButtonIcon")
  m.ButtonText = m.top.findNode("ButtonText")

  m.badgeLabel = m.top.findNode("badgeLabel")
  m.badgeLabel.padding = [12, 9]


  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.buttonText, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.badgeLabel, typographyConstants.ids.bodyExtraSmallStrong)

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

  m.focusedColor = invalid
  m.neutralColor = invalid
  m.backgroundColor = invalid
  m.primaryTextColor = invalid

  if theme <> invalid
    m.ButtonBG.blendColor = theme.neutralColor
    m.focusedColor = theme.focusedColor
    m.neutralColor = theme.neutralColor
    m.backgroundColor = theme.backgroundColor
    m.primaryTextColor = theme.primaryTextColor
    m.ButtonText.color = m.primaryTextColor
    m.badgeLabel.fontColor = m.backgroundColor
  end if
End Function


Function onItemContentChange(msg)
  item = msg.getData()

  if item <> invalid then
    m.ButtonIcon.uri = item.HDPosterUrl
    m.ButtonText.text = item.title
    padding = 36
    spacing = 12

    if isNonEmptyString(item.badgeText) = true
      m.badgeLabel.text = item.badgeText
      calculatedTextWidth = m.IconAndLabelGroup.boundingRect().width + m.badgeLabel.boundingRect().width + spacing
      m.badgeLabel.visible = true
      m.badgeLabel.translation = [calculatedTextWidth - 12, 15]
    else
      calculatedTextWidth = m.IconAndLabelGroup.boundingRect().width
      m.badgeLabel.visible = false
    end if

    calculatedWidth = padding + calculatedTextWidth + spacing + padding
    m.top.calculatedWidth = calculatedWidth
    m.ButtonBG.width = calculatedWidth
    m.ButtonBG.visible = item.isUnfocusedFootprintEnabled
  end if
End Function


Function onItemHasFocus()
  if m.top.itemHasFocus = true
    m.ButtonBG.blendcolor = m.focusedColor
  else
    m.ButtonBG.blendcolor = m.neutralColor
  end if
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    if m.top.isInGrid = false
      m.ButtonIcon.blendcolor = m.backgroundColor
      m.ButtonText.color = m.backgroundColor
      m.badgeLabel.fontColor = m.primaryTextColor
      m.badgeLabel.blendColor = m.backgroundColor
    end if
    m.ButtonBG.blendcolor = m.focusedColor
  else
    m.ButtonBG.blendcolor = m.neutralColor
    m.ButtonIcon.blendcolor = m.primaryTextColor
    m.ButtonText.color = m.primaryTextColor
    m.badgeLabel.fontColor = m.backgroundColor
    m.badgeLabel.blendColor = m.primaryTextColor
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean

  if press then
    if key = "OK"
      m.top.buttonSelected = true
      return true
    end if
  end if

  return false
End Function
