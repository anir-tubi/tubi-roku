Function updateDetailScreen(data)
  if isValid(data)
    detailScreenViewNode = getDetailScreenViewNode(data.purposeItem, m.dataModel, m.contentContainer.height, data)
    OTPCDetailScreenView = m.OTPCDetailScreenView
    if isValid(m.top.isChildScreen) AND m.top.isChildScreen then OTPCDetailScreenView = m.OTPCChildDetailScreenView
    itemFocusHandler(OTPCDetailScreenView, detailScreenViewNode)
    m.scrollThumb.height = scrollHeight()
  end if
End Function

sub setFocusChildDetailScreen(currentValue = invalid)
  if isValid(m.backButton) AND m.backButton.visible AND isValid(m.backButton.content)
    node = { value: m.backButton }
    path = [0, 0]
    if not isValid(currentValue) then currentValue = getDefaultvalue("down", {}, [{ value: m.OTConsentButtons }, { value: m.OTAdditionalButtons }])
    if isValid(currentValue) AND isValid(currentValue.["default"]) AND isValid(currentValue["defaultPath"])
      node = { value: currentValue["default"] }
      path = currentValue["defaultPath"]
      if isValid(m.scrollThumb) AND m.scrollThumb.visible
        setScrollOpacity(m.style.focusOpacity)
        resetScroll(invalid)
      end if
    end if
    setfocusNode(node, path)
  end if
end sub

sub onBackFocusChildDetailScreen(childData)
  itemFocused = invalid
  translation = invalid
  if isValid(childData)
    node = { value: childData.node }
    path = childData.key
    itemFocused = childData.itemFocused
    translation = childData.translation
  else if isValid(m.backButton) AND m.backButton.visible AND isValid(m.backButton.content)
    node = { value: m.backButton }
    path = [0, 0]
  else
    node = { value: m.OTConsentButtons }
    path = [1, 1]
  end if
  setfocusNode(node, path, invalid, translation, itemFocused)
end sub

sub setTextToSpeechDetailScreen(isSelected = false as Boolean, issearchNoResults = false as Boolean)
  if isValid(m.roAudioGuide) AND isValid(m.WCAGRoles)
    vendorQrCode = invalid
    if isValid(m.descriptionRec) AND m.descriptionRec.visible then vendorQrCode = m.descriptionRec.findNode("vendorQrCode")
    if isSelected
      m.roAudioGuide.Flush()
      if not (isValid(vendorQrCode) AND vendorQrCode.visible) then sayText(m.heading, m.WCAGRoles.headingAriaLabel)
    end if
    if issearchNoResults AND isValid(m.searchNoResultsFoundText) AND m.searchNoResultsFoundText.visible then sayText(m.searchNoResultsFoundText)
    if isValid(vendorQrCode) AND vendorQrCode.visible then sayPoster(vendorQrCode)
    subHeading = invalid
    if isValid(m.headerLayout) then subHeading = m.headerLayout.getChild(1)
    if isValid(subHeading) AND subHeading.id = "subHeading" then sayText(subHeading)
    if isValid(m.alwaysActiveLabel) then sayText(m.alwaysActiveLabel)
    if isValid(m.descriptionRec) AND m.descriptionRec.visible AND not (isValid(vendorQrCode) AND vendorQrCode.visible) then sayLayout(m.descriptionRec, "")
    if isValid(m.adtlDescriptionRec) AND m.adtlDescriptionRec.visible then sayLayout(m.adtlDescriptionRec, "")

    if isValid(m.policyLinkText) AND m.policyLinkText.visible AND isValid(m.qrCodeImg) AND m.qrCodeImg.visible
      sayPoster(m.qrCodeImg)
    end if
    if isValid(m.OTConsentButtons) AND m.OTConsentButtons.isInFocusChain()
      item = m.OTConsentButtons.getChild(0).getChild(m.OTConsentButtons.itemFocused)
      role = m.WCAGRoles.button
      role2 = m.WCAGRoles.selectedAriaLabel
      if isValid(item) AND (item.id = "legitInterestCheckBox" OR item.id = "consentCheckBox" OR item.id = "activeTextCheckBox" OR item.id = "inActiveTextCheckBox" OR item.id = "sdkFilterList" OR item.id = "iabFilterList")
        role = m.WCAGRoles.checkBoxDisabledAriaLabel
        if item.status = 1 then role = m.WCAGRoles.checkBoxEnabledAriaLabel
        role2 = ""
        if item.id = "iabFilterList" OR item.id = "sdkFilterList"
          Mcount = m.OTConsentButtons.content.getChildCount()
          itemFocused = m.OTConsentButtons.itemFocused + 1
          role2 = itemFocused.toStr() + " of " + Mcount.toStr()
        end if
      end if
      saylayout(item, role, role2)
    else if isValid(m.backButton) AND m.backButton.isInFocusChain()
      item = m.backButton.getChild(0).getChild(m.backButton.itemFocused)
      say(item.itemContent.subText, m.WCAGRoles.button, m.WCAGRoles.selectedAriaLabel)
    end if
  end if
end sub