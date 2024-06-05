function init()
    m.constant = applicationConstants()
    m.errortype = getErrorType()
    m.errorTags = getErrorTags()
    m.logger = logUtil()
end function
function buildAPIrequest(url as string, methodType as string, ssl as boolean, bodyParam = "" as dynamic)
    reqAPI = CreateObject("roUrlTransfer")
    reqAPI.SetUrl(url)
    headers = {
        "Content-Type": "application/json",
        "Accept": "*/*",
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
        reqAPI.InitClientCertificates()
    end if
    return reqAPI
end function

function isSSLenabled(url as string) as boolean
    ssl = false
    if Left(url, 5) = "https"
        ssl = true
    end if
    return ssl
end function

function OTgetContent()
    url = m.top.url
    sslEnabled = isSSLenabled(url)
    m.request = buildAPIrequest(url, "GET", sslEnabled)
    port = CreateObject("roMessagePort")
    m.request.SetMessagePort(port)
    response = {}
    m.request.AsyncCancel()
    if m.request.AsyncGetToString()
        msg = wait(0, port)
        if(type(msg) = "roUrlEvent")
            responseString = msg.GetString()
            responseCode = msg.GetResponseCode()
            if responseCode = 200
                if responseString <> invalid and responseString <> "" and responseString.Instr("<html") = -1
                    regx = createObject("roRegex", "\s(\s+)?", "")
                    responseString = regx.replaceAll(responseString, " ")
                    responseString = responseString.Replace("}, ]", "}]").Replace(Chr(160), "")
                    response = ParseJson(responseString)
                    m.top.response = { url: m.request.GetUrl(), response: response }
                end if
            else
                failureReason = msg.GetFailureReason()
                m.logger.set(m.errortype.Failed, m.errorTags.NetworkRequestHandler, m.constant.failed["600"], m.request.GetUrl() + "(" +responseCode.tostr() + ") -" + failureReason)
            end if
            m.top.taskCompleted = true
        end if
    end if
end function