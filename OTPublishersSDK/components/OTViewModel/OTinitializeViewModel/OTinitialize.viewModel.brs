Function init()
  m.registry = RegistryUtil()
  m.constant = applicationConstants()
  m.errortype = getErrorType()
  m.errorTags = getErrorTags()
  m.logger = logUtil()
  setfullScreenResolution()
  m.headerParams = {}
  m.subjectIdentifier = ""
  m.isAppIdentifier = false
  m.shouldCreateProfile = false
  m.syncProfile = invalid
  m.authProfileId = ""
  m.isAuthenticatedConsent = false
  _OT_config = getOTconfig()
  if optionalChaining(_OT_config, "version") <> invalid
    m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["704"], _OT_config.version)
  end if

  ' cmpapi init
  m.top.eventlistener = CreateObject("roSGNode", "OTEventliseners")

  m.node = getNode()
  m.global.Addfield("OT_Data", "assocarray", false)
  m.global.OT_Data = {}
  m.style = style()
  OT_Data = {
    fonts: m.style.fonts
    fontSize: m.style.fontSize
  }
  updateOTConfigs(OT_Data)

  m.OT_Data = {
    "OT_modelData": {},
  }
  m.consentData = CreateObject("roSGNode", "ContentNode")
  m.consentData.Addfield("purposesStatus", "assocarray", false)
  m.consentData.Addfield("iabVendorsStatus", "assocarray", false)
  m.consentData.Addfield("googleVendorsStatus", "assocarray", false)
  m.consentData.Addfield("sdkStatus", "assocarray", false)
  m.consentData.Addfield("OT_GroupConsents", "assocarray", false)
  m.consentData.Addfield("OT_GroupLIConsents", "assocarray", false)
  m.consentData.Addfield("OT_VendorConsents", "string", false)
  m.consentData.Addfield("OT_vendorLIConsents", "string", false)
  m.consentData.Addfield("OT_AddtlConsent", "string", false)
  m.consentData.Addfield("OT_SdkConsents", "assocarray", false)
  m.consentData["purposesStatus"] = {}
  m.consentData["iabVendorsStatus"] = {}
  m.consentData["googleVendorsStatus"] = {}
  m.consentData["sdkStatus"] = {}
  m.consentData["OT_GroupConsents"] = {}
  m.consentData["OT_GroupLIConsents"] = {}
  m.consentData["OT_SdkConsents"] = {}
  m.consentData["OT_VendorConsents"] = ""
  m.consentData["OT_vendorLIConsents"] = ""
  m.consentData["OT_AddtlConsent"] = ""
  setShouldShowBannerStatus(-1)
  setIsBannerShownStatus(-1)
End Function

Function isRequiredParams(params as Object) as Boolean
  if params["language"] = invalid OR params["language"] = ""
    m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "Language", m.constant.warning["900"])
    return false
  end if
  if params["applicationId"] = invalid OR params["applicationId"] = ""
    m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "Application ID", m.constant.warning["900"])
    return false
  end if
  if params["location"] = invalid OR params["location"] = ""
    m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "Location", m.constant.warning["900"])
    return false
  end if
  if params["version"] = invalid OR params["version"] = ""
    m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "SDK version", m.constant.warning["900"])
    return false
  end if
  if params["shouldCreateProfile"] <> invalid AND type(params["shouldCreateProfile"]) = "roBoolean"
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
    if type(params["syncProfileAuth"]) = "roString" OR type(params["syncProfileAuth"]) = "String"
      setAuthProfileId(params["syncProfileAuth"])
    else
      m.logger.set(m.errortype.Warning, m.errorTags.OTPublishersHeadlessSDK, "syncProfileAuth", m.constant.warning["902"])
      return false
    end if
  end if
  return true
End Function

Function OTSdkParams() as Object
  params = {
    applicationId: sdkParams().getAppId(),
    location: sdkParams().getLocation(),
    version: sdkParams().getsdkVersion(),
    language: sdkParams().getLanguage(),
    shouldCreateProfile: sdkParams().getShouldCreateProfile(),
    countryCode: sdkParams().getCountryCode(),
    regionCode: sdkParams().getRegionCode(),
    identifier: sdkParams().getIdentifier()
  }
  profileSyncParams = getProfileSyncParams()
  params.Append(profileSyncParams)
  return params
End Function

Function sdkParams()
  instance = {
    getAppId: Function() as Dynamic
      headerParams = getHeaderParams()
      return headerParams.applicationId
    End Function,
    getLocation: Function() as Dynamic
      headerParams = getHeaderParams()
      return headerParams.location
    End Function,
    getLanguage: Function() as Dynamic
      headerParams = getHeaderParams()
      return headerParams.language
    End Function,
    getsdkVersion: Function() as Dynamic
      headerParams = getHeaderParams()
      return headerParams.version
    End Function
    getShouldCreateProfile: Function() as Dynamic
      return getCreateProfile()
    End Function,
    getSyncProfile: Function() as Dynamic
      return getSyncProfile()
    End Function
    getIdentifier: Function() as String
      return getIdentifier()
    End Function
    getAuthProfileId: Function() as String
      return getAuthProfileId()
    End Function
    getCountryCode: Function() as Dynamic
      headerParams = getHeaderParams()
      return headerParams.countryCode
    End Function
    getRegionCode: Function() as Dynamic
      headerParams = getHeaderParams()
      return headerParams.regionCode
    End Function
  }
  return instance
End Function

Function getProfileSyncParams() as Object
  profileParams = {
    syncProfile: sdkParams().getSyncProfile(),
    identifier: sdkParams().getIdentifier(),
    syncProfileAuth: sdkParams().getAuthProfileId()
  }
  return profileParams
End Function

Function getHeaderParams() as Object
  return m.headerParams
End Function

Function getCreateProfile() as Boolean
  return m.shouldCreateProfile
End Function

Function getSyncProfile() as Dynamic
  return m.syncProfile
End Function

Function getIdentifier() as String
  identifier = m.registry.read("subjectIdentifier")
  if not isString(identifier) then identifier = ""
  return identifier
End Function

Function getAuthProfileId() as String
  return m.authProfileId
End Function

Function setSyncProfile(isProfileSync as Boolean)
  m.syncProfile = isProfileSync
End Function

Function setAuthProfileId(authProfileId as String)
  m.authProfileId = authProfileId
End Function

Function setIdentifier(identifier as String)
  m.subjectIdentifier = identifier
End Function

Function setfullScreenResolution()
  deviceInfo = CreateObject("roDeviceInfo")
  scale = {
    "FHD": 1,
    "HD": 2 / 3,
    "SD": 3 / 8
  }
  screenSize = deviceInfo.GetUIResolution()
  scene = m.top.GetScene()
  m.global.Addfield("screenSize", "assocarray", false)
  if optionalChaining(scene, "currentDesignResolution.height") <> invalid then screenSize.height = scene.currentDesignResolution.height
  if optionalChaining(scene, "currentDesignResolution.width") <> invalid then screenSize.width = scene.currentDesignResolution.width
  if optionalChaining(scene, "currentDesignResolution.resolution") <> invalid then screenSize.name = scene.currentDesignResolution.resolution
  resolution = {
    w: screenSize.width
    h: screenSize.height
    name: screenSize.name
    scale: scale[screenSize.name]
  }
  m.global.screenSize = resolution
End Function

Function saveConsent(interactionType as String)
  saveLogConsent({ interactionType: interactionType }, m)
End Function

Function updatePurposeConsent(id as String, status as Boolean)
  updatelocalConsents(id, status)
End Function

Function updatePurposeLegitInterest(id as String, status as Boolean)
  updatelocalConsents(id, status, "legitInterestCheckBox")
End Function

Function updateVendorConsent(id as String, status as Boolean)
  updatelocalConsents(id, status, "", "iab")
End Function

Function updateVendorLegitInterest(id as String, status as Boolean)
  updatelocalConsents(id, status, "legitInterestCheckBox", "iab")
End Function

Function updatelocalConsents(id, status, fId = "", vendortype = invalid)
  statustemp = 1
  if isValid(status) AND status then statustemp = 0
  focusNode = {
    id: fId,
    itemContent: {
      uId: id,
      parentId: ""
    },
    status: statustemp
  }
  updateConsents(focusNode, m, vendortype)
End Function
