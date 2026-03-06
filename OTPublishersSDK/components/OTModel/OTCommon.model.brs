Function setbPCTextModel(data, regx, removeHTMLTags = false)
  contentNodeItem = CreateObject("roSGNode", "OTTextInterface")
  if data <> invalid AND data.text <> invalid AND data.text.Trim() <> ""
    text = regx.replaceAll(data.text, " ")
    if removeHTMLTags then text = StringRemoveHTMLTags(data.text)
    contentNodeItem.text = text
  end if
  if data.textColor <> invalid then contentNodeItem.textColor = data.textColor
  if data.urlQRCode <> invalid then contentNodeItem.url = data.urlQRCode
  return contentNodeItem
End Function

Function PCbuttonContentNodeItem(button as Object, model, id as String, Btype = "rectangleBtn", eventinteractionType = "")
  isBorder = false
  if model.border <> invalid AND model.border then isBorder = true
  btext = button[id].text
  textColor = button[id].textColor
  color = button[id].color
  maxLines = 3
  position = 0
  if button[id].position <> invalid then position = button[id].position
  if id = "closeButton"
    btext = ""
    textColor = "0x000000"
    Btype = "circleBtn"
    color = model.itemDescription.textColor
    textColor = model.itemDescription.textColor
    maxLines = 2
    'if button[id].imgcolor <> invalid then textColor = button[id].imgcolor
    if button[id].showText <> invalid AND button[id].showText
      Btype = "rectangleBtn"
      btext = button[id].text
      color = button[id].color
      textColor = button[id].textColor
      if button[id].showAsLink <> invalid AND button[id].showAsLink
        isBorder = false
        color = model.backgroundColor
        textColor = model.itemDescription.textColor
      end if
    end if
  end if

  contentNodeItem = CreateObject("roSGNode", "OTButtonInterface")
  contentNodeItem.id = id
  contentNodeItem.text = btext
  contentNodeItem.color = color
  contentNodeItem.textColor = textColor
  contentNodeItem.focusButtonColor = model.buttonFocusColor
  contentNodeItem.focusButtonTextColor = model.buttonFocusTextColor
  contentNodeItem.border = isBorder
  contentNodeItem.position = position
  contentNodeItem.maxLines = maxLines
  contentNodeItem.Btype = Btype
  contentNodeItem.fonts = model.fonts
  contentNodeItem.horizAlign = "center"
  contentNodeItem.interactionType = button[id].interactionType
  contentNodeItem.eventinteractionType = eventinteractionType
  contentNodeItem.activeColor = model.buttonActiveColor
  contentNodeItem.activeTextColor = model.buttonActiveTextColor
  if isValid(model)
    if isValid(model.itemDescription) AND isString(model.itemDescription.textColor) then contentNodeItem.descriptionColor = model.itemDescription.textColor
  end if
  return contentNodeItem
End Function

Function buttonBackNodeItem(backButton, model, id as String)
  contentNodeItem = CreateObject("roSGNode", "OTButtonInterface")
  contentNodeItem.id = id
  contentNodeItem.subText = backButton.backBtnVoiceOverText
  contentNodeItem.color = model.itemDescription.textColor
  contentNodeItem.textColor = model.itemDescription.textColor
  contentNodeItem.focusButtonColor = model.buttonFocusColor
  contentNodeItem.focusButtonTextColor = model.buttonFocusTextColor
  return contentNodeItem
End Function

Function getStatusBoolToNum(status)
  tempStatus = 0
  if status then tempStatus = 1
  return tempStatus
End Function

Function updateConsents(focusNode, OTinitialize, viewType = invalid)
  if isValid(focusNode)
    isInteractionChoice = not (focusNode.id = "activeTextCheckBox" OR focusNode.id = "inActiveTextCheckBox")
    if isInteractionChoice OR (not ((focusNode.status = 0 AND focusNode.id = "inActiveTextCheckBox") OR (focusNode.status = 1 AND focusNode.id = "activeTextCheckBox")) AND not isInteractionChoice)
      groupid = focusNode.itemContent.uId
      parentGroupId = invalid
      ParentFirstPartyCookies = invalid
      purposeItem = invalid
      sdkPurposesStatusKey = invalid
      sdkPurposesStatus = invalid
      if isString(focusNode.itemContent.parentId) then parentGroupId = focusNode.itemContent.parentId
      if isValid(focusNode.itemContent.purposeItem) then purposeItem = focusNode.itemContent.purposeItem
      status = "status"
      consentData = OTinitialize.consentData
      purposesStatusKey = getStatusKey(viewType)
      purposesStatus = consentData[purposesStatusKey]
      purposesStatusEvent = {}
      consentstatus = invalid
      if isString(focusNode.id) AND focusNode.id = "legitInterestCheckBox"
        status = "liStatus"
        if groupid <> invalid
          consentstatusNum = getRegistryVendorStatus(consentData, groupid, viewType, "OT_VendorConsents")
          if consentstatusNum <> invalid consentstatus = consentstatusNum = 1
        end if
      end if
      if purposesStatusKey = "purposesStatus" AND status = "status"
        sdkPurposesStatusKey = "sdkStatus"
        sdkPurposesStatus = consentData[sdkPurposesStatusKey]
      end if
      purposeidKey = getPurposeidKey(viewType)
      if purposesStatus[groupid] = invalid then purposesStatus[groupid] = {}
      purposesStatus[groupid][purposeidKey] = groupid
      if focusNode.status = 0
        purposesStatus[groupid][status] = true
        purposesStatusEvent[groupid] = true
        focusNode.status = 1
      else if focusNode.status = 1
        purposesStatus[groupid][status] = false
        purposesStatusEvent[groupid] = false
        focusNode.status = 0
      end if
      if not isInteractionChoice AND isValid(m.OTConsentButtons) AND m.OTConsentButtons.visible AND isValid(m.OTConsentButtons.content)
        activeCheckBox = invalid
        if focusNode.id = "inActiveTextCheckBox" then activeCheckBox = m.OTConsentButtons.findNode("activeTextCheckBox")
        if focusNode.id = "activeTextCheckBox" then activeCheckBox = m.OTConsentButtons.findNode("inActiveTextCheckBox")
        if isValid(activeCheckBox) then activeCheckBox.status = focusNode.status
      end if
      if consentstatus <> invalid AND purposesStatus[groupid] <> invalid AND purposesStatus[groupid]["status"] = invalid then purposesStatus[groupid]["status"] = consentstatus

      if isString(sdkPurposesStatusKey) AND isValid(sdkPurposesStatus) AND isValid(purposeItem) AND isValid(purposesStatus[groupid][status])
        sdkPurposesStatus = updateSdkPurposesStatus(purposeItem.FirstPartyCookies, sdkPurposesStatus, status, purposesStatus[groupid][status])
      end if

      if isString(focusNode.id) AND (focusNode.id = "consentCheckBox" OR focusNode.id = "activeTextCheckBox" OR focusNode.id = "inActiveTextCheckBox") AND m.OTPurposeChildButtons <> invalid AND m.OTPurposeChildButtons.content <> invalid AND (m.OTPurposeChildButtons.visible OR isValid(parentGroupId))
        parentStatus = false
        if m.OTPurposeChildButtons.visible OR (isValid(parentGroupId) AND purposesStatus[groupid][status])
          parentStatus = true
          Lcount = m.OTPurposeChildButtons.content.getChildCount()
          for i = 0 to Lcount - 1
            child = m.OTPurposeChildButtons.content.getChild(i)
            cGroupid = child.uId
            if child.status <> 2
              if isValid(parentGroupId)
                cStatus = child.status = 1
                if cGroupid = groupid then cStatus = purposesStatus[groupid][status]
                if not cStatus
                  parentStatus = false
                  exit for
                end if
              else
                if purposesStatus[cGroupid] = invalid then purposesStatus[cGroupid] = {}
                purposesStatus[cGroupid][purposeidKey] = cGroupid
                purposesStatus[cGroupid][status] = purposesStatus[groupid][status]

                if isString(sdkPurposesStatusKey) AND isValid(sdkPurposesStatus) AND isValid(purposeItem) AND isValid(purposesStatus[groupid][status])
                  sdkPurposesStatus = updateSdkPurposesStatus(purposeItem.children[i].FirstPartyCookies, sdkPurposesStatus, status, purposesStatus[groupid][status])
                end if

                if purposesStatusEvent["children"] = invalid then purposesStatusEvent["children"] = {}
                purposesStatusEvent["children"][cGroupid] = purposesStatus[cGroupid][status]
                child.status = focusNode.status
              end if
            end if
          end for
        end if
        if isValid(parentGroupId)
          if purposesStatus[parentGroupId] = invalid then purposesStatus[parentGroupId] = {}
          purposesStatus[parentGroupId][purposeidKey] = parentGroupId
          purposesStatus[parentGroupId][status] = parentStatus

          if isString(sdkPurposesStatusKey) AND isValid(sdkPurposesStatus) AND isValid(purposeItem) AND isValid(parentStatus)
            if isValid(focusNode.itemContent.ParentFirstPartyCookies) AND focusNode.itemContent.ParentFirstPartyCookies.count() > 0 then ParentFirstPartyCookies = focusNode.itemContent.ParentFirstPartyCookies
            sdkPurposesStatus = updateSdkPurposesStatus(ParentFirstPartyCookies, sdkPurposesStatus, status, parentStatus)
          end if

          if purposesStatusEvent["parent"] = invalid then purposesStatusEvent["parent"] = {}
          purposesStatusEvent["parent"][parentGroupId] = parentStatus
        end if
      end if

      consentData[purposesStatusKey] = purposesStatus
      if isString(sdkPurposesStatusKey) AND isValid(sdkPurposesStatus) then consentData[sdkPurposesStatusKey] = sdkPurposesStatus

      if isString(purposesStatusKey) AND purposesStatusKey = "sdkStatus"
        consentData = onchangeSdkStatusUpdatePurpose(purposesStatus, consentData, purposeItem, purposesStatus[groupid][status])
      end if

      OTinitialize.consentData = consentData
      eventName = ""
      if purposesStatusKey = "purposesStatus" AND status = "status" then eventName = m.constant.listener["ELP105"]
      if purposesStatusKey = "purposesStatus" AND status = "liStatus" then eventName = m.constant.listener["ELP104"]
      if purposesStatusKey = "iabVendorsStatus" then eventName = m.constant.listener["ELV107"]
      if purposesStatusKey = "iabVendorsStatus" AND status = "liStatus" then eventName = m.constant.listener["ELV108"]
      if purposesStatusKey = "googleVendorsStatus" then eventName = m.constant.listener["ELV107"]
      if purposesStatusKey = "sdkStatus" then eventName = m.constant.listener["ELS104"]
      if isString(eventName) then eventListeners(OTinitialize.top.eventlistener, eventName, purposesStatusEvent)
    end if
  end if
End Function

Function updateSdkPurposesStatus(FirstPartyCookies, sdkPurposesStatus, statusKey, status)
  if isArray(FirstPartyCookies) AND FirstPartyCookies.count() > 0
    for k = 0 to FirstPartyCookies.count() - 1
      item = FirstPartyCookies[k]
      if sdkPurposesStatus[item.sdkId] = invalid then sdkPurposesStatus[item.sdkId] = {}
      sdkPurposesStatus[item.sdkId]["sdkId"] = item.sdkId
      sdkPurposesStatus[item.sdkId][statusKey] = status
    end for
  end if
  return sdkPurposesStatus
End Function

Function onchangeSdkStatusUpdatePurpose(purposesStatus, consentData, purposeItem, status)
  if isValid(m.sdkListGroupData) AND isString(purposeItem.sdkId)
    if isString(purposeItem.groupId)
      if isValid(m.sdkListGroupData.sdkiddata) AND isValid(m.sdkListGroupData.sdkiddata[purposeItem.groupId])
        sdkList = m.sdkListGroupData.sdkiddata[purposeItem.groupId]
        tempStatus = status
        for each item in sdkList
          if isValid(consentData["OT_SdkConsents"]) AND isValid(consentData["OT_SdkConsents"][item]) then tempStatus = consentData["OT_SdkConsents"][item] = 1
          if isValid(purposesStatus[item]) then tempStatus = purposesStatus[item].status
          if status <> tempStatus then exit for
        end for
        if tempStatus = status

          purposeGroupId = purposeItem.groupId
          isParent = false
          if isString(purposeItem.parent)
            purposeGroupId = purposeItem.parent
            isParent = true
          end if

          tempPurposesStatus = consentData["purposesStatus"]
          tempSDKListStatus = consentData["sdkStatus"]
          tempPurposesStatus = updateStatusinlocal(tempPurposesStatus, purposeItem.groupId, status, "groupId")

          if isValid(m.sdkListGroupData.purposeiddata) AND isArray(m.sdkListGroupData.purposeiddata[purposeGroupId]) AND m.sdkListGroupData.purposeiddata[purposeGroupId].count() > 0
            pcount = m.sdkListGroupData.purposeiddata[purposeGroupId].count() - 1
            for i = 0 to pcount
              pitem = m.sdkListGroupData.purposeiddata[purposeGroupId][i]
              if not isParent then tempPurposesStatus = updateStatusinlocal(tempPurposesStatus, pitem, status, "groupId")
              if isValid(m.sdkListGroupData.sdkiddata) AND isValid(m.sdkListGroupData.sdkiddata[pitem]) AND m.sdkListGroupData.sdkiddata[pitem].count() > 0
                sdkListCount = m.sdkListGroupData.sdkiddata[pitem].count() - 1
                for k = 0 to sdkListCount
                  listItem = m.sdkListGroupData.sdkiddata[pitem][k]
                  if not isParent then tempSDKListStatus = updateStatusinlocal(tempSDKListStatus, listItem, status, "sdkId")
                  if isParent
                    if isValid(consentData["OT_SdkConsents"]) AND isValid(consentData["OT_SdkConsents"][listItem]) then tempStatus = consentData["OT_SdkConsents"][listItem] = 1
                    if isValid(purposesStatus[listItem]) then tempStatus = purposesStatus[listItem].status
                    if status <> tempStatus then exit for
                  end if
                end for
                if isParent AND status <> tempStatus then exit for
              end if
            end for
          end if

          if isParent AND (status = tempStatus OR not status)
            tempPurposesStatus = updateStatusinlocal(tempPurposesStatus, purposeGroupId, status, "groupId")
            if isValid(m.sdkListGroupData.sdkiddata) AND isValid(m.sdkListGroupData.sdkiddata[purposeGroupId]) AND m.sdkListGroupData.sdkiddata[purposeGroupId].count() > 0
              sdkListCount = m.sdkListGroupData.sdkiddata[purposeGroupId].count() - 1
              for k = 0 to sdkListCount
                listItem = m.sdkListGroupData.sdkiddata[purposeGroupId][k]
                tempSDKListStatus = updateStatusinlocal(tempSDKListStatus, listItem, status, "sdkId")
              end for
            end if
          end if
          consentData["sdkStatus"] = tempSDKListStatus
          consentData["purposesStatus"] = tempPurposesStatus
        end if
      end if
    end if
  end if
  return consentData
End Function

Function updateStatusinlocal(tempSDKListStatus, listItem, status, key)
  if tempSDKListStatus[listItem] = invalid then tempSDKListStatus[listItem] = {}
  tempSDKListStatus[listItem][key] = listItem
  tempSDKListStatus[listItem]["status"] = status
  return tempSDKListStatus
End Function

Function getStatusKey(viewType)
  purposesStatusKey = "purposesStatus"
  if viewType <> invalid AND viewType = "iab" then purposesStatusKey = "iabVendorsStatus"
  if viewType <> invalid AND viewType = "google" then purposesStatusKey = "googleVendorsStatus"
  if viewType <> invalid AND viewType = "sdkList" then purposesStatusKey = "sdkStatus"
  return purposesStatusKey
End Function

Function getRegistryVendorStatus(consentData, uId, viewType, iskey = invalid)
  status = invalid
  if viewType = "sdkList" AND consentData.OT_SdkConsents[uId] <> invalid
    status = consentData.OT_SdkConsents[uId]
  else if viewType = "iab"
    status = getRegistryIabStatus(consentData, uId, iskey)
  else if viewType = "google" AND isString(consentData.OT_AddtlConsent)
    OT_AddtlConsent = consentData.OT_AddtlConsent.replace("1~", ".") + "."
    matchArray = OT_AddtlConsent.split("." + uId + ".")
    status = 0
    if matchArray <> invalid AND matchArray.count() > 1 then status = 1
  else if viewType = invalid
    status = consentData.OT_GroupConsents[uId]
  end if
  return status
End Function

Function getRegistryIabStatus(consentData, uId, iskey)
  status = invalid
  if isValid(iskey) AND isValid(consentData) AND isString(consentData[iskey])
    OT_VendorConsents = consentData.[iskey].split("")
    uId = (uId.toInt() - 1)
    if OT_VendorConsents <> invalid AND OT_VendorConsents.count() > 0 AND (OT_VendorConsents[uId] = "0" OR OT_VendorConsents[uId] = "1")
      status = OT_VendorConsents[uId].ToInt()
    end if
  end if
  return status
End Function

Function getPurposeidKey(viewType)
  purposeidKey = "groupId"
  if viewType <> invalid AND (viewType = "iab" OR viewType = "google") then purposeidKey = "vId"
  if viewType <> invalid AND viewType = "sdkList" then purposeidKey = "sdkId"
  return purposeidKey
End Function

Function StringRemoveHTMLTags(baseStr as String) as String
  if isString(baseStr)
    baseStr = baseStr.Replace("\n", "")
    regexPreserve = CreateObject("roRegex", "<b>\d+</b>", "i")
    matches = regexPreserve.MatchAll(baseStr)
    for each match in matches
      placeholder = match[0].Replace("<b>", "###/")
      placeholder = placeholder.Replace("</b>", "/###")
      baseStr = baseStr.Replace(match[0], placeholder)
    end for
    r = createObject("roRegex", "<[^<]+?>", "i")
    baseStr = r.replaceAll(baseStr, "")
    baseStr = baseStr.Replace("###/", "<b>")
    baseStr = baseStr.Replace("/###", "</b>")
  end if
  return baseStr
End Function

Function getBackButtonContentNode(backButton, dataNode)
  'backcontentNode = CreateObject("roSGNode", "ContentNode")
  'backButton.id = "backButton"
  'backButton.position = position
  backButton.previousNode = dataNode.previousNode
  'backcontentNode.appendChild(backButton)
  return backButton
End Function

Function getWCAGRoles(data)
  WCAGRoles = CreateObject("roSGNode", "OTWCAGInterface")
  if isValid(m.global.OT_Data) AND isValid(m.global.OT_Data["WCAGRoles"]) then WCAGRoles = m.global.OT_Data["WCAGRoles"]
  if isValid(data) AND isValid(data.general)
    if isValid(data.general.listAriaLabel) then WCAGRoles.listAriaLabel = data.general.listAriaLabel
    if isValid(data.general.listItemAriaLabel) then WCAGRoles.listItemAriaLabel = data.general.listItemAriaLabel
    if isValid(data.general.checkBoxEnabledAriaLabel) then WCAGRoles.checkBoxEnabledAriaLabel = data.general.checkBoxEnabledAriaLabel
    if isValid(data.general.checkBoxDisabledAriaLabel) then WCAGRoles.checkBoxDisabledAriaLabel = data.general.checkBoxDisabledAriaLabel
    ' if isValid(data.general.sdkListTitleAriaLabel) then WCAGRoles.sdkListTitleAriaLabel = data.general.sdkListTitleAriaLabel
    ' if isValid(data.general.filterSDKListAriaLabel) then WCAGRoles.filterSDKListAriaLabel = data.general.filterSDKListAriaLabel
    if isValid(data.general.alphabeticFilterAriaLabel) then WCAGRoles.alphabeticFilterAriaLabel = data.general.alphabeticFilterAriaLabel
    ' if isValid(data.general.copyConfirmationAriaLabel) then WCAGRoles.copyConfirmationAriaLabel = data.general.copyConfirmationAriaLabel
    if isValid(data.general.clearButtonAnnouncement) then WCAGRoles.clearButtonAnnouncement = data.general.clearButtonAnnouncement
    if isValid(data.general.qrCodeAriaLabel) then WCAGRoles.qrCodeAriaLabel = data.general.qrCodeAriaLabel
    if isValid(data.general.filterAriaLabel) then WCAGRoles.filterAriaLabel = data.general.filterAriaLabel
    if isValid(data.general.headingAriaLabel) then WCAGRoles.headingAriaLabel = data.general.headingAriaLabel
    if isValid(data.general.selectedAriaLabel) then WCAGRoles.selectedAriaLabel = data.general.selectedAriaLabel
    if isValid(data.general.activeAriaLabel) then WCAGRoles.activeAriaLabel = data.general.activeAriaLabel
  end if
  if WCAGRoles.qrCodeAriaLabel.Instr("[X]") <> -1 then WCAGRoles.qrCodeAriaLabel = WCAGRoles.qrCodeAriaLabel.Replace("[X]", "<X>")
  if WCAGRoles.alphabeticFilterAriaLabel.Instr("[X]") <> -1 then WCAGRoles.alphabeticFilterAriaLabel = WCAGRoles.alphabeticFilterAriaLabel.Replace("[X]", "<X>")
  if WCAGRoles.alphabeticFilterAriaLabel.Instr("[Y]") <> -1 then WCAGRoles.alphabeticFilterAriaLabel = WCAGRoles.alphabeticFilterAriaLabel.Replace("[Y]", "<Y>")
  if isValid(m.global.OT_Data)
    OT_Data = m.global.OT_Data
    OT_Data["WCAGRoles"] = WCAGRoles
    m.global.OT_Data = OT_Data
  end if
End Function