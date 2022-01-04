Function init()
  m.top.functionName = "execGetChannelMetadata"
End Function

Function execGetChannelMetadata() As Void
  tubiLog("ChannelsCategoriesMetadataTask.execGetDetailMetadata()")

  constants = m.global.constants
  RequestModule = TubiRequest(constants.settings)
  AuthModule = TubiAuth(constants, RequestModule)
  apiUtils = ApiUtils(constants)
  cms = CmsApi(constants, RequestModule, AuthModule, apiUtils)
  translate = TubiMetadataTranslate(constants)
  request = cms.channelsCategoriesScreenReq(m.top.kidsMode)
  port = CreateObject("roMessagePort")
  m.top.observeField("cancelRequest", port)
  m.top.observeField("canceled", port)

  data = request.start(port)
  timer = CreateObject("roTimespan")

  '// The maximum number of miliseconds it should take to receive a response from the server
  timeout = 5000

  while true
    msg = wait(100, port)

    if type(msg) = "roSGNodeEvent" and msg.getField() = "cancelRequest"
      request.cancel()
      m.top.canceled = true
    else if type(msg) = "roUrlEvent"
      req = request.handleEvent(msg)
      if req <> invalid
        response = req.response
        if response <> invalid and response.code <> invalid and success(response.code)
          parsed = ParseJSON(response.data)
          if parsed <> invalid
            dataNode = translate.translateChannelsCategories(parsed, m.top.displayChannels)
            m.top.response = dataNode
          else
            tubiLog("ChannelsCategoriesMetadataTask failed to parse JSON response")
            response.data = ""  'no need to pass potentially large invalid JSON string across thread boundary
            m.top.error = formatError(response)
          end if
        else
          m.top.error = formatError(response)
        end if
      else
        m.top.error = formatError()
      end if
    else if timer.TotalMilliseconds() > timeout
      m.top.error = formatError()
      exit while
    end if
  end while
End Function


' Helper for checking HTTP request success
' @code: integer, an HTTP request code
Function success(code)
  return code >= 200 and code < 400
End Function


' Helper to populate default values for an error if necessary
' @response: assocArray, as delivered by request.handleEvent().response, has keys: code(int), data(str), failReason(str), name(str)
Function formatError(response = invalid)
  code = -1234
  if response <> invalid and response.code <> invalid
    code = response.code
  end if

  data = ""
  if response <> invalid and response.data <> invalid
    data = response.data
  end if

  failReason = "Result is invalid"
  if response <> invalid and response.failReason <> invalid
    failReason = response.failReason
  end if

  m.top.error = {
    code: code
    data: data
    failReason: failReason
  }
End Function