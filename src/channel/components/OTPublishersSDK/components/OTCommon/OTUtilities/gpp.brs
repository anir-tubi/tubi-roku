function isGppEnabled()
    sdkData = m.global._OT_initialize_data
    IsGPPEnable = optionalChaining(sdkData, "culture.DomainData.IsGPPEnabled")
    if IsGPPEnable <> invalid and IsGPPEnable
        return sdkData.culture.DomainData.IsGPPEnabled
    else
        return false
    end if
end function

function saveToGPPRegistry(data)
    if data <> invalid
        if m.decodedTCString <> invalid and optionalChaining(data, "decodedString.tcfeuv2.encodedString") <> invalid
            data.decodedString["tcfeuv2"] = m.decodedTCString
            m.decodedTCString = invalid
        end if
        if data.gppString <> invalid and data.gppString <> ""
            m.registry.writeKeys({
                "IABGPP_HDR_GppString": data.gppString,
                "IABGPP_HDR_Sections": getAvailableSections(data.decodedString),
                "IABGPP_HDR_Version": 1,
                "IABGPP_GppSID": getCurrentSection()
            })
            m.logger.set(m.errortype.Info, m.errorTags.Token, m.constant.Info["738"], data.gppString)
        end if
        if data.decodedString <> invalid
            if data.decodedString["tcfeuv2"] <> invalid and optionalChaining(data.decodedString["tcfeuv2"], "cmpId") <> invalid
                m.registry.writeKeys({
                    "IABGPP_2_String": optionalChaining(data.decodedString["tcfeuv2"], "encodedString"),
                    "IABGPP_TCFEU2_CmpSdkID": optionalChaining(data.decodedString["tcfeuv2"], "cmpId"),
                    "IABGPP_TCFEU2_CmpSdkVersion": optionalChaining(data.decodedString["tcfeuv2"], "cmpVersion"),
                    "IABGPP_TCFEU2_PolicyVersion": optionalChaining(data.decodedString["tcfeuv2"], "tcfPolicyVersion"),
                    "IABGPP_TCFEU2_gdprApplies": optionalChaining(data.decodedString["tcfeuv2"], "gdprApplies"),
                    "IABGPP_TCFEU2_PublisherCC": optionalChaining(data.decodedString["tcfeuv2"], "publisherCC"),
                    "IABGPP_TCFEU2_PurposeOneTreatment": optionalChaining(data.decodedString["tcfeuv2"], "purposeOneTreatment"),
                    "IABGPP_TCFEU2_SpecialFeaturesOptIns": optionalChaining(data.decodedString["tcfeuv2"], "specialFeatureOptins"),
                    "IABGPP_TCFEU2_UseNonStandardStacks": optionalChaining(data.decodedString["tcfeuv2"], "useNonStandardStacks"),
                    "IABGPP_TCFEU2_PurposeConsents": optionalChaining(data.decodedString["tcfeuv2"], "purpose.consents"),
                    "IABGPP_TCFEU2_PurposeLegitimateInterests": optionalChaining(data.decodedString["tcfeuv2"], "purpose.legitimateInterests"),
                    "IABGPP_TCFEU2_PublisherConsent": optionalChaining(data.decodedString["tcfeuv2"], "publisher.consents"),
                    "IABGPP_TCFEU2_PublisherLegitimateInterests": optionalChaining(data.decodedString["tcfeuv2"], "publisher.legitimateInterests"),
                    "IABGPP_TCFEU2_VendorConsents": optionalChaining(data.decodedString["tcfeuv2"], "vendor.consents"),
                    "IABGPP_TCFEU2_VendorLegitimateInterests": optionalChaining(data.decodedString["tcfeuv2"], "vendor.legitimateInterests"),
                    "IABGPP_TCFEU2_LastUpdated": optionalChaining(data.decodedString["tcfeuv2"], "lastUpdated"),
                    "IABGPP_TCFEU2_IsServiceSpecific": optionalChaining(data.decodedString["tcfeuv2"], "isServiceSpecific"),
                    "IABGPP_TCFEU2_PublisherRestrictions1": optionalChaining(data.decodedString["tcfeuv2"], "publisher.restrictions.1"),
                    "IABGPP_TCFEU2_PublisherRestrictions2": optionalChaining(data.decodedString["tcfeuv2"], "publisher.restrictions.2"),
                    "IABGPP_TCFEU2_PublisherRestrictions3": optionalChaining(data.decodedString["tcfeuv2"], "publisher.restrictions.3"),
                    "IABGPP_TCFEU2_PublisherRestrictions4": optionalChaining(data.decodedString["tcfeuv2"], "publisher.restrictions.4"),
                    "IABGPP_TCFEU2_PublisherRestrictions5": optionalChaining(data.decodedString["tcfeuv2"], "publisher.restrictions.5"),
                    "IABGPP_TCFEU2_PublisherRestrictions6": optionalChaining(data.decodedString["tcfeuv2"], "publisher.restrictions.6"),
                    "IABGPP_TCFEU2_PublisherRestrictions7": optionalChaining(data.decodedString["tcfeuv2"], "publisher.restrictions.7"),
                    "IABGPP_TCFEU2_PublisherRestrictions8": optionalChaining(data.decodedString["tcfeuv2"], "publisher.restrictions.8"),
                    "IABGPP_TCFEU2_PublisherRestrictions9": optionalChaining(data.decodedString["tcfeuv2"], "publisher.restrictions.9"),
                    "IABGPP_TCFEU2_PublisherRestrictions10": optionalChaining(data.decodedString["tcfeuv2"], "publisher.restrictions.10")
                })
            end if
            if data.decodedString["uspv1"] <> invalid
                m.registry.writeKeys({
                    "IABGPP_6_String": data.decodedString["uspv1"].encodedString
                    "IABGPP_USP1_Version": data.decodedString["uspv1"].Version,
                    "IABGPP_USP1_Notice": data.decodedString["uspv1"].Notice,
                    "IABGPP_USP1_OptOut": data.decodedString["uspv1"].OptOutSale,
                    "IABGPP_USP1_LSPACovered": data.decodedString["uspv1"].LspaCovered
                })
            end if

            if data.decodedString[m.GPPConstants.USNATIONAL] <> invalid
                m.registry.writeKeys({
                    "IABGPP_7_String": data.decodedString[m.GPPConstants.USNATIONAL].encodedString
                })
            end if

            if data.decodedString[m.GPPConstants.CPRA] <> invalid
                m.registry.writeKeys({
                    "IABGPP_8_String": data.decodedString[m.GPPConstants.CPRA].encodedString
                })
            end if

            if data.decodedString[m.GPPConstants.CDPA] <> invalid
                m.registry.writeKeys({
                    "IABGPP_9_String": data.decodedString[m.GPPConstants.CDPA].encodedString
                })
            end if

            if data.decodedString[m.GPPConstants.COLORADO] <> invalid
                m.registry.writeKeys({
                    "IABGPP_10_String": data.decodedString[m.GPPConstants.COLORADO].encodedString
                })
            end if

            if data.decodedString[m.GPPConstants.UCPA] <> invalid
                m.registry.writeKeys({
                    "IABGPP_11_String": data.decodedString[m.GPPConstants.UCPA].encodedString
                })
            end if

            if data.decodedString[m.GPPConstants.CTDPA] <> invalid
                m.registry.writeKeys({
                    "IABGPP_12_String": data.decodedString[m.GPPConstants.CTDPA].encodedString
                })
            end if

        end if
    end if

end function

function getAvailableSections(data)
    availableSections = ""
    sections = []
    if data <> invalid
        if data["tcfeuv2"] <> invalid
            sections.push("2")
        end if
        if data["uspv1"] <> invalid
            sections.push("6")
        end if
        if data[m.GPPConstants.USNATIONAL] <> invalid
            sections.push("7")
        end if
        if data[m.GPPConstants.CPRA] <> invalid
            sections.push("8")
        end if
        if data[m.GPPConstants.CDPA] <> invalid
            sections.push("9")
        end if
        if data[m.GPPConstants.COLORADO] <> invalid
            sections.push("10")
        end if
        if data[m.GPPConstants.UCPA] <> invalid
            sections.push("11")
        end if
        if data[m.GPPConstants.CTDPA] <> invalid
            sections.push("12")
        end if
        availableSections = sections.join("_")
    end if
    return availableSections
end function

function getCurrentSection()
    sections = []
    templateType = getTemplateType()
    if isIAB2()
        sections.push("2")
    end if
    if isCCPA()
        sections.push("6")
    end if
    if templateType = m.GPPConstants.USNAT_TEMPLATE
        sections.push("7")
    end if
    if templateType = m.GPPConstants.CALIFORNIA_TEMPLATE
        sections.push("8")
    end if
    if templateType = m.GPPConstants.VIRGINIA_TEMPLATE
        sections.push("9")
    end if
    if templateType = m.GPPConstants.COLORADO_TEMPLATE
        sections.push("10")
    end if
    if templateType = m.GPPConstants.UTAH_TEMPLATE
        sections.push("11")
    end if
    if templateType = m.GPPConstants.CONNECTICUT_TEMPLATE
        sections.push("12")
    end if
    availableSections = sections.join("_")
    return availableSections
end function

function setConsentString(isOnLaunch = false)
    uspString = setCCPAValues()
    request = {}
    if not isOnLaunch then request = setIABString()
    if isGppEnabled() and uspString <> invalid and uspString <> ""
        if request = invalid then request = {}
        request["uspv1"] = {
            "encodedString": uspString
        }
    end if
    request = getSectionData(request)
    if isOnLaunch <> invalid and isOnLaunch and m.decodedTCString <> invalid and request["tcfeuv2"] = invalid
        request["tcfeuv2"] = {
            "encodedString": m.decodedTCString.encodedString
        }
    end if
    IABGPP_HDR_GppString = m.registry.read("IABGPP_HDR_GppString")
    if IABGPP_HDR_GppString <> invalid then request["gppString"] = IABGPP_HDR_GppString
    if request <> invalid and request.count() > 0
        iabLogConsent = CreateObject("roSGNode", "OTtask")
        iabLogConsent.consentUrl = getUrl("encode")
        iabLogConsent.payload = request
        if isOnLaunch
            iabLogConsent.observeField("consentResponse", "onlaunchGPPResponse")
        else
            iabLogConsent.observeField("consentResponse", "onIABConsentResponse")
        end if
        iabLogConsent.functionName = "logConsent"
        addToNetwork(iabLogConsent, true)
    else
        if not isOnLaunch then updateLogConsent()
    end if
end function

function onlaunchGPPResponse(message as object)
    m.logger.set(m.errortype.Success, m.errorTags.NetworkRequestHandler, "encode" + m.constant.success["202"])
    request = message.getRoSGNode()
    response = request.consentResponse
    if isGppEnabled()
        saveToGPPRegistry(response)
    else
        saveToIABRegistry(response.decodedString.tcfeuv2)
    end if
end function

function onIABConsentResponse(message as object)
    m.logger.set(m.errortype.Success, m.errorTags.NetworkRequestHandler, "encode" + m.constant.success["202"])
    request = message.getRoSGNode()
    response = request.consentResponse
    if isGppEnabled()
        saveToGPPRegistry(response)
    else
        saveToIABRegistry(response.decodedString.tcfeuv2)
    end if
    updateLogConsent()
end function

function removeGPPRegistry()
    m.registry.deleteKeys([
        "IABGPP_HDR_GppString",
        "IABGPP_HDR_Sections",
        "IABGPP_HDR_Version",
        "IABGPP_GppSID",
        "IABGPP_2_String",
        "IABGPP_TCFEU2_CmpSdkID",
        "IABGPP_TCFEU2_CmpSdkVersion",
        "IABGPP_TCFEU2_PolicyVersion",
        "IABGPP_TCFEU2_gdprApplies",
        "IABGPP_TCFEU2_PublisherCC",
        "IABGPP_TCFEU2_PurposeOneTreatment",
        "IABGPP_TCFEU2_SpecialFeaturesOptIns",
        "IABGPP_TCFEU2_UseNonStandardStacks",
        "IABGPP_TCFEU2_PurposeConsents",
        "IABGPP_TCFEU2_PurposeLegitimateInterests",
        "IABGPP_TCFEU2_PublisherConsent",
        "IABGPP_TCFEU2_PublisherLegitimateInterests",
        "IABGPP_TCFEU2_VendorConsents",
        "IABGPP_TCFEU2_VendorLegitimateInterests",
        "IABGPP_TCFEU2_LastUpdated",
        "IABGPP_TCFEU2_IsServiceSpecific",
        "IABGPP_TCFEU2_PublisherRestrictions1",
        "IABGPP_TCFEU2_PublisherRestrictions2",
        "IABGPP_TCFEU2_PublisherRestrictions3",
        "IABGPP_TCFEU2_PublisherRestrictions4",
        "IABGPP_TCFEU2_PublisherRestrictions5",
        "IABGPP_TCFEU2_PublisherRestrictions6",
        "IABGPP_TCFEU2_PublisherRestrictions7",
        "IABGPP_TCFEU2_PublisherRestrictions8",
        "IABGPP_TCFEU2_PublisherRestrictions9",
        "IABGPP_TCFEU2_PublisherRestrictions10",
        "IABGPP_6_String",
        "IABGPP_USP1_Version",
        "IABGPP_USP1_Notice",
        "IABGPP_USP1_OptOut",
        "IABGPP_USP1_LSPACovered",
        "IABGPP_7_String",
        "IABGPP_8_String",
        "IABGPP_9_String",
        "IABGPP_10_String",
        "IABGPP_11_String",
        "IABGPP_12_String",
    ])
end function

function convertIABGPPKeys()
    IABGPP_HDR_GppString = m.registry.read("IABGPP_HDR_GppString")
    gppString = IABGPP_HDR_GppString
    IABUSPrivacy_String = m.registry.read("IABUSPrivacy_String")
    IABTCF_TCString = m.registry.read("IABTCF_TCString")
    tcString = IABTCF_TCString
    isGppEnable = isGppEnabled()
    templateType = getTemplateType()
    m.decodedTCString = invalid
    if isGppEnable
        m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.Info["739"].Replace("$1", "enabled").Replace("$2", ""))
    else
        m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.Info["739"].Replace("$1", "disabled").Replace("$2", " not"))
    end if
    gppEncripted = m.registry.read("gppEncripted")
    if isGppEnable and IABGPP_HDR_GppString <> invalid
        if isCCPA() or templateType = m.GPPConstants.USNAT_TEMPLATE or templateType = m.GPPConstants.CALIFORNIA_TEMPLATE or templateType = m.GPPConstants.COLORADO_TEMPLATE or templateType = m.GPPConstants.UTAH_TEMPLATE or templateType = m.GPPConstants.CONNECTICUT_TEMPLATE or templateType = m.GPPConstants.VIRGINIA_TEMPLATE
            IABGPP_HDR_GppString = invalid
            tcString = m.registry.read("IABGPP_2_String")
        end if
    end if
    if IABGPP_HDR_GppString = invalid or gppEncripted <> invalid
        if isGppEnable
            if gppEncripted <> invalid then m.registry.write("IABGPP_HDR_GppString", gppEncripted)
            if IABTCF_TCString <> invalid
                m.decodedTCString = {
                    "cmpId": m.registry.read("IABTCF_CmpSdkID"),
                    "cmpVersion": m.registry.read("IABTCF_CmpSdkVersion"),
                    "tcfPolicyVersion": m.registry.read("IABTCF_PolicyVersion"),
                    "gdprApplies": m.registry.read("IABTCF_gdprApplies"),
                    "isServiceSpecific": m.registry.read("IABTCF_IsServiceSpecific"),
                    "publisherCC": m.registry.read("IABTCF_PublisherCC"),
                    "purposeOneTreatment": m.registry.read("IABTCF_PurposeOneTreatment"),
                    "purpose": {
                        "consents": m.registry.read("IABTCF_PurposeConsents"),
                        "legitimateInterests": m.registry.read("IABTCF_PurposeLegitimateInterests"),
                    },
                    "vendor": {
                        "consents": m.registry.read("IABTCF_VendorConsents"),
                        "legitimateInterests": m.registry.read("IABTCF_VendorLegitimateInterests"),
                    },
                    "specialFeatureOptins": m.registry.read("IABTCF_SpecialFeaturesOptIns"),
                    "publisher": {
                        "consents": m.registry.read("IABTCF_PublisherConsent"),
                        "legitimateInterests": m.registry.read("IABTCF_PublisherLegitimateInterests"),
                        "restrictions": {
                            "1": m.registry.read("IABTCF_PublisherRestrictions1"),
                            "2": m.registry.read("IABTCF_PublisherRestrictions2"),
                            "3": m.registry.read("IABTCF_PublisherRestrictions3"),
                            "4": m.registry.read("IABTCF_PublisherRestrictions4"),
                            "5": m.registry.read("IABTCF_PublisherRestrictions5"),
                            "7": m.registry.read("IABTCF_PublisherRestrictions7"),
                            "8": m.registry.read("IABTCF_PublisherRestrictions8"),
                            "9": m.registry.read("IABTCF_PublisherRestrictions9"),
                            "10": m.registry.read("IABTCF_PublisherRestrictions10")
                        }
                    },
                    "useNonStandardStacks": m.registry.read("IABTCF_UseNonStandardStacks"),
                    "lastUpdated": m.registry.read("IABTCF_LastUpdated"),
                    "encodedString": m.registry.read("IABTCF_TCString"),
                    "tcString": m.registry.read("IABTCF_TCString"),
                }
            end if
            m.registry.delete("gppEncripted")
            setConsentString(true)
            removeIabGlobal()
            'removeUSPGlobal()
            removeIabRegistry()
            'removeUSPRegistry()
        end if
    else
        'removeUSPGlobal()
        'removeUSPRegistry()
        if not isGppEnable
            m.registry.write("gppEncripted", gppString)
            uspString = m.registry.read("IABGPP_6_String")
            if IABUSPrivacy_String <> invalid and uspString = invalid then uspString = IABUSPrivacy_String
            tcString = m.registry.read("IABGPP_2_String")
            if tcString <> invalid
                tcfeuv2 = {
                    "cmpId": m.registry.read("IABGPP_TCFEU2_CmpSdkID"),
                    "cmpVersion": m.registry.read("IABGPP_TCFEU2_CmpSdkVersion"),
                    "tcfPolicyVersion": m.registry.read("IABGPP_TCFEU2_PolicyVersion"),
                    "gdprApplies": m.registry.read("IABGPP_TCFEU2_gdprApplies"),
                    "isServiceSpecific": m.registry.read("IABGPP_TCFEU2_IsServiceSpecific"),
                    "publisherCC": m.registry.read("IABGPP_TCFEU2_PublisherCC"),
                    "purposeOneTreatment": m.registry.read("IABGPP_TCFEU2_PurposeOneTreatment"),
                    "purpose": {
                        "consents": m.registry.read("IABGPP_TCFEU2_PurposeConsents"),
                        "legitimateInterests": m.registry.read("IABGPP_TCFEU2_PurposeLegitimateInterests"),
                    },
                    "vendor": {
                        "consents": m.registry.read("IABGPP_TCFEU2_VendorConsents"),
                        "legitimateInterests": m.registry.read("IABGPP_TCFEU2_VendorLegitimateInterests"),
                    },
                    "specialFeatureOptins": m.registry.read("IABGPP_TCFEU2_SpecialFeaturesOptIns"),
                    "publisher": {
                        "consents": m.registry.read("IABGPP_TCFEU2_PublisherConsent"),
                        "legitimateInterests": m.registry.read("IABGPP_TCFEU2_PublisherLegitimateInterests"),
                        "restrictions": {
                            "1": m.registry.read("IABGPP_TCFEU2_PublisherRestrictions1"),
                            "2": m.registry.read("IABGPP_TCFEU2_PublisherRestrictions2"),
                            "3": m.registry.read("IABGPP_TCFEU2_PublisherRestrictions3"),
                            "4": m.registry.read("IABGPP_TCFEU2_PublisherRestrictions4"),
                            "5": m.registry.read("IABGPP_TCFEU2_PublisherRestrictions5"),
                            "7": m.registry.read("IABGPP_TCFEU2_PublisherRestrictions7"),
                            "8": m.registry.read("IABGPP_TCFEU2_PublisherRestrictions8"),
                            "9": m.registry.read("IABGPP_TCFEU2_PublisherRestrictions9"),
                            "10": m.registry.read("IABGPP_TCFEU2_PublisherRestrictions10")
                        }
                    },
                    "useNonStandardStacks": m.registry.read("IABGPP_TCFEU2_UseNonStandardStacks"),
                    "lastUpdated": m.registry.read("IABGPP_TCFEU2_LastUpdated"),
                    "encodedString": m.registry.read("IABGPP_2_String"),
                    "tcString": m.registry.read("IABGPP_2_String"),
                    "code": 200
                }
                saveToIABRegistry(tcfeuv2)
            end if
            if uspString <> invalid
                saveUSP(uspString)
            end if
            removeGPPRegistry()
        end if

    end if
end function