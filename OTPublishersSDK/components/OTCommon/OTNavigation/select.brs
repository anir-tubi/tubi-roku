Function itemSelectedHandler(data, OTinitialize = invalid)
  if isValid(data) AND isValid(data.content) AND isValid(data.itemSelected)
    contentData = data.content.getChild(data.itemSelected)
    if contentData.id <> "iab" AND contentData.id <> "google"
      if contentData.interactionType <> invalid AND contentData.interactionType <> ""
        eventinteractionType = contentData.interactionType
        if isString(contentData.eventinteractionType) then eventinteractionType = contentData.eventinteractionType
        eventListeners(m.OTinitialize.top.eventlistener, eventinteractionType, true, "click")
        saveLogConsent(contentData, m.OTinitialize)
        closeOnetrustScreen(m.OTinitialize.OT_Data.view, m.OTinitialize, contentData.interactionType)
      else
        if contentData.id = "showPreferences"
          if OTinitialize <> invalid then OTinitialize.top.callFunc("showPreferenceCenterUI", true)
        end if
        if contentData.id = "vendorList"
          if OTinitialize <> invalid then OTinitialize.top.callFunc("showVendorListUI", true)
        end if
      end if
    end if
  end if
End Function

Function itemFocusHandler(node, data)
  node.data = data
End Function

Function closeOnetrustScreen(view, otsdk, interactionType = invalid)
  'm.logger.set(m.errortype.Info + "." + m.errortype.Banner, m.errorTags.EventListener, m.constant.listener["ELB105"])
  viewChildCount = view.getChildCount()
  isOTClose = false
  onHide = ""
  currentView = view.getChild(viewChildCount - 1)
  if currentView.id = "OTBanner" then onHide = m.constant.listener["ELB105"]
  if currentView.id = "OTPreferenceCenter" then onHide = m.constant.listener["ELP110"]
  if currentView.id = "OTVendorList"
    if currentView.viewType = "sdkList" then eventName = m.constant.listener["ELS100"] else eventName = m.constant.listener["ELV100"]
    onHide = eventName
  end if
  onScreen = ""
  for i = viewChildCount to 1 step -1
    child = view.getChild(i - 1)
    if child <> invalid AND (child.id.Instr("OTPreferenceCenter") <> -1 OR child.id.Instr("OTVendorList") <> -1 OR (child.id.Instr("OTBanner") <> -1 AND interactionType <> invalid))
      view.removeChild(child)
      onDestroyView(child, interactionType)
      isOTClose = true
      if not isString(interactionType)
        ichild = view.getChild(i - 2)
        if ichild <> invalid AND (ichild.id = "OTBanner" OR ichild.id = "OTPreferenceCenter")
          isOTClose = false
          ichild.callFunc("setViewFocus", {})
          if ichild.id = "OTBanner" then onScreen = m.constant.listener["ELB115"]
          if ichild.id = "OTPreferenceCenter" then onScreen = m.constant.listener["ELP115"]
        end if
        exit for
      end if
    else
      exit for
    end if
  end for

  if isString(onHide)
    eventListeners(otsdk.top.eventlistener, onHide)
  end if
  if isString(onScreen)
    eventListeners(otsdk.top.eventlistener, onScreen)
  end if

  if isOTClose
    otsdk.consentData.purposesStatus = {}
    otsdk.consentData.iabVendorsStatus = {}
    otsdk.consentData.googleVendorsStatus = {}
    otsdk.consentData.sdkStatus = {}
    eventListeners(otsdk.top.eventlistener, "allSDKViewsDismissed", interactionType)
  end if
End Function

Function onDestroyView(view, interactionType)
  ' Assume vendorView is a previously created roSGNode
  if view <> invalid
    ' Remove from parent if necessary
    'parent = view.getParent()
    if view.parent <> invalid
      view.parent.RemoveChild(view)
    end if

    ' Clear references
    view.removeChildren(view.getChildren(-1, 0))
    view = invalid
  end if

  ' Optional: Force garbage collection
  if not isString(interactionType) then RunGarbageCollector()
End Function

Function navigateOK(focusValue)
  if focusValue <> invalid AND focusValue.value <> invalid AND focusValue.value.visible AND focusValue.value.focusedChild <> invalid
    getPurposesStatus(focusValue)
    setAdditionalButtons(focusValue)
    setPurposeChild(focusValue)
    selectBackButton(focusValue)
    onClickQrcode(focusValue)
    onclickVendorbtn(focusValue)
    onclickFilterListItem(focusValue)
  end if
End Function

Function getPurposesStatus(focusValue)
  if focusValue.value.id = "OTConsentButtons"
    focusNode = getFocusedChild(focusValue)
    if isValid(focusNode) AND (focusNode.id = "consentCheckBox" OR focusNode.id = "legitInterestCheckBox" OR focusNode.id = "activeTextCheckBox" OR focusNode.id = "inActiveTextCheckBox")
      updateConsents(focusNode, m.OTinitialize, m.top.viewType)
      role = m.WCAGRoles.checkBoxDisabledAriaLabel
      if focusNode.status = 1 then role = m.WCAGRoles.checkBoxEnabledAriaLabel
      say(focusNode.itemContent.text, role, "", true)
    end if
  end if
End Function

Function setAdditionalButtons(focusValue)
  if focusValue.value.id = "OTAdditionalButtons"
    focusNode = getFocusedChild(focusValue)
    if isValid(focusNode)
      if focusNode.itemContent.id = "viewIllustrations"
        m.top.slideLayer += 1
        if isValid(m.childData)
          m.childData.push({
            node: focusValue.value,
            key: m.navDirections.key,
            itemFocused: focusValue.value.itemFocused,
            translation: [m.detailScreenlayoutScroll.translation, m.scrollThumb.translation]
          })
        end if
        focusNode.itemUnfocused = true
        if isValid(m.top.isChildScreen) then m.top.isChildScreen = true
        updateDetailScreen(focusNode.itemContent)
        setFocusChildDetailScreen()
        setTextToSpeechDetailScreen(true)
      end if
      if focusNode.itemContent.id = "vendorListTextBtn"
        m.OTinitialize.top.callFunc("showVendorListUI", m.top.bannerExits, "iab", getSelectedFilteredData(focusNode.itemContent.purposeItem, "iab"))
      end if
      if focusNode.itemContent.id = "sdkListTextBtn"
        m.OTinitialize.top.callFunc("showVendorListUI", m.top.bannerExits, "sdkList", getSelectedFilteredData(focusNode.itemContent.purposeItem, "sdkList"))
      end if
    end if
  end if
End Function

Function getSelectedFilteredData(data, viewType)
  selectedFilteredData = {}
  if isValid(data) AND isString(data.groupId)
    isIabPurpose = data.isIabPurpose <> invalid AND data.isIabPurpose
    if (viewType = "sdkList" AND not isIabPurpose) OR (viewType = "iab" AND isIabPurpose)
      if not isIab_STACK(data.Type) then selectedFilteredData[data.groupId] = 1
      if isValid(data.children) AND data.children.count() > 0
        for each item in data.children
          if isString(item.groupId) then selectedFilteredData[item.groupId] = 1
        end for
      end if
    end if
  end if
  return selectedFilteredData
End Function

Function isIab_STACK(iab_type)
  return iab_type <> invalid AND iab_type.Instr("_STACK") <> -1
End Function

Function setPurposeChild(focusValue)
  if focusValue.value.id = "OTPurposeChildButtons"
    focusNode = getFocusedChild(focusValue)
    if isValid(focusNode)
      m.top.slideLayer += 1
      if isValid(m.childData)
        m.childData.push({
          node: focusValue.value,
          key: m.navDirections.key,
          itemFocused: focusValue.value.itemFocused,
          translation: [m.detailScreenlayoutScroll.translation, m.scrollThumb.translation]
        })
      end if
      focusNode.itemUnfocused = true
      if isValid(m.top.isChildScreen) then m.top.isChildScreen = true
      updateDetailScreen(focusNode.itemContent)
      setFocusChildDetailScreen()
      setTextToSpeechDetailScreen(true)
    end if
  end if
End Function

Function selectBackButton(focusValue)
  isMainBack = true
  if focusValue.value.id = "backButton"
    if isValid(m.top.isChildScreen) AND m.top.isChildScreen
      focusNode = getFocusedChild(focusValue)
      if isValid(focusNode)
        setChildBackButton(focusNode.itemContent)
        isMainBack = false
      end if
    end if
    if isMainBack then navigation1("back", true)
  end if
End Function

sub setChildBackButton(itemContent)
  resetScroll({ value: m.navDirections.scrollValue }, [{ value: m.OTConsentButtons }])
  previousNode = itemContent.previousNode
  childData = m.childData.pop()
  if isValid(m.filteredListId) AND isValid(childData) AND isValid(childData.filteredListId) then m.filteredListId = childData.filteredListId
  if isValid(m.top.isChildScreen) AND m.top.slideLayer = 1
    m.OTPCChildDetailScreenView.slide = true
    m.top.isChildScreen = false
  end if
  if isValid(previousNode) then updateDetailScreen(previousNode)
  m.top.slideLayer -= 1
  onBackFocusChildDetailScreen(childData)
end sub

Function onClickQrcode(focusValue)
  if focusValue.value.id = "OTAdditionalButtons"
    focusNode = getFocusedChild(focusValue)
    if isValid(focusNode) AND (focusNode.id = "vendorsPolicyBtn" OR focusNode.id = "legIntClaimPolicyBtn")
      qrCodeDialog(focusNode.itemContent, focusValue, focusNode)
    end if
  end if
End Function

Function qrCodeDialog(item, focusValue, focusNode)
  if item.text <> invalid AND item.url <> invalid AND item.text <> "" AND item.url <> ""
    m.top.slideLayer += 1
    if isValid(m.childData)
      m.childData.push({
        node: focusValue.value,
        key: m.navDirections.key,
        itemFocused: focusValue.value.itemFocused,
      })
    end if
    focusNode.itemUnfocused = true
    if isValid(m.top.isChildScreen) then m.top.isChildScreen = true
    updateDetailScreen(item)
    setFocusChildDetailScreen()
    setTextToSpeechDetailScreen(true)
  end if
End Function

Function onclickVendorbtn(focusValue)
  if focusValue.value.id = "OTConsentButtons"
    focusNode = getFocusedChild(focusValue)
    if isValid(focusNode)
      if focusNode.id = "iabVendorsBtn" then m.OTinitialize.top.callFunc("showVendorListUI", m.top.bannerExits)
      if focusNode.id = "googleVendorsBtn" then m.OTinitialize.top.callFunc("showVendorListUI", m.top.bannerExits, "google")
    end if
  end if
End Function

Function onclickFilterListItem(focusValue)
  if focusValue.value.id = "OTConsentButtons"
    focusNode = getFocusedChild(focusValue)
    if isValid(focusNode) AND isValid(m.filteredListId) AND (focusNode.id = "sdkFilterList" OR focusNode.id = "iabFilterList")
      groupid = focusNode.itemContent.uId
      if focusNode.status = 0
        focusNode.status = 1
        m.filteredListId[groupid] = focusNode.status
      else if focusNode.status = 1
        focusNode.status = 0
        if m.filteredListId.doesExist(groupid) then m.filteredListId.delete(groupid)
      end if
      role = m.WCAGRoles.checkBoxDisabledAriaLabel
      if focusNode.status = 1 then role = m.WCAGRoles.checkBoxEnabledAriaLabel
      say(focusNode.itemContent.text, role, "", true)
    end if
  end if
End Function

Function getFocusedChild(focusValue)
  childNode = invalid
  if isValid(focusValue) AND isValid(focusValue.value) AND isValid(focusValue.value.focusedChild) AND isValid(focusValue.value.focusedChild.focusedChild)
    childNode = focusValue.value.focusedChild.focusedChild
  end if
  return childNode
End Function