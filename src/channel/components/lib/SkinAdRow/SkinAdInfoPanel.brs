Function init()
  tubilog("SkinAdInfoPanel.init")
  m.constants = getConstantsFromGlobal()

  m.nodeHelpers = TubiNodeHelpers()

  m.infoPanelGroup = m.top.findNode("infoPanelGroup")

  m.tubiLogo = m.top.findNode("tubiLogo")
  m.presentedByLabel = m.top.findNode("presentedByLabel")
  m.titleGroup = m.top.findNode("TitleGroup")
  m.title = m.top.findNode("Title")
  m.titleImage = m.top.findNode("TitleImage")
  
  m.titleImage.loadHeight = m.constants.ui.logoSizes.skinAds.infoPanel.height
  m.titleImage.loadWidth = m.constants.ui.logoSizes.skinAds.infoPanel.width
  m.descriptionPanel = m.top.findNode("DescriptionPanel")

  m.titleImage.observeFieldScoped("loadStatus", "onTitleImageLoadStatusChange")
  m.top.observeFieldScoped("content", "onContentChange")

  m.typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, m.typographyConstants.ids.headerLarge)
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
    m.title.color = theme.primaryTextColor
    m.presentedByLabel.color = theme.primaryTextColor
  end if
End Function


Function onContentChange(msg)
  content = msg.getData()
  m.title.text = content.title
  setTitleImage(content.titleImageUrl)
  sTitlePrefix = content.titlePrefix

  '//Create a new SkinAdContentNode to pass content data that you wish to pass to the description panel.
  '//   Not all the fields in content should be passed: i.e. title and titleImageUrl.
  '//   If the title fields were passed, then it would display the title twice: 1) in the infoPanel, and 2) in the descriptionPanel
  descriptionPanelContent = CreateObject("roSGNode", "SkinAdContentNode")
  descriptionPanelContent.description = content.description
  descriptionPanelContent.subDescription = content.subDescription
  descriptionPanelContent.qrCodeUrl = content.qrCodeUrl
  m.descriptionPanel.content = descriptionPanelContent

  '//Reset the labels
  m.presentedByLabel.text = ""

  if isNonEmptyString(sTitlePrefix) = true
    presentedByIndex = m.nodeHelpers.getChildIndex(m.infoPanelGroup, m.tubiLogo) + 1
    m.infoPanelGroup.insertChild(m.presentedByLabel, presentedByIndex)
    m.presentedByLabel.text = sTitlePrefix
  else
    m.infoPanelGroup.removeChild(m.presentedByLabel)
  end if

End Function


Function onTitleImageLoadStatusChange(msg)
  if (msg.getData() = "failed")
    tubiLog("SkinAdInfoPanel onTitleImageLoadStatusChange(), title image failed to load")
    setTitleImage("")   '//attempt to display text-only version, if available
  end if
End function


Function setTitleImage(titleImageUri)
    if isNonEmptyString(titleImageUri) = true
      m.titleGroup.appendChild(m.titleImage)
      m.titleGroup.removeChild(m.title)
      
      m.titleImage.uri = replaceURLParameter(titleImageUri, "w", m.constants.ui.logoSizes.skinAds.infoPanel.width, true)
    else
      m.titleGroup.appendChild(m.title)
      m.titleGroup.removeChild(m.titleImage)
        
      m.titleImage.uri = ""
    end if
End Function
