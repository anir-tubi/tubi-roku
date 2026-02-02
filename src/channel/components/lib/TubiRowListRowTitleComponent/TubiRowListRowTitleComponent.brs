Function init()
  m.titleLabel = m.top.findNode("titleLabel")

  m.enhancedButton = invalid

  m.top.observeFieldScoped("content", "onContentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.titleLabel, typographyConstants.ids.subheaderMedium)

  m.global.observeFieldScoped("theme", "onThemeChange")
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.titleLabel.color = theme.primaryTextColor
  end if
End Function


Function onContentChange()
  content = m.top.content
  if content <> invalid then
    m.titleLabel.text = content.title

    if content.hasField("isRowFocused") then
      content.unobserveFieldScoped("isRowFocused")
      content.observeFieldScoped("isRowFocused", "onIsRowFocusedChange")

      if m.enhancedButton = invalid then
        m.enhancedButton = createObject("roSGNode", "EnhancedButton")
        m.enhancedButton.height = 72
        m.enhancedButton.padding = 24
        m.enhancedButton.backgroundUri = "pkg:/images/pill_button_72_$$RES$$.9.png"
      end if

      ' Have to add isPrimaryButton to content to get proper styling
      content.update({
        "isPrimaryButton": true
        "rightAlignedIcon": true
        "iconUrl": "pkg:/images/icon_chevron_right.png"
      }, true)

      m.enhancedButton.itemContent = content
      m.top.insertChild(m.enhancedButton, 0)

      m.titleLabel.scale = [0, 0]
      m.titleLabel.visible = false
    else if m.enhancedButton <> invalid then
      if m.enhancedButton.itemContent <> invalid then
        m.enhancedButton.itemContent.unobserveFieldScoped("isRowFocused")
      end if

      m.top.removeChild(m.enhancedButton)
      m.enhancedButton = invalid

      m.titleLabel.scale = [1, 1]
      m.titleLabel.visible = true
    end if
  end if
End Function


Function onIsRowFocusedChange(msg)
  isFocused = msg.getData()

  m.enhancedButton.itemHasFocus = isFocused
End Function
