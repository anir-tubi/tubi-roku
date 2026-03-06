' OneTrust SDK Header
sub init()
  m.style = style()
  m.logger = logUtil()
  m.registry = RegistryUtil()
  m.WCAGRoles = CreateObject("roSGNode", "OTWCAGInterface")
  m.OT_Data = m.global.OT_Data
  m.screenSize = m.global.screenSize
  setMultistyleLabel()
  m.top.observeField("focusedChild", "onFocusedChildChange")

  m.detailScreenInnerContainer = m.top.findNode("detailScreenInnerContainer")
  m.OTdetailScreenHeader = m.top.findNode("OTdetailScreenHeader")
  m.detailScreenViewContainer = m.top.findNode("detailScreenViewContainer")
  m.detailScreenViewSection = m.top.findNode("detailScreenViewSection")

  m.filterButtonList = m.top.findNode("filterButtonList")
  m.filterButtonList.observeField("itemFocused", "onItemFocused")

  m.OTConsentButtons = m.top.findNode("OTConsentButtons")
  m.OTAdditionalButtons = m.top.findNode("OTAdditionalButtons")
  m.OTPurposeChildButtons = m.top.findNode("OTPurposeChildButtons")
  m.alwaysActiveLabel = m.top.findNode("alwaysActiveLabel")

  m.OTConsentButtons.observeField("scrollHeight", "setScrollHeight")
  m.OTAdditionalButtons.observeField("scrollHeight", "setScrollHeight")
  m.OTPurposeChildButtons.observeField("scrollHeight", "setScrollHeight")

  m.headerLayout = m.top.findNode("headerLayout")
  m.heading = m.top.findNode("heading")

  m.detailScreenlayout = m.top.findNode("detailScreenlayout")
  m.detailScreenlayoutScroll = m.top.findNode("detailScreenlayoutScroll")
  m.scrollThumb = m.top.findNode("scrollThumb")
  m.scrollThumb.width = m.style.scrollThumb.width

  m.descriptionRec = m.top.findNode("descriptionRec")
  m.adtlDescriptionRec = m.top.findNode("adtlDescriptionRec")
  m.policyLinkRec = m.top.findNode("policyLinkRec")
  m.childDivider = m.top.findNode("childDivider")
  m.childDivider2 = m.top.findNode("childDivider2")
  m.additionalBtnDivider = m.top.findNode("additionalBtnDivider")
  m.childHeadingRec = m.top.findNode("childHeadingRec")
  m.childHeading = m.top.findNode("childHeading")
  m.headerLayout.insertChild(getNode().getMultiStyleLabel("subHeading", m.ismultiStyleLabel), 1)
  m.subHeading = m.headerLayout.findNode("subHeading")

  m.policyLinkText = m.top.findNode("policyLinkText")
  m.qrCodeImg = m.top.findNode("qrCodeImg")

  m.OTSlideAnimation = m.top.findNode("OTSlideAnimation")
  m.OTSlideAnimationInterpolator = m.top.findNode("OTSlideAnimationInterpolator")
  m.OTslideOverlay = m.top.findNode("OTslideOverlay")

  setFont([m.policyLinkText], m.OT_Data.fonts.description)

  m.getNode = getNode()
  m.LifeSpanDuration = {
    SECOND_DIVIDER: 2629746,
    MONTH_DIVIDER: 86400,
  }
  m.deviceStorageDisclosureData = {}
  m.roAudioGuide = CreateObject("roAudioGuide")
end sub

sub onContentChange()
  data = m.top.data
  m.OTslideOverlay.visible = false
  if data <> invalid AND data.keys().count() > 0
    if isValid(m.global.OT_Data) AND isValid(m.global.OT_Data["WCAGRoles"]) then m.WCAGRoles = m.global.OT_Data["WCAGRoles"]
    width = data.width
    height = data.height
    translation = data.translation
    Hwidth = width
    Hheight = height
    Htranslation = translation
    if isValid(data.backButton)
      m.OTSlideAnimation.control = "stop"
      m.OTslideOverlay.visible = true
      m.OTdetailScreenHeader.data = data
      m.OTdetailScreenHeader.translation = [m.style.detailScreen.padding, m.style.detailScreen.padding]
      m.OTslideOverlay.translation = data.overlayTranslation
      m.OTslideOverlay.width = m.screenSize.w
      m.OTslideOverlay.height = m.screenSize.h
      childTranslation = m.screenSize.w - data.width + 2 * data.overlayTranslation[0]
      translation = [childTranslation, translation[1]]
      Hwidth = m.screenSize.w - childTranslation
      Hheight = m.screenSize.h
      Htranslation = [translation[0], data.overlayTranslation[1]]
      m.OTSlideAnimationInterpolator.keyValue = [[translation[0] + Hwidth, data.overlayTranslation[1]], [translation[0], data.overlayTranslation[1]]]
      if m.top.getParent().getParent().getParent().getParent().slideLayer = 1 then m.top.slide = false
    end if
    if isString(data.backgroundColor)
      m.detailScreenInnerContainer.color = data.backgroundColor
      m.detailScreenViewContainer.color = data.backgroundColor
      m.detailScreenViewSection.color = data.backgroundColor
      m.detailScreenlayout.color = data.backgroundColor
    end if
    m.detailScreenViewContainer.width = Hwidth
    m.detailScreenViewContainer.height = Hheight
    m.detailScreenViewContainer.translation = Htranslation
    m.detailScreenInnerContainer.width = width
    m.detailScreenInnerContainer.height = height
    m.detailScreenInnerContainer.translation = [0, -Htranslation[1]]
    m.style.setPadding(m.detailScreenViewSection, [m.style.detailScreen.padding, 0, 0, 0], m.detailScreenInnerContainer.width, m.detailScreenInnerContainer.height)

    m.heading.visible = false
    m.heading.scale = [0, 0]
    if isValid(data.headerNode)
      m.heading.visible = true
      m.heading.scale = [1, 1]
      m.heading.width = m.detailScreenViewSection.width
      m.heading.color = data.headerNode.textColor
      m.heading.font = m.OT_Data.fonts.heading
      m.heading.text = data.headerNode.text
    end if

    m.subHeading.visible = false
    m.subHeading.scale = [0, 0]
    m.headerLayout.itemSpacings = [0]
    if isValid(data.subHeaderNode)
      m.headerLayout.itemSpacings = [m.style.detailScreen.itemSpacings]
      m.subHeading.visible = true
      m.subHeading.scale = [1, 1]
      font = m.OT_Data.multiStyleFonts.description.fontUri
      if isValid(data.viewIllustrations) AND data.viewIllustrations.count() > 0 then font = m.OT_Data.multiStyleFonts.boldDescription.fontUri
      drawingStyles = {
        "b": {
          "fontUri": m.OT_Data.multiStyleFonts.boldDescription.fontUri,
          "fontSize": m.OT_Data.multiStyleFonts.boldDescription.fontSize,
          "color": data.subHeaderNode.textColor
        },
        "default": {
          "fontUri": font,
          "fontSize": m.OT_Data.multiStyleFonts.description.fontSize,
          "color": data.subHeaderNode.textColor
        }
      }
      getNode().getMultiStyleLabel("subHeading", m.isMultiStyleLabel, m.subHeading, data.subHeaderNode.text, drawingStyles, m.detailScreenViewSection.width)
    end if

    m.filterButtonList.visible = false
    m.filterButtonList.scale = [0, 0]
    m.OTConsentButtons.isScrollable = false
    if isValid(data.filterBtnNode)
      m.filterButtonList.visible = true
      m.filterButtonList.scale = [1, 1]
      m.filterButtonList.itemSpacing = [m.style.buttonspacing, m.style.buttonspacing]
      m.filterButtonList.itemSize = data.filterBtnSize
      m.filterButtonList.content = data.filterBtnNode
      m.OTConsentButtons.isScrollable = true
    end if

    detailScreenlayoutScrollItemSpacings = []
    Lcount = m.detailScreenlayoutScroll.getChildCount()
    for i = 0 to Lcount - 1
      childLabel = m.detailScreenlayoutScroll.getChild(i)
      childLabel.visible = false
      childLabel.scale = [0, 0]
      detailScreenlayoutScrollItemSpacings.push(0)
    end for

    m.detailScreenlayout.width = m.detailScreenViewSection.width + m.style.scrollThumb.padding + m.scrollThumb.width
    detailScreenWidth = m.detailScreenlayout.width - m.style.scrollThumb.padding - m.scrollThumb.width

    m.detailScreenlayout.translation = [0, m.headerLayout.boundingRect().height + m.style.detailScreen.paddinglabel]
    m.detailScreenlayout.height = m.detailScreenViewSection.height - m.detailScreenlayout.translation[1]

    if isValid(data.descriptionNode) then setDsIdDetails(data, data.descriptionNode.textColor, detailScreenWidth)

    'm.detailScreenlayoutScroll.itemSpacings = [m.style.detailScreen.itemSpacings]
    m.detailScreenlayoutScroll.translation = [0, 0]
    if isValid(data.viewIllustrations) AND data.viewIllustrations.count() > 0 AND isValid(data.descriptionNode)
      m.descriptionRec.visible = true
      setCustomIllustrations(data.viewIllustrations, data.descriptionNode.textColor, detailScreenWidth)
    else if isValid(data.item)
      getVendorDescriptions(data.item, data.headerNode.textColor, detailScreenWidth, m.adtlDescriptionRec)
    else if data.id = "vendorsPolicyBtn" OR data.id = "legIntClaimPolicyBtn"
      m.descriptionRec.visible = true
      if isValid(data.descriptionNode) AND isString(data.descriptionNode.url) AND isString(m.heading.text) then getQrCode(data.descriptionNode.url, data.backgroundColor, data.descriptionNode.textColor)
    else
      if isValid(data.descriptionNode) AND isString(data.descriptionNode.text)
        ' if isValid(data.subHeaderNode) and isValid(m.subHeading.font) then m.subHeading.font = m.OT_Data.fonts.description
        m.descriptionRec.visible = true
        setDescription(data.id, data.descriptionNode.text, data.descriptionNode.textColor, detailScreenWidth)
      end if
    end if

    setpolicyLinkQrcode(data, detailScreenWidth)

    if isValid(data.consentBtnNode)
      alwaysActiveNode = data.consentBtnNode.getChild(0)
      if isValid(alwaysActiveNode) AND isValid(alwaysActiveNode.status) AND alwaysActiveNode.status = 2 AND isString(alwaysActiveNode.text)
        m.alwaysActiveLabel.visible = true
        m.alwaysActiveLabel.text = alwaysActiveNode.text
        m.alwaysActiveLabel.width = detailScreenWidth
        if isValid(data.descriptionNode) then m.alwaysActiveLabel.color = data.descriptionNode.textColor
        m.alwaysActiveLabel.font = m.OT_Data.fonts.description
      else
        m.OTConsentButtons.visible = true
        m.OTConsentButtons.itemSpacing = [0]
        cWidth = detailScreenWidth
        if data.id = "vendorsListItem"
          cWidth = cWidth / 2
          m.OTConsentButtons.itemSpacing = [m.style.detailScreen.itemSpacings]
        end if
        m.OTConsentButtons.width = cWidth
        m.OTConsentButtons.height = 0
        if m.OTConsentButtons.isScrollable then m.OTConsentButtons.height = m.detailScreenlayout.height
        m.OTConsentButtons.content = data.consentBtnNode
      end if
    end if

    if isValid(data.additionalBtnNode)
      m.OTAdditionalButtons.visible = true
      m.OTAdditionalButtons.itemSpacing = [m.style.detailScreen.itemSpacings]
      m.OTAdditionalButtons.width = detailScreenWidth / 2
      m.OTAdditionalButtons.content = data.additionalBtnNode
    end if

    if isValid(data.purposeChildBtnNode)
      m.childHeadingRec.visible = true
      m.OTPurposeChildButtons.visible = true
      m.childHeading.width = detailScreenWidth
      m.childHeading.color = data.childHeaderText.textColor
      m.childHeading.font = m.OT_Data.fonts.boldDescription
      m.childHeading.text = data.childHeaderText.text

      m.OTPurposeChildButtons.itemSpacing = [0]
      m.OTPurposeChildButtons.width = detailScreenWidth
      m.OTPurposeChildButtons.content = data.purposeChildBtnNode
    end if

    if data.viewType <> "sdkList" AND isValid(data.descriptionNode) AND (m.childHeadingRec.visible OR m.adtlDescriptionRec.visible)
      m.childDivider.visible = true
      m.childDivider.width = detailScreenWidth
      m.childDivider.color = data.descriptionNode.textColor
    end if

    if data.viewType <> "sdkList" AND isValid(data.descriptionNode) AND m.policyLinkRec.visible
      m.childDivider2.visible = true
      m.childDivider2.width = detailScreenWidth
      m.childDivider2.color = data.descriptionNode.textColor
    end if

    if m.OTAdditionalButtons.visible AND (m.descriptionRec.visible OR m.OTConsentButtons.visible OR m.alwaysActiveLabel.visible)
      m.additionalBtnDivider.visible = true
      m.additionalBtnDivider.width = detailScreenWidth
      m.additionalBtnDivider.color = data.descriptionNode.textColor
    end if

    Lcount = m.detailScreenlayoutScroll.getChildCount()
    for i = 0 to Lcount - 1
      childLabel = m.detailScreenlayoutScroll.getChild(i)
      if childLabel.visible
        detailScreenlayoutScrollItemSpacings[i] = m.style.detailScreen.paddinglabel
        childLabel.scale = [1, 1]
      end if
    end for
    m.detailScreenlayoutScroll.itemSpacings = detailScreenlayoutScrollItemSpacings
    if m.OTConsentButtons.isScrollable
      m.scrollThumb.scale = [0, 0]
      m.detailScreenlayoutScroll.itemSpacings = [0]
    end if

    if isValid(data.descriptionNode) then m.scrollThumb.color = data.descriptionNode.textColor
    m.scrollThumb.translation = [detailScreenWidth + m.style.scrollThumb.padding, 0]
  end if
end sub

Function setScrollHeight(data)
  node = data.getRoSGNode()
  m.top.scrollHeight = {
    key: node.key
    scrollHeight: data.getData()
  }
End Function

Function setCustomIllustrations(IabIllustrations, color, width)
  child = m.descriptionRec.getChild(0)
  if child <> invalid then m.descriptionRec.removeChild(child)
  fragment = m.getNode.layoutGroup("IabIllustration", "vert", [m.style.detailScreen.paddinglabel])
  m.descriptionRec.appendChild(fragment)
  if IabIllustrations <> invalid AND IabIllustrations.count() > 0
    Illsutrationcount = IabIllustrations.count() - 1
    for item = 0 to Illsutrationcount step 1
      label = m.getNode.label("IabIllustration_" + item.ToStr(), IabIllustrations[item], m.OT_Data.fonts.description, color, width)
      fragment.appendChild(label)
      if Illsutrationcount <> item
        horzLine = m.getNode.rectangle("horzLine", color, width, 1)
        horzLine.opacity = "0.5"
        fragment.appendChild(horzLine)
      end if
    end for
  end if
End Function

Function setDescription(id, description, color, width)
  child = m.descriptionRec.getChild(0)
  if child <> invalid then m.descriptionRec.removeChild(child)
  fragment = getMultistyleLabel(id, "detailDescription", description, color, width)
  m.descriptionRec.appendChild(fragment)
End Function

sub getQrCode(uri, lightColor, darkColor)
  child = m.descriptionRec.getChild(0)
  if child <> invalid then m.descriptionRec.removeChild(child)
  qrCode = CreateObject("roSGNode", "QRCode")
  qrCode.id = "vendorQrCode"
  qrCode.translation = [0, 0]
  qrCode.lightColor = lightColor
  qrCode.darkColor = darkColor
  qrCode.width = m.style.qrcodeUri.size
  qrCode.height = m.style.qrcodeUri.size
  qrCode.border = 0
  qrCode["audioGuideText"] = m.WCAGRoles.qrCodeAriaLabel.Replace("<X>", m.heading.text)
  qrCode.text = uri
  m.descriptionRec.appendChild(qrCode)
end sub

Function setMultistyleLabel()
  osVersion = getDeviceInfo("osVersion")
  m.ismultiStyleLabel = true
  if osVersion = invalid OR osVersion < 10.5 then m.ismultiStyleLabel = false
End Function

Function getMultistyleLabel(nodeId, id, description, color, width)
  descriptionLabel = getNode().label(id, description, m.OT_Data.fonts.description, color, width)
  if m.ismultiStyleLabel AND nodeId = "privacyItem"
    descriptionLabel = getNode().MultiStyleLabel(id, description, width)
    drawingStyles = {
      "b": {
        "fontUri": m.OT_Data.multiStyleFonts.boldDescription.fontUri,
        "fontSize": m.OT_Data.multiStyleFonts.boldDescription.fontSize,
        "color": color
      },
      "default": {
        "fontUri": m.OT_Data.multiStyleFonts.description.fontUri,
        "fontSize": m.OT_Data.multiStyleFonts.description.fontSize,
        "color": color
      }
    }
    descriptionLabel.drawingStyles = drawingStyles
  end if
  return descriptionLabel
End Function

Function setDsIdDetails(bannerModel, color, width)
  m.adtlDescriptionRec.visible = false
  if isValid(bannerModel.dsIdDetails)
    fragment = m.getNode.layoutGroup("dsIdDetails", "vert", [m.style.detailScreen.paddinglabel])
    if isString(bannerModel.dsIdDetails.titleText) then fragment.appendChild(m.getNode.label("titleText_Header", bannerModel.dsIdDetails.titleText, m.OT_Data.fonts.boldDescription, color, width))
    if isString(bannerModel.dsIdDetails.dsidText) then fragment.appendChild(m.getNode.label("dsidText", bannerModel.dsIdDetails.dsidText, m.OT_Data.fonts.description, color, width))
    if isString(bannerModel.dsIdDetails.timestampTitleText) then fragment.appendChild(m.getNode.label("timestampTitleText_Header", bannerModel.dsIdDetails.timestampTitleText, m.OT_Data.fonts.boldDescription, color, width))
    fragment.appendChild(m.getNode.label("notYetConsentedText", getTimestampFormate(bannerModel.dsIdDetails.notYetConsentedText), m.OT_Data.fonts.description, color, width))
    if isString(bannerModel.dsIdDetails.descriptionText) then fragment.appendChild(m.getNode.label("descriptionText", bannerModel.dsIdDetails.descriptionText, m.OT_Data.fonts.description, color, width))
    if fragment.getChildCount() > 0
      m.adtlDescriptionRec.visible = true
      m.adtlDescriptionRec.appendChild(fragment)
    end if
  end if
End Function

Function getTimestampFormate(notYetConsentedText)
  timeStamp = ""
  try
    OT_LastConsentedDate = m.registry.read("OT_LastConsentedDate")
    if isString(OT_LastConsentedDate)
      dateTime = CreateObject("roDateTime")
      dateTime.fromISO8601String(OT_LastConsentedDate)
      dateTime.ToLocalTime()
      timeStamp = dateTime.GetYear().ToStr() + "-" + dateTime.GetMonth().ToStr() + "-" + dateTime.GetDayOfMonth().ToStr() + " " + dateTime.GetHours().ToStr() + ":" + dateTime.GetMinutes().ToStr() + ":" + dateTime.GetSeconds().ToStr()
    else if isString(notYetConsentedText)
      timeStamp = notYetConsentedText
    end if
  catch e
    timeStamp = ""
    print "Error: " e
  end try
  return timeStamp
End Function

Function setpolicyLinkQrcode(bannerModel, width)
  m.policyLinkText.visible = false
  if isValid(bannerModel.policyLink)
    m.policyLinkRec.visible = true
    m.policyLinkText.visible = true
    m.policyLinkText.font = m.OT_Data.fonts.description
    m.policyLinkText.text = bannerModel.policyLink.text
    m.policyLinkText.width = width
    m.policyLinkText.color = bannerModel.policyLink.textColor
    m.qrCodeImg.loadHeight = m.style.qrcode.width
    m.qrCodeImg.loadWidth = m.style.qrcode.height
    m.qrCodeImg.width = m.qrCodeImg.loadHeight
    m.qrCodeImg.height = m.qrCodeImg.loadWidth
    m.qrCodeImg.uri = bannerModel.policyLink.url
    m.qrCodeImg["audioGuideText"] = m.WCAGRoles.qrCodeAriaLabel.Replace("<X>", m.policyLinkText.text)
    m.qrCodeImg.blendColor = bannerModel.policyLink.textColor
    if isValid(bannerModel.descriptionNode) AND bannerModel.descriptionNode.textColor <> invalid
      m.policyLinkText.color = bannerModel.descriptionNode.textColor
      m.qrCodeImg.blendColor = bannerModel.descriptionNode.textColor
    end if
  end if
End Function

Function getVendorDescriptions(vendor, color, width, node)
  m.data = m.top.data
  m.detailScreenWidth = width
  child = node.getChild(0)
  if child <> invalid then node.removeChild(child)
  fragment = m.getNode.layoutGroup("fragment", "vert", [30])
  node.appendChild(fragment)
  url = optionalChaining(vendor, "deviceStorageDisclosureUrl")
  dataRetentionPurpose = {}
  dataRetentionSP = {}
  ' sdk description
  if vendor <> invalid AND m.data.viewType = "sdkList" AND vendor.description <> invalid AND vendor.description <> "" then fragment.appendChild(m.getNode.label("description", vendor.description, m.OT_Data.fonts.description, color, width))

  ' iab description
  if vendor <> invalid AND (vendor.cookieMaxAgeSeconds <> invalid OR m.data.viewType = "iab") then fragment = setDisclosuresLayout(fragment, "cookieMaxAgeSeconds", m.data.lifespan + ": ", calculateCookieLifespan(vendor.cookieMaxAgeSeconds), color, width * 0.3, width * 0.7, m.OT_Data.fonts.boldDescription)

  if vendor <> invalid AND m.data.viewType = "iab" AND optionalChaining(m.data, "nonCookieUsageText") <> invalid AND m.data.nonCookieUsageText <> "" then fragment.appendChild(m.getNode.label("usesNonCookieAccess", m.data.nonCookieUsageText, m.OT_Data.fonts.description, color, width))

  if vendor <> invalid AND vendor.dataDeclaration <> invalid AND vendor.dataDeclaration.count() > 0 then fragment = setDisclosuresLayout(fragment, "iabDataCategories", m.data.dataDeclarationText, vendor.dataDeclaration, color, width, width, m.OT_Data.fonts.boldDescription, "vert")

  if vendor <> invalid AND vendor.dataRetention <> invalid then fragment = setDisclosuresLayout(fragment, "dataRetention", m.data.dataRetentionText, vendor.dataRetention, color, width, width, m.OT_Data.fonts.boldDescription, "vert")

  if vendor <> invalid AND optionalChaining(vendor.dataRetention, "purposes") <> invalid then dataRetentionPurpose = vendor.dataRetention.purposes
  if vendor <> invalid AND vendor.purposes <> invalid AND vendor.purposes.count() > 0 then fragment = setDisclosuresLayout(fragment, "purposes", m.data.consentPurposes, vendor.purposes, color, width, width, m.OT_Data.fonts.boldDescription, "vert", dataRetentionPurpose)

  if vendor <> invalid AND optionalChaining(vendor.dataRetention, "specialPurposes") <> invalid then dataRetentionSP = vendor.dataRetention.specialPurposes
  if vendor <> invalid AND vendor.specialPurposes <> invalid AND vendor.specialPurposes.count() > 0 then fragment = setDisclosuresLayout(fragment, "specialPurposes", m.data.specialPurposes, vendor.specialPurposes, color, width, width, m.OT_Data.fonts.boldDescription, "vert", dataRetentionSP)

  if vendor <> invalid AND vendor.legIntPurposes <> invalid AND vendor.legIntPurposes.count() > 0 then fragment = setDisclosuresLayout(fragment, "purposes", m.data.legitimateInterestPurposesText, vendor.legIntPurposes, color, width, width, m.OT_Data.fonts.boldDescription, "vert", dataRetentionPurpose)

  if vendor <> invalid AND vendor.features <> invalid AND vendor.features.count() > 0 then fragment = setDisclosuresLayout(fragment, "features", m.data.features, vendor.features, color, width, width, m.OT_Data.fonts.boldDescription, "vert")

  if vendor <> invalid AND vendor.specialFeatures <> invalid AND vendor.specialFeatures.count() > 0 then fragment = setDisclosuresLayout(fragment, "specialFeatures", m.data.specialFeatures, vendor.specialFeatures, color, width, width, m.OT_Data.fonts.boldDescription, "vert")

  if url <> invalid AND url <> ""
    url = url.Trim()
    m.disclosureIndex = fragment.getChildCount()
    m.disclosureUrl = url
    if m.deviceStorageDisclosureData.doesExist(url)
      parseDeviceStorageDisclosureData({ url: url, response: m.deviceStorageDisclosureData[url] })
    else
      getDeviceStorageDisclosureData(url)
    end if
  end if
  if isValid(fragment) AND fragment.getChildCount() > 0 then m.adtlDescriptionRec.visible = true
  return fragment
End Function

Function getDeviceStorageDisclosureData(url as Dynamic)
  createTaskPromise("OTNetworkTask", {
    method: "GET",
    name: url,
    headers: {
      "Content-Type": "application/json",
      "Accept": "*/*",
    },
    functionName: "fetchGetApi",
  }, true, "response").then(sub(data)
    if isValid(data) then parseDeviceStorageDisclosureData(data)
  end sub)
End Function

Function taskCompleted()
  if m.initializeNetwork <> invalid
    m.initializeNetwork.unobserveField("taskCompleted")
    m.initializeNetwork.unobserveField("response")
    m.initializeNetwork.control = "STOP"
    m.initializeNetwork = invalid
  end if
End Function

Function parseDeviceStorageDisclosureData(data as Object)
  try
    if type(data) = "roSGNodeEvent" then data = data.getData()
    if m.disclosureUrl = data.url
      m.deviceStorageDisclosureData[data.url] = data.response
      data = data.response
    else
      data = invalid
    end if
    if data <> invalid AND ((data.disclosures <> invalid AND data.disclosures.count() > 0) OR (data.domains <> invalid AND data.domains.count() > 0))
      deviceStorageDisclosure = getNode().layoutGroup("deviceStorageDisclosure", "vert", [20, 30, 20])
      fragment = m.adtlDescriptionRec.getChild(0)
      if fragment <> invalid AND fragment.getChildCount() > 0
        for i = 0 to fragment.getChildCount() - 1
          child = fragment.getChild(i)
          if child.id <> invalid AND child.id = "deviceStorageDisclosure"
            fragment.removeChild(child)
            exit for
          end if
        end for
        fragment.insertChild(deviceStorageDisclosure, m.disclosureIndex)
      end if
    end if
    color = ""
    if isValid(m.data.descriptionNode) then color = m.data.descriptionNode.textColor
    width = m.detailScreenWidth
    if data <> invalid AND data.disclosures <> invalid AND data.disclosures.count() > 0
      VendorListDisclosureLabel = getNode().label("VendorListDisclosureLabel_Header", m.data.disclosureTitle, m.OT_Data.fonts.boldDescription, color, width)
      deviceStorageDisclosure.appendChild(VendorListDisclosureLabel)
      VendorListDisclosureLayoutGroup = getNode().layoutGroup("VendorListDisclosureLayoutGroup", "vert", [20])
      if isArray(data.disclosures)
        for each disclosure in data.disclosures
          VendorListDisclosureinnerLayoutGroup = getNode().layoutGroup("VendorListDisclosureinnerLayoutGroup")
          identifier = ""
          if disclosure <> invalid AND disclosure.identifier <> invalid then identifier = disclosure.identifier
          if disclosure <> invalid AND disclosure.name <> invalid then identifier = disclosure.name
          if identifier <> invalid then VendorListDisclosureinnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureinnerLayoutGroup, "identifier_Sub", m.data.storageIdentifierText + ": ", identifier, color, width * 0.3, width * 0.7)
          if disclosure <> invalid AND disclosure.type <> invalid then VendorListDisclosureinnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureinnerLayoutGroup, "storageType_Sub", m.data.storageIdentifierType + ": ", disclosure.type, color, width * 0.3, width * 0.7)
          if disclosure <> invalid then VendorListDisclosureinnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureinnerLayoutGroup, "lifeSpan_Sub", m.data.lifespanDay + ": ", calculateCookieLifespan(disclosure.maxAgeSeconds), color, width * 0.3, width * 0.7)
          if disclosure <> invalid AND disclosure.domain <> invalid AND (type(disclosure.domain) = "roString" OR type(disclosure.domain) = "String") then VendorListDisclosureinnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureinnerLayoutGroup, "domain_Sub", m.data.storageDomain + ": ", disclosure.domain, color, width * 0.3, width * 0.7)
          if disclosure <> invalid AND disclosure.purposes <> invalid AND type(disclosure.purposes) = "roArray" AND disclosure.purposes.count() > 0 then VendorListDisclosureinnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureinnerLayoutGroup, "purposes_Sub", m.data.storagePurposes + ": ", disclosure.purposes, color, width * 0.3, width * 0.7)
          VendorListDisclosureLayoutGroup.appendChild(VendorListDisclosureinnerLayoutGroup)
        end for
      end if
      deviceStorageDisclosure.scale = [1, 1]
      deviceStorageDisclosure.appendChild(VendorListDisclosureLayoutGroup)
    end if
  catch e
    m.logger.error(e)
  end try
  parseDeviceStorageDisclosureDomainData(data, deviceStorageDisclosure, color, width)
  m.top.updateScroll = true
End Function

Function parseDeviceStorageDisclosureDomainData(data, deviceStorageDisclosure, color, width)
  if data <> invalid AND data.domains <> invalid AND data.domains.count() > 0
    VendorListDisclosureDomainLabel = getNode().label("VendorListDisclosureDomainLabel_Header", m.data.domainsUsed, m.OT_Data.fonts.boldDescription, color, width)
    deviceStorageDisclosure.appendChild(VendorListDisclosureDomainLabel)
    VendorListDisclosureDomainLayoutGroup = getNode().layoutGroup("VendorListDisclosureDomainLayoutGroup", "vert", [20])

    for each disclosure in data.domains
      VendorListDisclosureDomaininnerLayoutGroup = getNode().layoutGroup("VendorListDisclosureDomaininnerLayoutGroup")
      if disclosure <> invalid AND type(disclosure) = "roAssociativeArray" AND disclosure.domain <> invalid then VendorListDisclosureDomaininnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureDomaininnerLayoutGroup, "domain_Sub", m.data.storageDomain + ": ", disclosure.domain, color, width * 0.3, width * 0.7)
      if disclosure <> invalid AND type(disclosure) = "roAssociativeArray" AND disclosure.use <> invalid then VendorListDisclosureDomaininnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureDomaininnerLayoutGroup, "use_Sub", m.data.domainUse + ": ", disclosure.use, color, width * 0.3, width * 0.7)
      VendorListDisclosureDomainLayoutGroup.appendChild(VendorListDisclosureDomaininnerLayoutGroup)
    end for

    deviceStorageDisclosure.appendChild(VendorListDisclosureDomainLayoutGroup)
  end if
End Function

Function calculateCookieLifespan(maxSeconds, inDays = false as Boolean)
  if maxSeconds <> invalid AND (type(maxSeconds) = "roString" OR type(maxSeconds) = "String") then maxSeconds = maxSeconds.ToInt()
  VendorListLifespanDay = m.data.lifespanDay
  VendorListLifespanDays = m.data.lifespanDays
  VendorListLifespanMonth = m.data.lifespanMonth
  VendorListLifespanMonths = m.data.lifespanMonths

  if maxSeconds = invalid OR maxSeconds <= 0 then return "0" + " " + VendorListLifespanDays
  finalString = ""
  if inDays
    days = maxSeconds
    if days >= 2 then finalString = days.toStr() + " " + VendorListLifespanDays
    if days = 1 then finalString = days.toStr() + " " + VendorListLifespanDay
  else
    months = Fix(maxSeconds / m.LifeSpanDuration.SECOND_DIVIDER)
    remainderMonths = maxSeconds mod m.LifeSpanDuration.SECOND_DIVIDER
    days = Fix(remainderMonths / m.LifeSpanDuration.MONTH_DIVIDER)
    if days = 30
      months = months + 1
      days = 0
    end if
    if months >= 2 then finalString = months.toStr() + " " + VendorListLifespanMonths
    if months = 1 then finalString = months.toStr() + " " + VendorListLifespanMonth
    if days >= 2 then finalString += " " + days.toStr() + " " + VendorListLifespanDays
    if days = 1 then finalString += " " + days.toStr() + " " + VendorListLifespanDay
    if months = 0 AND days = 0 then finalString = days.toStr() + " " + VendorListLifespanDays
  end if

  return finalString
End Function

Function setDisclosuresLayout(node, id, header, value, color, headerW, valueW, font = "font:SmallestSystemFont", direction = "horiz", dataRetention = invalid)
  disclosuresLayoutGroup = m.getNode.layoutGroup(id + "LayoutGroup", direction)
  disclosuresHeader = m.getNode.label(id + "_Header", header, font, color, headerW)
  if id = "purposes_Sub" then id = "purposes"
  if id = "purposes" OR id = "features" OR id = "specialPurposes" OR id = "specialFeatures" OR id = "iabDataCategories" OR id = "dataRetention"
    disclosuresValue = setlistLayout(id, value, color, valueW, dataRetention)
  else
    disclosuresValue = m.getNode.label(id, value, m.OT_Data.fonts.description, color, valueW)
  end if
  disclosuresLayoutGroup.appendChild(disclosuresHeader)
  disclosuresLayoutGroup.appendChild(disclosuresValue)
  node.appendChild(disclosuresLayoutGroup)
  return node
End Function

Function setlistLayout(id, list, color, width, dataRetention)
  innerLayoutGroup = m.getNode.layoutGroup(id + "InnerLayoutGroup")
  iabGrps = m.data.iabGroups
  if id = "iabDataCategories"
    if m.data.IABDataCategories <> invalid
      iabGrps = { "IABDataCategories": m.data.IABDataCategories }
    else
      iabGrps = { "IABDataCategories": {} }
    end if
  end if
  if id = "dataRetention"
    if list <> invalid AND list.stdRetention <> invalid AND optionalChaining(m.data, "dataStdRetentionText") <> invalid
      text = m.data.dataStdRetentionText + " (" + calculateCookieLifespan(list.stdRetention, true) + ")"
      listNode = m.getNode.label(id + "_" + "stdRetention", text, m.OT_Data.fonts.description, color, width)
      innerLayoutGroup.appendChild(listNode)
    end if
  else if list <> invalid AND list.count() > 0
    for each l in list
      text = ""
      if iabGrps <> invalid AND iabGrps[id] <> invalid AND iabGrps[id][l.toStr()] <> invalid then text = iabGrps[id][l.toStr()]
      if optionalChaining(text, "name") <> invalid then text = text["name"]
      if text <> invalid AND text <> ""
        if (id = "purposes" OR id = "specialPurposes") AND dataRetention <> invalid AND dataRetention[l.toStr()] <> invalid
          text += " (" + calculateCookieLifespan(dataRetention[l.toStr()], true) + ")"
        end if
        listLayoutGroup = m.getNode.layoutGroup(id + "listLayoutGroup", "horiz", [m.style.listItem.padding])
        listNode = m.getNode.label(id + "_" + l.toStr(), text, m.OT_Data.fonts.description, color, width)
        bulletNode = m.getNode.label(id + "_bullet", Chr(8226), "font:SmallestSystemFont", color, m.style.listItem.bulletWidth)
        listLayoutGroup.appendChild(bulletNode)
        listLayoutGroup.appendChild(listNode)
        innerLayoutGroup.appendChild(listLayoutGroup)
      end if
    end for
  end if
  return innerLayoutGroup
End Function

sub onSlide()
  m.OTslideOverlay.visible = not m.top.slide
  m.OTSlideAnimationInterpolator.reverse = m.top.slide
  m.OTSlideAnimation.control = "start"
end sub

sub onItemFocused(data as Object)
  data = data.getRoSGNode()
  itemFocused = data.itemFocused
  item = data.content.getChild(itemFocused)
  say(item.text, m.WCAGRoles.button, m.WCAGRoles.selectedAriaLabel, true)
end sub

