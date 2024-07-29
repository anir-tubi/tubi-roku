function init()
    m.registry = RegistryUtil()
    m.constant = applicationConstants()
    m.errortype = getErrorType()
    m.errorTags = getErrorTags()
    m.logger = logUtil()
    m.GPPConstants = getGPPConstants()
    m.deviceInfo = CreateObject("roDeviceInfo")
    setfullScreenResolution()
    m.headerParams = {}
    m.subjectIdentifier = ""
    m.isAppIdentifier = false
    m.shouldCreateProfile = false
    m.syncProfile = invalid
    m.authProfileId = ""
    m.previousAppId = getRegAppId()
    m.previousSubjectIdentifier = getSubjectIdentifierRegistry()
    _OT_config = getOTconfig()
    if optionalChaining(_OT_config, "version") <> invalid
        m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["704"], _OT_config.version)
    end if
    m.networkAPIQueue = []
    m.saveGroupqueue = {}
    m.initGroups = {}
    m.tempsdkListConsentStatus = {}
    m.onShowPreferenceCenter = false
    m.iabPurposeList = []
    m.groups = []
    m.identifierType = "DeviceID"
end function

function getRegAppId() as string
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    if sdkReg.Exists("appId")
        return sdkReg.Read("appId")
    end if
    return ""
end function

function deleteSDKReg()
    m.registry.deleteSection("OT_Profiles")
    m.registry.deleteSection()
end function

function saveAppIdReg(appId as string)
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    sdkReg.Write("appId", appId)
    sdkReg.Flush()
end function

function clearOTSDK()
    resetOTinitialize()
    deleteSDKReg()
    m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["701"])
end function

function initOTSDKData(params as object) as void
    m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "initOTSDKData" + m.constant.info["705"])
    isMultiProfile = true
    if m.isSwitchUserProfile <> invalid and m.isSwitchUserProfile
        isMultiProfile = true
        m.isSwitchUserProfile = invalid
    else
        sdkData = optionalChaining(m.global, "_OT_initialize_data")
        if sdkData = invalid or sdkData.keys().count() = 0
            isMultiProfile = true
        else if isMultiProfileAllowed()
            isMaxProfileLimit = isMaxProfileLimitReached()
            if params["identifier"] = ""
                identifier = getGenericProfile()
                if identifier <> "" then params["identifier"] = identifier
                if identifier = "" and isMaxProfileLimit
                    m.previousSubjectIdentifier = ""
                    switchProfile(identifier)
                end if
            end if
            isMultiProfile = (isMaxProfileLimit or isProfileExists(params["identifier"]))
        end if
    end if
    if params["identifierType"] <> invalid
        m.identifierType = params["identifierType"]
    end if
    if isRequiredParams(params) and isMultiProfile
        if params["identifier"] <> invalid and params["identifier"] = ""
            params["identifier"] = m.subjectIdentifier
            m.previousSubjectIdentifier = m.subjectIdentifier
        end if
        m.global.Addfield("_OT_initialize_data", "assocarray", false)
        if m.headerParams.keys().count() > 0
            m.global.unObserveFieldScoped("_OT_initialize_data")
        else
            m.global.observeField("_OT_initialize_data", "saveInitialData")
        end if
        m.global.Addfield("_OT_IABVendor_data", "assocarray", false)
        m.global._OT_IABVendor_data = {}
        m.headerParams.Append(params)
        saveAppIdReg(params["applicationId"])
        ONETRUST_ROKU_KEYS = m.registry.read("ONETRUST_ROKU_KEYS")
        if (params["applicationId"] <> m.previousAppId and m.previousAppId <> invalid and m.previousAppId <> "")
            deleteSDKReg()
            if ONETRUST_ROKU_KEYS <> invalid and ONETRUST_ROKU_KEYS <> "" then m.registry.write("ONETRUST_ROKU_KEYS", ONETRUST_ROKU_KEYS)
        end if
        eTag = getETag()
        if eTag <> ""
            params.AddReplace("profileSyncETag", eTag)
        end if
        params.AddReplace("lastlaunch", getTimestampReg())
        initializeSDK(params)
        setGlobaldata()
    else
        m.setTimeout = setTimeoutTask()
        m.setTimeout.observeField("taskCompleted", "onHideFailure")
    end if
end function

function onHideFailure()
    m.setTimeout.control = "STOP"
    m.setTimeout.unObserveField("taskCompleted")
    m.setTimeout = invalid
    m.top.onHideFailure = true
end function

function isRequiredParams(params as object) as boolean
    if params["language"] = invalid or params["language"] = ""
        m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "Language", m.constant.warning["900"])
        return false
    end if
    if params["applicationId"] = invalid or params["applicationId"] = ""
        m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "Application ID", m.constant.warning["900"])
        return false
    end if
    if params["location"] = invalid or params["location"] = ""
        m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "Location", m.constant.warning["900"])
        return false
    end if
    if params["version"] = invalid or params["version"] = ""
        m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "SDK version", m.constant.warning["900"])
        return false
    end if
    if params["shouldCreateProfile"] <> invalid and type(params["shouldCreateProfile"]) = "roBoolean"
        m.shouldCreateProfile = params["shouldCreateProfile"]
    end if
    if params.syncProfile <> invalid
        if type(params.syncProfile) <> "roBoolean"
            m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "Syncprofile", m.constant.warning["901"])
            return false
        else
            setSyncProfile(params["syncProfile"])
        end if
    end if
    if params["syncProfileAuth"] <> invalid
        if type(params["syncProfileAuth"]) = "roString" or type(params["syncProfileAuth"]) = "String"
            setAuthProfileId(params["syncProfileAuth"])
        else
            m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "syncProfileAuth", m.constant.warning["902"])
            return false
        end if
    end if
    ONETRUST_ROKU_KEYS = m.registry.read("ONETRUST_ROKU_KEYS")
    genericProfile = m.registry.read("genericProfile")
    if params["identifier"] <> "" or (m.previousSubjectIdentifier <> "" and params["identifier"] = "" and genericProfile <> invalid and not (ONETRUST_ROKU_KEYS <> invalid and ONETRUST_ROKU_KEYS <> ""))
        if type(params["identifier"]) = "roString" or type(params["identifier"]) = "String"
            if m.previousSubjectIdentifier <> "" and params["identifier"] = "" then params["identifier"] = m.previousSubjectIdentifier
            setIdentifier(params["identifier"])
            m.isAppIdentifier = true
        else
            m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "identifier", m.constant.warning["902"])
            return false
        end if
    else
        getSubjectIdentifier()
    end if
    return true
end function

function OTSdkParams() as object
    params = {
        applicationId: sdkParams().getAppId(),
        location: sdkParams().getLocation(),
        version: sdkParams().getsdkVersion(),
        language: sdkParams().getLanguage(),
        shouldCreateProfile: sdkParams().getShouldCreateProfile(),
        countryCode: sdkParams().getCountryCode(),
        regionCode: sdkParams().getRegionCode()
    }
    profileSyncParams = getProfileSyncParams()
    params.Append(profileSyncParams)
    params = setONETRUST_ROKU_KEYS(params)
    return params
end function

function setONETRUST_ROKU_KEYS(params)
    ONETRUST_ROKU_KEYS = m.registry.read("ONETRUST_ROKU_KEYS")
    if ONETRUST_ROKU_KEYS <> invalid
        tempparams = ParseJson(ONETRUST_ROKU_KEYS)
        if optionalChaining(tempparams, "identifier") <> invalid and tempparams.identifier = "" and params.identifier <> "" then tempparams.identifier = params.identifier
        params.Append(tempparams)
    end if
    return params
end function

function sdkParams()
    instance = {
        getAppId: function() as dynamic
            headerParams = getHeaderParams()
            return headerParams.applicationId
        end function,
        getLocation: function() as dynamic
            headerParams = getHeaderParams()
            return headerParams.location
        end function,
        getLanguage: function() as dynamic
            headerParams = getHeaderParams()
            return headerParams.language
        end function,
        getsdkVersion: function() as dynamic
            headerParams = getHeaderParams()
            return headerParams.version
        end function
        getShouldCreateProfile: function() as dynamic
            return getCreateProfile()
        end function,
        getSyncProfile: function() as dynamic
            return getSyncProfile()
        end function
        getIdentifier: function() as string
            return getIdentifier()
        end function
        getAuthProfileId: function() as string
            return getAuthProfileId()
        end function
        getCountryCode: function() as dynamic
            headerParams = getHeaderParams()
            return headerParams.countryCode
        end function
        getRegionCode: function() as dynamic
            headerParams = getHeaderParams()
            return headerParams.regionCode
        end function
    }
    return instance
end function

function getProfileSyncParams() as object
    profileParams = {
        syncProfile: sdkParams().getSyncProfile(),
        identifier: sdkParams().getIdentifier(),
        syncProfileAuth: sdkParams().getAuthProfileId()
    }
    return profileParams
end function

function getHeaderParams() as object
    return m.headerParams
end function

function getCreateProfile() as boolean
    return m.shouldCreateProfile
end function

function getSyncProfile() as dynamic
    return m.syncProfile
end function

function getIdentifier() as string
    return m.subjectIdentifier
end function

function getIdentifierType() as string
    return m.identifierType
end function

function getAuthProfileId() as string
    return m.authProfileId
end function

function setSyncProfile(isProfileSync as boolean)
    m.syncProfile = isProfileSync
end function

function setAuthProfileId(authProfileId as string)
    m.authProfileId = authProfileId
end function

function setIdentifier(identifier as string)
    m.subjectIdentifier = identifier
end function

function initializeSDK(params as object)
    m.initializeSDK = CreateObject("roSGNode", "OTtask")
    m.initializeSDK.functionName = "initializeSDK"
    m.initializeSDK.requestParams = params
    m.initializeSDK.observeField("taskCompleted", "removeOTtask")
    m.initializeSDK.control = "RUN"
end function

function removeOTtask()
    if m.initializeSDK <> invalid
        m.initializeSDK.unObserveField("taskCompleted")
        m.initializeSDK.control = "STOP"
        m.initializeSDK = invalid
    end if
end function

function setupUI(data as object) as void
    m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "setupUI" + m.constant.info["705"])
    if data.view = invalid
        m.logger.set(m.errortype.Warning, m.errorTags.OneTrust, m.constant.warning["903"])
        return
    end if
    m.view = data.view
    if data.type <> invalid
        m.viewType = data.type
        m.global.observeFieldScoped("_OT_initialize_data", "onInitializeData")
    end if
end function

function onInitializeData()
    if m.viewType = "banner"
        showBannerUI(false)
    else if m.viewType = "preferencecenter"
        showPreferenceCenterUI()
    end if
end function

function showBannerUI(override = true) as void
    if type(override) <> "roSGNodeEvent" then m.override = override
    if m.view = invalid
        m.logger.set(m.errortype.Warning, m.errorTags.OneTrust, m.constant.warning["904"])
        return
    else if m.global._OT_initialize_data = invalid
        m.global.observeFieldScoped("_OT_initialize_data", "showBannerUI", override)
        return
    else if (havingIabvendor() and optionalChaining(m.global._OT_IABVendor_data, "iab") = invalid) or (havingGooglevendor() and optionalChaining(m.global._OT_IABVendor_data, "google") = invalid)
        m.global.observeFieldScoped("_OT_IABVendor_data", "showBannerUI", override)
        return
    end if
    m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "showBannerUI" + m.constant.info["705"])
    m.global.unObserveFieldScoped("_OT_IABVendor_data")
    if shouldShowBanner(m.override)
        m.bannerView = createObject("roSGNode", "OTBanner")
        m.bannerView.observeField("onHideBanner", "closeBanner")
        m.bannerView.observeField("onShowBanner", "onShowBanner")
        m.bannerView.observeField("onBannerClickedAcceptAll", "onBannerClickedAcceptAll")
        m.bannerView.observeField("onBannerClickedRejectAll", "onBannerClickedRejectAll")
        m.bannerView.observeField("onBannerClickedSettings", "showPreferenceCenterUI")
        m.bannerView.observeField("onBannerClickedVendorList", "showVendorListUI")
        m.bannerView.bannerData = getBannerData()
        m.bannerView.id = "OTBanner"
        m.view.appendChild(m.bannerView)
        saveBannerShownRegistry()
    end if
end function

function onAcceptAll(interactionType as string)
    groups = getValidGroup()
    acceptGroups = setGroupsAccept(groups)
    defaultAcceptAll = optionalChaining(m.global._OT_IABVendor_data, "defaultAcceptAll")
    if defaultAcceptAll <> invalid
        acceptGroups.append(defaultAcceptAll)
    end if
    acceptGroups["sdk"] = {}
    m.saveGroupqueue = acceptGroups
    saveGroupsToRegistry(acceptGroups)
    m.interactionType = interactionType
    m.action = "acceptAll"
    setConsentString()
end function

function updateLogConsent()
    consentData = getConsentPayload(m.action, m.interactionType)
    logConsent(consentData, m.action)
end function

function onRejectAll(interactiontype)
    culture = m.global._OT_initialize_data.culture
    statusObjectToLI = culture.MobileData.general.objectToLI = "LIActiveIfLegalBasis"
    groups = getValidGroup()
    rejectGroups = setGroupsReject(groups, statusObjectToLI)
    defaultRejectAll = optionalChaining(m.global._OT_IABVendor_data, "defaultRejectAll")
    vendorconsent = defaultRejectAll
    if statusObjectToLI then vendorConsent = setVendorsRejectObjectToLI(defaultRejectAll)
    if defaultRejectAll <> invalid
        rejectGroups.append(vendorConsent)
    end if
    rejectGroups["sdk"] = {}
    m.saveGroupqueue = rejectGroups
    saveGroupsToRegistry(rejectGroups)
    m.interactionType = interactionType
    m.action = "rejectAll"
    setConsentString()
end function

' functon to set vendors data on rejectall to LIActiveIfLegalBasis
function setVendorsRejectObjectToLI(vendors)
    regGroupData = getRegGroupData()
    vendortype = "iab"
    if vendors <> invalid and vendors[vendortype] <> invalid
        for each item in vendors[vendortype].items()
            status = "active"
            id = item.key
            if Left(item.key, 2) = "Li"
                if regGroupData[vendortype] <> invalid and regGroupData[vendortype].doesExist(id)
                    status = regGroupData[vendortype][id]
                end if
                if m.saveGroupqueue[vendortype] <> invalid and m.saveGroupqueue[vendortype].doesExist(id)
                    status = m.saveGroupqueue[vendortype][id]
                end if
                vendors[vendortype].AddReplace(item.key, status)
            end if
        end for
    end if
    return vendors
end function

function onShowBanner()
    m.logger.set(m.errortype.Info + "." + m.errortype.Banner, m.errorTags.EventListener, m.constant.listener["ELB100"])
    m.top.onShowBanner = true
end function

function onBannerClickedAcceptAll(message = {} as object)
    m.logger.set(m.errortype.Info + "." + m.errortype.Banner, m.errorTags.EventListener, m.constant.listener["ELB101"])
    m.top.AcceptAll = true
    onAcceptAll(m.constant.info.bannerAllowAll)
    onHideBanner(message)
end function

function setGroupsAccept(groups as object) as object
    groupIds = {}
    for each gp in groups
        if gp.status <> "always active"
            if gp.HasConsentOptOut = true
                groupIds.AddReplace(gp.CustomGroupId, "active")
            end if
            if isLegitimateInterest(gp, getLegIntSettings())
                groupIds.AddReplace("Li_" + gp.CustomGroupId, "active")
            end if
        else
            groupIds.AddReplace(gp.CustomGroupId, gp.status)
        end if
    end for
    return groupIds
end function

function onBannerClickedRejectAll(message = {} as object)
    m.logger.set(m.errortype.Info + "." + m.errortype.Banner, m.errorTags.EventListener, m.constant.listener["ELB102"])
    m.top.RejectAll = true
    onRejectAll(m.constant.info.bannerRejectAll)
    onHideBanner(message)
end function

function setGroupsReject(groups as object, statusObjectToLI) as object
    groupIds = {}
    li_status = "inactive"
    for each gp in groups
        if gp.status <> "always active"
            groupIds.AddReplace(gp.CustomGroupId, "inactive")
            if statusObjectToLI
                if gp.li_status <> invalid then groupIds.AddReplace("Li_" + gp.CustomGroupId, gp.li_status)
            else
                groupIds.AddReplace("Li_" + gp.CustomGroupId, li_status)
            end if
        else
            groupIds.AddReplace(gp.CustomGroupId, gp.status)
        end if
    end for
    return groupIds
end function

function onHideBanner(message = {} as object)
    m.logger.set(m.errortype.Info + "." + m.errortype.Banner, m.errorTags.EventListener, m.constant.listener["ELB105"])
    if type(message) = "roSGNodeEvent"
        view = message.getRoSGNode()
        m.view.removeChild(view)
    else if type(message) = "roSGNode"
        m.view.removeChild(message)
    end if
    m.top.onHideBanner = true
    m.top.onShowBanner = false
end function

function closeBanner(message = {} as object)
    view = message.getRoSGNode()
    interactionType = ""
    groups = m.saveGroupqueue
    vendorConsent = saveVendorConsent()
    groups.append(vendorConsent)
    saveGroupsToRegistry(groups)
    if view <> invalid and View.hideInteractionType <> "" then interactionType = View.hideInteractionType
    m.top.close = true
    m.interactionType = interactionType
    m.action = "close"
    setConsentString()
    onHideBanner(message)
end function

function onPreferenceCenterAcceptAll(message = {} as object)
    m.logger.set(m.errortype.Info + "." + m.errortype.preferenceCenter, m.errorTags.EventListener, m.constant.listener["ELP101"])
    onAcceptAll(m.constant.info.preferenceCenterAllowAll)
    onHidePreferencecenter(message)
end function

function onPreferenceCenterRejectAll(message = {} as object)
    m.logger.set(m.errortype.Info + "." + m.errortype.preferenceCenter, m.errorTags.EventListener, m.constant.listener["ELP102"])
    onRejectAll(m.constant.info.preferenceCenterRejectAll)
    onHidePreferencecenter(message)
end function

function onVendorListAcceptAll(message = {} as object)
    if m.vlView <> invalid and m.vlView.filterType <> invalid and m.vlView.filterType.vendorType <> invalid and m.vlView.filterType.vendorType <> ""
        msg = m.constant.listener["ELV101"]
        path = m.errortype.VendorList
        interactionType = m.constant.info.vendorListAllowAll
        if m.vlView.filterType.vendorType = "sdk"
            msg = m.constant.listener["ELS101"]
            path = m.errortype.SDKList
            interactionType = m.constant.info.sdkListAllowAll
        end if
    end if
    m.logger.set(m.errortype.Info + "." + path, m.errorTags.EventListener, msg)
    onAcceptAll(interactionType)
    onHideVendorList(message)
end function

function onVendorListRejectAll(message = {} as object)
    if m.vlView <> invalid and m.vlView.filterType <> invalid and m.vlView.filterType.vendorType <> invalid and m.vlView.filterType.vendorType <> ""
        msg = m.constant.listener["ELV102"]
        path = m.errortype.VendorList
        interactionType = m.constant.info.vendorListRejectAll
        if m.vlView.filterType.vendorType = "sdk"
            msg = m.constant.listener["ELS102"]
            path = m.errortype.SDKList
            interactionType = m.constant.info.sdkListRejectAll
        end if
    end if
    m.logger.set(m.errortype.Info + "." + path, m.errorTags.EventListener, msg)
    onRejectAll(interactionType)
    onHideVendorList(message)
end function

function onHidePreferencecenter(message = {} as object) as void
    m.logger.set(m.errortype.Info + "." + m.errortype.preferenceCenter, m.errorTags.EventListener, m.constant.listener["ELP110"])
    m.top.onHidePreferencecenter = true
    m.onShowPreferenceCenter = false
    if type(message) = "roSGNodeEvent"
        view = message.getRoSGNode()
        m.view.removeChild(view)
        if m.top.onShowBanner and view.id = "OTPreferenceCenter"
            viewChildCount = m.view.getChildCount()
            bannerChild = m.view.getChild(viewChildCount - 1)
            if view.onHidePreferenceCenter
                bannerChild.callFunc("setViewFocus", {})
            else
                onHideBanner(bannerChild)
            end if
        end if
    end if
end function

function onHideVendorList(message = {} as object) as void
    if m.vlView <> invalid and m.vlView.filterType <> invalid and m.vlView.filterType.vendorType <> invalid and m.vlView.filterType.vendorType <> ""
        msg = m.constant.listener["ELV100"]
        path = m.errortype.VendorList
        if m.vlView.filterType.vendorType = "sdk"
            msg = m.constant.listener["ELS100"]
            path = m.errortype.SDKList
        end if
    end if
    m.logger.set(m.errortype.Info + "." + path, m.errorTags.EventListener, msg)
    m.top.onHidePreferencecenter = true
    if type(message) = "roSGNodeEvent"
        view = message.getRoSGNode()
        m.view.removeChild(view)
        'if m.top.onShowBanner
        viewChildCount = m.view.getChildCount()
        child = m.view.getChild(viewChildCount - 1)
        if view.onHidePreferenceCenter
            if m.tempsdkListConsentStatus <> invalid and m.tempsdkListConsentStatus.count() > 0 then m.saveGroupqueue["sdk"] = m.tempsdkListConsentStatus
            child.callFunc("setViewFocus", { "vendorType": view.filterType.vendorType, "saveGroupqueue": m.saveGroupqueue })
        else
            removeChild = m.pcView
            if m.top.onShowBanner
                removeChild = m.bannerView
            end if
            onHideBanner(child)
            m.view.removeChild(removeChild)
        end if
        'end if
    end if
end function

function onPreferenceCenterConfirmChoices(message = {} as object) as void
    m.logger.set(m.errortype.Info + "." + m.errortype.preferenceCenter, m.errorTags.EventListener, m.constant.listener["ELP103"])
    m.top.ConfirmMyChoice = true
    if type(message) = "roSGNodeEvent"
        saveConsent(m.constant.info.preferenceCenterConfirm)
        onHidePreferencecenter(message)
    else
        m.top.onHidePreferencecenter = true
    end if
end function

function onVendorListConfirmChoices(message = {} as object) as void
    if m.vlView <> invalid and m.vlView.filterType <> invalid and m.vlView.filterType.vendorType <> invalid and m.vlView.filterType.vendorType <> ""
        msg = m.constant.listener["ELV103"]
        path = m.errortype.VendorList
        interactionType = m.constant.info.vendorListConfirm
        if m.vlView.filterType.vendorType = "sdk"
            msg = m.constant.listener["ELS103"]
            path = m.errortype.SDKList
            interactionType = m.constant.info.sdkListConfirm
        end if
    end if
    m.logger.set(m.errortype.Info + "." + path, m.errorTags.EventListener, msg)
    m.top.ConfirmMyChoice = true
    if type(message) = "roSGNodeEvent"
        if m.tempsdkListConsentStatus <> invalid and m.tempsdkListConsentStatus.count() > 0 then m.saveGroupqueue["sdk"] = m.tempsdkListConsentStatus
        saveConsent(interactionType)
        onHideVendorList(message)
    else
        m.top.onHidePreferencecenter = true
    end if
end function

function saveConsent(interactionType = "" as string)
    groups = m.saveGroupqueue
    vendorConsent = saveVendorConsent()
    groups.append(vendorConsent)
    saveGroupsToRegistry(groups)
    m.interactionType = interactionType
    m.action = "savePreference"
    setConsentString()
end function

function saveVendorConsent()
    regGroupData = getRegGroupData()
    culture = m.global._OT_initialize_data.culture
    vendorConsentModel = culture.DomainData["VendorConsentModel"]
    consent = {}
    defaultAcceptAll = optionalChaining(m.global._OT_IABVendor_data, "defaultAcceptAll")
    if defaultAcceptAll <> invalid and defaultAcceptAll["iab"] <> invalid
        consent["iab"] = {}
        vendortype = "iab"
        for each item in defaultAcceptAll["iab"].items()
            status = "active"
            id = item.key
            if Left(item.key, 2) <> "Li" and vendorConsentModel <> invalid and vendorConsentModel <> "opt-out"
                status = "inactive"
            end if
            if regGroupData[vendortype] <> invalid and regGroupData[vendortype].doesExist(id)
                status = regGroupData[vendortype][id]
            end if
            if m.saveGroupqueue[vendortype] <> invalid and m.saveGroupqueue[vendortype].doesExist(id)
                status = m.saveGroupqueue[vendortype][id]
            end if
            consent["iab"].AddReplace(item.key, status)
        end for
    end if
    if defaultAcceptAll <> invalid and defaultAcceptAll["google"] <> invalid
        consent["google"] = {}
        vendortype = "google"
        for each item in defaultAcceptAll["google"].items()
            status = "active"
            id = item.key
            if Left(item.key, 2) <> "Li" and vendorConsentModel <> invalid and vendorConsentModel <> "opt-out"
                status = "inactive"
            end if
            if regGroupData[vendortype] <> invalid and regGroupData[vendortype].doesExist(id)
                status = regGroupData[vendortype][id]
            end if
            if m.saveGroupqueue[vendortype] <> invalid and m.saveGroupqueue[vendortype].doesExist(id)
                status = m.saveGroupqueue[vendortype][id]
            end if
            consent["google"].AddReplace(item.key, status)
        end for
    end if
    return consent
end function

function checkInReg() as boolean
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    if sdkReg.Exists("isBannershowed")
        return true
    else
        return false
    end if
end function

function getBannerShownTime() as integer
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    bannerShownTime = 0
    if sdkReg.Exists("isBannershowed")
        bannerShownTime = sdkReg.Read("isBannershowed").ToInt()
    end if
    return bannerShownTime
end function

function showPreferenceCenterUI() as void
    if m.view = invalid
        m.logger.set(m.errortype.Warning, m.errorTags.OneTrust, m.constant.warning["904"])
        return
    else if m.global._OT_initialize_data = invalid
        m.global.observeFieldScoped("_OT_initialize_data", "showPreferenceCenterUI")
        return
    else if (havingIabvendor() and optionalChaining(m.global._OT_IABVendor_data, "iab") = invalid) or (havingGooglevendor() and optionalChaining(m.global._OT_IABVendor_data, "google") = invalid)
        m.global.observeFieldScoped("_OT_IABVendor_data", "showPreferenceCenterUI")
        return
    end if
    m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "showPreferenceCenterUI" + m.constant.info["705"])
    m.global.unObserveFieldScoped("_OT_IABVendor_data")
    m.pcView = createObject("roSGNode", "OTPreferenceCenter")
    m.pcView.observeField("onHidePreferenceCenter", "onHidePreferenceCenter")
    m.pcView.observeField("onShowPreferenceCenter", "onShowPreferenceCenter")
    m.pcView.observeField("onPreferenceCenterAcceptAll", "onPreferenceCenterAcceptAll")
    m.pcView.observeField("onPreferenceCenterRejectAll", "onPreferenceCenterRejectAll")
    m.pcView.observeField("onPreferenceCenterConfirmChoices", "onPreferenceCenterConfirmChoices")
    m.pcView.observeField("onPreferenceCenterPurposeLegitimateInterestChanged", "onPreferenceCenterPurposeLegitimateInterestChanged")
    m.pcView.observeField("onPreferenceCenterPurposeConsentChanged", "onPreferenceCenterPurposeConsentChanged")
    m.pcView.id = "OTPreferenceCenter"
    m.pcView.pcData = getPreferenceCenterData()
    m.pcView.observeField("hide", "closePreferenceCenter")
    m.view.appendChild(m.pcView)
    saveBannerShownRegistry()
end function

function onShowPreferenceCenter()
    m.onShowPreferenceCenter = true
    if m.top.onShowBanner
        m.logger.set(m.errortype.Info + "." + m.errortype.Banner, m.errorTags.EventListener, m.constant.listener["ELB103"])
    else
        m.logger.set(m.errortype.Info + "." + m.errortype.preferenceCenter, m.errorTags.EventListener, m.constant.listener["ELP100"])
    end if
end function

function showVendorListUI(message = {} as object) as void
    if m.view = invalid
        m.logger.set(m.errortype.Warning, m.errorTags.OneTrust, m.constant.warning["904"])
        return
    else if (havingIabvendor() and optionalChaining(m.global._OT_IABVendor_data, "iab") = invalid) or (havingGooglevendor() and optionalChaining(m.global._OT_IABVendor_data, "google") = invalid)
        m.global.observeFieldScoped("_OT_IABVendor_data", "showVendorListUI")
        return
    end if
    m.global.unObserveFieldScoped("_OT_IABVendor_data")
    m.vlView = createObject("roSGNode", "OTVendorList")
    m.vlView.observeField("onHidePreferenceCenter", "onHideVendorList")
    m.vlView.observeField("onShowVendorList", "onShowVendorList")
    m.vlView.observeField("onPreferenceCenterAcceptAll", "onVendorListAcceptAll")
    m.vlView.observeField("onPreferenceCenterRejectAll", "onVendorListRejectAll")
    m.vlView.observeField("onPreferenceCenterConfirmChoices", "onVendorListConfirmChoices")
    'm.vlView.observeField("onPreferenceCenterPurposeLegitimateInterestChanged","onPreferenceCenterPurposeLegitimateInterestChanged")
    'm.vlView.observeField("onPreferenceCenterPurposeConsentChanged","onPreferenceCenterPurposeConsentChanged")
    m.vlView.id = "OTVendorList"
    m.vlView.filterType = { vendorType: "iab" }
    if type(message) = "roAssociativeArray" then m.vlView.filterType = message
    m.vlView.view = m.view
    m.vlView.pcData = getVendorPageData(message)
    m.vlView.observeField("hide", "closePreferenceCenter")
    'm.view.appendChild(m.vlView)
    saveBannerShownRegistry()
end function

function onShowVendorList()
    if m.top.onShowBanner and not m.onShowPreferenceCenter
        m.logger.set(m.errortype.Info + "." + m.errortype.Banner, m.errorTags.EventListener, m.constant.listener["ELB104"])
    else
        if m.vlView.filterType <> invalid and m.vlView.filterType.vendorType <> invalid and m.vlView.filterType.vendorType <> ""
            msg = m.constant.listener["ELP106"]
            if m.vlView.filterType.vendorType = "sdk"
                msg = m.constant.listener["ELP109"]
            end if
        end if
        m.logger.set(m.errortype.Info + "." + m.errortype.preferenceCenter, m.errorTags.EventListener, msg)
    end if
end function

function getPreferenceCenterData() as object
    sdkData = m.global._OT_initialize_data
    pcData = {}
    if sdkData = invalid or sdkData.keys().count() = 0
        return pcData
    end if
    DomainData = optionalChaining(sdkData, "culture.DomainData")
    'CommonData = optionalChaining(sdkData, "culture.CommonData")
    'OTTData = optionalChaining(sdkData, "culture.OTTData")
    MobileData = optionalChaining(sdkData, "culture.MobileData")
    pcData.logo = sdkData.culture.MobileData.preferenceCenterData.logo
    pcData.MainText = sdkData.culture.DomainData.MainText
    pcData.MainInfoText = sdkData.culture.DomainData.MainInfoText
    pcData.PreferenceCenterConfirmText = sdkData.culture.DomainData.PreferenceCenterConfirmText
    pcData.ConfirmText = sdkData.culture.DomainData.ConfirmText
    pcData.PCenterShowRejectAllButton = sdkData.culture.DomainData.PCenterShowRejectAllButton
    pcData.PCenterRejectAllButtonText = sdkData.culture.DomainData.PCenterRejectAllButtonText
    styledata = getPCStyleData()
    pcData.styleData = styledata
    pcData.VendorListText = sdkData.culture.DomainData.VendorListText
    pcData.PCIABVendorsText = sdkData.culture.DomainData.PCIABVendorsText
    pcData.BannerIABPartnersLink = sdkData.culture.DomainData.BannerIABPartnersLink
    pcData.ShowPreferenceCenterCloseButton = sdkData.culture.DomainData.ShowPreferenceCenterCloseButton
    if not optionalChaining(sdkData, "culture.MobileData.preferenceCenterData.purposeListItem.alwaysActiveLabelTextShow") <> invalid
        pcData.AlwaysActiveText = sdkData.culture.DomainData.AlwaysActiveText
    else
        pcData.AlwaysActiveText = sdkData.culture.MobileData.preferenceCenterData.purposeListItem.alwaysActiveLabelText
    end if
    pcData.BLegitInterestText = sdkData.culture.CommonData.BLegitInterestText
    pcData.Groups = getValidGroup()
    pcData.isIAB = isIAB2()
    pcData.LegIntSettings = getLegIntSettings()
    if isIAB2()
        pcData.BConsentText = sdkData.culture.CommonData.BConsentText
    else
        pcData.BConsentText = ternaryOperator(sdkData.culture.OTTData.preferenceCenterData.purposeList.InteractionChoiceText <> invalid and sdkData.culture.OTTData.preferenceCenterData.purposeList.InteractionChoiceText <> "", sdkData.culture.OTTData.preferenceCenterData.purposeList.InteractionChoiceText, sdkData.culture.CommonData.BConsentText)
    end if
    pcData.activeText = sdkData.culture.OTTData.preferenceCenterData.purposeList.ActiveText
    pcData.inactiveText = sdkData.culture.OTTData.preferenceCenterData.purposeList.InactiveText
    pcData.subCategoryHeaderText = sdkData.culture.OTTData.preferenceCenterData.purposeList.SubCategoryHeaderText
    pcData.MenuVendorListText = sdkData.culture.MobileData.preferenceCenterData.purposeDetails.links.vendorListText
    pcData.sdkListText = sdkData.culture.MobileData.preferenceCenterData.purposeDetails.links.sdkListText
    pcData.ShowCookieList = sdkData.culture.CommonData.ShowCookieList
    pcData.PCGoogleVendorsText = sdkData.culture.MobileData.preferenceCenterData.googleVendors.general.text
    pcData.UseGoogleVendors = sdkData.culture.MobileData.preferenceCenterData.googleVendors.general.show
    pcData.buttons = sdkData.culture.MobileData.preferenceCenterData.buttons
    pcData.policyLink = sdkData.culture.MobileData.preferenceCenterData.links.policyLink
    pcData.showLogo = false
    pcData.summary = sdkData.culture.MobileData.preferenceCenterData.summary
    fullLegalText = optionalChaining(MobileData, "preferenceCenterData.purposeDetails.links.fullLegalText")
    pcData.fullLegalText = ternaryOperator(fullLegalText <> invalid and fullLegalText <> "", fullLegalText, optionalChaining(DomainData, "PCVendorFullLegalText"))
    pcData.PCIllusText = optionalChaining(DomainData, "PCIllusText")
    pcData.IabLegalTextUrl = sdkData.culture.CommonData.IabLegalTextUrl
    pcData.PCGrpDescType = optionalChaining(DomainData, "PCGrpDescType")
    pcData.PCVendorsCountText = optionalChaining(DomainData, "PCVendorsCountText")
    if m.preferenceCenterLogoSize <> invalid
        pcData.logoSize = m.preferenceCenterLogoSize
    end if
    return pcData
end function

function getVendorPageData(message)
    sdkData = m.global._OT_initialize_data
    vendorPage = {}
    if sdkData = invalid or sdkData.keys().count() = 0
        return vendorPage
    end if
    domainData = optionalChaining(sdkData, "culture.DomainData")
    commonData = optionalChaining(sdkData, "culture.CommonData")
    OTTData = optionalChaining(sdkData, "culture.OTTData")
    MobileData = optionalChaining(sdkData, "culture.MobileData")
    vendorPage.OptanonLogo = commonData.OptanonLogo
    vendorPage.styleData = getPCStyleData()
    vendorPage.LegIntSettings = getLegIntSettings()
    vendorPage.PCenterVendorsListText = domainData.PCenterVendorsListText
    vendorPage.PCenterViewPrivacyPolicyText = domainData.PCenterViewPrivacyPolicyText
    vendorPage.PCenterAllowAllConsentText = domainData.PCenterAllowAllConsentText
    vendorPage.VendorListNonCookieUsage = domainData.PCenterVendorListNonCookieUsage
    vendorPage.VendorListLifespan = domainData.PCenterVendorListLifespan
    vendorPage.LifespanTypeText = domainData.LifespanTypeText
    vendorPage.VendorListLifespanDay = domainData.PCenterVendorListLifespanDay
    vendorPage.VendorListLifespanDays = domainData.PCenterVendorListLifespanDays
    vendorPage.VendorListLifespanMonth = domainData.PCenterVendorListLifespanMonth
    vendorPage.VendorListLifespanMonths = domainData.PCenterVendorListLifespanMonths
    vendorPage.ConsentPurposesText = commonData.BConsentPurposesText
    vendorPage.SpecialPurposesText = commonData.BSpecialPurposesText
    vendorPage.LIPurposesText = commonData.BLegitimateInterestPurposesText
    vendorPage.FeaturesText = commonData.BFeaturesText
    vendorPage.SpecialFeaturesText = commonData.BSpecialFeaturesText
    vendorPage.BConsentText = commonData.BConsentText
    vendorPage.BLegitInterestText = commonData.BLegitInterestText
    vendorPage.VendorListDisclosure = domainData.PCenterVendorListDisclosure
    vendorPage.VendorListStorageIdentifier = domainData.PCenterVendorListStorageIdentifier
    vendorPage.VendorListStorageType = domainData.PCenterVendorListStorageType
    vendorPage.VendorListStorageDomain = domainData.PCenterVendorListStorageDomain
    vendorPage.VendorTitleDomainUsed = domainData.PCVLSDomainsUsed
    vendorPage.VendorDomainUsed = domainData.PCVLSUse
    vendorPage.VendorListStoragePurposes = domainData.PCenterVendorListStoragePurposes
    'vendorPage.PreferenceCenterConfirmText = domainData.PreferenceCenterConfirmText;
    'vendorPage.ConfirmText = domainData.ConfirmText;
    'vendorPage.PCenterShowRejectAllButton = domainData.PCenterShowRejectAllButton;
    'vendorPage.PCenterRejectAllButtonText = domainData.PCenterRejectAllButtonText;
    vendorPage.PCenterClearFiltersText = domainData.PCenterClearFiltersText
    vendorPage.PCenterApplyFiltersText = domainData.PCenterApplyFiltersText
    'vendorPage.showFilter = false;
    vendorPage.activeText = OTTData.preferenceCenterData.purposeList.ActiveText
    vendorPage.inactiveText = OTTData.preferenceCenterData.purposeList.InactiveText
    vendorPage.searchNoResultsFoundText = OTTData.vendorListData.general.searchNoResultsFoundText
    vendorPage.iabGroups = getIabGroups(domainData.Groups)
    vendorPage.Groups = getValidGroup()
    vendorPage.initGroups = m.initGroups
    vendorPage.PCGoogleVendorsText = domainData.PCGoogleVendorsText
    vendorPage.buttons = MobileData.preferenceCenterData.buttons
    vendorPage.sdkLevelOptOutShow = MobileData.preferenceCenterData.general.sdkLevelOptOutShow
    vendorPage.AlwaysActiveText = domainData.AlwaysActiveText
    vendorPage.isIAB = isIAB2()
    vendorPage.PCIABVendorsText = sdkData.culture.DomainData.PCIABVendorsText
    vendorPage.PCGoogleVendorsText = sdkData.culture.MobileData.preferenceCenterData.googleVendors.general.text
    vendorPage.sdkListText = sdkData.culture.MobileData.preferenceCenterData.purposeDetails.links.sdkListText
    vendorPage.ShowCookieList = sdkData.culture.CommonData.ShowCookieList
    vendorPage.showLogo = false
    vendorPage.vendorData = m.global._OT_IABVendor_data
    vendorPage.showFilterIcon = OTTData.vendorListData.general.showFilterIcon
    vendorPage.logo = optionalChaining(MobileData, "preferenceCenterData.logo")
    vendorPage.PCVListDataDeclarationText = optionalChaining(domainData, "PCVListDataDeclarationText")
    vendorPage.PCVListDataRetentionText = optionalChaining(domainData, "PCVListDataRetentionText")
    vendorPage.PCVListStdRetentionText = optionalChaining(domainData, "PCVListStdRetentionText")
    vendorPage.PCIABVendorLegIntClaimText = optionalChaining(domainData, "PCIABVendorLegIntClaimText")
    vendorPage.language = optionalChaining(domainData, "Language.Culture")
    vendorPage.IABDataCategories = optionalChaining(domainData, "IABDataCategories")
    if type(message) = "roAssociativeArray" and message.vendorType = "sdk"
        vendorPage.vendorData = getSdkListData(vendorPage.Groups, vendorPage)
    end if
    return vendorPage
end function

function getSdkListData(groups, data)
    sdkListData = data.vendorData
    sdkListData["sdk"] = { "filteredVendorRecords": {}, "sortedVendorRecords": [], "sortedNodeVendorRecords": {} }
    for each item in groups
        if data.ShowCookieList <> invalid and data.ShowCookieList and item.ShowSDKListLink <> invalid and item.ShowSDKListLink and item.FirstPartyCookies <> invalid and item.FirstPartyCookies.count() > 0
            fCount = item.FirstPartyCookies.count() - 1
            for i = 0 to fCount
                subItem = ParseJson(FormatJson(item.FirstPartyCookies[i]))
                subItem["id"] = subItem.SdkId
                subItem.Append(ParseJson(FormatJson(item)))
                sdkListData["sdk"]["sortedVendorRecords"].push(subItem)
                sdkListData["sdk"]["filteredVendorRecords"].AddReplace(subItem["id"], subItem)
                sdkListData["sdk"]["sortedNodeVendorRecords"].AddReplace(subItem["id"], CreateObject("roSGNode", "OTGroupListData"))
            end for
        end if
    end for
    sdkListData["sdk"]["sortedVendorRecords"].sortby("Name", "i")
    m.global._OT_IABVendor_data = sdkListData
    return sdkListData
end function

function getBannerData() as object
    sdkData = m.global._OT_initialize_data
    OTTData = sdkData.culture.OTTData
    bannerData = {}
    if sdkData = invalid or sdkData.keys().count() = 0
        return bannerData
    end if
    domainData = sdkData.culture.DomainData
    mobileData = sdkData.culture.MobileData
    bannerData.logo = mobileData.bannerData.logo
    bannerData.ShowBannerAcceptButton = sdkData.culture.CommonData.ShowBannerAcceptButton
    bannerData.AlertAllowCookiesText = domainData.AlertAllowCookiesText
    bannerData.BannerShowRejectAllButton = domainData.BannerShowRejectAllButton
    bannerData.BannerRejectAllButtonText = domainData.BannerRejectAllButtonText
    bannerData.ShowBannerCookieSettings = sdkData.culture.CommonData.ShowBannerCookieSettings
    bannerData.AlertMoreInfoText = domainData.AlertMoreInfoText
    styledata = getBannerStyleData()
    bannerData.styleData = styledata
    bannerData.BannerIABPartnersLink = domainData.BannerIABPartnersLink
    bannerData.showBannerCloseButton = domainData.showBannerCloseButton
    bannerData.BannerAdditionalDescPlacement = domainData.BannerAdditionalDescPlacement
    bannerData.BannerSettingsButtonDisplayLink = domainData.BannerSettingsButtonDisplayLink
    bannerData.policyLink = mobileData.bannerData.links.policyLink
    bannerData.isIAB = isIAB2()
    bannerData.closeButton = mobileData.bannerData.buttons.closeButton
    bannerData.summary = mobileData.bannerData.summary
    bannerData.layout = OTTData.bannerData.general.layout
    if m.bannerLogoSize <> invalid
        bannerData.logoSize = m.bannerLogoSize
    end if
    return bannerData
end function

function getBannerStyleData() as object
    sdkData = m.global._OT_initialize_data
    commonData = sdkData.culture.CommonData
    OTTData = sdkData.culture.OTTData
    OTTbuttons = OTTData.bannerData.buttons
    styleData = {
        "textColor": "",
        "buttonColor": "",
        "backgroundColor": "",
        "acceptbuttonColor": "",
        "acceptbuttonTextColor": "",
        "acceptbuttonFocusColor": "",
        "acceptbuttonTextFocusColor": "",
        "rejectbuttonColor": "",
        "rejectbuttonTextColor": "",
        "rejectbuttonFocusColor": "",
        "rejectbuttonTextFocusColor": "",
        "pcbuttonColor": "",
        "pcbuttonTextColor": "",
        "pcbuttonFocusColor": "",
        "pcbuttonTextFocusColor": "",
        "customCSS": commonData.BannerCustomCSS,
        "vendorLinkColor": "",
    }

    styleData.textColor = ternaryOperator(OTTData <> invalid and OTTData.bannerData <> invalid and OTTData.bannerData.general <> invalid and OTTData.bannerData.general.textColor <> invalid and OTTData.bannerData.general.textColor <> "", OTTData.bannerData.general.textColor, commonData.TextColor)
    styleData.buttonColor = commonData.ButtonColor
    styleData.backgroundColor = ternaryOperator(OTTData <> invalid and OTTData.bannerData <> invalid and OTTData.bannerData.general <> invalid and OTTData.bannerData.general.backgroundColor <> invalid and OTTData.bannerData.general.backgroundColor <> "", OTTData.bannerData.general.backgroundColor, commonData.BackgroundColor)
    styleData.acceptbuttonColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.acceptAll <> invalid and OTTbuttons.acceptAll.color <> invalid and OTTbuttons.acceptAll.color <> "", OTTbuttons.acceptAll.color, commonData.ButtonColor)
    styleData.acceptbuttonTextColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.acceptAll <> invalid and OTTbuttons.acceptAll.textColor <> invalid and OTTbuttons.acceptAll.textColor <> "", OTTbuttons.acceptAll.textColor, commonData.ButtonTextColor)
    styleData.acceptbuttonFocusColor = ternaryOperator(OTTData <> invalid and OTTData.bannerData <> invalid and OTTData.bannerData.general <> invalid and OTTData.bannerData.general.buttonFocusColor <> invalid and OTTData.bannerData.general.buttonFocusColor <> "", OTTData.bannerData.general.buttonFocusColor, commonData.ButtonColor)
    styleData.acceptbuttonTextFocusColor = ternaryOperator(OTTData <> invalid and OTTData.bannerData <> invalid and OTTData.bannerData.general <> invalid and OTTData.bannerData.general.buttonFocusTextColor <> invalid and OTTData.bannerData.general.buttonFocusTextColor <> "", OTTData.bannerData.general.buttonFocusTextColor, commonData.ButtonTextColor)
    styleData.rejectbuttonColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.rejectAll <> invalid and OTTbuttons.rejectAll.color <> invalid and OTTbuttons.rejectAll.color <> "", OTTbuttons.rejectAll.color, commonData.ButtonColor)
    styleData.rejectbuttonTextColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.rejectAll <> invalid and OTTbuttons.rejectAll.textColor <> invalid and OTTbuttons.rejectAll.textColor <> "", OTTbuttons.rejectAll.textColor, commonData.ButtonTextColor)
    styleData.rejectbuttonFocusColor = ternaryOperator(OTTData <> invalid and OTTData.bannerData <> invalid and OTTData.bannerData.general <> invalid and OTTData.bannerData.general.buttonFocusColor <> invalid and OTTData.bannerData.general.buttonFocusColor <> "", OTTData.bannerData.general.buttonFocusColor, commonData.ButtonColor)
    styleData.rejectbuttonTextFocusColor = ternaryOperator(OTTData <> invalid and OTTData.bannerData <> invalid and OTTData.bannerData.general <> invalid and OTTData.bannerData.general.buttonFocusTextColor <> invalid and OTTData.bannerData.general.buttonFocusTextColor <> "", OTTData.bannerData.general.buttonFocusTextColor, commonData.ButtonTextColor)
    styleData.pcbuttonColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.showPreferences <> invalid and OTTbuttons.showPreferences.color <> invalid and OTTbuttons.showPreferences.color <> "", OTTbuttons.showPreferences.color, commonData.BannerMPButtonColor)
    styleData.pcbuttonTextColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.showPreferences <> invalid and OTTbuttons.showPreferences.textColor <> invalid and OTTbuttons.showPreferences.textColor <> "", OTTbuttons.showPreferences.textColor, commonData.BannerMPButtonTextColor)
    styleData.pcbuttonFocusColor = ternaryOperator(OTTData <> invalid and OTTData.bannerData <> invalid and OTTData.bannerData.general <> invalid and OTTData.bannerData.general.buttonFocusColor <> invalid and OTTData.bannerData.general.buttonFocusColor <> "", OTTData.bannerData.general.buttonFocusColor, commonData.BannerMPButtonTextColor)
    styleData.pcbuttonTextFocusColor = ternaryOperator(OTTData <> invalid and OTTData.bannerData <> invalid and OTTData.bannerData.general <> invalid and OTTData.bannerData.general.buttonFocusTextColor <> invalid and OTTData.bannerData.general.buttonFocusTextColor <> "", OTTData.bannerData.general.buttonFocusTextColor, commonData.BannerMPButtonColor)
    styleData.vendorbuttonColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.vendorList <> invalid and OTTbuttons.vendorList.color <> invalid and OTTbuttons.vendorList.color <> "", OTTbuttons.vendorList.color, commonData.BannerMPButtonColor)
    styleData.vendorbuttonTextColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.vendorList <> invalid and OTTbuttons.vendorList.textColor <> invalid and OTTbuttons.vendorList.textColor <> "", OTTbuttons.vendorList.textColor, commonData.BannerMPButtonTextColor)
    return styleData
end function

function getPCStyleData()
    sdkData = m.global._OT_initialize_data
    commonData = sdkData.culture.CommonData
    OTTData = sdkData.culture.OTTData
    OTTpcdata = OTTData.preferenceCenterData
    OTTbuttons = OTTpcdata.buttons
    styleData = {
        "textColor": "",
        "backgroundColor": "",
        "buttonColor": "",
        "buttonTextColor": "",
        "buttonFocusColor": "",
        "buttonTextFocusColor": "",
        "activeColor": "",
        "activeTextColor": "",
        "acceptbuttonColor": "",
        "acceptbuttonTextColor": "",
        "acceptbuttonFocusColor": "",
        "acceptbuttonTextFocusColor": "",
        "rejectbuttonColor": "",
        "rejectbuttonTextColor": "",
        "rejectbuttonFocusColor": "",
        "rejectbuttonTextFocusColor": "",
        "pcbuttonColor": "",
        "pcbuttonTextColor": "",
        "pcbuttonFocusColor": "",
        "pcbuttonTextFocusColor": "",
        "customCSS": commonData.PCCustomCSS
    }
    styleData.textColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.general <> invalid and OTTpcdata.general.textColor <> invalid and OTTpcdata.general.textColor <> "", OTTpcdata.general.textColor, commonData.PcTextColor)
    styleData.backgroundColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.general <> invalid and OTTpcdata.general.backgroundColor <> invalid and OTTpcdata.general.backgroundColor <> "", OTTpcdata.general.backgroundColor, commonData.PcBackgroundColor)
    styleData.buttonColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.menu <> invalid and OTTpcdata.menu.color <> invalid and OTTpcdata.menu.color <> "", OTTpcdata.menu.color, commonData.PcTextColor)
    styleData.buttonTextColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.menu <> invalid and OTTpcdata.menu.textColor <> invalid and OTTpcdata.menu.textColor <> "", OTTpcdata.menu.textColor, commonData.PcBackgroundColor)
    styleData.buttonFocusColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.menu <> invalid and OTTpcdata.menu.focusColor <> invalid and OTTpcdata.menu.focusColor <> "", OTTpcdata.menu.focusColor, commonData.PcButtonColor)
    styleData.buttonTextFocusColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.menu <> invalid and OTTpcdata.menu.focusTextColor <> invalid and OTTpcdata.menu.focusTextColor <> "", OTTpcdata.menu.focusTextColor, commonData.PcButtonTextColor)
    styleData.activeColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.menu <> invalid and OTTpcdata.menu.activeColor <> invalid and OTTpcdata.menu.activeColor <> "", OTTpcdata.menu.activeColor, commonData.PcButtonTextColor)
    styleData.activeTextColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.menu <> invalid and OTTpcdata.menu.activeTextColor <> invalid and OTTpcdata.menu.activeTextColor <> "", OTTpcdata.menu.activeTextColor, commonData.PcButtonColor)
    styleData.acceptbuttonColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.acceptAll <> invalid and OTTbuttons.acceptAll.color <> invalid and OTTbuttons.acceptAll.color <> "", OTTbuttons.acceptAll.color, commonData.PcButtonColor)
    styleData.acceptbuttonTextColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.acceptAll <> invalid and OTTbuttons.acceptAll.textColor <> invalid and OTTbuttons.acceptAll.textColor <> "", OTTbuttons.acceptAll.textColor, commonData.PcButtonTextColor)
    styleData.acceptbuttonFocusColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.general <> invalid and OTTpcdata.general.buttonFocusColor <> invalid and OTTpcdata.general.buttonFocusColor <> "", OTTpcdata.general.buttonFocusColor, commonData.PcButtonColor)
    styleData.acceptbuttonTextFocusColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.general <> invalid and OTTpcdata.general.buttonFocusTextColor <> invalid and OTTpcdata.general.buttonFocusTextColor <> "", OTTpcdata.general.buttonFocusTextColor, commonData.PcButtonTextColor)
    styleData.rejectbuttonColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.rejectAll <> invalid and OTTbuttons.rejectAll.color <> invalid and OTTbuttons.rejectAll.color <> "", OTTbuttons.rejectAll.color, commonData.PcButtonColor)
    styleData.rejectbuttonTextColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.rejectAll <> invalid and OTTbuttons.rejectAll.textColor <> invalid and OTTbuttons.rejectAll.textColor <> "", OTTbuttons.rejectAll.textColor, commonData.PcButtonTextColor)
    styleData.rejectbuttonFocusColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.general <> invalid and OTTpcdata.general.buttonFocusColor <> invalid and OTTpcdata.general.buttonFocusColor <> "", OTTpcdata.general.buttonFocusColor, commonData.PcButtonColor)
    styleData.rejectbuttonTextFocusColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.general <> invalid and OTTpcdata.general.buttonFocusTextColor <> invalid and OTTpcdata.general.buttonFocusTextColor <> "", OTTpcdata.general.buttonFocusTextColor, commonData.PcButtonTextColor)
    styleData.pcbuttonColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.showPreferences <> invalid and OTTbuttons.showPreferences.color <> invalid and OTTbuttons.showPreferences.color <> "", OTTbuttons.showPreferences.color, commonData.PcButtonColor)
    styleData.pcbuttonTextColor = ternaryOperator(OTTbuttons <> invalid and OTTbuttons.showPreferences <> invalid and OTTbuttons.showPreferences.textColor <> invalid and OTTbuttons.showPreferences.textColor <> "", OTTbuttons.showPreferences.textColor, commonData.PcButtonTextColor)
    styleData.pcbuttonFocusColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.general <> invalid and OTTpcdata.general.buttonFocusColor <> invalid and OTTpcdata.general.buttonFocusColor <> "", OTTpcdata.general.buttonFocusColor, commonData.PcButtonColor)
    styleData.pcbuttonTextFocusColor = ternaryOperator(OTTpcdata <> invalid and OTTpcdata.general <> invalid and OTTpcdata.general.buttonFocusTextColor <> invalid and OTTpcdata.general.buttonFocusTextColor <> "", OTTpcdata.general.buttonFocusTextColor, commonData.PcButtonTextColor)
    return styleData
end function

function ternaryOperator(conditon, trueValue, falseValue)
    if conditon
        return trueValue
    else
        return falseValue
    end if
end function

function getPurposesList()
    validGroups = getValidGroup()
    return validGroups
end function
function getValidGroup(id = "" as string, update = false as boolean) as object
    sdkData = m.global._OT_initialize_data
    groups = sdkData.culture.DomainData.Groups
    havingIAB2 = isIAB2()
    regGroupData = getRegGroupData()
    gpValid = []
    if not (m.groups <> invalid and m.groups.count() > 0) or update
        parentGroups = {}
        m.iabPurposeList = []
        sdkConsentGroup = {}
        for each gd in groups
            flag = false
            item = {}
            if gd.HasConsentOptOut or gd.HasLegIntOptOut or gd.Status = "always active"
                if havingIAB2 and gd.IsIabPurpose and gd.ShowInPopup
                    item = gd
                    if item.Parent <> "" then flag = true
                else
                    item = gd
                    if item.Parent <> "" and gd.FirstPartyCookies <> invalid and gd.FirstPartyCookies.count() > 0 then flag = true
                end if
                if item.count() > 0 and item.Parent = ""
                    if item.IsIabPurpose
                        flag = item.ShowInPopup
                    else
                        flag = item.FirstPartyCookies <> invalid and item.FirstPartyCookies.count() > 0
                        if item.FirstPartyCookies <> invalid and item.FirstPartyCookies.count() = 0
                            gCount = groups.count() - 1
                            for i = 0 to gCount
                                subItem = groups[i]
                                if subItem["Parent"] = item.OptanonGroupId and ((subItem.FirstPartyCookies <> invalid and subItem.FirstPartyCookies.count() > 0) or (subItem.IsIabPurpose and subItem.ShowInPopup))
                                    flag = true
                                end if
                            end for
                        end if
                    end if
                end if
            end if

            if flag
                if gd.Status <> "always active"
                    if regGroupData.doesExist(gd.CustomGroupId)
                        gd.status = regGroupData[gd.CustomGroupId]
                    end if
                    if m.saveGroupqueue.doesExist(gd.CustomGroupId)
                        gd.status = m.saveGroupqueue[gd.CustomGroupId]
                    end if
                    if regGroupData.doesExist("Li_" + gd.CustomGroupId)
                        gd.li_status = regGroupData["Li_" + gd.CustomGroupId]
                    end if
                    if m.saveGroupqueue.doesExist("Li_" + gd.CustomGroupId)
                        gd.li_status = m.saveGroupqueue["Li_" + gd.CustomGroupId]
                    end if
                    if item.Parent <> ""
                        if parentGroups[item.Parent] = invalid then parentGroups[item.Parent] = {}
                        parentGroups[item.Parent][gd.CustomGroupId] = gd.status
                    end if
                else
                    m.saveGroupqueue.AddReplace(gd.CustomGroupId, gd.status)
                end if
                if gd.IsIabPurpose then m.iabPurposeList.push(gd.CustomGroupId)
                m.initGroups[gd.CustomGroupId] = ParseJson(FormatJson(gd))
                gpValid.push(gd)
                m.initGroups[gd.CustomGroupId]["index"] = gpValid.count() - 1
                if gd.HasConsentOptOut = true
                    m.saveGroupqueue.AddReplace(gd.CustomGroupId, gd.status)
                end if
                if isLegitimateInterest(gd, getLegIntSettings())
                    li_status = "active"
                    if gd.li_status <> invalid then li_status = gd.li_status
                    m.saveGroupqueue.AddReplace("Li_" + gd.CustomGroupId, li_status)
                end if
                fpCookies = gd.FirstPartyCookies
                if fpCookies <> invalid and fpCookies.count() > 0
                    fCount = fpCookies.count() - 1
                    for i = 0 to fCount
                        sdkConsentGroup.AddReplace(fpCookies[i].SdkId, gd.OptanonGroupId)
                    end for
                end if
            end if
        end for
        parentIds = parentGroups.keys()
        if parentIds <> invalid and parentGroups <> invalid and parentIds.count() > 0
            for each parentID in parentGroups
                parentStatus = "active"
                childStatus = parentGroups[parentID].Items()
                for cStatus = 0 to childStatus.count() - 1
                    substatus = childStatus[cStatus].value
                    if substatus <> "always active" and substatus <> "active"
                        parentStatus = "inactive"
                        exit for
                    end if
                end for
                if parentID <> invalid and optionalChaining(m.initGroups, parentID.tostr() + ".status") <> parentStatus
                    m.initGroups[parentID].status = parentStatus
                    m.saveGroupqueue.AddReplace(parentID, parentStatus)
                    gpValid[m.initGroups[parentID].index].status = parentStatus
                end if
            end for
        end if
        m.registry.write("sdkConsentGroup", FormatJson(sdkConsentGroup))
        m.groups = gpValid
    else
        gpValid = []
        for each gd in m.groups
            if gd.Status <> "always active"
                if regGroupData.doesExist(gd.CustomGroupId)
                    gd.status = regGroupData[gd.CustomGroupId]
                end if
                if m.saveGroupqueue.doesExist(gd.CustomGroupId)
                    gd.status = m.saveGroupqueue[gd.CustomGroupId]
                end if
                if regGroupData.doesExist("Li_" + gd.CustomGroupId)
                    gd.li_status = regGroupData["Li_" + gd.CustomGroupId]
                end if
                if m.saveGroupqueue.doesExist("Li_" + gd.CustomGroupId)
                    gd.li_status = m.saveGroupqueue["Li_" + gd.CustomGroupId]
                end if
            end if
            m.initGroups[gd.CustomGroupId] = ParseJson(FormatJson(gd))
            gpValid.push(gd)
        end for
        m.groups = gpValid
    end if
    if id = ""
        return m.groups
    else
        return m.initGroups[id]
    end if
end function

function syncProfileToLocal()
    sdkData = m.global._OT_initialize_data
    profileSync = sdkData.profile.sync
    profilefetch = optionalChaining(sdkData, "profile.fetch")
    SyncGroupId = optionalChaining(sdkData, "domain.SyncGroupId")
    syncPreferences = profileSync.preferences
    consentData = {}
    for each syncPrefData in syncPreferences
        if syncPrefData.status <> "ALWAYS_ACTIVE" and syncPrefData.status <> "NO_CONSENT"
            groupId = getGroupId(syncPrefData.id)
            status = getValidStatus(syncPrefData.status)
            consentData.AddReplace(groupId, status)
        end if
    end for
    if profileSync.doesExist("parentToggleState")
        parentToggleState = profileSync.parentToggleState
        parentkeys = parentToggleState.keys()
        for each pKey in parentkeys
            if parentToggleState[pKey] <> "ALWAYS_ACTIVE" and parentToggleState[pKey] <> "NO_CONSENT"
                groupId = getGroupId(pKey)
                status = getValidStatus(parentToggleState[pKey])
                consentData.AddReplace(groupId, status)
            end if
        end for
    end if
    if profilefetch <> invalid and SyncGroupId <> invalid and optionalChaining(profilefetch, "syncGroups." + SyncGroupId.tostr() + ".tcStringV2Decoded") <> invalid
        tcStringV2Decoded = profilefetch.syncGroups[SyncGroupId].tcStringV2Decoded
        tcStringV2Decoded["code"] = 200
        saveToIABRegistry(tcStringV2Decoded)
    end if

    saveGroupsToRegistry(consentData)
end function

function getGroupId(value as string) as string
    v = UCase(value)
    sdkData = m.global._OT_initialize_data
    groups = sdkData.culture.DomainData.Groups
    for each group in groups
        if group.PurposeId = v or group.OptanonGroupId = v
            return group.CustomGroupId
        end if
    end for
    return ""
end function

function getValidStatus(status as string) as string
    if status = "ACTIVE"
        return "active"
    else
        return "inactive"
    end if
end function

function isParentGroup(groupId as string) as boolean
    sdkData = m.global._OT_initialize_data
    groups = sdkData.culture.DomainData.Groups
    for each gd in groups
        if gd.Parent <> invalid and gd.Parent = groupId
            return true
        end if
    end for
    return false
end function

function isConsentEnabled() as boolean
    sdkData = m.global._OT_initialize_data
    return sdkData.culture.DomainData.IsConsentLoggingEnabled
end function

function getConsentPayload(action as string, interactionType = "" as string) as object
    sdkData = m.global._OT_initialize_data
    culture = sdkData.culture
    domain = sdkData.domain
    consentIntegration = culture.CommonData.ConsentIntegration
    consentData = {}
    groupData = getValidGroup()
    purposes = []
    consentGroups = {}
    if groupData <> invalid and groupData.count() > 0
        for each gd in groupData
            if gd.status = "always active"
                transactionType = "NO_CHOICE"
            else
                if action = "acceptAll"
                    consentGroups.AddReplace(gd.OptanonGroupId, 1)
                    transactionType = "CONFIRMED"
                else if action = "rejectAll"
                    transactionType = "OPT_OUT"
                else if action = "close"
                    if gd.status = "active"
                        transactionType = "CONFIRMED"
                    else
                        transactionType = "NOTGIVEN"
                    end if
                else if action = "savePreference"
                    if gd.status = "active"
                        transactionType = "CONFIRMED"
                    else
                        transactionType = "OPT_OUT"
                    end if
                end if
            end if
            if gd.PurposeId <> ""
                purposeData = {}
                purposeData.AddReplace("Id", gd.PurposeId)
                purposeData.AddReplace("TransactionType", transactionType)
                purposes.push(purposeData)
            end if
        end for
    end if
    if consentIntegration <> invalid and consentIntegration.keys().count() > 0
        consentData.AddReplace("identifier", getSubjectIdentifier())
        consentData.AddReplace("identifierType", getIdentifierType())
        consentData.AddReplace("isAnonymous", checkIsAnonymous())
        consentData.AddReplace("test", isTestApp())
        if domain <> invalid and domain.SyncGroupId <> invalid
            consentData.AddReplace("syncGroup", domain.SyncGroupId)
        end if
        if m.global.IABTCF_TCString <> invalid and m.global.IABTCF_TCString <> "" then consentData.AddReplace("tcStringV2", m.global.IABTCF_TCString)
        if isGppEnabled() then consentData.AddReplace("tcStringV2", m.registry.read("IABGPP_2_String"))
        consentData.AddReplace("customPayload", { Interaction: 1, AddDefaultInteraction: true })
        consentData.AddReplace("dsDataElements", analytics(culture.DomainData.AdvancedAnalyticsCategory, domain.countryCode, interactionType))
        if consentIntegration.RequestInformation <> invalid
            consentData.AddReplace("requestInformation", consentIntegration.RequestInformation)
        end if
        consentData.AddReplace("purposes", purposes)
    end if
    return consentData
end function

function analytics(category as string, code as string, InteractionType as string)
    if category <> invalid and category.trim() <> ""
        'di=createobject("roDeviceInfo")
        'version=di.GetOSVersion()
        'version_major=version.major
        'version_minor=version.minor
        'version_build=version.build
        'userAgent="Roku/DVP-"+version_major+"."+version_minor+" ("+version_build+")"
        return {
            '   "UserAgent": userAgent,
            "Country": code,
            "InteractionType": InteractionType,
        }
    else
        return {}
    end if
end function

function logConsent(payload as object, consentAction as string) as void
    sdkData = m.global._OT_initialize_data
    consentIntegration = sdkData.culture.CommonData.ConsentIntegration
    'need to set the value so that it will notify application that consent is made
    m.top.onSdkBroadCast = true
    saveConsentTimeReg()
    if consentIntegration = invalid or consentIntegration.ConsentApi = invalid
        m.logger.set(m.errortype.Error, m.errorTags.OneTrust, m.constant.error["505"])
        return
    end if
    logConsentReceipt = CreateObject("roSGNode", "OTtask")
    logConsentReceipt.consentUrl = consentIntegration.ConsentApi
    logConsentReceipt.payload = payload
    logConsentReceipt.consentAction = consentAction
    logConsentReceipt.observeField("consentResponse", "onConsentResponse")
    logConsentReceipt.functionName = "logConsent"
    addToNetwork(logConsentReceipt, true)
    ' m.logConsent.control = "RUN"
end function

function onConsentResponse(message as object)
    m.logger.set(m.errortype.Success, m.errorTags.NetworkRequestHandler, "consentreceipts" + m.constant.success["202"])
    request = message.getRoSGNode()
    response = request.consentResponse
    m.top.consentResponse = response
    if response <> invalid
        m.logger.set(m.errortype.Info, m.errorTags.ConsentLogging, m.constant.info["719"], response.receipt)
    end if
end function

function setDataSubjectIdentifier(data as object)
    m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "setDataSubjectIdentifier" + m.constant.info["705"] + m.constant.info["712"], FormatJson(data))
    if data.subjectIdentifier <> invalid
        if (type(data.subjectIdentifier) = "roString" or type(data.subjectIdentifier) = "String")
            if data.subjectIdentifier <> ""
                m.logger.set(m.errortype.info, m.errorTags.PublicMethod, m.constant.info["706"], data.subjectIdentifier)
                m.isAppIdentifier = true
                setIdentifier(data.subjectIdentifier)
                saveIdentifierToRegistry(m.subjectIdentifier)
            else
                m.logger.set(m.errortype.Warning, m.errorTags.PublicMethod, "identifier", m.constant.warning["906"])
            end if
        else
            m.logger.set(m.errortype.Warning, m.errorTags.PublicMethod, "identifier", m.constant.warning["902"])
        end if
    end if
end function

function getSubjectIdentifier() as string
    if getIdentifier() = ""
        regSubjectIdentifier = getSubjectIdentifierRegistry()
        genericProfile = m.registry.read("genericProfile")
        if regSubjectIdentifier <> "" and genericProfile <> invalid
            setIdentifier(regSubjectIdentifier)
        else
            identifier = getGenericProfile()
            if regSubjectIdentifier <> "" and genericProfile = invalid and identifier <> ""
                setIdentifier(identifier)
            else
                randomId = getRandomHexString(8) + "-" + getRandomHexString(4) + "-" + getRandomHexString(4) + "-" + getRandomHexString(4) + "-" + getRandomHexString(12)
                setIdentifier(randomId)
                saveIdentifierToRegistry(randomId)
                m.registry.write("genericProfile", "true")
                ONETRUST_ROKU_KEYS = m.registry.read("ONETRUST_ROKU_KEYS")
                if ONETRUST_ROKU_KEYS <> invalid and ONETRUST_ROKU_KEYS <> ""
                    ONETRUST_ROKU_KEYS = ParseJson(ONETRUST_ROKU_KEYS)
                    ONETRUST_ROKU_KEYS.identifier = randomId
                    m.registry.write("ONETRUST_ROKU_KEYS", FormatJson(ONETRUST_ROKU_KEYS))
                end if
            end if
        end if
    end if
    return m.subjectIdentifier
end function

function getSubjectIdentifierRegistry() as string
    subjectIdentifier = ""
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    if sdkReg.Exists("subjectIdentifier")
        subjectIdentifier = sdkReg.Read("subjectIdentifier")
    end if
    return subjectIdentifier
end function

function saveIdentifierToRegistry(subjectIdentifier as string)
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    sdkReg.Write("subjectIdentifier", subjectIdentifier)
    sdkReg.Flush()
end function

function getRandomHexString(length as integer) as string
    hexChars = "0123456789ABCDEF"
    hexString = ""
    for i = 1 to length
        hexString = hexString + hexChars.Mid(Rnd(16) - 1, 1)
    next
    return hexString
end function


function isTestApp() as boolean
    sdkData = m.global._OT_initialize_data
    scriptType = sdkData.domain.ScriptType
    if scriptType <> invalid and LCase(scriptType) = "test"
        return true
    end if
    return false
end function

function checkIsAnonymous() as boolean
    return not (m.shouldCreateProfile and m.isAppIdentifier)
end function

function saveBannerShownRegistry()
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    sdkReg.Write("bannerDisplayed", "true")
    sdkReg.Flush()
end function

function setBannerLogoSize(data as object)
    m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "setBannerLogoSize" + m.constant.info["705"] + m.constant.info["712"], FormatJson(data))
    m.bannerLogoSize = data
end function

function setPreferenceCenterLogoSize(data as object)
    m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "setPreferenceCenterLogoSize" + m.constant.info["705"] + m.constant.info["712"], FormatJson(data))
    m.preferenceCenterLogoSize = data
end function

function getETag() as string
    regEtag = getEtagReg()
    eTag = ""
    if regEtag <> ""
        eTag = regEtag
    end if
    return eTag
end function

function getEtagReg() as string
    eTag = ""
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    if sdkReg.Exists("OT_ProfileSyncETag")
        eTag = sdkReg.Read("OT_ProfileSyncETag")
    end if
    return eTag
end function

function saveInitialData()
    saveTimestampReg()
    ONETRUST_ROKU_KEYS = m.registry.read("ONETRUST_ROKU_KEYS")
    if (m.previousSubjectIdentifier <> invalid and m.subjectIdentifier <> m.previousSubjectIdentifier)
        switchProfile(m.subjectIdentifier)
        if ONETRUST_ROKU_KEYS <> invalid and ONETRUST_ROKU_KEYS <> "" then m.registry.write("ONETRUST_ROKU_KEYS", ONETRUST_ROKU_KEYS)
    end if
    saveIdentifierToRegistry(m.subjectIdentifier)
    sdkData = m.global._OT_initialize_data
    profileSync = sdkData.profile.sync
    if sdkData.profile.sync.keys().count() > 0
        if profileSync.eTag <> invalid and profileSync.eTag <> ""
            saveEtagToReg(profileSync.eTag)
        end if
        syncProfileToLocal()
    end if
    setVendorDetails(m.global._OT_initialize_data)
    initLastReConsentDate(optionalChaining(sdkData, "culture.DomainData"))
    checkGroupImplied()
    initializeCCPAValues()
    checkPendingConsent()
    convertIABGPPKeys()
    if m.iabVendorTask = invalid and m.googleVendorTask = invalid
        m.top.eventlistener = "dataDownloadSucess"
    end if
    m.logger.set(m.errortype.Info, m.errorTags.StorageUtils, m.constant.info["736"], m.registry.GetSpaceAvailable().tostr() + " KB")
end function

function checkGroupImplied()
    groups = getValidGroup()
    impliedGroupIds = {}
    for each grp in groups
        if grp.Status.Instr("landingpage") <> -1
            impliedGroupIds.AddReplace(grp.OptanonGroupId, "active")
        end if
    end for
    if impliedGroupIds.keys().count() > 0
        saveGroupsToRegistry(impliedGroupIds)
    end if
end function

function checkPendingConsent()
    regConsentAction = getRegConsentAction()
    if regConsentAction <> ""
        m.logger.set(m.errortype.Info, m.errorTags.ConsentLogging, m.constant.info["708"], regConsentAction)
        consentData = getConsentPayload(regConsentAction)
        logConsent(consentData, regConsentAction)
        setCCPAValues()
        addConsentToReg()
    end if
end function

function saveEtagToReg(eTag as string)
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    sdkReg.Write("OT_ProfileSyncETag", eTag)
    sdkReg.Flush()
end function

function addToNetwork(taskNode as object, requestListener = false as boolean) as void
    if requestListener
        taskNode.id = getRandomHexString(8)
        taskNodeObject = {}
        taskNodeObject.AddReplace(taskNode.id, taskNode)
        if not m.deviceInfo.GetLinkStatus()
            addConsentToReg(taskNode.consentAction)
            setNetworkTimer()
            return
        end if
        m.networkAPIQueue.push(taskNodeObject)
        taskNode.observeField("taskCompleted", "removeFromNetwork")
    end if
    taskNode.control = "RUN"
end function

function removeFromNetwork(node as object)
    request = node.getRoSGNode()
    id = request.id
    for task = m.networkAPIQueue.count() - 1 to 0 step -1
        if m.networkAPIQueue[task].doesExist(id)
            m.networkAPIQueue[task][id].unObserveField("taskCompleted")
            m.networkAPIQueue[task][id].control = "STOP"
            m.networkAPIQueue.Delete(task)
        end if
    end for
    if request <> invalid and request.consentResponse <> invalid and request.consentResponse.keys().count() = 0
        addConsentToReg(request.consentAction)
    end if
end function

function addConsentToReg(consentAction = "" as string)
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    sdkReg.Write("OT_ConsentAction", consentAction)
    sdkReg.Flush()
end function

function getRegConsentAction()
    consentAction = ""
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    if sdkReg.Exists("OT_ConsentAction")
        consentAction = sdkReg.Read("OT_ConsentAction")
    end if
    return consentAction
end function

function setNetworkTimer()
    m.networkTimer = CreateObject("roSGNode", "Timer")
    m.networkTimer.observeField("fire", "checkNetworkStatus")
    m.networkTimer.duration = 10
    m.networkTimer.repeat = true
    m.networkTimer.control = "start"
end function

function checkNetworkStatus()
    m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["709"], m.deviceInfo.GetLinkStatus())
    if m.deviceInfo.GetLinkStatus()
        checkPendingConsent()
        m.networkTimer.unObserveField("fire")
        m.networkTimer.control = "stop"
        m.networkTimer = invalid
    end if
end function

function optIntoSaleOfData() as void
    m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "optIntoSaleOfData" + m.constant.info["705"])
    if isCCPA() then updateOptOut(true)
end function

function optOutOfSaleOfData() as void
    m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "optOutOfSaleOfData" + m.constant.info["705"])
    if isCCPA() then updateOptOut(false)
end function

function getSubGroups(groupId as string) as object
    groups = getValidGroup()
    subGroups = []
    for each grp in groups
        if grp.Parent = groupId
            subGroups.push(grp)
        end if
    end for
    return subGroups
end function

function updateOptOut(status) as void
    sdkData = m.global._OT_initialize_data
    parentId = sdkData.culture.MobileData.ccpaData.parentCCPACategory
    uspString = "1---"
    if m.global.IABUSPrivacy_String <> invalid then uspString = m.global.IABUSPrivacy_String
    if parentId <> ""
        groups = {}
        parentGroupDetail = getValidGroup(parentId)
        gStatus = parentGroupDetail.Status
        if gStatus = "always active"
            m.logger.set(m.errortype.Warning, m.errorTags.OneTrust, m.constant.warning["907"])
            return
        end if
        if status
            if gStatus.Instr("inactive") < 0
                saveUSP(uspString)
                return
            end if
            updateStatus = "active"
        else
            if gStatus.Instr("inactive") <> -1
                saveUSP(uspString)
                return
            end if
            updateStatus = "inactive"
        end if
        groups.AddReplace(parentId, updateStatus)
        subGroups = getSubGroups(parentGroupDetail["OptanonGroupId"])
        for each sGroups in subGroups
            groups.AddReplace(sGroups.CustomGroupId, updateStatus)
        end for
        saveGroupsToRegistry(groups)
        consentData = getConsentPayload("savePreference")
        logConsent(consentData, "savePreference")
        setCCPAValues()
    end if
end function

function saveConsentTimeReg()
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    consentTime = CreateObject("roDateTime").AsSeconds()
    m.logger.set(m.errortype.Info, m.errorTags.ConsentLogging, m.constant.info["710"], consentTime)
    sdkReg.Write("OT_LastConsentTime", consentTime.toStr())
    sdkReg.Flush()
    updateLastReConsentDate(getLastReconsentDate())
end function

function saveTimestampReg()
    sdkData = m.global._OT_initialize_data
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    lastlaunch = ""
    if sdkData.info <> invalid and sdkData.info.lastLaunch <> invalid
        lastlaunch = sdkData.info.lastLaunch.date
    end if
    sdkReg.Write("lastlaunch", lastlaunch)
    sdkReg.Flush()
    m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["703"], lastlaunch)
end function

function getTimestampReg()
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    lastlaunch = ""
    if sdkReg.Exists("lastlaunch")
        lastlaunch = sdkReg.Read("lastlaunch")
    end if
    m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["702"], lastlaunch)
    return lastlaunch
end function

function updatePurposeConsent(groupData, groupRecId) as void
    groupId = groupData.id
    groupidList = {}
    status = groupData.status
    isParent = isParentGroup(groupId)
    updateStatus = "inactive"
    if status
        updateStatus = "active"
    end if
    logMsg = " PurposeID = " + groupId + "  ConsentStatus: " + status.tostr()
    logMsg1 = m.constant.listener["ELP105"]
    if groupRecId = "buttonsListLIGrp"
        logMsg = " PurposeID = " + groupId + "  Legitimate Interest: " + status.tostr()
        groupId = "Li_" + groupId
        logMsg1 = m.constant.listener["ELP104"]
    end if
    m.saveGroupqueue.AddReplace(groupId, updateStatus)
    groupidList[groupId] = updateStatus
    if groupData.onClickedSdkConsent = invalid then m.logger.set(m.errortype.preferenceCenter, m.errorTags.ConsentLogging, logMsg1, logMsg)
    if groupRecId <> "buttonsListLIGrp"
        if isParent
            subGroups = getSubGroups(groupId)
            for each group in subGroups
                if group.Status <> "always active"
                    groupidList[group.OptanonGroupId] = updateStatus
                    m.saveGroupqueue.AddReplace(group.OptanonGroupId, updateStatus)
                end if
            end for
        else
            gd = getValidGroup(groupId)
            if gd = invalid
                m.logger.set(m.errortype.Warning, m.errorTags.ConsentLogging, m.constant.warning["905"], groupId)
                return
            end if
            parentId = gd.Parent
            subGroups = getSubGroups(parentId)
            isStatus = "active"
            for each group in subGroups
                id = group.OptanonGroupId
                substatus = group.Status
                regGroupData = getRegGroupData()
                if regGroupData.doesExist(id)
                    substatus = regGroupData[id]
                end if
                if m.saveGroupqueue.doesExist(id)
                    substatus = m.saveGroupqueue[id]
                end if
                if substatus <> "always active" and substatus <> "active"
                    isStatus = "inactive"
                    exit for
                end if
            end for
            if m.saveGroupqueue <> invalid and m.saveGroupqueue.doesExist(parentId) and m.saveGroupqueue[parentId] <> isStatus
                groupidList[parentId] = isStatus
            end if
            m.saveGroupqueue.AddReplace(parentId, isStatus)
        end if
        onchangePCupdateSdkListConsent(groupidList, groupData.onClickedSdkConsent)
    end if
end function

function onchangePCupdateSdkListConsent(groupidList, onClickedSdkConsent)
    initGroups = m.initGroups
    m.tempsdkListConsentStatus = ParseJson(FormatJson(m.saveGroupqueue["sdk"]))
    for each item in groupidList.items()
        if item.key <> "" and initGroups[item.key].ShowSDKListLink and initGroups[item.key].FirstPartyCookies <> invalid and initGroups[item.key].FirstPartyCookies.count() > 0
            FirstPartyCookies = initGroups[item.key].FirstPartyCookies
            fCount = FirstPartyCookies.count() - 1
            for i = 0 to fCount
                subItem = ParseJson(FormatJson(FirstPartyCookies[i]))
                if m.tempsdkListConsentStatus <> invalid and m.tempsdkListConsentStatus.doesExist(subItem.SdkId)
                    consent = m.tempsdkListConsentStatus[subItem.SdkId]
                    m.tempsdkListConsentStatus[subItem.SdkId] = item.value
                    if onClickedSdkConsent <> invalid and item.value = "inactive"
                        m.tempsdkListConsentStatus[subItem.SdkId] = consent
                    end if
                end if
            end for
        end if
    end for
    if onClickedSdkConsent = invalid
        m.saveGroupqueue["sdk"] = m.tempsdkListConsentStatus
        m.tempsdkListConsentStatus = {}
    end if
end function

function updateVendorPurposeConsent(group, groupRecId, vendorType) as void
    groupId = group.id
    status = group.status
    updateStatus = "inactive"
    if status
        updateStatus = "active"
    end if
    logMsg = " VendorID = " + groupId + "  ConsentStatus: " + status.tostr()
    logMsg1 = m.constant.listener["ELV107"]
    logMsgType = m.errortype.VendorList
    if vendortype = "sdk"
        logMsg = " SDKID = " + groupId + "  ConsentStatus: " + status.tostr()
        logMsg1 = m.constant.listener["ELS104"]
        logMsgType = m.errortype.SDKList
    end if
    if groupRecId = "buttonsListLIGrp"
        logMsg = " vendorID = " + groupId + "  Legitimate Interest: " + status.tostr()
        groupId = "Li_" + groupId
        logMsg1 = m.constant.listener["ELV108"]
    end if
    if m.saveGroupqueue[vendortype] = invalid then m.saveGroupqueue[vendortype] = {}
    m.saveGroupqueue[vendorType].AddReplace(groupId, updateStatus)
    m.logger.set(logMsgType, m.errorTags.ConsentLogging, logMsg1, logMsg)
    if vendortype = "sdk"
        initGroups = m.initGroups
        groupId = group.groupId
        if status
            subgroups = getSubGroups(groupId)
            for each item in initGroups[groupId].FirstPartyCookies
                if m.saveGroupqueue[vendortype] <> invalid and m.saveGroupqueue[vendortype].doesExist(item.SdkId) and m.saveGroupqueue[vendortype][item.SdkId] = "inactive"
                    status = false
                    exit for
                end if
            end for
            if status and subgroups <> invalid and subgroups.count() > 0
                for each subItem in subGroups
                    FirstPartyCookies = subItem.FirstPartyCookies
                    fCount = FirstPartyCookies.count() - 1
                    for i = 0 to fCount
                        if m.saveGroupqueue[vendortype] <> invalid and m.saveGroupqueue[vendortype].doesExist(FirstPartyCookies[i].SdkId) and m.saveGroupqueue[vendortype][FirstPartyCookies[i].SdkId] = "inactive"
                            status = false
                            exit for
                        end if
                    end for
                end for
            end if
        end if
        g = {}
        g.AddReplace("id", groupId)
        g.AddReplace("status", status)
        g.AddReplace("onClickedSdkConsent", true)
        updatePurposeConsent(g, groupRecId)
    end if
end function

function getVendorStatus(id, vendortype, isConsent, regGroupData) as object
    if regGroupData = invalid then regGroupData = getRegGroupData()
    culture = m.global._OT_initialize_data.culture
    vendorConsentModel = culture.DomainData["VendorConsentModel"]
    status = "active"
    if isConsent and vendorConsentModel <> invalid and vendorConsentModel <> "opt-out"
        status = "inactive"
    end if
    if regGroupData[vendortype] <> invalid and regGroupData[vendortype].doesExist(id)
        status = regGroupData[vendortype][id]
    end if
    if m.saveGroupqueue[vendortype] <> invalid and m.saveGroupqueue[vendortype].doesExist(id)
        status = m.saveGroupqueue[vendortype][id]
    end if
    return status
end function

function getIabGroups(groups)
    iabGrps = {
        purpose: {},
        sp: {},
        feature: {},
        sf: {}
    }
    for each grp in groups
        iabGrpId = getPurposeIDs(grp.CustomGroupId)
        grpName = grp.GroupName
        if iabGrpId <> invalid and isIab_PURPOSE(grp.Type)
            iabGrps.purpose[iabGrpId] = grpName
        else if iabGrpId <> invalid and isIab_SPL_PURPOSE(grp.Type)
            iabGrps.sp[iabGrpId] = grpName
        else if iabGrpId <> invalid and isIab_FEATURE(grp.Type)
            iabGrps.feature[iabGrpId] = grpName
        else if iabGrpId <> invalid and isIab_SPL_FEATURE(grp.Type)
            iabGrps.sf[iabGrpId] = grpName
        end if
    end for
    return iabGrps
end function

function setfullScreenResolution()
    screenSize = m.deviceInfo.GetDisplaySize()
    scene = m.top.GetScene()
    m.global.Addfield("screenSize", "assocarray", false)
    if optionalChaining(scene, "currentDesignResolution.height") <> invalid then screenSize.h = scene.currentDesignResolution.height
    if optionalChaining(scene, "currentDesignResolution.width") <> invalid then screenSize.w = scene.currentDesignResolution.width
    m.global.screenSize = screenSize
end function

function updateSdkListConsentData(records)
    regGroupData = getRegGroupData()
    sdkStatusList = {}
    for each item in records
        id = item.id
        sdkStatusList[id] = item.status
        if regGroupData[item.CustomGroupId] <> invalid and regGroupData.doesExist(item.CustomGroupId)
            sdkStatusList[id] = regGroupData[item.CustomGroupId]
        end if
        if m.saveGroupqueue <> invalid and m.saveGroupqueue.doesExist(item.CustomGroupId)
            sdkStatusList[id] = m.saveGroupqueue[item.CustomGroupId]
        end if
        if regGroupData["sdk"] <> invalid and regGroupData["sdk"].doesExist(id)
            sdkStatusList[id] = regGroupData["sdk"][id]
        end if
        if m.saveGroupqueue["sdk"] <> invalid and m.saveGroupqueue["sdk"].doesExist(id)
            sdkStatusList[id] = m.saveGroupqueue["sdk"][id]
        end if
    end for
    m.saveGroupqueue["sdk"] = sdkStatusList
end function

function setGlobaldata()
    sdkreg = m.registry.readSection()
    if sdkreg <> invalid
        if sdkreg.doesExist("IABTCF_TCString") and not isGppEnabled()
            setIabGlobalInitilization()
            m.global.IABTCF_CmpSdkID = sdkreg.IABTCF_CmpSdkID
            m.global.IABTCF_CmpSdkVersion = sdkreg.IABTCF_CmpSdkVersion
            m.global.IABTCF_PolicyVersion = sdkreg.IABTCF_PolicyVersion
            m.global.IABTCF_gdprApplies = sdkreg.IABTCF_gdprApplies
            m.global.IABTCF_TCString = sdkreg.IABTCF_TCString
            m.global.IABTCF_PublisherCC = sdkreg.IABTCF_PublisherCC
            m.global.IABTCF_PurposeOneTreatment = sdkreg.IABTCF_PurposeOneTreatment

            m.global.IABTCF_SpecialFeaturesOptIns = sdkreg.IABTCF_SpecialFeaturesOptIns
            m.global.IABTCF_UseNonStandardStacks = sdkreg.IABTCF_UseNonStandardStacks

            m.global["IABTCF_PurposeConsents"] = sdkreg.IABTCF_PurposeConsents
            m.global["IABTCF_PurposeLegitimateInterests"] = sdkreg.IABTCF_PurposeLegitimateInterests

            m.global["IABTCF_PublisherConsent"] = sdkreg.IABTCF_PublisherConsent
            m.global["IABTCF_PublisherLegitimateInterests"] = sdkreg.IABTCF_PublisherLegitimateInterests

            m.global["IABTCF_VendorConsents"] = sdkreg.IABTCF_VendorConsents
            m.global["IABTCF_VendorLegitimateInterests"] = sdkreg.IABTCF_VendorLegitimateInterests
            m.global["IABTCF_LastUpdated"] = sdkreg.IABTCF_LastUpdated
            m.global["IABTCF_IsServiceSpecific"] = sdkreg.IABTCF_IsServiceSpecific

            m.global["IABTCF_PublisherRestrictions1"] = sdkreg.IABTCF_PublisherRestrictions1
            m.global["IABTCF_PublisherRestrictions2"] = sdkreg.IABTCF_PublisherRestrictions2
            m.global["IABTCF_PublisherRestrictions3"] = sdkreg.IABTCF_PublisherRestrictions3
            m.global["IABTCF_PublisherRestrictions4"] = sdkreg.IABTCF_PublisherRestrictions4
            m.global["IABTCF_PublisherRestrictions5"] = sdkreg.IABTCF_PublisherRestrictions5
            m.global["IABTCF_PublisherRestrictions6"] = sdkreg.IABTCF_PublisherRestrictions6
            m.global["IABTCF_PublisherRestrictions7"] = sdkreg.IABTCF_PublisherRestrictions7
            m.global["IABTCF_PublisherRestrictions8"] = sdkreg.IABTCF_PublisherRestrictions8
            m.global["IABTCF_PublisherRestrictions9"] = sdkreg.IABTCF_PublisherRestrictions9
            m.global["IABTCF_PublisherRestrictions10"] = sdkreg.IABTCF_PublisherRestrictions10
        end if

        if sdkreg.doesExist("IABUSPrivacy_String") and not isGppEnabled()
            if not m.global.doesExist("IABUSPrivacy_String") then m.global.Addfield("IABUSPrivacy_String", "string", false)
            m.global.IABUSPrivacy_String = sdkreg.IABUSPrivacy_String
        end if

        if sdkreg.doesExist("IABTCF_AddtlConsent")
            if not m.global.doesExist("IABTCF_AddtlConsent") then m.global.Addfield("IABTCF_AddtlConsent", "string", false)
            m.global.IABTCF_AddtlConsent = sdkreg.IABTCF_AddtlConsent
        end if
    end if
end function

function setsaveGroupqueue(data)
    m.saveGroupqueue.append(data)
end function
