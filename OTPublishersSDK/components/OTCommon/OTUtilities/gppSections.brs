function getSectionData(data)
    if isGppEnabled()
        templateType = getTemplateType()
        sdkData = m.global._OT_initialize_data
        if data = invalid then data = {}

        gppServerData = {}
        generalData = optionalChaining(sdkData, "culture.MobileData.gppData.general")
        if generalData <> invalid
            gppServerData["sensitiveDataProcessApplicable"] = optionalChaining(generalData, "sensitiveDataProcessApplicable")
            gppServerData["knownChildApplicable"] = optionalChaining(generalData, "knownChildApplicable")
            gppServerData["isMSPAEnabled"] = optionalChaining(generalData, "isMSPAEnabled")
            gppServerData["mspaOptionMode"] = optionalChaining(generalData, "mspaOptionMode")
        end if
        categoryIdData = optionalChaining(sdkData, "culture.MobileData.gppData.categoryIds")
        if categoryIdData <> invalid
            gppServerData["salePI"] = optionalChaining(categoryIdData, "salePI")
            gppServerData["sharePI"] = optionalChaining(categoryIdData, "sharePI")
            gppServerData["personalData"] = optionalChaining(categoryIdData, "personalData")
            gppServerData["targetedAd"] = optionalChaining(categoryIdData, "targetedAd")
            gppServerData["biometric"] = optionalChaining(categoryIdData, "biometric")
            gppServerData["communication"] = optionalChaining(categoryIdData, "communication")
            gppServerData["genetic"] = optionalChaining(categoryIdData, "genetic")
            gppServerData["geolocation"] = optionalChaining(categoryIdData, "geolocation")
            gppServerData["health"] = optionalChaining(categoryIdData, "health")
            gppServerData["rrepInfo"] = optionalChaining(categoryIdData, "rrepInfo")
            gppServerData["sexualOrientation"] = optionalChaining(categoryIdData, "sexualOrientation")
            gppServerData["sensitivePI"] = optionalChaining(categoryIdData, "sensitivePI")
            gppServerData["sensitiveSI"] = optionalChaining(categoryIdData, "sensitiveSI")
            gppServerData["race"] = optionalChaining(categoryIdData, "race")
            gppServerData["religion"] = optionalChaining(categoryIdData, "religion")
            gppServerData["immigration"] = optionalChaining(categoryIdData, "immigration")
            gppServerData["unionMembership"] = optionalChaining(categoryIdData, "unionMembership")

            gppServerData["knownChildSell"] = optionalChaining(categoryIdData, "knownChildSell")
            gppServerData["knownChildSharePI"] = optionalChaining(categoryIdData, "knownChildSharePI")
            gppServerData["knownChildProcess"] = optionalChaining(categoryIdData, "knownChildProcess")
            gppServerData["personalDataConsentAboveAge"] = optionalChaining(categoryIdData, "personalDataConsentAboveAge")
            gppServerData["personalDataConsentBelowAge"] = optionalChaining(categoryIdData, "personalDataConsentBelowAge")
        end if

        if templateType = m.GPPConstants.USNAT_TEMPLATE
            data[m.GPPConstants[templateType]] = {
                "Version": 1,
                "SharingNotice": getNoticeValue(gppServerData.sharePI),
                "SaleOptOutNotice": getNoticeValue(gppServerData.salePI),
                "SharingOptOutNotice": getNoticeValue(gppServerData.sharePI),
                "TargetedAdvertisingOptOutNotice": getNoticeValue(gppServerData.targetedAd),
                "SensitiveDataProcessingOptOutNotice": getSensitiveDataNotice(gppServerData, templateType),
                "SensitiveDataLimitUseNotice": getSensitiveDataNotice(gppServerData, templateType),
                "SaleOptOut": getGppConsentState(gppServerData.salePI),
                "SharingOptOut": getGppConsentState(gppServerData.sharePI),
                "TargetedAdvertisingOptOut": getGppConsentState(gppServerData.targetedAd),
                "SensitiveDataProcessing": getBitStrForSensitiveData(gppServerData, templateType).split(""),
                "KnownChildSensitiveDataConsents": getBitStrKnownChildSensitiveData(gppServerData, categoryIdData.personalDataConsentAboveAge, categoryIdData.personalDataConsentBelowAge),
                "PersonalDataConsents": getGppConsentState(gppServerData.personalData),
                "MspaCoveredTransaction": getMSPAStatus(gppServerData.isMSPAEnabled),
                "MspaOptOutOptionMode": getMSPAMode(gppServerData, m.GPPConstants.optOut),
                "MspaServiceProviderMode": getMSPAMode(gppServerData, m.GPPConstants.serviceProvider),
                "GpcSegmentType": 1,
                "GpcSegmentIncluded": false,
                "Gpc": false
            }
        end if

        if templateType = m.GPPConstants.CALIFORNIA_TEMPLATE
            data[m.GPPConstants[templateType]] = {
                "Version": 1,
                "SaleOptOutNotice": getNoticeValue(gppServerData.salePI),
                "SharingOptOutNotice": getNoticeValue(gppServerData.sharePI),
                "SensitiveDataLimitUseNotice": getSensitiveDataNotice(gppServerData, templateType),
                "SaleOptOut": getGppConsentState(gppServerData.salePI),
                "SharingOptOut": getGppConsentState(gppServerData.sharePI),
                "SensitiveDataProcessing": getBitStrForSensitiveData(gppServerData, templateType).split(""),
                "KnownChildSensitiveDataConsents": getBitStrKnownChildSensitiveData(gppServerData, categoryIdData.knownChildSell, categoryIdData.knownChildSharePI),
                "PersonalDataConsents": getGppConsentState(gppServerData.personalData),
                "MspaCoveredTransaction": getMSPAStatus(gppServerData.isMSPAEnabled),
                "MspaOptOutOptionMode": getMSPAMode(gppServerData, m.GPPConstants.optOut),
                "MspaServiceProviderMode": getMSPAMode(gppServerData, m.GPPConstants.serviceProvider),
                "GpcSegmentType": 1,
                "GpcSegmentIncluded": false,
                "Gpc": false
            }
        end if

        if templateType = m.GPPConstants.VIRGINIA_TEMPLATE
            data[m.GPPConstants[templateType]] = {
                "Version": 1,
                "SharingNotice": getNoticeValue(gppServerData.salePI, gppServerData.targetedAd),
                "SaleOptOutNotice": getNoticeValue(gppServerData.salePI),
                "TargetedAdvertisingOptOutNotice": getNoticeValue(gppServerData.targetedAd),
                "SaleOptOut": getGppConsentState(gppServerData.salePI),
                "TargetedAdvertisingOptOut": getGppConsentState(gppServerData.targetedAd),
                "SensitiveDataProcessing": getBitStrForSensitiveData(gppServerData, templateType).split(""),
                "KnownChildSensitiveDataConsents": getGppConsentState(gppServerData.knownChildSell),
                "MspaCoveredTransaction": getMSPAStatus(gppServerData.isMSPAEnabled),
                "MspaOptOutOptionMode": getMSPAMode(gppServerData, m.GPPConstants.optOut),
                "MspaServiceProviderMode": getMSPAMode(gppServerData, m.GPPConstants.serviceProvider),
            }
        end if

        if templateType = m.GPPConstants.COLORADO_TEMPLATE
            data[m.GPPConstants[templateType]] = {
                "Version": 1,
                "SharingNotice": getNoticeValue(gppServerData.salePI, gppServerData.targetedAd),
                "SaleOptOutNotice": getNoticeValue(gppServerData.salePI),
                "TargetedAdvertisingOptOutNotice": getNoticeValue(gppServerData.targetedAd),
                "SaleOptOut": getGppConsentState(gppServerData.salePI),
                "TargetedAdvertisingOptOut": getGppConsentState(gppServerData.targetedAd),
                "SensitiveDataProcessing": getBitStrForSensitiveData(gppServerData, templateType).split(""),
                "KnownChildSensitiveDataConsents": getGppConsentState(gppServerData.knownChildSell),
                "MspaCoveredTransaction": getMSPAStatus(gppServerData.isMSPAEnabled),
                "MspaOptOutOptionMode": getMSPAMode(gppServerData, m.GPPConstants.optOut),
                "MspaServiceProviderMode": getMSPAMode(gppServerData, m.GPPConstants.serviceProvider),
                "GpcSegmentIncluded": false,
                "GpcSegmentType": 1,
                "Gpc": false
            }
        end if

        if templateType = m.GPPConstants.CONNECTICUT_TEMPLATE
            data[m.GPPConstants[templateType]] = {
                "Version": 1,
                "SharingNotice": getNoticeValue(gppServerData.salePI, gppServerData.targetedAd),
                "SaleOptOutNotice": getNoticeValue(gppServerData.salePI),
                "TargetedAdvertisingOptOutNotice": getNoticeValue(gppServerData.targetedAd),
                "SaleOptOut": getGppConsentState(gppServerData.salePI),
                "TargetedAdvertisingOptOut": getGppConsentState(gppServerData.targetedAd),
                "SensitiveDataProcessing": getBitStrForSensitiveData(gppServerData, templateType).split(""),
                "KnownChildSensitiveDataConsents": getBitStrKnownChildSensitiveData(gppServerData, categoryIdData.knownChildProcess, categoryIdData.knownChildSell, categoryIdData.knownChildSharePI),
                "MspaCoveredTransaction": getMSPAStatus(gppServerData.isMSPAEnabled),
                "MspaOptOutOptionMode": getMSPAMode(gppServerData, m.GPPConstants.optOut),
                "MspaServiceProviderMode": getMSPAMode(gppServerData, m.GPPConstants.serviceProvider),
                "GpcSegmentIncluded": false,
                "GpcSegmentType": 1,
                "Gpc": false
            }
        end if

        if templateType = m.GPPConstants.UTAH_TEMPLATE
            data[m.GPPConstants[templateType]] = {
                "Version": 1,
                "SharingNotice": getNoticeValue(gppServerData.salePI, gppServerData.targetedAd),
                "SaleOptOutNotice": getNoticeValue(gppServerData.salePI),
                "TargetedAdvertisingOptOutNotice": getNoticeValue(gppServerData.targetedAd),
                "SensitiveDataProcessingOptOutNotice": getSensitiveDataNotice(gppServerData, templateType),
                "SaleOptOut": getGppConsentState(gppServerData.salePI),
                "TargetedAdvertisingOptOut": getGppConsentState(gppServerData.targetedAd),
                "SensitiveDataProcessing": getBitStrForSensitiveData(gppServerData, templateType).split(""),
                "KnownChildSensitiveDataConsents": getGppConsentState(gppServerData.knownChildSell),
                "MspaCoveredTransaction": getMSPAStatus(gppServerData.isMSPAEnabled),
                "MspaOptOutOptionMode": getMSPAMode(gppServerData, m.GPPConstants.optOut),
                "MspaServiceProviderMode": getMSPAMode(gppServerData, m.GPPConstants.serviceProvider),
            }
        end if
    end if
    return data
end function

' Function to get current template type
function getTemplateType() as string
    sdkData = m.global._OT_initialize_data
    templateType = ""
    ruleDetails = optionalChaining(sdkData, "domain.ruleDetails")
    if ruleDetails <> invalid and ruleDetails.type <> invalid then templateType = ruleDetails.type
    useGPPUSNational = optionalChaining(sdkData, "culture.MobileData.gppData.general.useGPPUSNational")
    if templateType = m.GPPConstants.CCPA_CALIFORNIA_TEMPLATE then templateType = m.GPPConstants.CALIFORNIA_TEMPLATE
    if not isIAB2() and useGPPUSNational then templateType = m.GPPConstants.USNAT_TEMPLATE
    return templateType
end function

' method to return status for notice values based on the purpose mapped.
function getNoticeValue(categoryVal1, categoryVal2 = "")
    if isApplicable(categoryVal1) or isApplicable(categoryVal2)
        return m.GPPConstants.NOTICE_GIVEN
    end if
    return m.GPPConstants.NOT_APPLICABLE
end function

' check if a category is assigned to the Gpp purpose of a template and if assigned, whether
' its shown in UI
function isApplicable(category)
    return category <> invalid and category <> "" and getValidGroup(category) <> invalid
end function

function getSensitiveDataNotice(categoryIdData, templateType)
    sensitiveData = getBitStrForSensitiveData(categoryIdData, templateType)
    if sensitiveData.Instr("1") <> -1 or sensitiveData.Instr("2") <> -1
        return m.GPPConstants.NOTICE_GIVEN
    end if
    return m.GPPConstants.NOT_APPLICABLE
end function

' calculates bit string for Sensitive Data
function getBitStrForSensitiveData(categoryIdData, templateType)
    isValidState = categoryIdData.sensitiveDataProcessApplicable <> invalid and categoryIdData.sensitiveDataProcessApplicable
    sensitiveData = ""
    race = getGppConsentState(categoryIdData.race, isValidState).tostr()
    religion = getGppConsentState(categoryIdData.religion, isValidState).tostr()
    health = getGppConsentState(categoryIdData.health, isValidState).tostr()
    sexualOrientation = getGppConsentState(categoryIdData.sexualOrientation, isValidState).tostr()
    immigration = getGppConsentState(categoryIdData.immigration, isValidState).tostr()
    genetic = getGppConsentState(categoryIdData.genetic, isValidState).tostr()
    biometric = getGppConsentState(categoryIdData.biometric, isValidState).tostr()
    geolocation = getGppConsentState(categoryIdData.geolocation, isValidState).tostr()
    sensitivePI = getGppConsentState(categoryIdData.sensitivePI, isValidState).tostr()
    sensitiveSI = getGppConsentState(categoryIdData.sensitiveSI, isValidState).tostr()
    unionMembership = getGppConsentState(categoryIdData.unionMembership, isValidState).tostr()
    communication = getGppConsentState(categoryIdData.communication, isValidState).tostr()
    rrepInfo = getGppConsentState(categoryIdData.rrepInfo, isValidState).tostr()

    if templateType = m.GPPConstants.USNAT_TEMPLATE
        sensitiveData = race + religion + health + sexualOrientation + immigration + genetic + biometric + geolocation + sensitivePI + sensitiveSI + unionMembership + communication
    end if

    if templateType = m.GPPConstants.CALIFORNIA_TEMPLATE
        sensitiveData = sensitivePI + sensitiveSI + geolocation + rrepInfo + communication + genetic + biometric + health + sexualOrientation
    end if

    if templateType = m.GPPConstants.VIRGINIA_TEMPLATE or templateType = m.GPPConstants.CONNECTICUT_TEMPLATE
        sensitiveData = race + religion + health + sexualOrientation + immigration + genetic + biometric + geolocation
    end if

    if templateType = m.GPPConstants.COLORADO_TEMPLATE
        sensitiveData = race + religion + health + sexualOrientation + immigration + genetic + biometric
    end if

    if templateType = m.GPPConstants.UTAH_TEMPLATE
        sensitiveData = race + religion + sexualOrientation + immigration + health + genetic + biometric + geolocation
    end if

    return sensitiveData
end function

' calculates bit string for KnownChild Sensitive Data
function getBitStrKnownChildSensitiveData(categoryIdData, knownChild1, knownChild2, knownChild3 = invalid)
    isValidState = categoryIdData.knownChildApplicable <> invalid and categoryIdData.knownChildApplicable
    knownChildData = [
        getGppConsentState(knownChild1, isValidState),
        getGppConsentState(knownChild2, isValidState)
    ]
    if knownChild3 <> invalid
        knownChildData.push(getGppConsentState(knownChild3, isValidState))
    end if
    return knownChildData
end function

function getGppConsentState(category, isValidState = true)
    if isApplicable(category) and isValidState
        regGroupData = getRegGroupData()
        if regGroupData <> invalid and regGroupData[category] <> invalid
            statusId = regGroupData[category]
        end if
        if m.saveGroupqueue <> invalid and m.saveGroupqueue[category] <> invalid
            statusId = m.saveGroupqueue[category]
        end if
        if statusId <> invalid
            status = m.GPPConstants.CONSENT_OR_OPTED
            if statusId.Instr("inactive") <> -1
                status = m.GPPConstants.NO_CONSENT_OR_OPTED_OUT
            end if
            return status
        end if
    end if
    return m.GPPConstants.NOT_APPLICABLE
end function

function getMSPAMode(data, mode)
    isMSPAEnabled = data.isMSPAEnabled
    if isMSPAEnabled <> invalid and mode <> invalid and isMSPAEnabled and mode <> ""
        return getMSPAStatus(data.mspaOptionMode = mode)
    end if
    return m.GPPConstants.NOT_APPLICABLE
end function

function getMSPAStatus(data)
    if data <> invalid and data
        return m.GPPConstants.MSP_ENABLED
    end if
    return m.GPPConstants.MSP_DISABLED
end function