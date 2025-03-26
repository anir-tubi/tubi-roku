Function init()
  tubilog("SkinAdDescriptionPanel.init")
  m.constants = getConstantsFromGlobal()

  m.panelGroup = m.top.findNode("PanelGroup")
  m.description = m.top.findNode("Description")
  m.subDescription = m.top.findNode("SubDescription")
  m.titleGroup = m.top.findNode("TitleGroup")
  m.title = m.top.findNode("Title")
  m.titleImage = m.top.findNode("TitleImage")
  m.QRCodeImage = m.top.findNode("QRCodeImage")
  m.QRParentGroup = m.top.findNode("QRParentGroup")
  m.QRContentParentGroup = m.top.findNode("QRContentParentGroup")
  m.QRBackground = m.top.findNode("QRBackground")
  m.QRBackground.height = 140
  m.QRBackgroundSpacing = m.top.findNode("QRBackgroundSpacing")
  m.descriptionTextGroup = m.top.findNode("DescriptionTextGroup")

  m.titleImage.loadHeight = 72
  m.titleImage.loadWidth = 300
  m.titleImage.observeFieldScoped("loadStatus", "onTitleImageLoadStatusChange")
  m.top.observeFieldScoped("content", "onContentChange")

  m.typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.description, m.typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.subDescription, m.typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.title, m.typographyConstants.ids.subheaderMedium)

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
    m.description.color = theme.primaryTextColor
    m.subDescription.color = theme.primaryTextColor
    m.QRBackground.blendColor = theme.shadeColor2
  end if
End Function


Function onContentChange(msg)
  content = msg.getData()
  
  sTitle = content.title
  sTitleImage = content.titleImageUrl
  sDescription = content.description
  sSubDescription = content.subDescription
  sQRCodeUri = content.qrCodeUrl

  '//Reset the label strings
  m.title.text = ""
  m.description.text = ""
  m.subDescription.text = ""
  m.QRCodeImage.uri = ""
  m.descriptionTextGroup.itemSpacings = [12]


  if isNonEmptyString(sQRCodeUri) = true
    m.QRCodeImage.uri = sQRCodeUri
    m.QRContentParentGroup.appendChild(m.QRCodeImage)
    m.QRContentParentGroup.appendChild(m.descriptionTextGroup)
    m.panelGroup.appendChild(m.QRParentGroup)
  end if

  bTitleAvailable = (isNonEmptyString(sTitle) = true or isNonEmptyString(sTitleImage) = true)
  if bTitleAvailable = false
    '//title not present so do not show
    m.descriptionTextGroup.removeChild(m.titleGroup)
  else
    m.descriptionTextGroup.appendChild(m.titleGroup)
    setTitleImage(sTitleImage)
  end if

  if isNonEmptyString(sDescription) = true
    m.descriptionTextGroup.appendChild(m.description)
    m.description.text = sDescription
  else
    m.descriptionTextGroup.removeChild(m.description)
  end if

  if isNonEmptyString(sSubDescription) = true
    m.descriptionTextGroup.appendChild(m.subDescription)
    m.subDescription.text = sSubDescription
  else
    m.descriptionTextGroup.removeChild(m.subDescription)
  end if


  resizeBgroundAndArrangeUI()
End Function


'//Called to resize the background and to arrange the UI elements on the stage
Function resizeBgroundAndArrangeUI()
  '//reset the widths and strings of the labels to ensure the proper width is set
  m.title.width = 0
  m.description.width = 0
  m.subDescription.width = 0
  m.title.text = m.title.text
  m.description.text = m.description.text
  m.subDescription.text = m.subDescription.text

  '//Determine the widest heading and use that in part to determine the width of the QR background if the QR code is visible
  nWidestHeading = m.description.boundingRect().width

  if m.subDescription.boundingRect().width > nWidestHeading
    nWidestHeading = m.subDescription.boundingRect().width
  end if

  bTitleAvailable = (isNonEmptyString(m.title.text) = true OR (isNonEmptyString(m.titleImage.uri) = true AND m.titleImage.loadStatus <> "failed"))
  bQRCodeAvailable = (isNonEmptyString(m.QRCodeImage.uri) = true)

  if bTitleAvailable = true
    if m.titleImage.getParent() <> invalid
      if m.titleImage.boundingRect().width > nWidestHeading
        nWidestHeading = m.titleImage.boundingRect().width
      end if
    else
      if m.title.boundingRect().width > nWidestHeading
        nWidestHeading = m.title.boundingRect().width
      end if
    end if
  end if

  m.description.width = nWidestHeading
  m.subDescription.width = nWidestHeading
  m.title.width = nWidestHeading

  nPaddingTop = m.QRBackgroundSpacing.translation[1]
  nPaddingLeft = m.QRBackgroundSpacing.translation[0]

  if bQRCodeAvailable = true
    nPaddingInside = m.QRContentParentGroup.itemSpacings[0]

    if nWidestHeading > 0
      nHeaderWidth = (nPaddingInside * 2) + nWidestHeading
    else
      '//if there are no headers visible, then set the right padding of the QR background to be the same as the left padding
      nHeaderWidth = nPaddingLeft
    end if

    nHeightOfVisibleAssets = m.QRContentParentGroup.boundingRect().height

    m.QRBackground.height = nPaddingTop + nHeightOfVisibleAssets + nPaddingTop 'Add padding to the top and bottom of the height of the visible assets
    m.QRBackground.width = nPaddingLeft + m.QRCodeImage.width + nHeaderWidth

  else
    if bTitleAvailable = true
      '//if the title is available, then display the contents within a background box
      m.QRContentParentGroup.appendChild(m.descriptionTextGroup)
      m.QRContentParentGroup.removeChild(m.QRCodeImage)

      nHeightOfVisibleAssets = m.QRContentParentGroup.boundingRect().height
      m.QRBackground.height = nPaddingTop + nHeightOfVisibleAssets + nPaddingTop 'Add padding to the top and bottom of the height of the visible assets
      m.QRBackground.width = nPaddingLeft + nWidestHeading + nPaddingLeft
    else
      m.panelGroup.appendChild(m.descriptionTextGroup)
      m.panelGroup.removeChild(m.QRParentGroup)
    end if
  end if
End Function


Function onTitleImageLoadStatusChange(msg)
  bResizeBgroundAndArrangeUI = false
  if (msg.getData() = "failed")
    tubiLog("SkinAdDescriptionPanel onTitleImageLoadStatusChange(), title image failed to load")
        
    setTitleImage("")   '//attempt to display text-only version, if available
    bResizeBgroundAndArrangeUI = true
  else if (msg.getData() = "ready")
    bResizeBgroundAndArrangeUI = true
  end if

  if bResizeBgroundAndArrangeUI = true
    '//after a successful or failed attempt to load the title image, arrange everything so labels are properly spaced/oriented and the background is the proper size.
    resizeBgroundAndArrangeUI()
  end if
End Function


Function setTitleImage(titleImageUri)
  if isNonEmptyString(titleImageUri) = true
    m.titleGroup.appendChild(m.titleImage)
    m.titleGroup.removeChild(m.title)
    m.titleImage.uri = replaceURLParameter(titleImageUri, "h", m.titleImage.height.toStr(), true)
    m.descriptionTextGroup.itemSpacings = [0, 12]
  else
    m.titleGroup.appendChild(m.title)
    m.titleGroup.removeChild(m.titleImage)
    content = m.top.content
    if content <> invalid AND isNonEmptyString(content.title) = true
      '//Fallback to the title string if it exists
      m.title.text = content.title
    else
      m.descriptionTextGroup.removeChild(m.titleGroup)
    end if
    m.titleImage.uri = ""
    
  end if
End Function
