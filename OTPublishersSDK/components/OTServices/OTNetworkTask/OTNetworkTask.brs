Function init()
  m.constant = applicationConstants()
  m.errortype = getErrorType()
  m.errorTags = getErrorTags()
  m.logger = logUtil()
  m._OT_config = getOTconfig()
  m.registry = RegistryUtil()
End Function

Function isNetworkConnected() as Boolean
  connected = false
  roDeviceInfo = CreateObject("roDeviceInfo")
  if isValid(roDeviceInfo) then connected = roDeviceInfo.getLinkStatus()
  return connected
End Function

Function fetchApi()
  body = invalid
  if m.top.method = "POST"
    body = m.top.body
    if body <> invalid AND body.userAgent <> invalid AND body.userAgent = ""
      userAgentreq = CreateObject("roUrlTransfer")
      if FindMemberFunction(userAgentreq, "GetUserAgent") <> invalid then body.userAgent = userAgentreq.GetUserAgent()
    end if
    logUtil().set(getErrorType().Info, getErrorTags().NetworkRequestHandler, "body" + applicationConstants().info["712"], FormatJson(body))
  end if
  if isNetworkConnected() AND isValid(m.top.headers)
    request = HttpRequest({
      method: m.top.method
      url: getUrl(m.top.name),
      headers: initializeAPIHeaders(m.top.headers)
      data: body
    })
    response = request.send()
    responseString = response.GetString()
    responseCode = response.GetResponseCode()
    data = {}
    if responseCode = 200
      message = ""
      if isString(responseString)
        data = ParseJson(responseString)
        if not isValid(data)
          message = "parseJson error on success data -> " + responseString
        end if
      else
        message = "string error on success data -> " + responseString
      end if
      if isString(message)
        data = {
          "errors": [
            {
              "code": responseCode,
              "message": response.GetFailureReason()
            }
          ]
        }
      end if
      m.top.response = data
    end if
    if not isValid(data) OR responseCode <> 200
      error = {
        "errors": [
          {
            "code": responseCode,
            "message": response.GetFailureReason()
          }
        ]
      }
      if responseCode = 400
        error = ParseJson(responseString)
      end if
      m.top.response = error
    end if
  else
    error = {
      "errors": [
        {
          "code": 500,
          "message": "Network connection failed: Unable to establish a connection. Please check your internet settings."
        }
      ]
    }
    if not isValid(m.top.headers)
      error["errors"] = [
        {
          "code": 500,
          "message": "Please send valid parameters"
        }
      ]
    end if
    m.top.response = error
  end if
End Function

Function fetchGetApi()
  try
    if isNetworkConnected()
      m.request = HttpRequest({
        method: m.top.method
        url: m.top.name,
        headers: m.top.headers
      })
      response = m.request.send()
      responseString = response.GetString()
      responseCode = response.GetResponseCode()
      if responseCode = 200
        if responseString <> invalid AND responseString <> "" AND responseString.Instr("<html") = -1
          regx = createObject("roRegex", "\s(\s+)?", "")
          responseString = regx.replaceAll(responseString, " ")
          responseString = responseString.Replace("}, ]", "}]").Replace(Chr(160), "")
          m.top.response = { url: m.request._http.GetUrl(), response: ParseJson(responseString) }
        end if
      else
        failureReason = response.GetFailureReason()
        m.logger.set(m.errortype.Failed, m.errorTags.NetworkRequestHandler, m.constant.failed["600"], m.request._http.GetUrl() + "(" + responseCode.tostr() + ") -" + failureReason)
      end if
    else
      m.logger.set(m.errortype.Failed, m.errorTags.NetworkRequestHandler, m.constant.failed["600"], m.request._http.GetUrl() + "Network connection failed: Unable to establish a connection. Please check your internet settings.")
    end if
  catch e
    m.logger.error(e)
  end try
End Function