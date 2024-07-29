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
        end if
    end if
end function