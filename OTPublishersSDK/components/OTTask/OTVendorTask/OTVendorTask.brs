function init()
    m.constant = applicationConstants()
    m.errortype = getErrorType()
    m.errorTags = getErrorTags()
    m.logger = logUtil()
    m.registry = RegistryUtil()
end function

'  IAB Vendors
function IABVendorsList()
    sdkData = m.top.applicationData
    iabTypeversion = getIabTypeVersion()
    IabV2Data = optionalChaining(sdkData, "domain." + "Iab" + iabTypeversion + "Data")

    if isIAB2() and IabV2Data <> invalid and IabV2Data.globalVendorListUrl <> invalid and IabV2Data.globalVendorListUrl <> ""
        m.customHeaders = invalid
        OTgetContent(IabV2Data.globalVendorListUrl, setInitializeIABVData)
    end if
end function

function setInitializeIABVData(initializeData as object)
    m.logger.set(m.errortype.Success, m.errorTags.NetworkRequestHandler, "IAB" + m.constant.success["201"])
    iab = m.global._OT_IABVendor_data
    iab["iab"] = initializeData
    iab = getIABVendorData("iab", iab)
    _OT_IABVendor_data = m.global._OT_IABVendor_data
    if optionalChaining(_OT_IABVendor_data, "defaultAcceptAll") <> invalid then iab.defaultAcceptAll.append(_OT_IABVendor_data.defaultAcceptAll)
    if optionalChaining(_OT_IABVendor_data, "defaultRejectAll") <> invalid then iab.defaultRejectAll.append(_OT_IABVendor_data.defaultRejectAll)
    if optionalChaining(_OT_IABVendor_data, "defaultSPLI") <> invalid then iab.defaultSPLI.append(_OT_IABVendor_data.defaultSPLI)
    if optionalChaining(_OT_IABVendor_data, "google") <> invalid then iab["google"] = _OT_IABVendor_data.google
    m.global._OT_IABVendor_data = iab
    m.top.callback = {vendorType: "iab"}
end function

'  google Vendors
function GoogleVendorsList()
    sdkData = m.top.applicationData
    MobileData = optionalChaining(sdkData, "culture.MobileData")
    GoogleData = optionalChaining(sdkData, "domain.GoogleData")
    if MobileData <> invalid and MobileData.preferenceCenterData <> invalid and MobileData.preferenceCenterData.googleVendors <> invalid and MobileData.preferenceCenterData.googleVendors.general <> invalid and MobileData.preferenceCenterData.googleVendors.general.show and GoogleData <> invalid and GoogleData.googleVendorListUrl <> invalid and GoogleData.googleVendorListUrl <> ""
        m.customHeaders = invalid
        OTgetContent(GoogleData.googleVendorListUrl, setInitializeGoogleVData)
    end if
end function

function setInitializeGoogleVData(initializeData as object)
    m.logger.set(m.errortype.Success, m.errorTags.NetworkRequestHandler, "Google" + m.constant.success["201"])
    google = m.global._OT_IABVendor_data
    google["google"] = initializeData
    google = getIABVendorData("google", google)
    _OT_IABVendor_data = m.global._OT_IABVendor_data
    if optionalChaining(_OT_IABVendor_data, "defaultAcceptAll") <> invalid then google.defaultAcceptAll.append(_OT_IABVendor_data.defaultAcceptAll)
    if optionalChaining(_OT_IABVendor_data, "defaultRejectAll") <> invalid then google.defaultRejectAll.append(_OT_IABVendor_data.defaultRejectAll)
    if optionalChaining(_OT_IABVendor_data, "defaultSPLI") <> invalid then google.defaultSPLI.append(_OT_IABVendor_data.defaultSPLI)
    if optionalChaining(_OT_IABVendor_data, "iab") <> invalid google["iab"] = _OT_IABVendor_data.iab
    m.global._OT_IABVendor_data = google
    m.top.callback = {vendorType: "google"}
end function

function getIABVendorData(vendortype, data)
    records = finalIABVendorRecords(vendortype, data)
   ' sortrecords = []
   ' dataNode = {}
   ' for each item in records[vendortype]["filteredVendorRecords"].Items()
   '     if item.value.shouldShowVendor <> invalid and item.value.shouldShowVendor
   '         sortrecords.push(item.value)
   '         dataNode.AddReplace(item.value["id"].toStr(), CreateObject("roSGNode", "OTGroupListData")) 
   '     end if
   ' end for
   ' sortrecords.sortby("name", "i")
   ' records[vendortype]["sortedVendorRecords"] = sortrecords
   ' records[vendortype]["sortedNodeVendorRecords"] = dataNode
    return records
end function

function finalIABVendorRecords(vendortype, data)
    sdkData = m.top.applicationData
    culture = sdkData.culture
    vendors = data[vendortype]["vendors"]
    DomainData = culture.DomainData
    sortrecords = []
    dataNode = {}
    regIabData = invalid
    IABTCF_VendorConsents = invalid
    IABTCF_VendorLegitimateInterests = invalid
    IABTCF_AddtlConsent = invalid
    newVendorsInactiveEnabled = optionalChaining(DomainData, "NewVendorsInactiveEnabled")
    iabTypeversion = getIabTypeVersion()
    iabTypeversionN = getIabTypeVersion(false)
    LegIntSettings = getLegIntSettings()
    isAllPurposesUpdatedAfterSync = checkAllPurposeUpdatedSync()
    if vendortype = "iab" then data[vendortype]["filteredSupportPurposes"] = {}
    isGppEnable = isGppEnabled()
    havingTcsting = (m.global.IABTCF_TCString <> invalid and m.global.IABTCF_TCString <> "") or (isGppEnable and m.registry.read("IABGPP_2_String") <> invalid)
    havingVendors = (m.global.IABTCF_VendorConsents <> invalid or m.global.IABTCF_VendorLegitimateInterests <> invalid) or (isGppEnable and (m.registry.read("IABGPP_TCFEU2_VendorConsents") <> invalid or m.registry.read("IABGPP_TCFEU2_VendorLegitimateInterests") <> invalid))
    if vendortype = "iab" and havingTcsting and havingVendors
        if regIabData = invalid then regIabData = {}
        if regIabData.iab = invalid then regIabData["iab"] = {}
        IABTCF_VendorConsents = m.registry.read("vendorConsentsEncoded")
        IABTCF_VendorLegitimateInterests = m.registry.read("vendorLegitimateInterestsEncoded")
        if IABTCF_VendorConsents <> invalid 
            IABTCF_VendorConsents = IABTCF_VendorConsents.split("")
        else 
            tempVC = m.global.IABTCF_VendorConsents
            if isGppEnable then tempVC = m.registry.read("IABGPP_TCFEU2_VendorConsents")
            IABTCF_VendorConsents = tempVC.split("")
        end if
        if IABTCF_VendorLegitimateInterests <> invalid
            IABTCF_VendorLegitimateInterests = IABTCF_VendorLegitimateInterests.split("")
        else
            tempVl = m.global.IABTCF_VendorLegitimateInterests
            if isGppEnable then tempVl = m.registry.read("IABGPP_TCFEU2_VendorLegitimateInterests")
            IABTCF_VendorLegitimateInterests = tempVl.split("")
        end if
    end if
    if vendortype = "google" and m.global.IABTCF_AddtlConsent <> invalid and m.global.IABTCF_AddtlConsent <> "" 
        if regIabData = invalid then regIabData = {}
        if regIabData.iab = invalid then regIabData["google"] = {}
        IABTCF_AddtlConsent = ""
        if m.global.IABTCF_AddtlConsent <> "1~" then IABTCF_AddtlConsent = m.global.IABTCF_AddtlConsent.replace("1~", ".") + "."
    end if
    overriddenVendors = DomainData.OverriddenVendors
    vendorListVersion = optionalChaining(sdkData, "domain." + "Iab" + iabTypeversion + "Data" + ".vendorListVersion")
    if vendortype = "google" then overriddenVendors = DomainData.OverridenGoogleVendors
    PublisherRestrictions = DomainData.publisher.restrictions
    organizedPublisherRestrictions = organizePublisherRestrictionsForQuickLookupByVendor(PublisherRestrictions)
    vendorRecords = vendors
    vendorKeys = vendorRecords.Keys()
    vCount = vendorKeys.count() - 1
    for i = 0 to vCount
        vendorRecord = vendorRecords[vendorKeys[i]]
        strVendorID = vendorRecord["id"].toStr()
        vendorRecord["shouldShowVendor"] = true
        overriddenVendorRecord = overriddenVendors[strVendorID]
        if vendortype = "google"
            vendorRecord["shouldShowConsentToggleForVendor"] = true
            vendorRecord["purposes"] = []
            vendorRecord["legIntPurposes"] = []
            vendorRecord["specialPurposes"] = []
            vendorRecord["features"] = []
            vendorRecord["specialFeatures"] = []
            if overriddenVendorRecord <> invalid
                ' should show vendor override
                vendorRecord["shouldShowVendor"] = overriddenVendorRecord["active"]
            end if
        else
            ' check published iab vendors version
            iabGVLVersion = optionalChaining(vendorRecord, "iab"+ iabTypeversionN + "GVLVersion")
            vendorRecord["shouldShowVendor"] = ((newVendorsInactiveEnabled = invalid or newVendorsInactiveEnabled) and iabGVLVersion <> invalid and vendorListVersion <> invalid and iabGVLVersion <= vendorListVersion) or not newVendorsInactiveEnabled
            ' override defaults based on publisher restrictions rules...
            ' if restriction type = 0 , remove purpose id from LI and Purpose
            ' if restriction type = 1 , move purpose id from LI to Purpose
            ' if restriction type = 2 , move purpose id from Purpose to LI
            if organizedPublisherRestrictions.doesExist(strVendorID)
                ' purposeIDsToRemove
                for each purposeID in organizedPublisherRestrictions[strVendorID]["0"]
                    vendorRecords[strVendorID]["purposes"] = filterArray(vendorRecords[strVendorID]["purposes"], purposeID)
                    vendorRecords[strVendorID]["legIntPurposes"] = filterArray(vendorRecords[strVendorID]["legIntPurposes"], purposeID)
                end for

                ' purposeIDs_move_LI_to_Purpose
                for each purposeID in organizedPublisherRestrictions[strVendorID]["1"]
                    islegIntPurposes = false
                    for each item in vendorRecords[strVendorID]["legIntPurposes"]
                        if item = purposeID
                            islegIntPurposes = true
                            exit for
                        end if
                    end for
                    if islegIntPurposes
                        vendorRecords[strVendorID]["purposes"] = filterArray(vendorRecords[strVendorID]["purposes"], purposeID)
                        vendorRecords[strVendorID]["legIntPurposes"] = filterArray(vendorRecords[strVendorID]["legIntPurposes"], purposeID)
                        vendorRecords[strVendorID]["purposes"].push(purposeID)
                        vendorRecords[strVendorID]["purposes"].sort()
                    end if
                end for

                ' purposeIDs_move_Purpose_to_LI
                for each purposeID in organizedPublisherRestrictions[strVendorID]["2"]
                    isPurposes = false
                    for each item in vendorRecords[strVendorID]["purposes"]
                        if item = purposeID
                            isPurposes = true
                            exit for
                        end if
                    end for
                    if isPurposes
                        vendorRecords[strVendorID]["purposes"] = filterArray(vendorRecords[strVendorID]["purposes"], purposeID)
                        vendorRecords[strVendorID]["legIntPurposes"] = filterArray(vendorRecords[strVendorID]["legIntPurposes"], purposeID)
                        vendorRecords[strVendorID]["legIntPurposes"].push(purposeID)
                        vendorRecords[strVendorID]["legIntPurposes"].sort()
                    end if
                end for
                if not vendorRecord["shouldShowVendor"]
                    vendorRecord["shouldShowConsentToggleForVendor"] = false
                    vendorRecord["shouldShowLegitimateInterestToggleForVendor"] = false
                end if
            end if

            ' override defaults based on overridden Vendor rules
            if overriddenVendorRecord <> invalid
                ' should show vendor override
                vendorRecord["shouldShowVendor"] = overriddenVendorRecord["active"]
                ' should update the consent and legint from the overriden values
                vendorRecord["shouldShowConsentToggleForVendor"] = overriddenVendorRecord["consent"]
                vendorRecord["shouldShowLegitimateInterestToggleForVendor"] = overriddenVendorRecord["legInt"]
                if overriddenVendorRecord.disabledCP <> invalid and overriddenVendorRecord.disabledCP.count() > 0
                    for each purposeID in overriddenVendorRecord.disabledCP
                        vendorRecords[strVendorID]["purposes"] = filterArray(vendorRecords[strVendorID]["purposes"], purposeID)
                    end for
                end if
                if overriddenVendorRecord.disabledLIP <> invalid and overriddenVendorRecord.disabledLIP.count() > 0
                    for each purposeID in overriddenVendorRecord.disabledLIP
                        vendorRecords[strVendorID]["legIntPurposes"] = filterArray(vendorRecords[strVendorID]["legIntPurposes"], purposeID)
                    end for
                end if
            end if
            if optionalChaining(LegIntSettings, "PAllowLI") <> invalid AND not LegIntSettings.PAllowLI then vendorRecords[strVendorID]["legIntPurposes"] = []
            vendorRecord["shouldShowConsentToggleForVendor"] = vendorRecord.purposes.count() > 0
            vendorRecord["shouldShowLegitimateInterestToggleForVendor"] = vendorRecord.legIntPurposes.count() > 0

        end if
        if vendorRecord["shouldShowVendor"]
            if m.defaultAcceptAll = invalid then m.defaultAcceptAll = {}
            if m.defaultRejectAll = invalid then m.defaultRejectAll = {}
            if m.defaultAcceptAll[vendortype] = invalid then m.defaultAcceptAll[vendortype] = {}
            if m.defaultRejectAll[vendortype] = invalid then m.defaultRejectAll[vendortype] = {}
            if m.defaultSPLI = invalid then m.defaultSPLI = []
            if vendorRecord["shouldShowConsentToggleForVendor"] <> invalid and vendorRecord["shouldShowConsentToggleForVendor"]
                m.defaultAcceptAll[vendortype][strVendorID] = "active"
                m.defaultRejectAll[vendortype][strVendorID] = "inactive"
                regIabData = saveIabSyncProfile(IABTCF_VendorConsents, strVendorID, regIabData, isAllPurposesUpdatedAfterSync, true) 
                regIabData = saveGoogleSyncProfile(IABTCF_AddtlConsent, strVendorID, regIabData) 
            end if
            if isVendorLegitimateInterest(vendorRecord, LegIntSettings)
                m.defaultAcceptAll[vendortype]["Li_" + strVendorID] = "active"
                m.defaultRejectAll[vendortype]["Li_" + strVendorID] = "inactive"
                regIabData = saveIabSyncProfile(IABTCF_VendorLegitimateInterests, strVendorID, regIabData, isAllPurposesUpdatedAfterSync, false) 
            end if
            if vendortype = "iab" and vendorRecord.specialPurposes <> invalid and vendorRecord.specialPurposes.count() > 0 and vendorRecord["shouldShowConsentToggleForVendor"] <> invalid and not vendorRecord["shouldShowConsentToggleForVendor"] and not isVendorLegitimateInterest(vendorRecord, LegIntSettings)
                ' vendorID LI = 1 moves to TC string when no purposes and legIntPurposes
                m.defaultSPLI.push(strVendorID.ToInt())
            end if
            sortrecords.push(vendorRecords[strVendorID])
            dataNode.AddReplace(strVendorID, CreateObject("roSGNode", "OTGroupListData"))
            if vendortype = "iab" then data = setIabPurposeFilter(vendorRecords[strVendorID],strVendorID,data, iabTypeversion)
        end if
    end for
    if regIabData <> invalid then m.global.OTsdk.callFunc("setsaveGroupqueue", regIabData)
    data[vendortype]["filteredVendorRecords"] = vendorRecords
    data["defaultAcceptAll"] = m.defaultAcceptAll
    data["defaultRejectAll"] = m.defaultRejectAll
    data["defaultSPLI"] = m.defaultSPLI
    sortrecords.sortby("name", "i")
    data[vendortype]["sortedVendorRecords"] = sortrecords
    data[vendortype]["sortedNodeVendorRecords"] = dataNode
    return data
end function

function saveIabSyncProfile(syncArray, strVendorID, regIabData, isAllPurposesUpdatedAfterSync, isconsent)
    if syncArray <> invalid and (syncArray.count() > 0 or syncArray.count() = 0)
        vIdIndex = (strVendorID.toInt() - 1)
        value = syncArray[vIdIndex]
        if value = "0" or value = "1" or isAllPurposesUpdatedAfterSync
            vstatus = "inactive"
            if value = "1" then vstatus = "active"
            if not isconsent then strVendorID = "Li_" + strVendorID
            regIabData.iab[strVendorID] = vstatus
        end if
    end if
    return regIabData
end function


function saveGoogleSyncProfile(syncArray, strVendorID, regIabData)
    if syncArray <> invalid
        vstatus = "inactive"
        if syncArray <> ""
            matchArray = syncArray.split("." + strVendorID + ".")
            if matchArray <> invalid and matchArray.count() > 1 then vstatus = "active"
        end if
        regIabData.google[strVendorID] = vstatus
    end if
    return regIabData
end function

function organizePublisherRestrictionsForQuickLookupByVendor(publisherRestrictions)
    answer = {}
    publisherRestrictionsKeys = publisherRestrictions.keys()
    if publisherRestrictionsKeys.count() > 0
        for each purposeID in publisherRestrictionsKeys
            'purposeID = publisherRestrictionsKeys[index]
            vendorDict = publisherRestrictions[purposeID]
            if vendorDict <> invalid
                for each vendorID in vendorDict
                    ' vendorID = vendorIDs[index2]
                    restrictionType = vendorDict[vendorID]

                    if restrictionType >= 0 and restrictionType <= 2
                        strVendorID = vendorID
                        strRestrictionType = restrictionType.tostr()

                        if not answer.doesExist(strVendorID)
                            answer[strVendorID] = { "0": [], "1": [], "2": [] }
                        end if

                        answer[strVendorID][strRestrictionType].push(purposeID.toInt())

                    end if

                end for
            end if
        end for
    end if
    return answer
end function

function filterArray(records, purposeID)
    purposes = []
    for each item in records
        if item <> purposeID
            purposes.push(item)
        end if
    end for
    return purposes
end function

function setIabPurposeFilter(vendor, id, data, iabTypeversion)
    if optionalChaining(vendor, "purposes") <> invalid and vendor.purposes.count() > 0
        for each item in vendor.purposes
            pid = "IAB" + iabTypeversion + "_" + item.toStr()
            if data["iab"]["filteredSupportPurposes"][pid] = invalid then data["iab"]["filteredSupportPurposes"][pid] = {}
            data["iab"]["filteredSupportPurposes"][pid][id] = vendor
        end for
    end if
    if optionalChaining(vendor, "legIntPurposes") <> invalid and vendor.legIntPurposes.count() > 0
        for each item in vendor.legIntPurposes
            pid = "IAB" + iabTypeversion + "_" + item.toStr()
            if data["iab"]["filteredSupportPurposes"][pid] = invalid then data["iab"]["filteredSupportPurposes"][pid] = {}
            data["iab"]["filteredSupportPurposes"][pid][id] = vendor
        end for
    end if 
    if optionalChaining(vendor, "specialPurposes") <> invalid and vendor.specialPurposes.count() > 0
        for each item in vendor.specialPurposes
            pid = "ISP" + iabTypeversion + "_" + item.toStr()
            if data["iab"]["filteredSupportPurposes"][pid] = invalid then data["iab"]["filteredSupportPurposes"][pid] = {}
            data["iab"]["filteredSupportPurposes"][pid][id] = vendor
        end for
    end if
    if optionalChaining(vendor, "features") <> invalid and vendor.features.count() > 0
        for each item in vendor.features
            pid = "IFE" + iabTypeversion + "_" + item.toStr()
            if data["iab"]["filteredSupportPurposes"][pid] = invalid then data["iab"]["filteredSupportPurposes"][pid] = {}
            data["iab"]["filteredSupportPurposes"][pid][id] = vendor
        end for
    end if
    if optionalChaining(vendor, "specialFeatures") <> invalid and vendor.specialFeatures.count() > 0
        for each item in vendor.specialFeatures
            pid = "ISF" + iabTypeversion + "_" + item.toStr()
            if data["iab"]["filteredSupportPurposes"][pid] = invalid then data["iab"]["filteredSupportPurposes"][pid] = {}
            data["iab"]["filteredSupportPurposes"][pid][id] = vendor
        end for
    end if
    return data
end function

function isGppEnabled()
    sdkData = m.global._OT_initialize_data
    IsGPPEnable = optionalChaining(sdkData, "culture.DomainData.IsGPPEnabled")
    if IsGPPEnable <> invalid and IsGPPEnable
        return sdkData.culture.DomainData.IsGPPEnabled
    else
        return false
    end if
end function