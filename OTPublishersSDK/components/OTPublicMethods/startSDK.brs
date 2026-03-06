' cmp API startsdk
Function startSDK(params as Object)
  m.apis = {
    banner: "notInitialized",
    'preference: "notInitialized",
    'vendor: "notInitialized"
  }
  m.apisCount = 0
  if isValid(params) AND isRequiredParams(params)
    if not isStringType(params.identifier) then params.identifier = ""
    checkApplicationIDExits(params)
    validateConsentMigration(params)
    m.isAuthenticatedConsent = isAuthenticatedConsent(params)
    isAllowed = true
    if isValid(params.identifier) AND not isBoolean(m.isAuthenticatedConsent)
      isAllowed = switchProfile(params.identifier)
    end if
    if isAllowed
      checkIdentifierExits(params)
      m.headerParams.Append(params)
      setShouldShowBannerStatus(-1)
      setIsBannerShownStatus(-1)
      dataDownload(params)
    else
      errors = {
        "errors": [
          {
            "message": m.constant.warning["909"]
          }
        ]
      }
      m.top.onDataSuccessMP = false
      m.top.onDataSuccess = false
      m.top.eventlistener["dataDownloadSucess"] = { name: "dataDownloadSucess", response: false, error: errors.errors }
    end if
  else
    errors = {
      "errors": [
        {
          "message": "Please provide required Application details"
        }
      ]
    }
    m.top.onDataSuccessMP = false
    m.top.onDataSuccess = false
    m.top.eventlistener["dataDownloadSucess"] = { name: "dataDownloadSucess", response: false, error: errors.errors }
  end if
End Function

Function dataDownload(params)
  for each item in m.apis
    getAPIData(item, params)
  end for
End Function

Function getAPIData(viewType, params)
  createTaskPromise("OTNetworkTask", {
    method: "GET",
    name: viewType,
    headers: params,
    isAuthenticatedConsent: m.isAuthenticatedConsent,
    functionName: "fetchApi",
  }, false, "response").then(sub(task)
    m.apisCount++
    results = task.response
    if results <> invalid AND results.errors <> invalid AND results.errors.count() = 0
      m.logger.set(m.errortype.Success, m.errorTags.NetworkRequestHandler, task.name + m.constant.success["202"])
      m.OT_Data.OT_modelData.Append(results)
      m.OT_Data.AddReplace("path", task.name)
      m.apis[task.name] = "success"
    else
      if results <> invalid AND results.errors <> invalid AND results.errors.count() > 0
        for each item in results.errors
          m.logger.set(m.errortype.Failed, m.errorTags.NetworkRequestHandler, m.constant.failed["600"], task.name + " Api " + item.code.tostr() + "-" + item.message)
        end for
      else
        results = {}
        results["errors"] = [{ message: m.constant.failed["603"] }]
        m.logger.set(m.errortype.Failed, m.errorTags.NetworkRequestHandler, m.constant.failed["600"], m.constant.failed["603"])
      end if
      m.apis[task.name] = "failed"
    end if
    if m.apis <> invalid AND m.apis.count() = m.apisCount
      downloadSuccess = true
      for each item in m.apis
        if m.apis[item] = "failed"
          downloadSuccess = false
          exit for
        end if
      end for
      if downloadSuccess
        OT_RP = getStorageKeys("OT_RP")
        if isString(OT_RP) then m.registry.delete("OT_RP")
        setGenericProfileIdentifier()
        setMultiProfileserverData() ' set the multiprofile server data to registry
        havingAuthenticatedConsent = handleAuthenticatedConsent(task.headers)
        if not havingAuthenticatedConsent then setSDKInitializationSuccess()
      else
        m.top.onDataSuccessMP = false
        m.top.onDataSuccess = false
        m.top.eventlistener["dataDownloadSucess"] = { name: "dataDownloadSucess", response: false, error: results.errors }
      end if
    end if
  end sub)
End Function

Function setSDKInitializationSuccess()
  setShouldShowBannerStatus(0)
  setIsBannerShownStatus(0)
  ' showBanner is false and checking for cross device or already consent holds.
  if (not m.OT_Data.OT_modelData.appConfig.showBanner)
    BannerReason_Code_SyncCompleted = 152 'Banner Reason codes
    status = 1
    if m.OT_Data.OT_modelData.appConfig.bannerReasonCode = BannerReason_Code_SyncCompleted then status = 2
    setShouldShowBannerStatus(1)
    if status = 2 then setIsBannerShownStatus(status)
  end if
  setStorageKeys(m.OT_Data.OT_modelData)
  m.top.onDataSuccessMP = true
  m.top.onDataSuccess = true
  m.top.eventlistener["dataDownloadSucess"] = { name: "dataDownloadSucess", response: true, success: m.OT_Data.OT_modelData }
End Function

Function checkApplicationIDExits(params)
  previousAppId = m.registry.read("appId")
  if params["applicationId"] <> previousAppId AND previousAppId <> invalid AND previousAppId <> ""
    m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["741"], previousAppId)
    clearOTSDK()
  end if
  m.registry.write("appId", params["applicationId"])
End Function

Function checkIdentifierExits(params)
  activeIdentifier = getCurrentActiveProfile()
  genericProfile = getStorageKeys("genericProfile")
  if isBoolean(m.isAuthenticatedConsent)
    if isValid(isMultiProfileAllowed())
      renameProfile(getCurrentActiveProfile(), params["identifier"])
    else
      renameProfile(params["identifier"])
    end if
  else if isValid(activeIdentifier) AND ((not isString(genericProfile) AND params["identifier"] <> activeIdentifier) OR (isString(genericProfile) AND not (params["identifier"] = "" OR params["identifier"] = activeIdentifier))) AND not isValid(isMultiProfileAllowed())
    m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["742"], activeIdentifier)
    clearOTSDK()
  end if
  if params["identifier"] = "" then m.registry.write("genericProfile", "true")
  m.registry.write("subjectIdentifier", params["identifier"])
End Function

Function setGenericProfileIdentifier()
  genericProfile = m.registry.read("genericProfile")
  if isString(genericProfile)
    identifier = getGenericProfileIdentifier()
    if isString(identifier) then m.registry.write("subjectIdentifier", identifier)
  end if
End Function

Function clearOTSDK()
  m.registry.deleteSection("OT_Profiles")
  m.registry.deleteSection("TCF")
  m.registry.deleteSection("GPP")
  m.registry.deleteSection()
  m.OT_Data = {
    "OT_modelData": {},
  }
  m.top.onDataSuccess = false
  m.logger.set(m.errortype.Info, m.errorTags.OneTrust, m.constant.info["701"])
End Function

Function validateConsentMigration(params)
  m.isMigrated = false
  otSDKReg = m.registry.readSection()
  OT_Profiles = m.registry.readSection("OT_Profiles")
  migrateMultiprofile(otSDKReg, params, true)
  for each item in OT_Profiles
    migrateMultiprofile(ParseJson(OT_Profiles[item]), params, false)
  end for
End Function

Function migrateMultiprofile(otSDKReg, params, isCurrentProfile)
  otConsentString = otSDKReg["otConsentString"]
  identifier = otSDKReg["subjectIdentifier"]
  genericProfile = otSDKReg["genericProfile"]
  data = {
    lastConsentDate: otSDKReg["OT_LastConsentTime"]
    appId: otSDKReg["appId"]
    dsId: identifier
    isAnonymous: isString(genericProfile) AND genericProfile = "true" AND isString(identifier)
  }
  isAppExits = not (params["applicationId"] <> data.appId AND data.appId <> invalid AND data.appId <> "")
  if not isString(otConsentString) AND isString(data.lastConsentDate) AND isValid(params) AND isAppExits
    generateOtConsentString(params, data, otSDKReg, isCurrentProfile)
  end if
End Function

Function generateOtConsentString(params, data, otSDKReg, isCurrentProfile)
  ' Fields to encode ot-consent-string
  '  shouldShowBanner: 0,
  '  groupConsents: {},
  '  groupLIConsents: {},
  '  sdkConsents: {},
  '  lastLaunchDate: 0,
  '  dsId: "",
  '  lastConsentDate: 0,
  '  lastInteractionType: ""
  '  appId: "",
  '  cdn: "",
  '  isAnonymous: 0,
  '  expiryDate: "",
  '  identifierType: "",
  '  countryCode: "",
  '  regionCode: "",
  consentObject = {}

  consentObject["shouldShowBanner"] = 0

  groupData = otSDKReg["groupData"]
  if isString(groupData)
    groupData = ParseJson(groupData)
    if groupData.count() > 0
      consentObject["groupConsents"] = {}
      consentObject["groupLIConsents"] = {}
      consentObject["sdkConsents"] = {}
      groupDataKeys = groupData.keys()
      for i = 0 to groupDataKeys.count() - 1
        if groupDataKeys[i] <> "iab" AND groupDataKeys[i] <> "google" AND isString(groupDataKeys[i])
          if groupDataKeys[i] = "sdk"
            if isValid(groupData[groupDataKeys[i]]) AND groupData[groupDataKeys[i]].count() > 0
              sdkdata = groupData[groupDataKeys[i]]
              sdkKeys = sdkdata.keys()
              for j = 0 to sdkKeys.count() - 1
                status = 1
                if sdkdata[sdkKeys[j]].Instr("inactive") <> -1 then status = 0
                consentObject["sdkConsents"][sdkKeys[j]] = status
              end for
            end if
          else
            status = 1
            if groupData[groupDataKeys[i]].Instr("inactive") <> -1 then status = 0
            leftTrimKey = Left(groupDataKeys[i], 3)
            if leftTrimKey = "Li_"
              liKey = Mid(groupDataKeys[i], 4)
              consentObject["groupLIConsents"][liKey] = status
            else
              consentObject["groupConsents"][groupDataKeys[i]] = status
            end if
          end if
        end if
      end for
    end if
  end if

  lastLaunchDate = otSDKReg["lastlaunch"]
  dt = CreateObject("roDateTime")
  if isString(lastLaunchDate)
    ' set lastLaunchDate ISO "2009-01-01T01:00:00.000Z" date to roDateTime
    dt.fromISO8601String(lastLaunchDate)
    lastLaunchDate = CreateObject("roLongInteger")
    lastLaunchDate.SetLongInt(dt.AsSeconds())
    lastLaunchDate = (lastLaunchDate * 1000) + dt.GetMilliseconds()
    consentObject["lastLaunchDate"] = lastLaunchDate
  end if

  if isString(data.dsId) then consentObject["dsId"] = data.dsId
  if isString(data.lastConsentDate)
    lastConsentDate = CreateObject("roLongInteger")
    lastConsentDate.SetLongInt(data.lastConsentDate.toInt())
    lastConsentDate = (lastConsentDate * 1000)
    consentObject["lastConsentDate"] = lastConsentDate
  end if
  if isString(params["applicationId"]) then consentObject["appId"] = params["applicationId"]
  if isString(params.location) then consentObject["cdn"] = params.location
  if isString(data.isAnonymous) then consentObject["isAnonymous"] = data.isAnonymous

  identifierType = otSDKReg["OT_identifierType"]
  if isString(identifierType) then consentObject["identifierType"] = identifierType

  base64EncodedString = EncodeJsonToBase64(consentObject)

  iabEncripted = otSDKReg["iabEncripted"]
  IABTCF_TCString = otSDKReg["IABTCF_TCString"]
  IABTCF_AddtlConsent = otSDKReg["IABTCF_AddtlConsent"]

  gppEncripted = otSDKReg["gppEncripted"]
  IABGPP_HDR_GppString = otSDKReg["IABGPP_HDR_GppString"]
  IABGPP_2_String = otSDKReg["IABGPP_2_String"]
  IABGPP_TCFEU2_AddtlConsent = otSDKReg["IABGPP_TCFEU2_AddtlConsent"]

  if not isString(IABTCF_TCString) AND isString(iabEncripted)
    iabEncripted = ParseJson(iabEncripted)
    if isValid(iabEncripted) AND isValid(iabEncripted.tcString) then IABTCF_TCString = iabEncripted.tcString
  end if
  if not isString(IABGPP_HDR_GppString) AND isString(gppEncripted) then IABGPP_HDR_GppString = gppEncripted
  if isString(IABGPP_2_String) IABTCF_TCString = IABGPP_2_String

  ' Print the Base64 encoded string
  m.logger.set(m.errortype.info, m.errorTags.Migration, m.constant.info["740"], base64EncodedString)
  if isCurrentProfile
    OT_Profiles = m.registry.readSection("OT_Profiles")
    if isValid(OT_Profiles) then m.registry.write("OT_MP", FormatJson({ limit: 6 }))
    m.registry.write("otConsentString", base64EncodedString)
    if isString(IABTCF_TCString) then m.registry.write("IABTCF_TCString", IABTCF_TCString, "TCF")
    if isString(IABTCF_AddtlConsent) then m.registry.write("IABTCF_AddtlConsent", IABTCF_AddtlConsent, "TCF")

    if isString(IABGPP_HDR_GppString) then m.registry.write("IABGPP_HDR_GppString", IABGPP_HDR_GppString, "GPP")
    if isString(IABGPP_TCFEU2_AddtlConsent) then m.registry.write("IABGPP_TCFEU2_AddtlConsent", IABGPP_TCFEU2_AddtlConsent, "GPP")
  else
    TCF = {}
    if isString(IABTCF_TCString) then TCF["IABTCF_TCString"] = IABTCF_TCString
    if isString(IABTCF_AddtlConsent) then TCF["IABTCF_AddtlConsent"] = IABTCF_AddtlConsent

    GPP = {}
    if isString(IABGPP_HDR_GppString) then GPP["IABGPP_HDR_GppString"] = IABGPP_HDR_GppString
    if isString(IABGPP_TCFEU2_AddtlConsent) then GPP["IABGPP_TCFEU2_AddtlConsent"] = IABGPP_TCFEU2_AddtlConsent

    if TCF.keys().count() > 0 then otSDKReg["TCF"] = FormatJson(TCF)
    if GPP.keys().count() > 0 then otSDKReg["GPP"] = FormatJson(GPP)
    otSDKReg["otConsentString"] = base64EncodedString
    otSDKReg["OT_MP"] = FormatJson({ limit: 6 })
    m.registry.write(data.dsId, FormatJson(otSDKReg), "OT_Profiles")
  end if

End Function

Function EncodeJsonToBase64(consentObject)
  ' Create a Base64 encoder
  base64Encoder = CreateObject("roByteArray")
  base64Encoder.FromAsciiString(FormatJson(consentObject))

  ' Encode the JSON string to Base64
  base64EncodedString = base64Encoder.ToBase64String()
  m.isMigrated = true
  return base64EncodedString
End Function

Function getGenericProfileIdentifier()
  identifier = ""
  otConsentString = m.registry.read("otConsentString")
  if isString(otConsentString)
    base64Encoder = CreateObject("roByteArray")
    base64Encoder.FromBase64String(otConsentString)
    data = base64Encoder.ToAsciiString()
    if isValid(data)
      data = ParseJson(data)
      if isValid(data["dsId"]) then identifier = data["dsId"]
    end if
  end if
  return identifier
End Function

Function handleAuthenticatedConsent(params)
  if isValid(params) AND isString(params.syncProfileAuth) then m.registry.write("issyncProfile", "1") else m.registry.write("issyncProfile", "0")
  havingAuthenticatedConsent = false
  if isBoolean(m.isAuthenticatedConsent)
    m.isAuthenticatedConsent = invalid
    OT_LastConsentedDate = getStorageKeys("OT_LastConsentedDate")
    if isString(OT_LastConsentedDate)
      date1 = CreateObject("roDateTime")
      date1.fromISO8601String(OT_LastConsentedDate)
      server_OT_LastConsentedDate = m.OT_Data.OT_modelData.storageKeys.OT_LastConsentedDate
      if isString(server_OT_LastConsentedDate)
        date2 = CreateObject("roDateTime")
        date2.fromISO8601String(server_OT_LastConsentedDate)
        havingAuthenticatedConsent = date1.AsSecondsLong() > date2.AsSecondsLong()
      else
        havingAuthenticatedConsent = true
      end if
      if havingAuthenticatedConsent
        havingAuthenticatedConsent = true
        logConsentForAuthenticatedConsent(params)
      end if
    end if
  end if
  return havingAuthenticatedConsent
End Function

Function isAuthenticatedConsent(params)
  issyncProfile = m.registry.read("issyncProfile")
  return isValid(params) AND isString(params.syncProfileAuth) AND isString(issyncProfile) AND issyncProfile = "0"
End Function

Function logConsentForAuthenticatedConsent(params)
  createTaskPromise("OTNetworkTask", {
    method: "POST",
    name: "saveLogConsent",
    body: {
      "interactionType": "SYNC_PROFILE",
      "userAgent": ""
    },
    headers: params,
    functionName: "fetchApi",

  }, false, "response").then(sub(task)
    results = task.response
    if results <> invalid AND results.errors <> invalid AND results.errors.count() = 0
      m.logger.set(m.errortype.Success, m.errorTags.NetworkRequestHandler, task.name + "unknow to known user flow")
      m.OT_Data.OT_modelData.Append(results)
      setSDKInitializationSuccess()
    else
      if results <> invalid AND results.errors <> invalid AND results.errors.count() > 0
        for each item in results.errors
          m.logger.set(m.errortype.Failed, m.errorTags.NetworkRequestHandler, m.constant.failed["600"], task.name + " Api " + item.code.tostr() + "-" + item.message)
        end for
      else
        results = {}
        results["errors"] = [{ message: m.constant.failed["603"] }]
        m.logger.set(m.errortype.Failed, m.errorTags.NetworkRequestHandler, m.constant.failed["600"], m.constant.failed["603"])
      end if
      m.top.onDataSuccessMP = false
      m.top.onDataSuccess = false
      m.top.eventlistener["dataDownloadSucess"] = { name: "dataDownloadSucess", response: false, error: results.errors }
    end if
  end sub)
End Function