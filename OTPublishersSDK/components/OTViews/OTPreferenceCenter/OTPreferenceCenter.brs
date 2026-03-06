' OneTrust SDK Banner
sub init()
  try
    m.style = style()
    m.errortype = getErrorType()
    m.errorTags = getErrorTags()
    m.logger = logUtil()
    m.registry = RegistryUtil()
    m.constant = applicationConstants()
    m.navConstant = getNavigationConstants()
    m.WCAGRoles = CreateObject("roSGNode", "OTWCAGInterface")

    screenSize = m.global.screenSize
    m.width = 1920
    m.height = 1080
    if isValid(screenSize)
      if isValid(screenSize.w) then m.width = screenSize.w
      if isValid(screenSize.h) then m.height = screenSize.h
    end if

    m.poweredLogo = m.top.findNode("poweredLogo")
    m.poweredLogo.translation = [m.width - m.poweredLogo.width - m.style.containerPadding, m.height - m.poweredLogo.height - (m.style.containerPaddingTop / 2)]

    m.container = m.top.findNode("container")
    m.container.width = screenSize.w
    m.container.height = screenSize.h

    m.innerContainer = m.top.findNode("innerContainer")
    m.style.setPadding(m.innerContainer, [m.style.containerPadding, m.style.containerPaddingTop, m.style.containerPaddingTop, m.style.containerPadding], m.container.width, m.container.height)

    m.OTBannerHeader = m.top.findNode("OTBannerHeader")
    m.OTBannerFooter = m.top.findNode("OTBannerFooter")
    m.OTPCListView = m.top.findNode("OTPCListView")
    m.OTPCListView.observeField("itemFocused", "onItemFocused")
    m.OTListGridview = m.OTPCListView.findNode("OTListGridview")
    m.buttonList = m.OTBannerFooter.findNode("buttonList")
    m.closetextList = m.OTBannerHeader.findNode("closetextList")
    m.mainBackButton = m.OTBannerHeader.findNode("backbutton")
    m.headerText = m.OTBannerHeader.findNode("headerText")
    m.OT_Data = m.global.OT_Data

    m.OTPCDetailScreenView = m.top.findNode("OTPCDetailScreenView")
    m.OTPCChildDetailScreenView = m.top.findNode("OTPCChildDetailScreenView")
    m.OTPCDetailScreenView.observeField("scrollHeight", "setScrollHeight")
    m.OTPCChildDetailScreenView.observeField("scrollHeight", "setScrollHeight")
    m.contentContainer = m.top.findNode("contentContainer")
    setOTPCDetailScreenView(m.OTPCDetailScreenView)

    m.lastTranslation = [0, 0]
    m.lastThumbTranslation = [0, 0]

    m.scrollTimer = CreateObject("roSGNode", "Timer")
    m.top.slideLayer = 0
    m.top.childData = []
    m.childData = []
    m.roAudioGuide = CreateObject("roAudioGuide")
  catch e
    ? "Error in OTPreferenceCenter init: " + e.message
  end try
end sub

sub isChildScreen()
  OTPCDetailScreenView = m.OTPCDetailScreenView
  if m.top.isChildScreen then OTPCDetailScreenView = m.OTPCChildDetailScreenView
  setOTPCDetailScreenView(OTPCDetailScreenView)
end sub

sub setOTPCDetailScreenView(OTPCDetailScreenView)
  try
    if isValid(OTPCDetailScreenView)
      m.descriptionRec = OTPCDetailScreenView.findNode("descriptionRec")
      m.adtlDescriptionRec = OTPCDetailScreenView.findNode("adtlDescriptionRec")
      m.heading = OTPCDetailScreenView.findNode("heading")
      m.childHeading = OTPCDetailScreenView.findNode("childHeading")
      m.headerLayout = OTPCDetailScreenView.findNode("headerLayout")
      m.alwaysActiveLabel = OTPCDetailScreenView.findNode("alwaysActiveLabel")
      m.policyLinkText = OTPCDetailScreenView.findNode("policyLinkText")
      m.qrCodeImg = OTPCDetailScreenView.findNode("qrCodeImg")
      m.OTPurposeChildButtons = m.OTPCDetailScreenView.findNode("OTPurposeChildButtons")
      m.detailScreenlayout = OTPCDetailScreenView.findNode("detailScreenlayout")
      m.detailScreenlayoutScroll = OTPCDetailScreenView.findNode("detailScreenlayoutScroll")
      m.scrollThumb = OTPCDetailScreenView.findNode("scrollThumb")
      m.backButton = OTPCDetailScreenView.findNode("backButton")
      m.OTConsentButtons = OTPCDetailScreenView.findNode("OTConsentButtons")
      m.OTAdditionalButtons = OTPCDetailScreenView.findNode("OTAdditionalButtons")
      ScrollInitialize(m, m.detailScreenlayout, m.detailScreenlayoutScroll)

      m.gridScrollAnimation = OTPCDetailScreenView.findNode("gridScrollAnimation")
      m.gridScrollAnimationInterpolator = OTPCDetailScreenView.findNode("gridScrollAnimationInterpolator")
      m.gridScrollThumbAnimation = OTPCDetailScreenView.findNode("gridScrollThumbAnimation")
      m.gridScrollThumbAnimationInterpolator = OTPCDetailScreenView.findNode("gridScrollThumbAnimationInterpolator")
    end if
  catch e
    ? "Error in setOTPCDetailScreenView: " + e.message
  end try
end sub

Function onChangeData()
  try
    m.OTinitialize = m.top.OTinitialize
    m.dataModel = getPreferenceCenterModelData(m.top.data, m.innerContainer.width)
    if m.dataModel <> invalid AND isValid(m.OTinitialize)
      if isValid(m.global.OT_Data) AND isValid(m.global.OT_Data["WCAGRoles"]) then m.WCAGRoles = m.global.OT_Data["WCAGRoles"]
      m.innerContainer.color = m.dataModel.backgroundColor
      m.container.color = m.dataModel.backgroundColor
      m.contentContainer.color = m.dataModel.backgroundColor

      m.OTBannerHeader.OTinitialize = m.OTinitialize
      m.dataModel.Hwidth = m.innerContainer.width
      m.dataModel.Hheight = m.innerContainer.height
      m.OTBannerHeader.isMainback = m.top.bannerExits
      m.OTBannerHeader.bannerExits = m.top.bannerExits
      m.OTBannerHeader.data = m.dataModel.clone(true)
      m.dataModel.width = m.dataModel.ratio[2] * m.innerContainer.width
      m.dataModel.height = m.innerContainer.height
      m.OTBannerFooter.OTinitialize = m.OTinitialize
      m.OTBannerFooter.data = m.dataModel.clone(true)
      m.OTBannerFooter.translation = [(m.dataModel.ratio[0] + m.dataModel.ratio[1]) * m.innerContainer.width, m.OTBannerHeader.height]
      m.dataModel.width = m.innerContainer.width
      'm.contentContainer.width = m.innerContainer.width
      m.contentContainer.height = m.innerContainer.height - m.OTBannerHeader.height
      m.contentContainer.translation = [0, m.OTBannerHeader.height]

      m.OTPCListView.OTinitialize = m.OTinitialize
      if isValid(m.dataModel.OTListView)
        m.dataModel.OTListView = m.dataModel.OTListView.clone(true)
        m.dataModel.OTListView.height = m.contentContainer.height
        m.OTPCListView.data = m.dataModel.OTListView
      end if
      updateDetailScreen(m.OTPCListView.data.listContentNode.getChild(0))
      createResolvedPromise(m.OTListGridview).then(sub(fire)
        if isValid(fire) then m.OTListGridview.setFocus(true)
        setTextToSpeech()
      end sub)
      setIsBannerShownStatus(1)
      eventListeners(m.OTinitialize.top.eventlistener, m.constant.listener["ELP115"])
    end if
  catch e
    ? "Error in setOTPCDetailScreenView: " + e.message
  end try
End Function

sub setTextToSpeech()
  if isValid(m.roAudioGuide) AND isValid(m.WCAGRoles)
    m.roAudioGuide.Flush()
    sayText(m.headerText, m.WCAGRoles.headingAriaLabel)
    saySelected(m.OTListGridview, m.WCAGRoles.listAriaLabel)
    setTextToSpeechDetailScreen()
  end if
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
  try
    currentPath = [0, 1]
    visiblePath = [0, 1]
    previousPath = [1, 1]
    if m.navDirections <> invalid AND m.navDirections.key <> invalid
      currentPath = m.navDirections.key
      visiblePath = m.navDirections.visiblePath
      previousPath = m.navDirections.previousPath
    end if

    OTConsentButtons = { key: m.navConstant.scrollTextButton: value: m.OTConsentButtons, skipSameNode: false, allowPreviousPath: true }
    OTAdditionalButtons = { key: m.navConstant.scrollTextButton: value: m.OTAdditionalButtons, skipSameNode: false, allowPreviousPath: true }
    OTPurposeChildButtons = { key: m.navConstant.scrollTextButton: value: m.OTPurposeChildButtons, skipSameNode: false, allowPreviousPath: true }
    detailScreenlayoutScroll = { key: m.navConstant.scrollTextButton: value: m.detailScreenlayoutScroll, skipSameNode: true, allowPreviousPath: true }

    isslideOpen = m.backButton <> invalid AND m.backButton.visible AND isValid(m.backButton.content)
    if not ((isValid(m.OTConsentButtons) AND m.OTConsentButtons.visible) OR (isValid(m.OTAdditionalButtons) AND m.OTAdditionalButtons.visible) OR (isValid(m.OTPurposeChildButtons) AND m.OTPurposeChildButtons.visible AND not isslideOpen))
      OTConsentButtons = detailScreenlayoutScroll
      OTAdditionalButtons = detailScreenlayoutScroll
      OTPurposeChildButtons = detailScreenlayoutScroll
    end if

    descriptionRedirectPath = [1, 1]
    if (isValid(m.OTPurposeChildButtons) AND m.OTPurposeChildButtons.visible)
      descriptionRedirectPath = [1, 3]
    end if
    if (isValid(m.OTAdditionalButtons) AND m.OTAdditionalButtons.visible)
      descriptionRedirectPath = [1, 2]
    end if
    if (isValid(m.OTConsentButtons) AND m.OTConsentButtons.visible)
      descriptionRedirectPath = [1, 1]
    end if

    if isslideOpen then descriptionRedirectPath = [0, descriptionRedirectPath[1]]

    'closeNode2 = { key: m.navConstant.button, value: m.closetextList, skipSameNode: false, redirect: {left: [0, 0]}, down: [2, 1]}
    closeNode = { key: m.navConstant.button, value: m.closetextList, skipSameNode: true, redirect: { left: [0, 0], down: [2, 1] } }
    footerButtonNode = { key: m.navConstant.button, value: m.buttonList, skipSameNode: true, accecptPreviousPath: true, jumptoItem: 0 }
    OTPCListView = { key: m.navConstant.button, value: m.OTListGridview, skipSameNode: true, resetScroll: true, redirect: { right: descriptionRedirectPath } }

    mainBackButton = closeNode
    if isValid(m.mainBackButton) AND m.mainBackButton.visible
      mainBackButton = { key: m.navConstant.button, value: m.mainBackButton, skipSameNode: true, redirect: { right: [2, 0], down: [0, 1] } }
      if not (isValid(m.closetextList) AND m.closetextList.visible) then closeNode = mainBackButton
    end if

    value = [
      [
        mainBackButton,
        OTPCListView,
        OTPCListView,
        OTPCListView
      ],
      [
        mainBackButton,
        OTConsentButtons,
        OTAdditionalButtons,
        OTPurposeChildButtons

      ],
      [
        closeNode,
        footerButtonNode,
        footerButtonNode,
        footerButtonNode
      ]

    ]
    if isslideOpen
      backButton = { key: m.navConstant.button, value: m.backButton, skipSameNode: false, redirect: { down: descriptionRedirectPath } }
      value = [
        [
          backButton,
          OTConsentButtons,
          OTAdditionalButtons
        ]
      ]
    end if

    m.navDirections = {
      key: currentPath,
      visiblePath: visiblePath,
      previousPath: previousPath,
      scrollValue: m.detailScreenlayoutScroll
      resetValues: [
        OTConsentButtons,
        OTAdditionalButtons,
        OTPurposeChildButtons
      ],
    value: value }
    return navigation1(key, press)
  catch e
    ? "Error in onKeyEvent: " + e.message
    return false
  end try
End Function

Function onItemFocused(data)
  try
    data = data.getRoSGNode()
    if isValid(data)
      data = data.itemFocused
      if isValid(data) then updateDetailScreen(data)
      saySelected(m.OTListGridview, m.WCAGRoles.listAriaLabel, true)
      setTextToSpeechDetailScreen()
    end if
  catch e
    ? "Error in onItemFocused: " + e.message
  end try
End Function

Function setScrollHeight(data)
  data = data.getData()
  if isValid(data)
    m.key = data.key
    if m.scrollThumb <> invalid AND m.scrollThumb.visible then scrollAnimation(data.scrollHeight)
  end if
End Function

Function setViewFocus(message as Object)
  try
    if message <> invalid
      if isValid(m.OTAdditionalButtons) AND m.OTAdditionalButtons.visible
        data = m.OTAdditionalButtons.content.getChild(m.OTAdditionalButtons.itemFocused)
        if isValid(data) AND isValid(m.WCAGRoles) then say(data.text, m.WCAGRoles.button, m.WCAGRoles.selectedAriaLabel, true)
        if isValid(data) AND data.id = "sdkListTextBtn"
          if isValid(m.OTListGridview) then data = m.OTListGridview.content.getChild(m.OTListGridview.itemFocused)
          if m.top.isChildScreen AND isValid(m.OTPurposeChildButtons) then data = m.OTPurposeChildButtons.content.getChild(m.OTPurposeChildButtons.itemFocused)
          if isValid(data)
            detailScreenViewNode = getDetailScreenViewNode(data.purposeItem, m.dataModel, m.contentContainer.height, data)
            if isValid(m.OTConsentButtons) AND m.OTConsentButtons.visible AND isValid(detailScreenViewNode) AND isValid(detailScreenViewNode.consentBtnNode) then m.OTConsentButtons.content = detailScreenViewNode.consentBtnNode
            if isValid(m.OTPurposeChildButtons) AND m.OTPurposeChildButtons.visible AND isValid(detailScreenViewNode) AND isValid(detailScreenViewNode.purposeChildBtnNode) then m.OTPurposeChildButtons.content = detailScreenViewNode.purposeChildBtnNode
          end if
        end if
        m.OTAdditionalButtons.setFocus(true)
      else if isValid(m.OTConsentButtons) AND m.OTConsentButtons.visible
        data = m.OTConsentButtons.content.getChild(m.OTConsentButtons.itemFocused)
        if isValid(data) AND isValid(m.WCAGRoles) then say(data.text, m.WCAGRoles.button, m.WCAGRoles.selectedAriaLabel, true)
        m.OTConsentButtons.setFocus(true)
      end if
    end if
  catch e
    ? "Error in setViewFocus: " + e.message
  end try
End Function
