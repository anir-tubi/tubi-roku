Function init()
  m.constants = getConstantsFromGlobal()
  m.tubiLogo = m.top.findNode("tubiLogo")
  m.description = m.top.findNode("Description")
  m.presentedByLabel = m.top.findNode("presentedByLabel")
  m.titleImage = m.top.findNode("TitleImage")

  m.top.observeFieldScoped("content", "onContentChange")

  m.typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.description, m.typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.presentedByLabel, m.typographyConstants.ids.bodyExtraSmallStrong)

  '//::TODO::JHAND - fix gradient in kids mode

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
    m.description.color = theme.primaryTextColor
    m.presentedByLabel.color = theme.primaryTextColor
  end if
End Function


Function onContentChange(msg)
  content = msg.getData()
  sTitlePrefix = content.titlePrefix
  titleImageUri = content.titleImage
  sDescription = content.description

  if isNonEmptyString(sTitlePrefix) = true
    m.presentedByLabel.text = sTitlePrefix
  else
    m.presentedByLabel.text = ""  
  end if

  if isNonEmptyString(titleImageUri) = true
    m.titleImage.uri = replaceURLParameter(titleImageUri, "w", m.constants.ui.logoSizes.skinAds.infoPanel.width, true)
  else
    m.titleImage.uri = ""
  end if

  if isNonEmptyString(sDescription) = true
    m.description.text = sDescription
  else
    m.description.text = ""  
  end if
End Function
