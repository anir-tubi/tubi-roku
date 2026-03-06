Function getPreferenceCenterData() as Object
  pcUIData = {}
  if isValid(optionalChaining(m, "OT_Data.OT_modelData.pcUIData"))
    pcUIData = m.OT_Data.OT_modelData
  else
    m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, "Preference center", m.constant.error["506"])
  end if
  return pcUIData
End Function

Function getVendorListData()
  pcUIData = {}
  if isValid(optionalChaining(m, "OT_Data.OT_modelData.vendorListUIData"))
    pcUIData = m.OT_Data.OT_modelData
  else
    m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, "vendor list", m.constant.error["506"])
  end if
  return pcUIData
End Function

Function getBannerData() as Object
  return m.OT_Data["OT_modelData"]
End Function

' Return consent status of GroupId.
' @param customGroupID groupID
' @return return consent status of GroupId.
' 1 = Consent is given
' 0 = Consent is not given
' -1 = Consent has not been collected (The SDK is not initialized OR there are no SDKs associated to this category)
Function getConsentStatusForGroupID(groupId as String) as Integer
  m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "getConsentStatusForGroupID" + m.constant.info["705"])
  status = -1
  if isString(groupId)
    OT_GroupConsents = optionalChaining(m, "consentData.OT_GroupConsents")
    if not (isValid(OT_GroupConsents) AND isValid(OT_GroupConsents[groupId]))
      OT_GroupConsents = m.registry.read("OT_GroupConsents")
      if isValid(OT_GroupConsents) then OT_GroupConsents = ParseJson(OT_GroupConsents)
    end if
    if isValid(OT_GroupConsents) AND isValid(OT_GroupConsents[groupId]) then status = OT_GroupConsents[groupId]
  end if
  if status = -1 then m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "Invalid custom group Id passed - " + groupId)
  return status
End Function

' Return consent status of skdId.
' @param customGroupID skdId
' @return return consent status of skdId.
' 1 = Consent is given
' 0 = Consent is not given
' -1 = Consent has not been collected (The SDK is not initialized OR there are no SDKs associated to this category)
Function getConsentStatusForSDKId(skdId as String) as Integer
  m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "getConsentStatusForSDKId" + m.constant.info["705"])
  status = -1
  if isString(skdId)
    OT_SdkConsents = optionalChaining(m, "consentData.OT_SdkConsents")
    if not (isValid(OT_SdkConsents) AND isValid(OT_SdkConsents[skdId]))
      OT_SdkConsents = m.registry.read("OT_SdkConsents")
      if isValid(OT_SdkConsents) then OT_SdkConsents = ParseJson(OT_SdkConsents)
    end if
    if isValid(OT_SdkConsents) AND isValid(OT_SdkConsents[skdId]) then status = OT_SdkConsents[skdId]
  end if
  if status = -1 then m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "Invalid custom sdk Id passed - " + skdId)
  return status
End Function

' Return consent status of vendorId.
' @param OTVendorListMode vendorId
' @return return consent status of vendorId.
' 1 = Consent is given
' 0 = Consent is not given
' -1 = Consent has not been collected (The SDK is not initialized OR there are no SDKs associated to this category)
Function getConsentStatusForVendorId(OTVendorListMode as String, vendorId as String) as Integer
  m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "getConsentStatusForVendorId" + m.constant.info["705"])
  status = -1
  if isString(vendorId) AND isString(OTVendorListMode)
    consentData = m.consentData
    if LCase(OTVendorListMode) = "iab"
      status = getRegistryIabStatus1(consentData, vendorId, "OT_VendorConsents")
    else if LCase(OTVendorListMode) = "google" AND isString(consentData.OT_AddtlConsent)
      OT_AddtlConsent = consentData.OT_AddtlConsent.replace("1~", ".") + "."
      matchArray = OT_AddtlConsent.split("." + vendorId + ".")
      status = 0
      if matchArray <> invalid AND matchArray.count() > 1 then status = 1
    end if
  end if
  if status = -1 then m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "Invalid parameter passed - " + OTVendorListMode + " , " + vendorId)
  return status
End Function

Function getRegistryIabStatus1(consentData, uId, iskey)
  status = -1
  if isValid(iskey) AND isValid(consentData) AND isString(consentData[iskey])
    OT_VendorConsents = consentData.[iskey].split("")
    uId = (uId.toInt() - 1)
    if OT_VendorConsents <> invalid AND OT_VendorConsents.count() > 0 AND (OT_VendorConsents[uId] = "0" OR OT_VendorConsents[uId] = "1")
      status = OT_VendorConsents[uId].ToInt()
    end if
  end if
  return status
End Function

' Method to get vendor count configured for a particular group.
' @param customGroupId String, group id for which vendors have been assigned to.
'        It can be a parent group id like Stack or an individual group like an IAB purpose.
' @return int, count from saved object, 0 (no vendors configured), -1(error cases) are the possible values.
Function getVendorCount(customGroupId as String)
  m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "getVendorCount" + m.constant.info["705"])
  countForCategory = -1
  if not (isValid(customGroupId) AND isString(customGroupId.Trim()))
    m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, m.constant.error["507"])
  else if not isValid(optionalChaining(m, "OT_Data.OT_modelData.pcUIData"))
    m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, "Preferences Cmp Api data is not available while fetching the vendor count for " + customGroupId + ". Please make sure to download Preferences data and try again.")
  else
    customGroupId = customGroupId.trim()
    purposes = optionalChaining(m, "OT_Data.OT_modelData.pcUIData.purposeTree.purposes")
    if isValid(purposes) AND purposes.count() > 0
      purposesCount = purposes.count() - 1
      regEx = CreateObject("roRegex", "\d+", "")
      for i = 0 to purposesCount
        purposeItem = purposes[i]
        if isValid(purposeItem)
          countForCategory = parseVendorCount(regEx, purposeItem, customGroupId, countForCategory)
          if countForCategory >= 0 then exit for
          if isValid(purposeItem.children) AND purposeItem.children.count() > 0
            childPurposesCount = purposeItem.children.count() - 1
            for j = 0 to childPurposesCount
              ChildPurposeItem = purposeItem.children[j]
              countForCategory = parseVendorCount(regEx, ChildPurposeItem, customGroupId, countForCategory)
              if countForCategory >= 0 then exit for
            end for
            if countForCategory >= 0 then exit for
          end if
        end if
      end for
    end if
    if countForCategory >= 0
      m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, m.constant.info["737"], customGroupId + " - " + countForCategory.toStr())
    else
      m.logger.set(m.errortype.Error, m.errorTags.PublicMethod, m.constant.info["737"], customGroupId + " - " + "not found")
    end if
  end if
  return countForCategory
End Function

Function parseVendorCount(regEx, purposeItem, id, countForCategory)
  if purposeItem.groupId = id AND isValid(purposeItem.vendorsLinkedInfo)
    pCount = GetFirstNumber(regEx, purposeItem.vendorsLinkedInfo)
    if isString(pCount)
      countForCategory = pCount.toInt()
    end if
  end if
  return countForCategory
End Function

Function GetFirstNumber(regEx, inputStr as String) as String
  match = regEx.Match(inputStr)

  if isValid(match) AND match.Count() > 0 then
    return match[0] ' Returns the first number found
  else
    return "0"
  end if
End Function