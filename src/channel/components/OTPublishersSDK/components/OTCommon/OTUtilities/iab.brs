' IAB TCF String
' IABTCF_TCString
function setIABString()
    if isIAB2() = false then
        return invalid
    end if
    defaultSPLI = optionalChaining(m.global._OT_IABVendor_data, "defaultSPLI")
    sdk = m.global._OT_initialize_data
    vendorData = m.global._OT_IABVendor_data
    PAllowLI = optionalChaining(sdk, "culture.DomainData.LegIntSettings.PAllowLI")
    iabTypeversion = getIabTypeVersion()
    iabValues = optionalChaining(sdk, "domain." + "Iab" + iabTypeversion + "Data")
    NewVendorsInactiveEnabled = optionalChaining(sdk, "culture.DomainData.NewVendorsInactiveEnabled")
    vendorListVersion = 0
    if vendorData <> invalid and vendorData.iab <> invalid and vendorData.iab.vendorListVersion <> invalid then vendorListVersion = vendorData.iab.vendorListVersion
    if (NewVendorsInactiveEnabled or NewVendorsInactiveEnabled = invalid) then vendorListVersion = optionalChaining(iabValues, "vendorListVersion")
    regGroupData = getRegGroupData()
    purposeConsents = getIABFinalArray(regGroupData, true, "purpose")
    purposeLegitimateInterests = getIABFinalArray(regGroupData, false, "purpose", PAllowLI)
    request = {
        "tcfeuv2": {
            "location": sdkParams().getLocation(),
            "gvlUrl": optionalChaining(iabValues, "globalVendorListUrl"),
            "tcModel": {
                "cmpId": iabValues.cmpId.ToInt(),
                "cmpVersion": iabValues.cmpVersion.ToInt(),
                "consentLanguage": "en",
                "consentScreen": iabValues.consentScreen.ToInt(),
                "gdprApplies": 1,
                "isServiceSpecific": 1,
                "publisherCountryCode": optionalChaining(sdk, "culture.DomainData.PublisherCC"),
                "purposeConsents": purposeConsents,
                "purposeLegitimateInterests": purposeLegitimateInterests,
                "specialFeatureOptins": getIABFinalArray(regGroupData, true, "sf"),
                "vendorConsents": getIABFinalArray(m.saveGroupqueue["iab"], true, "iab"),
                "vendorLegitimateInterests": getIABFinalArray(m.saveGroupqueue["iab"], false, "iab", PAllowLI, defaultSPLI),
                "publisherRestrictions": optionalChaining(sdk, "culture.DomainData.publisher.restrictions"),
                "publisherConsents": purposeConsents,
                "publisherLegitimateInterests": purposeLegitimateInterests,
                "vendorListVersion": vendorListVersion
            }
        }
    }

    setTcfAddtlConsent(m.saveGroupqueue)

    return request
end function

' Google Consent String
' IABTCF_AddtlConsent
function setTcfAddtlConsent(regGroupData)
    encodedString = ""
    if havingGooglevendor()
        encodedString = "1~"
        vendorConsents = getIABFinalArray(regGroupData["google"], true, "google")
        if vendorConsents <> invalid and vendorConsents.count() > 0
            consentArray = []
            for each item in vendorConsents
                consentArray.push(item.tostr())
            end for
            encodedString += consentArray.Join(".")
        end if
    end if
    if not m.global.doesExist("IABTCF_AddtlConsent") then m.global.Addfield("IABTCF_AddtlConsent", "string", false)
    m.global.IABTCF_AddtlConsent = encodedString
    m.registry.write("IABTCF_AddtlConsent", encodedString)
    m.logger.set(m.errortype.Info, m.errorTags.Token, m.constant.info["711"], encodedString)
end function

function getIABFinalArray(regGroupData as object, isConsent, cType as string, PAllowLI = false, defaultSPLI = [])
    result = []
    if regGroupData = invalid then return result
    keys = regGroupData.keys()
    keysCount = keys.Count()
    i = 0
    iabEncodeValue = ""
    while i < keysCount
        if LCase(keys[i]) <> "iab" and LCase(keys[i]) <> "google" and LCase(keys[i]) <> "sdk"
            leftTrimKey = Left(keys[i], 2)
            if (leftTrimKey <> "Li" and isConsent) or (leftTrimKey = "Li" and not isConsent and PAllowLI <> invalid and PAllowLI)
                value = keys[i].Split("_")
                key = keys[i]
                if leftTrimKey = "Li" then key = Mid(keys[i], 4)
                if value <> invalid and value.count() > 0 and regGroupData[keys[i]] = "active" and ((m.initGroups[key] <> invalid and ((cType = "purpose" and isIab_PURPOSE(m.initGroups[key].Type)) or (cType = "sf" and isIab_SPL_FEATURE(m.initGroups[key].Type)))) or (cType = "iab" or cType = "google"))
                    value = value[value.count() - 1]
                    result.push(value.ToInt())
                    if cType = "iab" then iabEncodeValue = getIABEncodedValues(iabEncodeValue, "1", value.ToInt())
                else if cType = "iab"
                    value = value[value.count() - 1]
                    iabEncodeValue = getIABEncodedValues(iabEncodeValue, "0", value.ToInt())
                end if
            end if
        end if
        i = i + 1
        if i = keysCount then exit while
    end while

    ' if 0 Purposes, 0 LegIntPurposes, and >0 Special Purposes then add it to vendorLegitimateInterests
    if defaultSPLI <> invalid and defaultSPLI.count() > 0 and PAllowLI <> invalid and PAllowLI and cType = "iab"
        for each item in defaultSPLI
            iabEncodeValue = getIABEncodedValues(iabEncodeValue, "1", item)
        end for
        result.append(defaultSPLI)
    end if

    if cType = "iab" and isConsent then m.registry.write("vendorConsentsEncoded", iabEncodeValue)
    if cType = "iab" and not isConsent then m.registry.write("vendorLegitimateInterestsEncoded", iabEncodeValue)
    return result
end function

function getIABEncodedValues(iabEncodeValue, value, position)
    if position > Len(iabEncodeValue) then iabEncodeValue = iabEncodeValue + string(position - Len(iabEncodeValue), ".")
    l = Left(iabEncodeValue, position - 1)
    r = Right(iabEncodeValue, Len(iabEncodeValue) - position)
    iabEncodeValue = l + value + r
    return iabEncodeValue
end function

function saveToIABRegistry(model as object)
    if model <> invalid and model.code <> "500".ToInt()
        setIabGlobalInitilization()
        m.global.IABTCF_CmpSdkID = optionalChaining(model, "cmpId").tostr()
        m.global.IABTCF_CmpSdkVersion = optionalChaining(model, "cmpVersion").tostr()
        m.global.IABTCF_PolicyVersion = optionalChaining(model, "tcfPolicyVersion").tostr()
        m.global.IABTCF_gdprApplies = optionalChaining(model, "gdprApplies").tostr()
        m.global.IABTCF_TCString = optionalChaining(model, "tcString").tostr()
        m.global.IABTCF_PublisherCC = optionalChaining(model, "publisherCC").tostr()
        m.global.IABTCF_PurposeOneTreatment = optionalChaining(model, "purposeOneTreatment").tostr()

        m.global.IABTCF_SpecialFeaturesOptIns = optionalChaining(model, "specialFeatureOptins").tostr()
        m.global.IABTCF_UseNonStandardStacks = optionalChaining(model, "useNonStandardStacks").tostr()

        m.global["IABTCF_PurposeConsents"] = optionalChaining(model, "purpose.consents").tostr()
        m.global["IABTCF_PurposeLegitimateInterests"] = optionalChaining(model, "purpose.legitimateInterests").tostr()

        m.global["IABTCF_PublisherConsent"] = optionalChaining(model, "publisher.consents").tostr()
        m.global["IABTCF_PublisherLegitimateInterests"] = optionalChaining(model, "publisher.legitimateInterests").tostr()

        m.global["IABTCF_VendorConsents"] = optionalChaining(model, "vendor.consents").tostr()
        m.global["IABTCF_VendorLegitimateInterests"] = optionalChaining(model, "vendor.legitimateInterests").tostr()
        m.global["IABTCF_LastUpdated"] = optionalChaining(model, "lastUpdated").tostr()
        m.global["IABTCF_IsServiceSpecific"] = optionalChaining(model, "isServiceSpecific").tostr()
        for i = 1 to 10
            value = ""
            if optionalChaining(model, "publisher.restrictions") <> invalid and model.publisher.restrictions[i.toStr()] <> invalid
                value = model.publisher.restrictions[i.toStr()]
            end if
            m.global["IABTCF_PublisherRestrictions" + i.tostr()] = value
        end for

        m.registry.writeKeys({
            "IABTCF_CmpSdkID": m.global.IABTCF_CmpSdkID,
            "IABTCF_CmpSdkVersion": m.global.IABTCF_CmpSdkVersion,
            "IABTCF_PolicyVersion": m.global.IABTCF_PolicyVersion,
            "IABTCF_gdprApplies": m.global.IABTCF_gdprApplies,
            "IABTCF_TCString": m.global.IABTCF_TCString,
            "IABTCF_PublisherCC": m.global.IABTCF_PublisherCC,
            "IABTCF_PurposeOneTreatment": m.global.IABTCF_PurposeOneTreatment,
            "IABTCF_SpecialFeaturesOptIns": m.global.IABTCF_SpecialFeaturesOptIns,
            "IABTCF_UseNonStandardStacks": m.global.IABTCF_UseNonStandardStacks,
            "IABTCF_PurposeConsents": m.global["IABTCF_PurposeConsents"],
            "IABTCF_PurposeLegitimateInterests": m.global["IABTCF_PurposeLegitimateInterests"],
            "IABTCF_PublisherConsent": m.global["IABTCF_PublisherConsent"],
            "IABTCF_PublisherLegitimateInterests": m.global["IABTCF_PublisherLegitimateInterests"],
            "IABTCF_VendorConsents": m.global["IABTCF_VendorConsents"],
            "IABTCF_VendorLegitimateInterests": m.global["IABTCF_VendorLegitimateInterests"],
            "IABTCF_LastUpdated": m.global["IABTCF_LastUpdated"],
            "IABTCF_IsServiceSpecific": m.global["IABTCF_IsServiceSpecific"],
            "IABTCF_PublisherRestrictions1": m.global["IABTCF_PublisherRestrictions1"],
            "IABTCF_PublisherRestrictions2": m.global["IABTCF_PublisherRestrictions2"],
            "IABTCF_PublisherRestrictions3": m.global["IABTCF_PublisherRestrictions3"],
            "IABTCF_PublisherRestrictions4": m.global["IABTCF_PublisherRestrictions4"],
            "IABTCF_PublisherRestrictions5": m.global["IABTCF_PublisherRestrictions5"],
            "IABTCF_PublisherRestrictions6": m.global["IABTCF_PublisherRestrictions6"],
            "IABTCF_PublisherRestrictions7": m.global["IABTCF_PublisherRestrictions7"],
            "IABTCF_PublisherRestrictions8": m.global["IABTCF_PublisherRestrictions8"],
            "IABTCF_PublisherRestrictions9": m.global["IABTCF_PublisherRestrictions9"],
            "IABTCF_PublisherRestrictions10": m.global["IABTCF_PublisherRestrictions10"]
        })
        m.logger.set(m.errortype.Info, m.errorTags.Token, m.constant.Info["723"], model.tcString)
    end if

end function

function clearIABConsentsOnAutoReconsent()
    regGroupData = getRegGroupData()
    if m.iabPurposeList <> invalid and m.iabPurposeList.count() > 0 and regGroupData <> invalid and regGroupData.count() > 0
        for each item in m.iabPurposeList
            if regGroupData.doesExist(item) then regGroupData.Delete(item)
            if regGroupData.doesExist("Li_" + item) then regGroupData.Delete("Li_" + item)
            if m.saveGroupqueue.doesExist(item) then m.saveGroupqueue.Delete(item)
            if m.saveGroupqueue.doesExist("Li_" + item) then m.saveGroupqueue.Delete("Li_" + item)
        end for
        if regGroupData.doesExist("iab") then regGroupData.Delete("iab")
        if regGroupData.doesExist("google") then regGroupData.Delete("google")
        if m.saveGroupqueue.doesExist("iab") then m.saveGroupqueue.Delete("iab")
        if m.saveGroupqueue.doesExist("google") then m.saveGroupqueue.Delete("google")
    end if
    m.registry.Write("groupData", FormatJson(regGroupData))
    getValidGroup("", true)
    m.logger.set(m.errortype.Info, m.errorTags.IABHelper, m.constant.Info["735"])
end function

function setIabGlobalInitilization()
    if not m.global.doesExist("IABTCF_CmpSdkID") then m.global.Addfield("IABTCF_CmpSdkID", "string", false)
    if not m.global.doesExist("iabtcf_cmpsdkversion") then m.global.Addfield("IABTCF_CmpSdkVersion", "string", false)
    if not m.global.doesExist("IABTCF_PolicyVersion") then m.global.Addfield("IABTCF_PolicyVersion", "string", false)
    if not m.global.doesExist("IABTCF_gdprApplies") then m.global.Addfield("IABTCF_gdprApplies", "string", false)
    if not m.global.doesExist("IABTCF_TCString") then m.global.Addfield("IABTCF_TCString", "string", false)
    if not m.global.doesExist("IABTCF_PublisherCC") then m.global.Addfield("IABTCF_PublisherCC", "string", false)
    if not m.global.doesExist("IABTCF_PurposeOneTreatment") then m.global.Addfield("IABTCF_PurposeOneTreatment", "string", false)
    if not m.global.doesExist("IABTCF_SpecialFeaturesOptIns") then m.global.Addfield("IABTCF_SpecialFeaturesOptIns", "string", false)
    if not m.global.doesExist("IABTCF_UseNonStandardStacks") then m.global.Addfield("IABTCF_UseNonStandardStacks", "string", false)
    if not m.global.doesExist("IABTCF_PurposeConsents") then m.global.Addfield("IABTCF_PurposeConsents", "string", false)
    if not m.global.doesExist("IABTCF_PurposeLegitimateInterests") then m.global.Addfield("IABTCF_PurposeLegitimateInterests", "string", false)
    if not m.global.doesExist("IABTCF_PublisherConsent") then m.global.Addfield("IABTCF_PublisherConsent", "string", false)
    if not m.global.doesExist("IABTCF_PublisherLegitimateInterests") then m.global.Addfield("IABTCF_PublisherLegitimateInterests", "string", false)
    if not m.global.doesExist("IABTCF_VendorConsents") then m.global.Addfield("IABTCF_VendorConsents", "string", false)
    if not m.global.doesExist("IABTCF_VendorLegitimateInterests") then m.global.Addfield("IABTCF_VendorLegitimateInterests", "string", false)
    if not m.global.doesExist("IABTCF_LastUpdated") then m.global.Addfield("IABTCF_LastUpdated", "string", false)
    if not m.global.doesExist("IABTCF_IsServiceSpecific") then m.global.Addfield("IABTCF_IsServiceSpecific", "string", false)
    if not m.global.doesExist("IABTCF_PublisherRestrictions1") then m.global.Addfield("IABTCF_PublisherRestrictions1", "string", false)
    if not m.global.doesExist("IABTCF_PublisherRestrictions2") then m.global.Addfield("IABTCF_PublisherRestrictions2", "string", false)
    if not m.global.doesExist("IABTCF_PublisherRestrictions3") then m.global.Addfield("IABTCF_PublisherRestrictions3", "string", false)
    if not m.global.doesExist("IABTCF_PublisherRestrictions4") then m.global.Addfield("IABTCF_PublisherRestrictions4", "string", false)
    if not m.global.doesExist("IABTCF_PublisherRestrictions5") then m.global.Addfield("IABTCF_PublisherRestrictions5", "string", false)
    if not m.global.doesExist("IABTCF_PublisherRestrictions6") then m.global.Addfield("IABTCF_PublisherRestrictions6", "string", false)
    if not m.global.doesExist("IABTCF_PublisherRestrictions7") then m.global.Addfield("IABTCF_PublisherRestrictions7", "string", false)
    if not m.global.doesExist("IABTCF_PublisherRestrictions8") then m.global.Addfield("IABTCF_PublisherRestrictions8", "string", false)
    if not m.global.doesExist("IABTCF_PublisherRestrictions9") then m.global.Addfield("IABTCF_PublisherRestrictions9", "string", false)
    if not m.global.doesExist("IABTCF_PublisherRestrictions10") then m.global.Addfield("IABTCF_PublisherRestrictions10", "string", false)
end function

function removeIabRegistry()
    m.registry.deleteKeys([
        "IABTCF_CmpSdkID",
        "IABTCF_CmpSdkVersion",
        "IABTCF_PolicyVersion",
        "IABTCF_gdprApplies",
        "IABTCF_TCString",
        "IABTCF_PublisherCC",
        "IABTCF_PurposeOneTreatment",
        "IABTCF_SpecialFeaturesOptIns",
        "IABTCF_UseNonStandardStacks",
        "IABTCF_PurposeConsents",
        "IABTCF_PurposeLegitimateInterests",
        "IABTCF_PublisherConsent",
        "IABTCF_PublisherLegitimateInterests",
        "IABTCF_VendorConsents",
        "IABTCF_VendorLegitimateInterests",
        "IABTCF_LastUpdated",
        "IABTCF_IsServiceSpecific",
        "IABTCF_PublisherRestrictions1",
        "IABTCF_PublisherRestrictions2",
        "IABTCF_PublisherRestrictions3",
        "IABTCF_PublisherRestrictions4",
        "IABTCF_PublisherRestrictions5",
        "IABTCF_PublisherRestrictions6",
        "IABTCF_PublisherRestrictions7",
        "IABTCF_PublisherRestrictions8",
        "IABTCF_PublisherRestrictions9",
        "IABTCF_PublisherRestrictions10"
    ])
end function

function removeIabGlobal()
    if m.global.doesExist("IABTCF_CmpSdkID") then m.global.removeField("IABTCF_CmpSdkID")
    if m.global.doesExist("IABTCF_CmpSdkVersion") then m.global.removeField("IABTCF_CmpSdkVersion")
    if m.global.doesExist("IABTCF_PolicyVersion") then m.global.removeField("IABTCF_PolicyVersion")
    if m.global.doesExist("IABTCF_gdprApplies") then m.global.removeField("IABTCF_gdprApplies")
    if m.global.doesExist("IABTCF_TCString") then m.global.removeField("IABTCF_TCString")
    if m.global.doesExist("IABTCF_PublisherCC") then m.global.removeField("IABTCF_PublisherCC")
    if m.global.doesExist("IABTCF_PurposeOneTreatment") then m.global.removeField("IABTCF_PurposeOneTreatment")
    if m.global.doesExist("IABTCF_SpecialFeaturesOptIns") then m.global.removeField("IABTCF_SpecialFeaturesOptIns")
    if m.global.doesExist("IABTCF_UseNonStandardStacks") then m.global.removeField("IABTCF_UseNonStandardStacks")
    if m.global.doesExist("IABTCF_PurposeConsents") then m.global.removeField("IABTCF_PurposeConsents")
    if m.global.doesExist("IABTCF_PurposeLegitimateInterests") then m.global.removeField("IABTCF_PurposeLegitimateInterests")
    if m.global.doesExist("IABTCF_PublisherConsent") then m.global.removeField("IABTCF_PublisherConsent")
    if m.global.doesExist("IABTCF_PublisherLegitimateInterests") then m.global.removeField("IABTCF_PublisherLegitimateInterests")
    if m.global.doesExist("IABTCF_VendorConsents") then m.global.removeField("IABTCF_VendorConsents")
    if m.global.doesExist("IABTCF_VendorLegitimateInterests") then m.global.removeField("IABTCF_VendorLegitimateInterests")
    if m.global.doesExist("IABTCF_LastUpdated") then m.global.removeField("IABTCF_LastUpdated")
    if m.global.doesExist("IABTCF_IsServiceSpecific") then m.global.removeField("IABTCF_IsServiceSpecific")
    if m.global.doesExist("IABTCF_PublisherRestrictions1") then m.global.removeField("IABTCF_PublisherRestrictions1")
    if m.global.doesExist("IABTCF_PublisherRestrictions2") then m.global.removeField("IABTCF_PublisherRestrictions2")
    if m.global.doesExist("IABTCF_PublisherRestrictions3") then m.global.removeField("IABTCF_PublisherRestrictions3")
    if m.global.doesExist("IABTCF_PublisherRestrictions4") then m.global.removeField("IABTCF_PublisherRestrictions4")
    if m.global.doesExist("IABTCF_PublisherRestrictions5") then m.global.removeField("IABTCF_PublisherRestrictions5")
    if m.global.doesExist("IABTCF_PublisherRestrictions6") then m.global.removeField("IABTCF_PublisherRestrictions6")
    if m.global.doesExist("IABTCF_PublisherRestrictions7") then m.global.removeField("IABTCF_PublisherRestrictions7")
    if m.global.doesExist("IABTCF_PublisherRestrictions8") then m.global.removeField("IABTCF_PublisherRestrictions8")
    if m.global.doesExist("IABTCF_PublisherRestrictions9") then m.global.removeField("IABTCF_PublisherRestrictions9")
    if m.global.doesExist("IABTCF_PublisherRestrictions10") then m.global.removeField("IABTCF_PublisherRestrictions10")
end function