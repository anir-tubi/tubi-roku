Function init()
  topRef = m.top
  m.signUpButton = topRef.findNode("signUpButton")
  m.title = topRef.findNode("title")
  m.description = topRef.findNode("description")
  m.subTitle = topRef.findNode("subTitle")
  m.border = topRef.findNode("border")
  m.contentSection = topRef.findNode("contentSection")

  m.title.text = getTranslation("metadata_continueWatching_notSignedIn_title")
  m.signUpButton.text = getTranslation("metadata_continueWatching_notSignedIn_container_button")
  m.subTitle.text = getTranslation("metadata_continueWatching_notSignedIn_container_description")
  m.description.text = getTranslation("metadata_continueWatching_notSignedIn_description")

  topRef.observeFieldScoped("itemHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("rowHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("width", "adjustContentAlignment")
  topRef.observeFieldScoped("height", "adjustContentAlignment")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.subTitle, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.description, typographyConstants.ids.bodyMedium)

  setThemeColors()
End Function


Function setThemeColors()
  theme = getThemeFromGlobal()
  
  if theme <> invalid
    m.title.color = theme.primaryTextColor
    m.subTitle.color = theme.secondaryTextColor
    m.description.color = theme.primaryTextColor
    m.focusedColor = theme.focusedColor
    m.neutralColor2 = theme.neutralColor2
    m.border.blendColor = m.neutralColor2
  end if
End Function


Function adjustContentAlignment()
  if m.top.width > 0 AND m.top.height > 0
    contentHeight = m.contentSection.boundingRect().height
    m.contentSection.translation = [69, (m.top.height - contentHeight) / 2]
  end if
End Function


Function onItemHasFocusChange(msg)
  itemHasFocus = (msg.getData() = true AND m.top.rowHasFocus = true)
  m.signUpButton.itemHasFocus = itemHasFocus
  if itemHasFocus = true
    m.border.blendColor = m.focusedColor
  else
    m.border.blendColor = m.neutralColor2
  end if
End Function
