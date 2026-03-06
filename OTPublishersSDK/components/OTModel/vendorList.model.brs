Function getVendorListModelData(data, width)
  model = CreateObject("roSGNode", "OTVendorlistInterface")
  buttonsData = invalid
  if data <> invalid AND data.count() > 0
    regx = createObject("roRegex", "\s(\s+)?", "")
    model.fonts = m.OT_Data.fonts
    model.multiStyleFonts = m.OT_Data.multiStyleFonts
    pcUIData = data.pcUIData
    iab2V2Vendors = data.iab2V2Vendors
    googleVendors = data.googleVendors
    data = data.vendorListUIData
    getWCAGRoles(pcUIData)
    if isValid(pcUIData) AND pcUIData.general <> invalid AND pcUIData.general.buttonBorderShow <> invalid then model.border = pcUIData.general.buttonBorderShow
    if isValid(data.vendorDetailsUIData) AND isValid(data.vendorDetailsUIData.description) then model.itemDescription = data.vendorDetailsUIData.description
    if data.general <> invalid
      if data.general.menu <> invalid then model.menu = data.general.menu
      if data.general.backgroundColor <> invalid then model.backgroundColor = data.general.backgroundColor
      if data.general.buttonFocusColor <> invalid then model.buttonFocusColor = data.general.buttonFocusColor
      if data.general.buttonFocusTextColor <> invalid then model.buttonFocusTextColor = data.general.buttonFocusTextColor
      if data.general.buttonActiveColor <> invalid then model.buttonActiveColor = data.general.buttonActiveColor
      if data.general.buttonActiveTextColor <> invalid then model.buttonActiveTextColor = data.general.buttonActiveTextColor
      if data.general.pageHeaderTitle <> invalid then model.pageHeaderVendorTitle = setbPCTextModel({ text: data.general.pageHeaderTitle, textColor: data.general.titleTextColor }, regx)
      if data.general.showFilterIcon <> invalid then model.showFilterIcon = data.general.showFilterIcon
      filterVendorListTitle = "Filter Vendor List"
      filterSDKListTitle = "Filter SDK List"
      if isValid(data.general.filterVendorListTitle) then filterVendorListTitle = data.general.filterVendorListTitle
      if isValid(pcUIData) AND isValid(pcUIData.general) AND isValid(pcUIData.general.filterSDKListTitle) then filterSDKListTitle = pcUIData.general.filterSDKListTitle
      if isString(data.general.titleTextColor) then model.pageHeaderFilterVendorTitle = setbPCTextModel({ text: filterVendorListTitle, textColor: data.general.titleTextColor }, regx)
      if isString(data.general.titleTextColor) then model.pageHeaderFilterSdkTitle = setbPCTextModel({ text: filterSDKListTitle, textColor: data.general.titleTextColor }, regx)
      if data.general.buttons <> invalid
        '   if data.buttons.acceptAll <> invalid then model.acceptAll = PCbuttonContentNodeItem(data.buttons, model, "acceptAll")
        '   if data.buttons.rejectAll <> invalid then model.rejectAll = PCbuttonContentNodeItem(data.buttons, model, "rejectAll")
        if data.general.buttons.backButton <> invalid then model.backButton = buttonBackNodeItem(data.general.buttons.backButton, model, "backButton")
        if data.general.buttons.savePreferencesButton <> invalid
          buttonsData = data.general.buttons.savePreferencesButton
          eventInteractionType = "VENDOR_LIST_CONFIRM"
          if m.top.viewType = "sdkList" then eventInteractionType = "SDK_LIST_CONFIRM"
          model.savePreferencesButton = PCbuttonContentNodeItem(data.general.buttons, model, "savePreferencesButton", "rectangleBtn", eventInteractionType)
        end if
        if data.general.buttons.filterApplyButton <> invalid
          buttons = data.general.buttons
          model.filterApplyButton = PCbuttonContentNodeItem(data.general.buttons, model, "filterApplyButton")
          if isValid(pcUIData) AND isValid(pcUIData.filter) AND isString(pcUIData.filter.filterClearText)
            buttons["tempfilterCloseButton"] = data.general.buttons.filterApplyButton
            buttons["tempfilterCloseButton"]["text"] = pcUIData.filter.filterClearText
            buttons["filterCloseButton"] = buttons["tempfilterCloseButton"]
            model.filterCloseButton = PCbuttonContentNodeItem(buttons, model, "filterCloseButton")
          end if
        end if
      end if
    end if
    consentColorCode = {
      color: "",
      textColor: "",
    }
    if isValid(model.itemDescription.textColor)
      consentColorCode = {
        color: model.backgroundColor
        textColor: model.itemDescription.textColor
      }
    end if
    if data.vendorDetailsUIData <> invalid
      if data.vendorDetailsUIData.title <> invalid then model.itemTitle = data.vendorDetailsUIData.title
      if data.vendorDetailsUIData.sdkListText <> invalid then model.pageHeaderSDKListTitle = setbPCTextModel({ text: data.vendorDetailsUIData.sdkListText, textColor: data.general.titleTextColor }, regx)
      if data.vendorDetailsUIData.lifespan <> invalid then model.lifespan = data.vendorDetailsUIData.lifespan
      if data.vendorDetailsUIData.lifespanDay <> invalid then model.lifespanDay = data.vendorDetailsUIData.lifespanDay
      if data.vendorDetailsUIData.lifespanDays <> invalid then model.lifespanDays = data.vendorDetailsUIData.lifespanDays
      if data.vendorDetailsUIData.lifespanMonth <> invalid then model.lifespanMonth = data.vendorDetailsUIData.lifespanMonth
      if data.vendorDetailsUIData.lifespanMonths <> invalid then model.lifespanMonths = data.vendorDetailsUIData.lifespanMonths
      if data.vendorDetailsUIData.disclosureTitle <> invalid then model.disclosureTitle = data.vendorDetailsUIData.disclosureTitle
      if data.vendorDetailsUIData.nonCookieUsageText <> invalid then model.nonCookieUsageText = data.vendorDetailsUIData.nonCookieUsageText
      if data.vendorDetailsUIData.storageIdentifierText <> invalid then model.storageIdentifierText = data.vendorDetailsUIData.storageIdentifierText
      if data.vendorDetailsUIData.storageIdentifierType <> invalid then model.storageIdentifierType = data.vendorDetailsUIData.storageIdentifierType
      if data.vendorDetailsUIData.storagePurposes <> invalid then model.storagePurposes = data.vendorDetailsUIData.storagePurposes
      if data.vendorDetailsUIData.storageDomain <> invalid then model.storageDomain = data.vendorDetailsUIData.storageDomain
      if data.vendorDetailsUIData.dataDeclarationText <> invalid then model.dataDeclarationText = data.vendorDetailsUIData.dataDeclarationText
      if data.vendorDetailsUIData.dataRetentionText <> invalid then model.dataRetentionText = data.vendorDetailsUIData.dataRetentionText
      if data.vendorDetailsUIData.domainsUsed <> invalid then model.domainsUsed = data.vendorDetailsUIData.domainsUsed
      if data.vendorDetailsUIData.domainUse <> invalid then model.domainUse = data.vendorDetailsUIData.domainUse
      if data.vendorDetailsUIData.consentPurposes <> invalid then model.consentPurposes = data.vendorDetailsUIData.consentPurposes
      if data.vendorDetailsUIData.features <> invalid then model.features = data.vendorDetailsUIData.features
      if data.vendorDetailsUIData.specialFeatures <> invalid then model.specialFeatures = data.vendorDetailsUIData.specialFeatures
      if data.vendorDetailsUIData.specialPurposes <> invalid then model.specialPurposes = data.vendorDetailsUIData.specialPurposes
      if data.vendorDetailsUIData.legitimateInterestPurposesText <> invalid then model.legitimateInterestPurposesText = data.vendorDetailsUIData.legitimateInterestPurposesText
      if data.vendorDetailsUIData.dataStdRetentionText <> invalid then model.dataStdRetentionText = data.vendorDetailsUIData.dataStdRetentionText
    end if
    if pcUIData <> invalid
      if isValid(pcUIData.searchBar) AND isString(pcUIData.searchBar.searchNoResultsFoundText) then model.searchNoResultsFoundText = pcUIData.searchBar.searchNoResultsFoundText
      if pcUIData.buttons <> invalid
        if pcUIData.buttons.closeButton <> invalid then
          if isValid(pcUIData.buttons.closeButton.closeBtnVoiceOverText) then model.closeBtnVoiceOverText = pcUIData.buttons.closeButton.closeBtnVoiceOverText
          model.closeButton = PCbuttonContentNodeItem(pcUIData.buttons, model, "closeButton")
        end if
        if pcUIData.buttons.acceptAll <> invalid
          buttonsData = pcUIData.buttons.acceptAll
          eventInteractionType = "VENDOR_LIST_ALLOW_ALL"
          if m.top.viewType = "sdkList" then eventInteractionType = "SDK_LIST_ALLOW_ALL"
          model.acceptAll = PCbuttonContentNodeItem(pcUIData.buttons, model, "acceptAll", "rectangleBtn", eventInteractionType)
        end if
        if pcUIData.buttons.rejectAll <> invalid
          buttonsData = pcUIData.buttons.rejectAll
          eventInteractionType = "VENDOR_LIST_REJECT_ALL"
          if m.top.viewType = "sdkList" then eventInteractionType = "SDK_LIST_REJECT_ALL"
          model.rejectAll = PCbuttonContentNodeItem(pcUIData.buttons, model, "rejectAll", "rectangleBtn", eventInteractionType)
        end if
      end if
      if pcUIData.purposeTree <> invalid
        if model.menu <> invalid then model = OTFilterListView(pcUIData.purposeTree.purposes, model.menu, model, width)
        if pcUIData.purposeTree.styling <> invalid
          if pcUIData.purposeTree.styling.alwaysActiveLabel <> invalid
            alwaysActiveLabel = pcUIData.purposeTree.styling.alwaysActiveLabel
            if alwaysActiveLabel <> invalid AND isString(alwaysActiveLabel.text) AND isValid(buttonsData) then model.alwaysActiveBtn = getContentNodeItem(alwaysActiveLabel.text, buttonsData, model, false, "checkBox", "left")
          end if
          if m.top.viewType = "sdkList" AND isValid(pcUIData.purposeTree.styling.itemDetailsConsentCheckboxInfo)
            if isValid(pcUIData.purposeTree.styling.itemDetailsConsentCheckboxInfo.activeText)
              model.activeTextBtn = getContentNodeItem(pcUIData.purposeTree.styling.itemDetailsConsentCheckboxInfo.activeText, consentColorCode, model, false, "checkBox", "left")
            end if
            if isValid(pcUIData.purposeTree.styling.itemDetailsConsentCheckboxInfo.inActiveText)
              model.inActiveTextBtn = getContentNodeItem(pcUIData.purposeTree.styling.itemDetailsConsentCheckboxInfo.inActiveText, consentColorCode, model, false, "checkBox", "left")
            end if
            model.interactionChoiceShow = isValid(pcUIData.purposeTree.styling.itemDetailsConsentCheckboxInfo.interactionChoiceText)
          end if
        end if
      end if
    end if
    if data.general <> invalid AND buttonsData <> invalid
      model.menuListNode = getMenuViewContentNode(data.general, buttonsData, model, googleVendors)
    end if

    if buttonsData <> invalid then model.filterViewNode = getFilterViewContentNode(buttonsData, model, width)
    if data.vendorDetailsUIData <> invalid
      if data.vendorDetailsUIData.vendorsPolicyText <> invalid AND isValid(buttonsData) then model.vendorsPolicyBtn = getContentNodeItem(data.vendorDetailsUIData.vendorsPolicyText, buttonsData, model, model.border)
      if data.vendorDetailsUIData.legIntClaimPolicyText <> invalid AND isValid(buttonsData) then model.legIntClaimPolicyBtn = getContentNodeItem(data.vendorDetailsUIData.legIntClaimPolicyText, buttonsData, model, model.border)
      if data.vendorDetailsUIData.consentToggleText <> invalid AND isValid(buttonsData) then model.consentBtn = getContentNodeItem(data.vendorDetailsUIData.consentToggleText, consentColorCode, model, false, "checkBox", "left")
      if data.vendorDetailsUIData.legitInterestToggleText <> invalid AND isValid(buttonsData) then model.legitInterestBtn = getContentNodeItem(data.vendorDetailsUIData.legitInterestToggleText, consentColorCode, model, false, "checkBox", "left")
    end if
    if m.top.viewType <> "sdkList"
      if iab2V2Vendors <> invalid
        if iab2V2Vendors.groupPrefixes <> invalid then model.groupPrefixes = getGroupPrefixes(iab2V2Vendors.groupPrefixes)
        if iab2V2Vendors.vendors <> invalid then model.iabVendorsNode = OTListViewContentNode(getSortedList(iab2V2Vendors.vendors, "name"), model.menu, model, width)
        if iab2V2Vendors.IABDataCategories <> invalid then model.IABDataCategories = iab2V2Vendors.IABDataCategories
        iabGroups = {}
        if iab2V2Vendors.purposes <> invalid then iabGroups["purposes"] = iab2V2Vendors.purposes
        if iab2V2Vendors.specialPurposes <> invalid then iabGroups["specialPurposes"] = iab2V2Vendors.specialPurposes
        if iab2V2Vendors.features <> invalid then iabGroups["features"] = iab2V2Vendors.features
        if iab2V2Vendors.specialFeatures <> invalid then iabGroups["specialFeatures"] = iab2V2Vendors.specialFeatures
        model.iabGroups = iabGroups
      end if
      if googleVendors <> invalid
        if googleVendors.vendors <> invalid then model.googleVendorsNode = OTListViewContentNode(getSortedList(googleVendors.vendors, "name"), model.menu, model, width)
      end if
    end if
  end if
  return model
End Function

Function OTListViewContentNode(list, menuColor, model, width)
  width = width * model.ratio[0]
  node = getContentNodeItemList("listItems", list, menuColor, model, "listViewRectangle")
  OTListViewInterface = CreateObject("roSGNode", "OTListViewInterface")
  OTListViewInterface.listContentNode = node
  OTListViewInterface.width = width
  OTListViewInterface.searchNoResultsFoundText = model.searchNoResultsFoundText
  OTListViewInterface.backgroundColor = menuColor.color
  OTListViewInterface.textColor = menuColor.textColor
  OTListViewInterface.fonts = model.fonts
  return OTListViewInterface
End Function

Function getDetailScreenViewNode(data, model, height, dataNode)
  OTDetailScreenViewInterface = CreateObject("roSGNode", "OTDetailScreenViewInterface")
  if isValid(data) OR dataNode.id = "filterIcon" OR dataNode.id = "vendorsPolicyBtn" OR dataNode.id = "legIntClaimPolicyBtn"
    consentData = m.consentData
    if isValid(model.WCAGRoles) then OTDetailScreenViewInterface.WCAGRoles = model.WCAGRoles
    regx = createObject("roRegex", "\s(\s+)?", "")
    OTDetailScreenViewInterface.width = model.width * model.ratio[1]
    OTDetailScreenViewInterface.translation = [model.width * model.ratio[0], 0]
    OTDetailScreenViewInterface.height = height
    OTDetailScreenViewInterface.backgroundColor = model.backgroundColor
    OTDetailScreenViewInterface.id = dataNode.id
    OTDetailScreenViewInterface.item = data
    itemTitle = model.itemTitle
    itemTitle["text"] = dataNode.text
    itemDescription = model.itemDescription
    OTDetailScreenViewInterface.headerNode = setbPCTextModel(itemTitle, regx)
    OTDetailScreenViewInterface.overlayTranslation = [-m.innerContainer.translation[0], - (m.innerContainer.translation[1] + m.contentContainer.translation[1])]
    if dataNode.id = "vendorsPolicyBtn" OR dataNode.id = "legIntClaimPolicyBtn"
      if isString(dataNode.url) then itemDescription["urlQRCode"] = dataNode.url
      OTDetailScreenViewInterface.descriptionNode = setbPCTextModel(itemDescription, regx)
      OTDetailScreenViewInterface.backButton = getBackButtonContentNode(model.backButton.clone(true), dataNode)
    else if dataNode.id = "filterIcon"
      itemTitle = model.pageHeaderFilterSdkTitle
      if m.top.viewType <> "sdkList" then itemTitle = model.pageHeaderFilterVendorTitle
      OTDetailScreenViewInterface.headerNode = setbPCTextModel(itemTitle, regx)
      filterBtnNode = CreateObject("roSGNode", "ContentNode")

      OTButtonView = CreateObject("roSGNode", "OTButtonView")
      OTButtonView.width = ((OTDetailScreenViewInterface.width - m.style.detailScreen.padding) / 2) - m.style.buttonspacing
      filterHeight = 0
      if isValid(model.filterApplyButton)
        OTButtonView.itemContent = model.filterApplyButton
        filterHeight = OTButtonView.boundingRect().height
        filterBtnNode.appendChild(model.filterApplyButton.clone(true))
      end if
      if isValid(model.filterCloseButton)
        OTButtonView.itemContent = model.filterCloseButton
        filterHeight1 = OTButtonView.boundingRect().height
        if filterHeight1 > filterHeight then filterHeight = filterHeight1
        filterBtnNode.appendChild(model.filterCloseButton.clone(true))
      end if
      if filterBtnNode.getChildCount() > 0
        OTDetailScreenViewInterface.filterBtnNode = filterBtnNode
        OTDetailScreenViewInterface.filterBtnSize = [OTButtonView.width, filterHeight]
      end if
      if m.dataModel.viewType = "sdkList"
        OTDetailScreenViewInterface.consentBtnNode = updateFilterStatus(model.sdkFilterListNode.clone(true))
      else if m.dataModel.viewType = "iab"
        OTDetailScreenViewInterface.consentBtnNode = updateFilterStatus(model.iabFilterListNode.clone(true))
      end if
      OTDetailScreenViewInterface.backButton = getBackButtonContentNode(model.backButton.clone(true), dataNode)
    else
      if data.groupDescription <> invalid then itemDescription["text"] = data.groupDescription
      if data.description <> invalid then itemDescription["text"] = data.description
      OTDetailScreenViewInterface.descriptionNode = setbPCTextModel(itemDescription, regx)
      descriptionColor = "#ffffff"
      if isValid(itemDescription["textColor"]) then descriptionColor = itemDescription["textColor"]

      if isString(model.lifespan) then OTDetailScreenViewInterface.lifespan = model.lifespan
      if isString(model.lifespanDay) then OTDetailScreenViewInterface.lifespanDay = model.lifespanDay
      if isString(model.lifespanDays) then OTDetailScreenViewInterface.lifespanDays = model.lifespanDays
      if isString(model.lifespanMonth) then OTDetailScreenViewInterface.lifespanMonth = model.lifespanMonth
      if isString(model.lifespanMonths) then OTDetailScreenViewInterface.lifespanMonths = model.lifespanMonths
      if isString(model.disclosureTitle) then OTDetailScreenViewInterface.disclosureTitle = model.disclosureTitle
      if isString(model.nonCookieUsageText) then OTDetailScreenViewInterface.nonCookieUsageText = model.nonCookieUsageText
      if isString(model.storageIdentifierText) then OTDetailScreenViewInterface.storageIdentifierText = model.storageIdentifierText
      if isString(model.storageIdentifierType) then OTDetailScreenViewInterface.storageIdentifierType = model.storageIdentifierType
      if isString(model.storagePurposes) then OTDetailScreenViewInterface.storagePurposes = model.storagePurposes
      if isString(model.storageDomain) then OTDetailScreenViewInterface.storageDomain = model.storageDomain
      if isString(model.dataDeclarationText) then OTDetailScreenViewInterface.dataDeclarationText = model.dataDeclarationText
      if isString(model.dataRetentionText) then OTDetailScreenViewInterface.dataRetentionText = model.dataRetentionText
      if isString(model.domainsUsed) then OTDetailScreenViewInterface.domainsUsed = model.domainsUsed
      if isString(model.domainUse) then OTDetailScreenViewInterface.domainUse = model.domainUse
      if isString(model.consentPurposes) then OTDetailScreenViewInterface.consentPurposes = model.consentPurposes
      if isString(model.features) then OTDetailScreenViewInterface.features = model.features
      if isString(model.specialPurposes) then OTDetailScreenViewInterface.specialPurposes = model.specialPurposes
      if isString(model.specialFeatures) then OTDetailScreenViewInterface.specialFeatures = model.specialFeatures
      if isString(model.legitimateInterestPurposesText) then OTDetailScreenViewInterface.legitimateInterestPurposesText = model.legitimateInterestPurposesText
      if isString(model.dataStdRetentionText) then OTDetailScreenViewInterface.dataStdRetentionText = model.dataStdRetentionText
      if isValid(model.IABDataCategories) then OTDetailScreenViewInterface.IABDataCategories = model.IABDataCategories
      if isValid(model.iabGroups) then OTDetailScreenViewInterface.iabGroups = model.iabGroups
      if isString(model.viewType) then OTDetailScreenViewInterface.viewType = model.viewType

      additionalBtnNode = CreateObject("roSGNode", "ContentNode")
      if isValid(model.vendorsPolicyBtn)
        url = ""
        if data.urls <> invalid AND isString(data.urls.privacy) then url = data.urls.privacy
        if isString(data.policyUrl) then url = data.policyUrl
        if isString(url)
          vendorsPolicyBtn = model.vendorsPolicyBtn.clone(true)
          vendorsPolicyBtn.id = "vendorsPolicyBtn"
          vendorsPolicyBtn.url = url
          vendorsPolicyBtn.descriptionColor = descriptionColor
          additionalBtnNode.appendChild(vendorsPolicyBtn)
        end if
      end if
      if data.urls <> invalid AND isValid(model.legIntClaimPolicyBtn) AND data.urls.legIntClaim <> invalid AND data.urls.legIntClaim <> ""
        legIntClaimPolicyBtn = model.legIntClaimPolicyBtn.clone(true)
        legIntClaimPolicyBtn.id = "legIntClaimPolicyBtn"
        legIntClaimPolicyBtn.url = data.urls.legIntClaim
        legIntClaimPolicyBtn.descriptionColor = descriptionColor
        additionalBtnNode.appendChild(legIntClaimPolicyBtn)
      end if
      if additionalBtnNode.getChildCount() > 0 then OTDetailScreenViewInterface.additionalBtnNode = additionalBtnNode

      consentBtnNode = CreateObject("roSGNode", "ContentNode")
      consentStatus = data.consentStatus
      if data.toggleStatus <> invalid then consentStatus = data.toggleStatus
      if consentStatus <> invalid
        if isString(consentStatus) then consentStatus = consentStatus.ToInt()
        data["consentToggleStatus"] = consentStatus
      end if
      if data.consentToggleStatus <> invalid AND data.consentToggleStatus <> -1
        if data.consentToggleStatus <> 2 AND not model.interactionChoiceShow
          activeTextBtn = createConsentButton("activeTextCheckBox", model.activeTextBtn, data, dataNode, consentData)
          if activeTextBtn <> invalid
            activeTextBtn.purposeItem = data
            consentBtnNode.appendChild(activeTextBtn)
          end if
          inActiveTextBtn = createConsentButton("inActiveTextCheckBox", model.inActiveTextBtn, data, dataNode, consentData)
          if inActiveTextBtn <> invalid
            inActiveTextBtn.purposeItem = data
            consentBtnNode.appendChild(inActiveTextBtn)
          end if
        else
          consentBtn = invalid
          if isValid(model.alwaysActiveBtn) AND data.consentToggleStatus = 2 then consentBtn = model.alwaysActiveBtn.clone(true)
          if isValid(model.consentBtn) AND data.consentToggleStatus <> 2 then consentBtn = model.consentBtn.clone(true)
          if isValid(consentBtn)
            consentBtn.id = "consentCheckBox"
            consentBtn.uId = dataNode.uId
            if data.consentToggleStatus = 2
              consentStatus = data.consentToggleStatus
            else
              OT_VendorConsents = getRegistryVendorStatus(consentData, consentBtn.uId, m.top.viewType, "OT_VendorConsents")
              if consentData <> invalid AND OT_VendorConsents <> invalid
                consentStatus = OT_VendorConsents
              end if
              purposesStatusKey = getStatusKey(m.top.viewType)
              if consentData <> invalid AND consentData[purposesStatusKey][consentBtn.uId] <> invalid AND consentData[purposesStatusKey][consentBtn.uId]["status"] <> invalid
                consentStatus = getStatusBoolToNum(consentData[purposesStatusKey][consentBtn.uId]["status"])
              end if
            end if
            consentBtn.status = consentStatus
            consentBtn.purposeItem = data
            consentBtnNode.appendChild(consentBtn)
          end if
        end if
      end if

      legIntStatus = data.legIntStatus
      if data.legIntStatus <> invalid AND isString(legIntStatus) then legIntStatus = legIntStatus.ToInt()
      if isValid(model.legitInterestBtn) AND data.legIntStatus <> invalid AND legIntStatus <> -1
        legitInterestBtn = model.legitInterestBtn.clone(true)
        legitInterestBtn.id = "legitInterestCheckBox"
        legitInterestBtn.uId = dataNode.uId
        OT_vendorLIConsents = getRegistryVendorStatus(consentData, legitInterestBtn.uId, m.top.viewType, "OT_vendorLIConsents")
        if consentData <> invalid AND OT_vendorLIConsents <> invalid
          legIntStatus = OT_vendorLIConsents
        end if
        purposesStatusKey = getStatusKey(m.top.viewType)
        if consentData <> invalid AND consentData[purposesStatusKey][legitInterestBtn.uId] <> invalid AND consentData[purposesStatusKey][legitInterestBtn.uId]["liStatus"] <> invalid
          legIntStatus = getStatusBoolToNum(consentData[purposesStatusKey][legitInterestBtn.uId]["liStatus"])
        end if
        legitInterestBtn.status = legIntStatus
        consentBtnNode.appendChild(legitInterestBtn)
      end if
      if consentBtnNode.getChildCount() > 0 then OTDetailScreenViewInterface.consentBtnNode = consentBtnNode
    end if
  end if
  consentData = invalid
  return OTDetailScreenViewInterface
End Function

Function getContentNodeItem(text, buttonsData, model, border = false, Btype = "rectangleBtn", horizAlign = "center", id = "")
  color = buttonsData.color
  textcolor = buttonsData.textColor
  if Btype = "closeButton"
    color = model.backgroundColor
  end if
  contentNodeItem = CreateObject("roSGNode", "OTButtonInterface")
  contentNodeItem.id = id
  contentNodeItem.text = text
  contentNodeItem.color = color
  contentNodeItem.textColor = textcolor
  contentNodeItem.focusButtonColor = model.buttonFocusColor
  contentNodeItem.focusButtonTextColor = model.buttonFocusTextColor
  contentNodeItem.fonts = model.fonts
  contentNodeItem.Btype = Btype
  contentNodeItem.border = border
  contentNodeItem.horizAlign = horizAlign
  if isValid(model.alwaysActiveNode) then contentNodeItem.alwaysActiveNode = model.alwaysActiveNode
  if isValid(model.activeTextNode) then contentNodeItem.activeTextNode = model.activeTextNode
  if isValid(model.inActiveTextNode) then contentNodeItem.inActiveTextNode = model.inActiveTextNode
  return contentNodeItem
End Function

Function getContentNodeItemList(id, list, menuColor, model, Btype = "rectangleBtn")
  contentNode = CreateObject("roSGNode", "ContentNode")
  if isValid(list)
    listKeys = list
    if not isArray(list) then listKeys = list.Keys()
    listCount = listKeys.count() - 1
    for i = 0 to listCount step 1
      item = listKeys[i]
      if not isArray(list) then item = list[listKeys[i]]
      contentNodeItem = getContentNodeListItem(id, item, menuColor, model, invalid, Btype)
      contentNode.appendChild(contentNodeItem)
    end for
  end if
  return contentNode
End Function

Function getContentNodeListItem(id, list, menuColor, model, dataNode, Btype)
  contentNodeItem = CreateObject("roSGNode", "OTButtonInterface")
  contentNodeItem.id = id
  if list.id <> invalid then contentNodeItem.uId = list.id
  if list.groupId <> invalid then contentNodeItem.uId = list.groupId
  if list.sdkId <> invalid then contentNodeItem.uId = list.sdkId
  name = list.groupName
  if list.name <> invalid then name = list.name
  if name <> invalid then contentNodeItem.text = name
  if isString(list.vendorsLinkedInfo) then contentNodeItem.subText = list.vendorsLinkedInfo
  contentNodeItem.color = menuColor.color
  contentNodeItem.textColor = menuColor.textColor
  contentNodeItem.focusButtonColor = menuColor.focusColor
  contentNodeItem.focusButtonTextColor = menuColor.focusTextColor
  contentNodeItem.activeColor = menuColor.activeColor
  contentNodeItem.activeTextColor = menuColor.activeTextColor
  contentNodeItem.maxLines = 10
  contentNodeItem.fonts = model.fonts
  contentNodeItem.multiStyleFonts = model.multiStyleFonts
  if dataNode <> invalid then contentNodeItem.previousNode = dataNode
  contentNodeItem.purposeItem = list
  contentNodeItem.Btype = Btype
  if list.consentStatus <> invalid
    consentStatus = list.consentStatus
    ' if consentData <> invalid and consentData.OT_VendorConsents[contentNodeItem.uId] <> invalid
    '     consentStatus = consentData.OT_VendorConsents[contentNodeItem.uId]
    ' end if
    ' if consentData <> invalid and list.groupId <> invalid and consentData.purposesStatus[contentNodeItem.uId] <> invalid and consentData.purposesStatus[contentNodeItem.uId]["status"] <> invalid
    '     consentStatus = consentData.purposesStatus[contentNodeItem.uId]["status"]
    ' end if
    contentNodeItem.status = consentStatus
  end if
  if isValid(model.alwaysActiveNode) then contentNodeItem.alwaysActiveNode = model.alwaysActiveNode
  if isValid(model.activeTextNode) then contentNodeItem.activeTextNode = model.activeTextNode
  if isValid(model.inActiveTextNode) then contentNodeItem.inActiveTextNode = model.inActiveTextNode
  return contentNodeItem
End Function

Function getMenuViewContentNode(data, buttonsData, model, googleVendors)
  iabBtnNode = invalid
  googleBtnNode = invalid
  tempbuttonsData = {}
  if data.iabVendorsTitle <> invalid AND model.menu <> invalid
    tempbuttonsData["iab"] = buttonsData
    tempbuttonsData["iab"]["text"] = data.iabVendorsTitle
    iabBtnNode = PCbuttonContentNodeItem(tempbuttonsData, model, "iab")
  end if
  if data.googleVendorsTitle <> invalid AND googleVendors <> invalid AND googleVendors.vendors <> invalid
    tempbuttonsData["google"] = buttonsData
    tempbuttonsData["google"]["text"] = data.googleVendorsTitle
    googleBtnNode = PCbuttonContentNodeItem(tempbuttonsData, model, "google")
  end if
  return { iabBtnNode: iabBtnNode, googleBtnNode: googleBtnNode }
End Function

Function getFilterViewContentNode(buttonsData, model, width)
  maxheight = 0
  buttonList = []
  tempbuttonsData = {}
  contentNode = CreateObject("roSGNode", "ContentNode")
  googleContentNode = CreateObject("roSGNode", "ContentNode")
  tempbuttonsData["textFilter"] = buttonsData
  tempbuttonsData["textFilter"]["text"] = "A-F"
  buttonList.push(PCbuttonContentNodeItem(tempbuttonsData, model, "textFilter"))
  tempbuttonsData["textFilter"]["text"] = "G-L"
  buttonList.push(PCbuttonContentNodeItem(tempbuttonsData, model, "textFilter"))
  tempbuttonsData["textFilter"]["text"] = "M-R"
  buttonList.push(PCbuttonContentNodeItem(tempbuttonsData, model, "textFilter"))
  tempbuttonsData["textFilter"]["text"] = "S-Z"
  buttonList.push(PCbuttonContentNodeItem(tempbuttonsData, model, "textFilter"))
  tempbuttonsData["filterIcon"] = buttonsData
  tempbuttonsData["filterIcon"]["text"] = ""
  filterIcon = PCbuttonContentNodeItem(tempbuttonsData, model, "filterIcon")
  filterIcon.subText = m.WCAGRoles.button + "  .  " + m.WCAGRoles.filterAriaLabel
  buttonList.push(filterIcon)
  OTButtonView = CreateObject("roSGNode", "OTButtonView")
  bcount = 5
  bwidth = ((width * model.ratio[0]) - ((bcount - 1) * m.style.buttonItemSpacings[0])) / (bcount)
  gcount = 4
  gWidth = ((width * model.ratio[0]) - ((gcount - 1) * m.style.buttonItemSpacings[0])) / (gcount)
  OTButtonView.width = bwidth
  for each item in buttonList
    OTButtonView.itemContent = item
    height = OTButtonView.boundingRect().height
    if height > maxheight then maxheight = height
    if item.id <> "filterIcon" then googleContentNode.appendChild(item.clone(true))
    if (item.id = "filterIcon" AND model.showFilterIcon) OR item.id <> "filterIcon" then contentNode.appendChild(item)
  end for
  return { sdkList: contentNode, iab: contentNode, google: googleContentNode, height: maxheight, width: bwidth, gWidth: gWidth }
End Function

Function OTFilterListView(list, menuColor, model, width)
  sdkData = {
    sdkFilterContentNode: CreateObject("roSGNode", "ContentNode"),
    sdkListData: []
    sdkListGroupData: {
      purposeIdData: {}
      SdkIdData: {}
    }
  }
  iabFilterContentNode = CreateObject("roSGNode", "ContentNode")
  buttonColorCode = {
    color: model.backgroundColor
    textColor: model.itemDescription.textColor
    focusColor: model.buttonFocusColor
    focusTextColor: model.buttonFocusTextColor
    activeColor: menuColor.activeColor
    activeColor: menuColor.activeTextColor
  }
  if list <> invalid AND list.count() > 0
    listCount = list.count() - 1
    for i = 0 to listCount
      item = list[i]
      havingChildFirstPartyCookies = false

      ' Process children if they exist
      if isValid(item.children) AND item.children.count() > 0
        childCount = item.children.count() - 1
        for j = 0 to childCount
          childItem = item.children[j]
          if childItem.isIabPurpose <> invalid AND childItem.isIabPurpose
            iabFilterContentNode = appendIabFilterItem(childItem, buttonColorCode, model, iabFilterContentNode)
          else if childItem.showSDKListLink <> invalid AND childItem.showSDKListLink AND childItem.FirstPartyCookies <> invalid AND childItem.FirstPartyCookies.count() > 0
            sdkData = appendSdkFilterItem(childItem, buttonColorCode, model, sdkData)
            havingChildFirstPartyCookies = true
          end if
        end for
      end if

      ' Process the current item
      if item.isIabPurpose <> invalid AND item.isIabPurpose
        if not isIab_STACK(item.Type)
          iabFilterContentNode = appendIabFilterItem(item, buttonColorCode, model, iabFilterContentNode)
        end if
      else if item.showSDKListLink <> invalid AND item.showSDKListLink AND isValid(item.type) AND item.type <> "BRANCH" AND ((item.FirstPartyCookies <> invalid AND item.FirstPartyCookies.count() > 0) OR havingChildFirstPartyCookies)
        sdkData = appendSdkFilterItem(item, buttonColorCode, model, sdkData)
      end if
    end for
  end if
  model.sdkFilterListNode = sdkData.sdkFilterContentNode
  model.iabFilterListNode = iabFilterContentNode
  model.sdkListGroupData = sdkData.sdkListGroupData
  model.sdkListNode = OTListViewContentNode(getSortedList(sdkData.sdkListData, "name"), model.menu, model, width)
  return model
End Function

Function appendIabFilterItem(item, buttonColorCode, model, iabFilterContentNode)
  contentNodeItem = getContentNodeListItem("iabFilterList", item, buttonColorCode, model, invalid, "checkBox")
  contentNodeItem.status = 0
  contentNodeItem.subText = ""
  iabFilterContentNode.appendChild(contentNodeItem)
  return iabFilterContentNode
End Function

Function appendSdkFilterItem(item, buttonColorCode, model, sdkData)
  contentNodeItem = getContentNodeListItem("sdkFilterList", item, buttonColorCode, model, invalid, "checkBox")
  contentNodeItem.status = 0
  sdkData.sdkFilterContentNode.appendChild(contentNodeItem)

  if item.FirstPartyCookies <> invalid AND item.FirstPartyCookies.count() > 0
    if isString(item.parent)
      if not isValid(sdkData.sdkListGroupData["purposeIdData"][item.parent]) then sdkData.sdkListGroupData["purposeIdData"][item.parent] = []
      sdkData.sdkListGroupData["purposeIdData"][item.parent].push(item.groupId)
    end if
    FirstPartyCookiesCount = item.FirstPartyCookies.count() - 1
    for k = 0 to FirstPartyCookiesCount
      fItem = item.FirstPartyCookies[k]
      fItem["groupId"] = item["groupId"]
      fItem["parent"] = item["parent"]
      if not isValid(sdkData.sdkListGroupData["SdkIdData"][item["groupId"]]) then sdkData.sdkListGroupData["SdkIdData"][item["groupId"]] = []
      if isValid(fItem.sdkId) then sdkData.sdkListGroupData["SdkIdData"][item["groupId"]].push(fItem.sdkId)
      sdkData.sdkListData.push(fItem)
    end for
  end if
  return sdkData
End Function


Function getSortedList(list, key)
  tempList = []
  if isValid(list) AND list.count() > 0
    listKeys = list
    if not isArray(list) then listKeys = list.Keys()
    listCount = listKeys.count() - 1
    for i = 0 to listCount step 1
      item = listKeys[i]
      if not isArray(list) then item = list[listKeys[i]]
      tempList.push(item)
    end for
    tempList.sortBy(key, "i")
  end if
  return tempList
End Function

Function getGroupPrefixes(data)
  prefix = {}
  for each item in data.items()
    prefix[item.value] = item.key + "s"
  end for
  return prefix
End Function

Function updateFilterStatus(node)
  filterListNode = CreateObject("roSGNode", "ContentNode")
  list = node.getChildren(-1, 0)
  for each item in list
    item.status = 0
    if m.filteredListId.doesExist(item.uId) then item.status = 1
  end for
  filterListNode.appendChildren(list)
  return filterListNode
End Function

Function createConsentButton(id as String, btnNode as Object, data as Object, dataNode as Object, consentData as Object) as Object
  ' Initialize the button as invalid
  consentBtn = invalid

  ' Clone the button if valid
  if isValid(btnNode)
    consentBtn = btnNode.clone(true)
  end if

  ' Proceed only if the button is valid
  if consentBtn <> invalid
    consentBtn.id = id
    consentBtn.uId = dataNode.uId

    if data.parent <> invalid
      consentBtn.parentId = data.parent
    end if

    ' Determine consent status
    consentStatus = data.consentStatus
    if data.consentToggleStatus = 2
      consentStatus = data.consentToggleStatus
    else
      RConsents = getRegistryVendorStatus(consentData, consentBtn.uId, m.top.viewType)
      if consentData <> invalid AND RConsents <> invalid
        consentStatus = RConsents
      end if
      purposesStatusKey = getStatusKey(m.top.viewType)
      if consentData <> invalid AND consentData[purposesStatusKey][consentBtn.uId] <> invalid AND consentData[purposesStatusKey][consentBtn.uId]["status"] <> invalid
        consentStatus = getStatusBoolToNum(consentData[purposesStatusKey][consentBtn.uId]["status"])
      end if
    end if

    consentBtn.status = consentStatus
  end if

  return consentBtn
End Function