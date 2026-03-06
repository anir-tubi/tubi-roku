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
    m.closetextList = m.OTBannerHeader.findNode("closetextList")
    m.mainBackButton = m.OTBannerHeader.findNode("backbutton")
    m.headerText = m.OTBannerHeader.findNode("headerText")

    m.OTBannerFooter = m.top.findNode("OTBannerFooter")
    m.OTPCListView = m.top.findNode("OTPCListView")
    m.OTPCListView.observeField("itemFocused", "onItemFocused")
    m.OTListGridview = m.OTPCListView.findNode("OTListGridview")
    m.searchNoResultsFoundText = m.OTPCListView.findNode("searchNoResultsFoundText")
    m.buttonList = m.OTBannerFooter.findNode("buttonList")
    m.buttonList.observeField("itemSelected", "onItemSelected")

    m.filterListView = m.top.findNode("filterListView")
    m.filterListView.observeField("itemFocused", "onFilterItemFocused")
    m.filterListView.observeField("itemSelected", "onFilterItemSelection")

    m.OTPCDetailScreenView = m.top.findNode("OTPCDetailScreenView")
    m.OTPCChildDetailScreenView = m.top.findNode("OTPCChildDetailScreenView")
    m.filterButtonList = m.OTPCChildDetailScreenView.findNode("filterButtonList")
    m.filterButtonList.observeField("itemSelected", "onfilterButtonListSelection")
    m.OTPCDetailScreenView.observeField("scrollHeight", "setScrollHeight")
    m.OTPCDetailScreenView.observeField("updateScroll", "updateScroll")
    m.OTPCChildDetailScreenView.observeField("scrollHeight", "setScrollHeight")
    m.OTPCChildDetailScreenView.observeField("updateScroll", "updateScroll")
    setOTPCDetailScreenView(m.OTPCDetailScreenView)

    m.contentContainer = m.top.findNode("contentContainer")

    m.OT_Data = m.global.OT_Data

    m.lastTranslation = [0, 0]
    m.lastThumbTranslation = [0, 0]

    m.scrollTimer = CreateObject("roSGNode", "Timer")
    m.filteredListId = {}
    m.top.slideLayer = 0
    m.top.childData = []
    m.childData = []
    m.roAudioGuide = CreateObject("roAudioGuide")
  catch e
    ? "Error in OTVendorList init: " + e.message
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
      m.alwaysActiveLabel = OTPCDetailScreenView.findNode("alwaysActiveLabel")
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
    if isValid(m.OTinitialize) then m.consentData = m.OTinitialize.consentData
    m.dataModel = getVendorListModelData(m.top.data, m.innerContainer.width)
    m.filterListView.scale = [0, 0]
    m.filterListView.visible = false
    if m.dataModel <> invalid AND isValid(m.OTinitialize)
      if isValid(m.global.OT_Data) AND isValid(m.global.OT_Data["WCAGRoles"]) then m.WCAGRoles = m.global.OT_Data["WCAGRoles"]
      if isValid(m.dataModel.sdkListGroupData) then m.sdkListGroupData = m.dataModel.sdkListGroupData
      if isValid(m.top.selectedFilteredData) AND m.top.selectedFilteredData.count() > 0 then m.filteredListId = m.top.selectedFilteredData
      m.innerContainer.color = m.dataModel.backgroundColor
      m.container.color = m.dataModel.backgroundColor
      m.contentContainer.color = m.dataModel.backgroundColor

      m.OTBannerHeader.OTinitialize = m.OTinitialize
      m.dataModel.Hwidth = m.innerContainer.width
      m.dataModel.Hheight = m.innerContainer.height
      pageHeaderTitle = m.dataModel.pageHeaderSDKListTitle
      if m.top.viewType <> "sdkList" then pageHeaderTitle = m.dataModel.pageHeaderVendorTitle
      m.dataModel.pageHeaderTitle = pageHeaderTitle
      m.OTBannerHeader.viewType = m.top.viewType
      m.OTBannerHeader.bannerExits = m.top.bannerExits
      m.OTBannerHeader.data = m.dataModel.clone(true)
      m.dataModel.width = m.dataModel.ratio[2] * m.innerContainer.width
      m.dataModel.height = m.innerContainer.height

      m.OTBannerFooter.OTinitialize = m.OTinitialize
      m.OTBannerFooter.viewType = m.top.viewType
      m.OTBannerFooter.data = m.dataModel.clone(true)
      m.OTBannerFooter.translation = [(m.dataModel.ratio[0] + m.dataModel.ratio[1]) * m.innerContainer.width, m.OTBannerHeader.height]
      m.dataModel.width = m.innerContainer.width
      'm.contentContainer.width = m.innerContainer.width
      m.contentContainer.height = m.innerContainer.height - m.OTBannerHeader.height
      m.contentContainer.translation = [0, m.OTBannerHeader.height]

      menuHeight = 0
      if isValid(m.dataModel.filterViewNode)
        m.filterListView.scale = [1, 1]
        m.filterListView.visible = true
        m.filterListView.content = m.dataModel.filterViewNode[m.top.viewType].clone(true)
        m.filterListView.itemSpacing = [m.style.buttonItemSpacings[0], 0]
        m.filterListView.itemSize = [m.dataModel.filterViewNode.gWidth, m.dataModel.filterViewNode.height]
        'm.filterListView.columnWidths = m.dataModel.filterViewNode.columnWidths
        if m.filterListView.content.getChildCount() = 5
          m.filterListView.itemSize = [m.dataModel.filterViewNode.width, m.dataModel.filterViewNode.height]
          if m.filteredListId.count() > 0
            filtericon = m.filterListView.content.getChild(4)
            if isValid(filtericon) then filtericon.status = 1
          end if
        end if
        menuHeight = menuHeight + m.filterListView.itemSize[1] + m.style.menu.padding
      end if

      m.OTPCListView.OTinitialize = m.OTinitialize
      m.OTPCListView.translation = [m.OTPCListView.translation[0], menuHeight]
      updateListViewData(m.top.viewType)
      updateListView(getFilterListViewData())

      if m.dataModel.viewType = "sdkList" then eventName = m.constant.listener["ELP117"] else eventName = m.constant.listener["ELP116"]
      createResolvedPromise(m.OTListGridview).then(sub(fire)
        if isValid(fire)
          m.OTListGridview.setFocus(true)
          setTextToSpeech()
        end if
      end sub)
      eventListeners(m.OTinitialize.top.eventlistener, eventName)
    end if
  catch e
    ? "Error in onChangeData: " + e.message
  end try
End Function

Function updateVendorScreen(viewType)
  try
    if m.dataModel <> invalid
      resetScroll({ value: m.navDirections.scrollValue }, [
        { value: m.OTConsentButtons },
        { value: m.OTAdditionalButtons },
        { value: m.OTListGridview }
      ])
      m.top.viewType = viewType
      m.navDirections = invalid
      m.filteredListId = {}
      m.OTBannerHeader.viewType = viewType
      m.OTBannerFooter.viewType = viewType
      if isValid(m.dataModel.filterViewNode)
        m.filterListView.content = m.dataModel.filterViewNode[viewType].clone(true)
        m.filterListView.itemSize = [m.dataModel.filterViewNode.gWidth, m.dataModel.filterViewNode.height]
        if m.filterListView.content.getChildCount() = 5 then m.filterListView.itemSize = [m.dataModel.filterViewNode.width, m.dataModel.filterViewNode.height]
      end if
      updateListViewData(viewType)
      updateListView(getFilterListViewData())
      createResolvedPromise(m.OTListGridview).then(sub(fire)
        if isValid(fire)
          m.OTListGridview.setFocus(true)
          setTextToSpeech()
        end if
      end sub)
    end if
  catch e
    ? "Error in updateVendorScreen: " + e.message
  end try
End Function

sub setTextToSpeech()
  if isValid(m.roAudioGuide) AND isValid(m.WCAGRoles)
    m.roAudioGuide.Flush()
    if isValid(m.headerText) then sayText(m.headerText, m.WCAGRoles.headingAriaLabel)
    if isValid(m.OTListGridview) then saySelected(m.OTListGridview, m.WCAGRoles.listAriaLabel)
    setTextToSpeechDetailScreen()
  end if
end sub

Function updateListViewData(viewType)
  try
    if isValid(m.dataModel)
      m.dataModel.viewType = viewType
      m.top.viewType = viewType
      dataModel = invalid
      if m.dataModel.viewType = "iab"
        dataModel = m.dataModel.iabVendorsNode.clone(true)
      end if
      if m.dataModel.viewType = "google"
        dataModel = m.dataModel.googleVendorsNode.clone(true)
      end if
      if m.dataModel.viewType = "sdkList"
        dataModel = m.dataModel.sdkListNode.clone(true)
      end if
      if isValid(dataModel)
        m.dataModel.OTListView = dataModel
        if isValid(m.dataModel.OTListView) then m.dataModel.OTListView.height = m.contentContainer.height - m.OTPCListView.translation[1]
      end if
    end if
  catch e
    ? "Error in updateListViewData: " + e.message
  end try
End Function

Function updateListView(filteredData)
  try
    dataModel = invalid
    dataModel = m.dataModel.OTListView.clone(true)
    dataModel.listContentNode = filteredData
    if isValid(dataModel)
      m.dataModel.OTListView.height = m.contentContainer.height - m.OTPCListView.translation[1]
      m.OTPCListView.data = dataModel
      data = m.OTPCListView.data.listContentNode
      if isValid(data) AND data.getChildCount() > 0 then data = data.getChild(0)
      updateDetailScreen(data)
    end if
  catch e
    ? "Error in updateListView: " + e.message
  end try
End Function

Function onKeyEvent(key as String, press as Boolean) as Boolean
  try
    currentPath = [0, 2]
    visiblePath = [0, 2]
    previousPath = [1, 1]
    if m.navDirections <> invalid AND m.navDirections.key <> invalid
      currentPath = m.navDirections.key
      visiblePath = m.navDirections.visiblePath
      previousPath = m.navDirections.previousPath
    end if

    mainBackButton = { key: m.navConstant.button, value: m.mainBackButton, skipSameNode: true, redirect: { right: [2, 0], down: [0, 1] } }
    filterListView = { key: m.navConstant.button, value: m.filterListView, skipSameNode: false, jumptoItem: 0 }
    filterButtonList = { key: m.navConstant.button, value: m.filterButtonList, jumptoItem: 0 }

    OTConsentButtons = { key: m.navConstant.scrollTextButton: value: m.OTConsentButtons, skipSameNode: false, allowPreviousPath: true, redirect: { left: [0, 2] } }
    OTAdditionalButtons = { key: m.navConstant.scrollTextButton: value: m.OTAdditionalButtons, skipSameNode: false, allowPreviousPath: true, redirect: { left: [0, 2] } }
    detailScreenlayoutScroll = { key: m.navConstant.scrollTextButton: value: m.detailScreenlayoutScroll, skipSameNode: true, allowPreviousPath: true }

    if not ((isValid(m.OTConsentButtons) AND m.OTConsentButtons.visible) OR (isValid(m.OTAdditionalButtons) AND m.OTAdditionalButtons.visible) OR (isValid(m.OTPurposeChildButtons) AND m.OTPurposeChildButtons.visible))
      OTConsentButtons = detailScreenlayoutScroll
      OTAdditionalButtons = detailScreenlayoutScroll
    end if

    descriptionRedirectPath = [1, 1]
    if (isValid(m.OTAdditionalButtons) AND m.OTAdditionalButtons.visible)
      descriptionRedirectPath = [1, 2]
    end if
    if (isValid(m.OTConsentButtons) AND m.OTConsentButtons.visible)
      descriptionRedirectPath = [1, 1]
    end if

    isslideOpen = m.backButton <> invalid AND m.backButton.visible AND isValid(m.backButton.content)
    if isslideOpen then descriptionRedirectPath = [0, descriptionRedirectPath[1]]

    'closeNode2 = { key: m.navConstant.button, value: m.closetextList, skipSameNode: false, redirect: {left: [0, 0]}}
    closeNode = { key: m.navConstant.button, value: m.closetextList, skipSameNode: true, redirect: { left: [0, 0], down: [2, 1] } }
    footerButtonNode = { key: m.navConstant.button, value: m.buttonList, skipSameNode: true, accecptPreviousPath: true, jumptoItem: 0 }
    OTPCListView = { key: m.navConstant.button, value: m.OTListGridview, skipSameNode: true, resetScroll: true, redirect: { right: descriptionRedirectPath } }

    if not (isValid(m.closetextList) AND m.closetextList.visible) then closeNode = mainBackButton

    value = [
      [
        mainBackButton,
        filterListView,
        OTPCListView
      ],
      [
        mainBackButton,
        OTConsentButtons,
        OTAdditionalButtons,
      ],
      [
        closeNode,
        footerButtonNode,
        footerButtonNode
      ]

    ]
    if isslideOpen
      backButton = { key: m.navConstant.button, value: m.backButton, skipSameNode: false, redirect: { down: descriptionRedirectPath } }
      OTConsentButtons["redirect"] = invalid
      value = [
        [
          backButton,
          filterButtonList,
          OTConsentButtons
        ]
      ]
    end if

    m.navDirections = {
      key: currentPath,
      visiblePath: visiblePath,
      previousPath: previousPath,
      scrollValue: m.detailScreenlayoutScroll
      resetValues: [
        filterButtonList,
        OTConsentButtons,
        OTAdditionalButtons,
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
      if isValid(data) then data = data.itemFocused
      if isValid(data) then updateDetailScreen(data)
      if isValid(m.OTListGridview) AND isValid(m.WCAGRoles) then saySelected(m.OTListGridview, m.WCAGRoles.listAriaLabel, true)
      setTextToSpeechDetailScreen()
    end if
  catch e
    ? "Error in onItemFocused: " + e.message
  end try
End Function

sub onFilterItemFocused(data as Object)
  try
    data = data.getRoSGNode()
    if isValid(data)
      itemFocused = data.itemFocused
      if isValid(itemFocused) AND isValid(data.content) then item = data.content.getChild(itemFocused)
      if isValid(item) AND isValid(m.WCAGRoles)
        item.itemUnfocused = false
        itemArray = []
        text = ""
        role1 = ""
        role = m.WCAGRoles.selectedAriaLabel
        role3 = ""
        role4 = ""
        if isValid(item.status) AND item.status = 1 then role += " " + m.WCAGRoles.activeAriaLabel
        if isString(item.text)
          itemArray = item.text.split("-")
          itemRoleArray = m.WCAGRoles.alphabeticFilterAriaLabel.split("<X>")
          if isString(itemRoleArray[0]) then role1 = itemRoleArray[0]
          if isString(itemArray[0]) then text = itemArray[0]
          if isString(itemRoleArray[1]) then itemRoleArray1 = itemRoleArray[1].split("<Y>")
          if isString(itemRoleArray1[0]) then role3 = itemRoleArray1[0]
          if isString(itemArray[1]) then role4 = itemArray[1]
        else if isString(item.subText)
          text = item.subText
        end if
        say(text, role1, role3, true, role4, role)
      end if
    end if
  catch e
    ? "Error in onItemFocused: " + e.message
  end try
end sub

Function setScrollHeight(data)
  data = data.getData()
  if isValid(data)
    m.key = data.key
    if m.scrollThumb <> invalid AND m.scrollThumb.visible then scrollAnimation(data.scrollHeight)
  end if
End Function

Function updateScroll()
  m.scrollThumb.height = scrollHeight()
End Function

Function onItemSelected(data as Object)
  try
    data = data.getRoSGNode()
    if isValid(data) AND isValid(data.content)
      contentData = data.content.getChild(data.itemSelected)
      if isValid(contentData) AND (contentData.id = "iab" OR contentData.id = "google")
        updateVendorScreen(contentData.id)
      end if
    end if
  catch e
    ? "Error in onItemSelected: " + e.message
  end try
End Function

Function onFilterItemSelection(data as Object)
  try
    data = data.getRoSGNode()
    if isValid(data) AND isValid(data.content)
      contentData = data.content.getChild(data.itemSelected)
      if isValid(contentData)
        if contentData.id = "filterIcon"
          contentData.itemUnfocused = true
          m.top.slideLayer += 1
          if isValid(m.childData)
            m.childData.push({
              node: m.filterListView,
              key: m.navDirections.key,
              itemFocused: m.filterListView.content.getChildCount() - 1
              filteredListId: ParseJson(FormatJson(m.filteredListId))
            })
          end if
          if isValid(m.top.isChildScreen) then m.top.isChildScreen = true
          updateDetailScreen(contentData)
          createResolvedPromise(m.OTListGridview).then(sub(fire)
            if isValid(fire)
              setFocusChildDetailScreen({ default: m.OTConsentButtons, defaultPath: [0, 2] })
              setTextToSpeechDetailScreen(true)
            end if
          end sub)
        else
          status = 0
          if contentData.status <> 1 then status = 1
          contentData.status = status
          updateListView(getFilterListViewData())
          isSelected = true
          if isValid(m.OTListGridview) AND m.OTListGridview.visible
            if isValid(m.filterListView) then m.filterListView.jumptoItem = 0
            node = { value: m.OTListGridview }
            path = [0, 2]
            setfocusNode(node, path)
            isSelected = false
          end if
          setTextToSpeechDetailScreen(isSelected, isSelected)
        end if
      end if
    end if
  catch e
    ? "Error in onFilterItemSelection: " + e.message
  end try
End Function

Function getActiveFilterItem(data)
  filterText = ""
  try
    if isValid(data)
      filterList = data.getChildren(-1, 0)
      for each item in filterList
        if item.id = "textFilter" AND item.status = 1 then filterText = filterText + LCase(item.text)
      end for
    end if
  catch e
    ? "Error in getActiveFilterItem: " + e.message
  end try
  return filterText
End Function

Function getFilterListViewData()
  filterContentNode = CreateObject("roSGNode", "ContentNode")
  try
    filterText = getActiveFilterItem(m.filterListView.content)
    purposeFilteredList = m.filteredListId
    groupPrefixes = m.dataModel.groupPrefixes
    OTListView = m.dataModel.OTListView.listContentNode.clone(true)
    viewType = m.top.viewType
    if isString(filterText) OR (isValid(purposeFilteredList) AND purposeFilteredList.Count() > 0)
      regEx = invalid
      if isString(filterText) then regEx = createObject("roRegEx", "[" + LCase(filterText) + "]", "")
      for each child in OTListView.getChildren(-1, 0)
        result = true
        firstChar = Left(LCase(child.text), 1)
        if isValid(regEx) AND isString(filterText) then result = regEx.isMatch(firstChar)
        if result AND (isValid(purposeFilteredList) AND purposeFilteredList.Count() > 0) then result = havingVendorPurpose(purposeFilteredList, groupPrefixes, child, viewType)
        if result
          filterContentNode.appendChild(child)
        end if
      end for
    else
      filterContentNode = OTListView
    end if
  catch e
    ? "Error in getFilterListViewData: " + e.message
  end try
  return filterContentNode
End Function

Function havingVendorPurpose(data, groupPrefixes, child, viewType)
  result = false
  try
    if isValid(data)
      dataKeys = data.keys()
      for i = 0 to dataKeys.count() - 1
        item = dataKeys[i]
        if viewType = "sdkList"
          result = child.purposeItem <> invalid AND item = child.purposeItem.groupId
        else
          prefix = item.split("_")
          if isValid(groupPrefixes) AND prefix.count() > 1 AND isValid(groupPrefixes[prefix[0]])
            if isValid(child.purposeItem[groupPrefixes[prefix[0]]]) AND child.purposeItem[groupPrefixes[prefix[0]]].count() > 0
              result = purposeExists(child.purposeItem[groupPrefixes[prefix[0]]], prefix[1])
            end if
            if not result AND groupPrefixes[prefix[0]] = "purposes" AND isValid(child.purposeItem["legIntPurposes"]) AND child.purposeItem["legIntPurposes"].count() > 0
              result = purposeExists(child.purposeItem["legIntPurposes"], prefix[1])
            end if
          end if
        end if
        if result then exit for
      end for
    end if
  catch e
    ? "Error in havingVendorPurpose: " + e.message
  end try
  return result
End Function

Function purposeExists(list, id)
  result = false
  try
    if isValid(list)
      for i = 0 to list.count() - 1
        if list[i].toStr() = id
          result = true
          exit for
        end if
      end for
    end if
  catch e
    ? "Error in havingVendorPurpose: " + e.message
  end try
  return result
End Function

Function onfilterButtonListSelection(data as Object)
  data = data.getRoSGNode()
  if isValid(data) AND isValid(data.content)
    contentData = data.content.getChild(data.itemSelected)
    if isValid(contentData) AND contentData.id = "filterCloseButton"
      say(m.WCAGRoles.clearButtonAnnouncement, "", "", true)
      m.filteredListId = {}
      data = m.filterListView.content.getChild(m.filterListView.itemSelected)
      detailScreenViewNode = invalid
      if isValid(data) then detailScreenViewNode = getDetailScreenViewNode(data.purposeItem, m.dataModel, m.contentContainer.height, data)
      if isValid(detailScreenViewNode) AND isValid(detailScreenViewNode.consentBtnNode) AND isValid(m.OTConsentButtons) AND isValid(m.OTConsentButtons.visible) then m.OTConsentButtons.content = detailScreenViewNode.consentBtnNode
    else
      if isArray(m.childData) AND m.childData.count() > 0 then m.childData.pop()
      filterListViewData = getFilterListViewData()
      resetScroll({ value: m.navDirections.scrollValue }, [{ value: m.OTConsentButtons }, { value: m.OTListGridview }])
      if isValid(m.filterListView.content) AND m.filterListView.content.getChildCount() = 5
        filtericon = m.filterListView.content.getChild(4)
        status = 0
        if m.filteredListId.count() > 0 then status = 1
        if isValid(filtericon)
          filtericon.itemUnfocused = false
          filtericon.status = status
          m.filterListView.jumptoItem = 0
        end if
      end if
      if isValid(m.top.isChildScreen) AND m.top.isChildScreen
        if isValid(m.top.isChildScreen) AND m.top.slideLayer = 1
          m.OTPCChildDetailScreenView.slide = true
          m.top.isChildScreen = false
        end if
        m.top.slideLayer -= 1
      end if
      updateListView(filterListViewData)
      if isValid(filterListViewData) AND filterListViewData.getChildCount() > 0
        node = { value: m.OTListGridview }
        path = [0, 2]
        setfocusNode(node, path)
        setTextToSpeechDetailScreen()
      else
        node = { value: m.filterListView }
        path = [0, 1]
        setfocusNode(node, path)
      end if
    end if
  end if
End Function