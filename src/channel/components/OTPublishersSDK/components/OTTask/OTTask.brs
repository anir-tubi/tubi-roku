function init()
    m.constant = applicationConstants()
    m.errortype = getErrorType()
    m.errorTags = getErrorTags()
    m.logger = logUtil()
    m.registry = RegistryUtil()
end function

function initializeSDK()
    url = getUrl()
    params = m.top.requestParams
    m.customHeaders = getInitializeAPIheaders(params)
    OTgetContent(url, setInitializeData)
end function

function setInitializeData(initializeData as object)
    m.logger.set(m.errortype.Success, m.errorTags.NetworkRequestHandler, m.constant.success["200"])
    if not initializeData.doesExist("culture") or not initializeData.doesExist("domain") or not initializeData.doesExist("profile")
        m.logger.set(m.errortype.Error, m.errorTags.OneTrust, m.constant.error["502"])
        m.global.OTsdk.onHideFailure = true
    else
        m.global._OT_initialize_data = initializeData
    end if
end function

function getInitializeAPIheaders(params as object) as object
    headerParams = {
        "location": params.location,
        "application": params.applicationId,
        "lang": params.language,
        "sdkVersion": params.version,
    }
    if params.lastlaunch <> invalid and params.lastlaunch <> ""
        headerParams.AddReplace("x-onetrust-lastlaunch", params.lastlaunch)
    end if
    if params.countryCode <> invalid and params.countryCode <> ""
        headerParams.AddReplace("OT-Country-Code", params.countryCode)
    end if
    if params.regionCode <> invalid and params.regionCode <> ""
        headerParams.AddReplace("OT-Region-Code", params.regionCode)
    end if

    profileSync = "false"
    headerParams.AddReplace("fetchType", "APP_DATA_ONLY")
    if params.syncProfile <> invalid
        if params.syncProfile
            profileSync = "true"
        end if
        headerParams.AddReplace("syncProfile", profileSync)
    end if
    if params.identifier <> ""
        headerParams.AddReplace("identifier", params.identifier)
        if profileSync = "true"
            headerParams.AddReplace("fetchType", "APP_DATA_AND_SYNC_PROFILE")
        end if
    else
        ' m.logger.set(m.errortype.Warning,m.errorTags.OTPublishersHeadlessSDK,"identifier",m.constant.warning["900"])
    end if
    if params.syncProfileAuth <> ""
        headerParams.AddReplace("syncProfileAuth", params.syncProfileAuth)
    end if
    if params.doesExist("profileSyncETag") and params.profileSyncETag <> ""
        headerParams.AddReplace("profileSyncETag", params.profileSyncETag)
    end if
    return headerParams
end function

function isSSLenabled(url as string) as boolean
    ssl = false
    if Left(url, 5) = "https"
        ssl = true
    end if
    return ssl
end function

function buildAPIrequest(url as string, methodType as string, ssl as boolean, bodyParam = "" as dynamic)
    reqAPI = CreateObject("roUrlTransfer")
    reqAPI.SetUrl(url)
    headers = {
        "Content-Type": "application/json;charset=utf-8",
        "Accept-Language": "en;q=1",
        "Accept": "*",
        "Accept-Charset": "utf-8"
    }
    m.logger.set(m.errortype.Info, m.errorTags.NetworkRequestHandler, "Get" + m.constant.info["718"], url)
    if m.customHeaders <> invalid
        m.logger.set(m.errortype.Info, m.errorTags.NetworkRequestHandler, "header" + m.constant.info["712"], m.customHeaders)
        headers.append(m.customHeaders)
    end if
    if bodyParam <> "" 
        m.logger.set(m.errortype.Info, m.errorTags.NetworkRequestHandler, "body" + m.constant.info["712"], bodyParam)
    end if
    reqAPI.RetainBodyOnError(true)
    reqAPI.EnableEncodings(true)
    reqAPI.SetRequest(methodType)
    reqAPI.SetHeaders(headers)
    if ssl
        reqAPI.SetCertificatesFile("common:/certs/ca-bundle.crt")
    end if
    return reqAPI
end function

function OTgetContent(url as string, callback as dynamic)
    sslEnabled = isSSLenabled(url)
    request = buildAPIrequest(url, "GET", sslEnabled)
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    response = {}
    if request.AsyncGetToString()
        msg = wait(0, port)
        if(type(msg) = "roUrlEvent")
            responseString = msg.GetString()
            responseCode = msg.GetResponseCode()
            if responseCode = 200
                if responseString <> invalid and responseString <> ""
                    response = ParseJson(responseString)
                end if
                callback(response)
            else
                failureReason = msg.GetFailureReason()
                m.logger.set(m.errortype.Failed, m.errorTags.NetworkRequestHandler, m.constant.failed["600"], responseCode.tostr() + "-" + failureReason)
                m.global.OTsdk.onHideFailure = true
            end if
            m.top.taskCompleted = true
        end if
    end if
end function

function logConsent()
    url = m.top.consentUrl
    payLoad = m.top.payload
    OTpostContent(url, payLoad)
end function

function OTpostContent(url as string, requestParams as object)
    param = ""
    if requestParams <> invalid and requestParams.Count() > 0
        param = FormatJson(requestParams)
    end if
    sslEnabled = isSSLenabled(url)
    request = buildAPIrequest(url, "POST", sslEnabled, param)
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    response = {}
    if request.AsyncPostFromString(param)
        msg = wait(0, port)
        if(type(msg) = "roUrlEvent")
            responseString = msg.GetString()
            responseCode = msg.GetResponseCode()
            if responseCode = 200
                if responseString <> invalid and responseString <> "" and responseString.Instr("<html") = -1
                    response = ParseJson(responseString)
                end if
                m.top.consentResponse = response
            else
                failureReason = msg.GetFailureReason()
                m.logger.set(m.errortype.Failed, m.errorTags.NetworkRequestHandler, m.constant.failed["601"], responseCode.tostr() + "-" + failureReason)
            end if
            m.top.taskCompleted = true
        end if
    end if
end function

function setTimeOut() as object
    sleep(m.top.time)
    m.top.taskCompleted = true
end function