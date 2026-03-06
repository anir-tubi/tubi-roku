' OneTrust SDK Banner
sub init()
  try
    screenSize = m.global.screenSize
    m.width = 1920
    m.height = 1080
    if isValid(screenSize)
      if isValid(screenSize.w) then m.width = screenSize.w
      if isValid(screenSize.h) then m.height = screenSize.h
    end if
    m.style = style()
    m.constant = applicationConstants()
    m.navConstant = getNavigationConstants()
    m.WCAGRoles = CreateObject("roSGNode", "OTWCAGInterface")
    m.buttonListRect = m.top.findNode("buttonListRect")
    m.descriptionRec = m.top.findNode("descriptionRec")
    m.normalDescription = m.top.findNode("normalDescription")
    m.descriptionIAB = m.top.findNode("descriptionIAB")
    m.qrCodeImg = m.top.findNode("qrCodeImg")
    m.policyLinkRec = m.top.findNode("policyLinkRec")
    m.policyLinkText = m.top.findNode("policyLinkText")
    m.descriptionScrollRec = m.top.findNode("descriptionScrollRec")
    m.descriptionScrollRec.itemSpacings = m.style.descriptionScrollRec.itemSpacings
    m.buttonContent = []
    m.OT_Data = m.global.OT_Data
    m.dpdTitle = m.top.findNode("dpdTitle")
    m.dpdheading = m.top.findNode("dpdheading")
    m.dpdheading.itemSpacings = [m.style.bannerHeading.itemSpacings]
    m.bannerHeading = m.top.findNode("bannerHeading")
    m.dpdheading.itemSpacings = [m.style.bannerHeading.itemSpacings]
    setMultistyleLabel()
    if isValid(m.OT_Data) AND isValid(m.OT_Data.fonts)
      setFont([m.dpdTitle], m.OT_Data.fonts.heading)
      setFont([m.policyLinkText], m.OT_Data.fonts.description)
    end if
    m.scrollThumb = m.top.findNode("scrollThumb")
    m.scrollThumb.width = m.style.scrollThumb.width
    m.poweredLogo = m.top.findNode("poweredLogo")
    m.OTBannerHeader = m.top.findNode("OTBannerHeader")
    m.OTBannerFooter = m.top.findNode("OTBannerFooter")
    m.buttonList = m.OTBannerFooter.findNode("buttonList")
    m.closetextList = m.OTBannerHeader.findNode("closetextList")
    m.logo = m.OTBannerHeader.findNode("logo")
    m.headerText = m.OTBannerHeader.findNode("headerText")
    m.closeBtnVoiceOverText = m.OTBannerHeader.findNode("closeBtnVoiceOverText")
    m.poweredLogo.translation = [m.width - m.poweredLogo.width - m.style.containerPadding, m.height - m.poweredLogo.height - (m.style.containerPaddingTop / 2)]
    m.layout = "bottom"
    m.top.hideInteractionType = ""

    ScrollInitialize(m, m.descriptionRec, m.descriptionScrollRec)

    m.gridScrollAnimation = m.top.findNode("gridScrollAnimation")
    m.gridScrollAnimationInterpolator = m.top.findNode("gridScrollAnimationInterpolator")
    m.gridScrollThumbAnimation = m.top.findNode("gridScrollThumbAnimation")
    m.gridScrollThumbAnimationInterpolator = m.top.findNode("gridScrollThumbAnimationInterpolator")

    m.lastTranslation = [0, 0]
    m.lastThumbTranslation = [0, 0]

    m.scrollTimer = CreateObject("roSGNode", "Timer")

    m.container = m.top.findNode("container")
    m.container.width = screenSize.w
    m.container.height = screenSize.h

    m.innerContainer = m.top.findNode("innerContainer")
    m.style.setPadding(m.innerContainer, [m.style.containerPadding, m.style.containerPaddingTop, m.style.containerPaddingTop, m.style.containerPadding], m.container.width, m.container.height)

    m.errortype = getErrorType()
    m.errorTags = getErrorTags()
    m.logger = logUtil()
    m.registry = RegistryUtil()
    m.roAudioGuide = CreateObject("roAudioGuide")
  catch e
    ? "Error in OTBanner init: " + e.message
  end try
end sub

Function onBannerData()
  try
    m.OTinitialize = m.top.OTinitialize
    bannerModel = getBannerModelData(m.top.bannerData)
    if bannerModel <> invalid
      if isValid(m.global.OT_Data) AND isValid(m.global.OT_Data["WCAGRoles"]) then m.WCAGRoles = m.global.OT_Data["WCAGRoles"]
      m.layout = bannerModel.layout
      m.container.color = bannerModel.backgroundColor
      m.innerContainer.color = m.container.color
      m.descriptionRec.color = m.container.color
      havingPolicyLink = havingPolicyLinkQrcode(bannerModel)
      m.OTBannerHeader.OTinitialize = m.OTinitialize
      bannerModel.Hwidth = m.innerContainer.width
      bannerModel.Hheight = m.innerContainer.height
      m.OTBannerHeader.data = bannerModel.clone(true)
      bannerModel.width = m.innerContainer.width
      bannerModel.height = m.innerContainer.height
      width = bannerModel.width - (bannerModel.ratio[0] * m.innerContainer.width)
      if m.layout = "right"
        bannerModel.width = width
        bannerModel.height -= m.OTBannerHeader.height
      end if

      m.OTBannerFooter.OTinitialize = m.OTinitialize
      m.OTBannerFooter.data = bannerModel.clone(true)

      m.descriptionRec.width = m.innerContainer.width
      m.descriptionRec.height = m.innerContainer.height - m.OTBannerHeader.height - m.OTBannerFooter.height
      m.descriptionRec.translation = [0, m.OTBannerHeader.height]
      policyLinkH = 0
      if m.layout = "right" OR havingPolicyLink
        m.descriptionRec.width -= (bannerModel.ratio[1] * m.innerContainer.width)
        if m.layout = "right"
          m.OTBannerFooter.translation = [m.descriptionRec.width, m.OTBannerHeader.height]
          policyLinkH = m.OTBannerFooter.height
        end if
        m.descriptionRec.height += policyLinkH
        m.policyLinkRec.translation = [m.descriptionRec.width + m.style.containerPaddingTop, m.OTBannerHeader.height + policyLinkH]
      end if
      m.descriptionRec.clippingRect = [0, 0, m.descriptionRec.width, m.descriptionRec.height]

      descriptionWidth = m.descriptionRec.width - m.scrollThumb.width
      setDescriptionWidth(descriptionWidth)
      m.scrollThumb.translation = [descriptionWidth, 0]
      textColor = setDescription(bannerModel)
      m.scrollThumb.color = textColor
      setpolicyLinkQrcode(bannerModel, textColor, width)
      m.scrollThumb.height = scrollHeight()
      bannerLoggingReason(bannerModel)
      createResolvedPromise(m.buttonList).then(sub(fire)
        if isValid(fire)
          m.buttonList.setFocus(true)
          setTextToSpeech()
        end if
      end sub)
      setIsBannerShownStatus(1)
      eventListeners(m.OTinitialize.top.eventlistener, m.constant.listener["ELB115"])
    end if
  catch e
    ? "Error in OTBanner init: " + e.message
  end try
End Function

sub setTextToSpeech()
  try
    if isValid(m.roAudioGuide) AND isValid(m.WCAGRoles)
      m.roAudioGuide.Flush()
      sayPoster(m.logo)
      sayText(m.headerText, m.WCAGRoles.headingAriaLabel)
      saylayout(m.bannerHeading, "")
      saylayout(m.dpdheading, "")
      sayPoster(m.qrCodeImg)
      sayFocused(m.buttonList, m.WCAGRoles.button, m.WCAGRoles.selectedAriaLabel)
    end if
  catch e
    ? "Error in setTextToSpeech init: " + e.message
  end try
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
  try
    closeNode = { key: m.navConstant.button, value: m.closetextList, skipSameNode: false }
    footerButtonNode = { key: m.navConstant.button, value: m.buttonList, skipSameNode: true, jumptoItem: 0 }
    descriptionNode = { key: m.navConstant.scrollTextButton, value: m.descriptionScrollRec, skipSameNode: true }

    currentPath = [0, 2]
    value = [
      [
        closeNode,
        descriptionNode,
        footerButtonNode
      ]
    ]
    if m.layout = "right"
      currentPath = [1, 1]
      footerButtonNode["resetScroll"] = true
      closeNode["redirect"] = { down: [1, 1] }
      value = [
        [
          closeNode,
          descriptionNode
        ],
        [
          closeNode,
          footerButtonNode
        ]
      ]
    end if
    visiblePath = currentPath
    previousPath = currentPath
    if m.navDirections <> invalid AND m.navDirections.key <> invalid
      currentPath = m.navDirections.key
      visiblePath = m.navDirections.visiblePath
      previousPath = m.navDirections.previousPath
    end if
    m.navDirections = {
      key: currentPath,
      visiblePath: visiblePath,
      previousPath: previousPath,
      scrollValue: m.descriptionScrollRec,
      value: value
    }
    return navigation1(key, press)
  catch e
    ? "Error in onKeyEvent: " + e.message
    return false
  end try
End Function

Function setViewFocus(message as Object)
  try
    if message <> invalid
      m.buttonList.setFocus(true)
      setTextToSpeech()
    end if
  catch e
    ? "Error in setViewFocus: " + e.message
  end try
End Function

Function setDescription(bannerModel)
  textColor = "0x00000"
  try
    if isValid(bannerModel)
      if bannerModel.additionalDescriptionPlacement = "AfterTitle" then textColor = setTextFeild(textColor, bannerModel.additionalDescription, m.AfterTitle, m.ismultiStyleLabel, m.bannerHeading)
      textColor = setTextFeild(textColor, bannerModel.description, m.description, m.ismultiStyleLabel, m.bannerHeading)
      if bannerModel.additionalDescriptionPlacement = "AfterDescription" then textColor = setTextFeild(textColor, bannerModel.additionalDescription, m.AfterDescription, m.ismultiStyleLabel, m.bannerHeading)
      textColor = setTextFeild(textColor, bannerModel.dpdTitle, m.dpdTitle, false)
      textColor = setTextFeild(textColor, bannerModel.dpdDescription, m.dpdDescription, m.ismultiStyleLabel, m.dpdheading)
      if bannerModel.additionalDescriptionPlacement = "AfterDPD" then textColor = setTextFeild(textColor, bannerModel.additionalDescription, m.AfterDPD, m.ismultiStyleLabel, m.dpdheading)
    end if
  catch e
    ? "Error in setDescription: " + e.message
  end try
  return textColor
End Function

Function setTextFeild(textColor, data, node, ismultiStyleLabel, parentNode = invalid)
  try
    if isValid(data) AND isValid(node)
      if isValid(parentNode) then parentNode.appendChild(node)
      node.visible = true
      node.scale = [1, 1]
      node.text = data.text
      node.color = data.textColor
      textColor = data.textColor
      if ismultiStyleLabel
        drawingStyles = {
          "b": {
            "fontUri": m.OT_Data.multiStyleFonts.boldDescription.fontUri,
            "fontSize": m.OT_Data.multiStyleFonts.boldDescription.fontSize,
            "color": data.textColor
          },
          "default": {
            "fontUri": m.OT_Data.multiStyleFonts.description.fontUri,
            "fontSize": m.OT_Data.multiStyleFonts.boldDescription.fontSize,
            "color": data.textColor
          }
        }
        if isValid(node.drawingStyles) then node.drawingStyles = drawingStyles
      end if
    end if
  catch e
    ? "Error in setTextFeild: " + e.message
  end try
  return textColor
End Function

Function setDescriptionWidth(width)
  try
    if isValid(width)
      m.description.width = width
      m.dpdTitle.width = width
      m.dpdDescription.width = width
      m.AfterTitle.width = width
      m.AfterDescription.width = width
      m.AfterDPD.width = width
    end if
  catch e
    ? "Error in setDescriptionWidth: " + e.message
  end try
End Function

Function setMultistyleLabel()
  try
    osVersion = getDeviceInfo("osVersion")
    m.ismultiStyleLabel = true
    if osVersion = invalid OR osVersion < 10.5 then m.ismultiStyleLabel = false
    m.AfterTitle = getMultistyleLabel("AfterTitle")
    m.description = getMultistyleLabel("description")
    m.AfterDescription = getMultistyleLabel("AfterDescription")
    m.dpdDescription = getMultistyleLabel("dpdDescription")
    m.dpdheading.insertChild(m.dpdDescription, 1)
    m.AfterDPD = getMultistyleLabel("AfterDPD")
  catch e
    ? "Error in setMultistyleLabel: " + e.message
  end try
End Function

Function getMultistyleLabel(id)
  descriptionLabel = getNode().label("label")
  try
    if isString(id) AND isValid(m.OT_Data) AND isValid(m.OT_Data.fonts)
      descriptionLabel = getNode().label(id, "", m.OT_Data.fonts.description)
      if m.ismultiStyleLabel then descriptionLabel = getNode().MultiStyleLabel(id)
      descriptionLabel.visible = false
      descriptionLabel.scale = [0, 0]
    end if
  catch e
    ? "Error in setMultistyleLabel: " + e.message
  end try
  return descriptionLabel
End Function

Function havingPolicyLinkQrcode(bannerModel)
  return isValid(bannerModel) AND isValid(bannerModel.policyLink) AND isString(bannerModel.policyLink.url)
End Function

Function setpolicyLinkQrcode(bannerModel, textColor, width)
  try
    m.policyLinkText.scale = [0.0, 0.0]
    m.qrCodeImg.scale = [0.0, 0.0]
    m.qrCodeImg.visible = false
    m.policyLinkText.visible = false
    if isValid(bannerModel) AND havingPolicyLinkQrcode(bannerModel)
      m.policyLinkText.scale = [1.0, 1.0]
      m.policyLinkText.visible = true
      m.policyLinkText.width = width - m.style.containerPaddingTop
      m.policyLinkText.color = bannerModel.policyLink.textColor
      m.policyLinkText.text = bannerModel.policyLink.text
      'm.policyLinkText.translation = [m.style.containerPaddingTop, 0]
      m.qrCodeImg.scale = [1.0, 1.0]
      m.qrCodeImg.visible = true
      m.qrCodeImg.loadHeight = m.style.qrcode.width
      m.qrCodeImg.loadWidth = m.style.qrcode.height
      m.qrCodeImg.width = m.qrCodeImg.loadHeight
      m.qrCodeImg.height = m.qrCodeImg.loadWidth
      m.qrCodeImg.uri = bannerModel.policyLink.url
      if isValid(m.WCAGRoles) then m.qrCodeImg["audioGuideText"] = m.WCAGRoles.qrCodeAriaLabel.Replace("<X>", m.policyLinkText.text)
      m.qrCodeImg.blendColor = bannerModel.policyLink.textColor
      if isValid(textColor)
        m.policyLinkText.color = textColor
        m.qrCodeImg.blendColor = textColor
      end if
    end if
  catch e
    ? "Error in setpolicyLinkQrcode: " + e.message
  end try
End Function