function havingIabvendor()
    sdkData = m.global._OT_initialize_data
    iabTypeversion = getIabTypeVersion()
    IabV2Data = optionalChaining(sdkData, "domain." + "Iab" + iabTypeversion + "Data")
    isIabvendor = false
    if isIAB2() and IabV2Data <> invalid and IabV2Data.globalVendorListUrl <> invalid and IabV2Data.globalVendorListUrl <> ""
        isIabvendor = true
    end if
    return isIabvendor
end function

function havingGooglevendor()
    sdkData = m.global._OT_initialize_data
    MobileData = optionalChaining(sdkData, "culture.MobileData")
    GoogleData = optionalChaining(sdkData, "domain.GoogleData")
    isGooglevendor = false
    if MobileData <> invalid and MobileData.preferenceCenterData <> invalid and MobileData.preferenceCenterData.googleVendors <> invalid and MobileData.preferenceCenterData.googleVendors.general <> invalid and MobileData.preferenceCenterData.googleVendors.general.show and GoogleData <> invalid and GoogleData.googleVendorListUrl <> invalid and GoogleData.googleVendorListUrl <> ""
        isGooglevendor = true
    end if
    return isGooglevendor
end function

function isIAB2() as boolean
    sdkData = m.global._OT_initialize_data
    if sdkData = invalid
        return false
    end if
    havingIAB2 = false
    if optionalChaining(sdkData, "domain.ruleDetails") <> invalid and (sdkData.domain.ruleDetails.type = "IAB2" or isIAB2V2()) then havingIAB2 = true
    return havingIAB2
end function

function isIAB2V2() as boolean
    sdkData = m.global._OT_initialize_data
    if sdkData = invalid
        return false
    end if
    havingIAB2 = false
    if optionalChaining(sdkData, "domain.ruleDetails") <> invalid and sdkData.domain.ruleDetails.type = "IAB2V2" then havingIAB2 = true
    return havingIAB2
end function

function setVendorDetails(data) 
    if havingIabvendor()
        ' iab vendor task
        m.iabVendorTask = CreateObject("roSGNode", "OTVendorTask")
        m.iabVendorTask.functionName = "IABVendorsList"
        m.iabVendorTask.applicationData = data
        m.iabVendorTask.observeField("callback", "vendorDetailsCallback")
        m.iabVendorTask.control = "RUN"
    end if
    if havingGooglevendor()
        ' google vendor task
        m.googleVendorTask = CreateObject("roSGNode", "OTVendorTask")
        m.googleVendorTask.functionName = "GoogleVendorsList"
        m.googleVendorTask.applicationData = data
        m.googleVendorTask.observeField("callback", "vendorDetailsCallback")
        m.googleVendorTask.control = "RUN"
    end if
end function

function vendorDetailsCallback(data)
    callback = data.getdata()
    if callback.vendortype = "iab" 
        m.iabVendorTask.unObserveField("callback")
        m.iabVendorTask.control = "STOP"
        m.iabVendorTask = invalid
    end if
    if callback.vendortype = "google" 
        m.googleVendorTask.unObserveField("callback")
        m.googleVendorTask.control = "STOP"
        m.googleVendorTask = invalid
    end if
    if m.iabVendorTask = invalid and m.googleVendorTask = invalid
        m.top.eventlistener = "dataDownloadSucess"
    end if
end function

function getPurposeIDs(id)
    if id <> invalid
        uid = id.split("_")
        if uid <> invalid and uid[1] <> invalid then return uid[1]
    end if
    return invalid
end function

function isIab_PURPOSE(iab_type)
    return iab_type <> invalid and iab_type.Instr("_SPL_PURPOSE") = -1 and iab_type.Instr("_PURPOSE") <> -1
end function

function isIab_SPL_PURPOSE(iab_type)
    return iab_type <> invalid and iab_type.Instr("_SPL_PURPOSE") <> -1 
end function

function isIab_FEATURE(iab_type)
    return iab_type <> invalid and iab_type.Instr("_SPL_FEATURE") = -1 and iab_type.Instr("_FEATURE") <> -1
end function

function isIab_SPL_FEATURE(iab_type)
    return iab_type <> invalid and iab_type.Instr("_SPL_FEATURE") <> -1 
end function

function isIab_STACK(iab_type)
    return iab_type <> invalid and iab_type.Instr("_STACK") <> -1
end function

function getIabTypeVersion(withVersion = true)
    sdkData = m.global._OT_initialize_data
    if sdkData = invalid
        return false
    end if
    iabTypeversion = "2V2"
    if optionalChaining(sdkData, "domain.ruleDetails.type") <> invalid
        iabTypeversion = sdkData.domain.ruleDetails.type.replace("IAB", "")
        if withVersion and iabTypeversion = "2" then iabTypeversion = "V" + iabTypeversion
    end if
    return iabTypeversion
end function