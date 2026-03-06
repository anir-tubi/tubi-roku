Function getHttp(_OT_config) as String
  ssl = _OT_config.ssl
  if ssl
    return "https"
  else
    return "http"
  end if
End Function

Function getBaseUrl(_OT_config) as String
  return _OT_config.acquisition.server
End Function

Function getUrl(name = "applicationdata")
  _OT_config = m._OT_config
  url = {
    applicationdata: getHttp(_OT_config) + "://" + getBaseUrl(_OT_config) + "/" + _OT_config.initialization.apiEp,
    encode: _OT_config.encodeAPI,
    banner: getHttp(_OT_config) + "://" + getBaseUrl(_OT_config) + "/" + _OT_config.initialization.banner,
    preference: getHttp(_OT_config) + "://" + getBaseUrl(_OT_config) + "/" + _OT_config.initialization.preference,
    vendor: getHttp(_OT_config) + "://" + getBaseUrl(_OT_config) + "/" + _OT_config.initialization.vendor
    saveLogConsent: getHttp(_OT_config) + "://" + getBaseUrl(_OT_config) + "/" + _OT_config.initialization.saveLogConsent
  }
  if not name = "applicationdata" AND not name = "encode"
    m.logger.set(m.errortype.Info, m.errorTags.NetworkRequestHandler, "Get" + m.constant.info["718"], url[name])
  end if
  return url[name]
End Function

Function getOTconfig()
  logUtil().set(getErrorType().Info, getErrorTags().OneTrust, applicationConstants().info["700"])
  ' jenkins will update the version in OTconfig file to automation the sdk version
  otConfig = {
    "acquisition": {
      "server": "mobile-data.onetrust.io"
    },
    "ssl": true,
    "initialization": {
      "apiEp": "bannersdk/v2/applicationdata",
      "banner": "cfw/cmp/v1/banner",
      "preference": "cfw/cmp/v1/preferences",
      "vendor": "cfw/cmp/v1/vendors",
      "saveLogConsent": "cfw/cmp/v1/save-log-consent"
    },
    "encodeAPI": "https://mobile.onetrust.io/iabtcf/v1/tcmodel/encode",
    "version": "latest"
  }
  otConfigJson = ReadAsciiFile("libpkg:/components/OTPublishersSDK/OTconfig.json")
  if isString(otConfigJson) AND otConfigJson <> ""
    otConfigJson = ParseJson(otConfigJson)
    if isValid(otConfigJson) AND isString(otConfigJson["version"]) then otConfig["version"] = otConfigJson["version"]
  end if
  return otConfig
End Function

Function initializeAPIHeaders(params as Object) as Object
  defaultHeaders = {
    "Content-Type": "application/json;charset=utf-8",
    "Accept-Language": "en;q=1",
    "Accept": "*",
    "Accept-Charset": "utf-8"
  }
  headers = {
    "OT-Device-Type": "ctv",
    "OT-Force-Fetch": "true",
    "OT-Fetch-Type": "APP_DATA_ONLY"
  }

  headers["OT-Platform"] = "Roku"
  sdkVersion = "latest"
  if isValid(m._OT_config) AND isString(m._OT_config.version) then sdkVersion = m._OT_config.version
  osVersion = getDeviceInfo("osVersion")
  if not isValid(osVersion) then osVersion = 0
  headers["OT-SDK-Identification"] = "Roku/" + osVersion.toStr() + "/" + sdkVersion

  genericProfile = getStorageKeys("genericProfile")
  if isString(genericProfile) then params.identifier = ""
  if params.location <> invalid then headers.AddReplace("OT-CDN-Location", params.location)
  if params.applicationId <> invalid then headers.AddReplace("OT-App-Id", params.applicationId)
  if params.language <> invalid then headers.AddReplace("OT-Language", params.language)
  if params.version <> invalid then headers.AddReplace("OT-SDK-Version", params.version)
  if params.identifier <> invalid then headers.AddReplace("OT-Identifier", params.identifier)
  if params.countryCode <> invalid then headers.AddReplace("OT-Country-Code", params.countryCode)
  if params.regionCode <> invalid then headers.AddReplace("OT-Region-Code", params.regionCode)
  if params.syncProfileAuth <> invalid then headers.AddReplace("OT-Sync-Profile-Auth", params.syncProfileAuth)
  if isString(params.identifierType) then headers.AddReplace("OT-Identifier-Type", params.identifierType)

  OT_RP = getStorageKeys("OT_RP")
  if isString(OT_RP) then headers.AddReplace("OT-Identifier-UpdateType", "Rename-Identifier")

  if not (isString(params.syncProfileAuth) AND isBoolean(m.top.isAuthenticatedConsent) AND m.top.method = "GET")
    otConsentString = getStorageKeys("otConsentString")
    if otConsentString <> invalid then headers.AddReplace("OT-Consent-String", otConsentString)

    AddtlConsent = getStorageKeys("AddtlConsent")
    if AddtlConsent <> invalid then headers.AddReplace("OT-Addtl-Consent-String", AddtlConsent)

    IABTCF_AddtlConsent = getStorageKeys("IABTCF_AddtlConsent")
    if IABTCF_AddtlConsent <> invalid then headers.AddReplace("OT-Addtl-Consent-String", IABTCF_AddtlConsent)

    IABGPP_TCFEU2_AddtlConsent = getStorageKeys("IABGPP_TCFEU2_AddtlConsent")
    if IABGPP_TCFEU2_AddtlConsent <> invalid then headers.AddReplace("OT-Addtl-Consent-String", IABGPP_TCFEU2_AddtlConsent)

    TCString = getStorageKeys("TCString")
    IABTCF_TCString = getStorageKeys("IABTCF_TCString")
    if isString(IABTCF_TCString) then TCString = IABTCF_TCString
    IABGPP_2_String = getStorageKeys("IABGPP_2_String")
    if isString(IABGPP_2_String) then TCString = IABGPP_2_String
    if TCString <> invalid then headers.AddReplace("OT-Tcf-Eu2v2-Consent-String", TCString)

    GppString = getStorageKeys("GppString")
    IABGPP_HDR_GppString = getStorageKeys("IABGPP_HDR_GppString")
    if isString(IABGPP_HDR_GppString) then GppString = IABGPP_HDR_GppString
    if GppString <> invalid then headers.AddReplace("OT-GPP-String", GppString)
  end if

  if params.countryCode = invalid then headers.AddReplace("OT-Country-Code", "")
  if params.regionCode = invalid then headers.AddReplace("OT-Region-Code", "")
  if params.syncProfileAuth <> invalid AND params.syncProfileAuth <> ""
    headers.AddReplace("OT-Fetch-Type", "APP_DATA_AND_SYNC_PROFILE")
  end if
  headers.append(defaultHeaders)
  logUtil().set(getErrorType().Info, getErrorTags().NetworkRequestHandler, "header" + applicationConstants().info["712"], headers)
  OT_Data = m.global.OT_Data
  OT_Data["headers"] = params
  m.global.OT_Data = OT_Data
  return headers
End Function