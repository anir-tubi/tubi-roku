Function init()
  m.top.functionName = "execGetUpNextContent"
End Function

Function execGetUpNextContent() As Void
  tubiLog("UpNextTask.execGetUpNextContent")
  
  if type(m.top.content) <> "roSGNode"
    m.top.error = {
      code: -1
      data: ""
      failReason: "Content was invalid"
    }
    return
  end if

  constants = m.global.constants
  appName = constants.settings.shortAppName
  url = constants.urls.cms.upNextContent + "/" + m.top.content.id + "/next"
  platform = constants.platform
  options = {
    params: {
      "app_id": appName
      "platform": platform
      "device_id": constants.deviceInfo.deviceId
    }
  }
  request = TubiRequest().createAsync(url, constants.reqNames.getUpNextContent, options)
  port = CreateObject("roMessagePort")
  request.start(port)

  while true
    msg = wait(0, port)
    result = request.handleEvent(msg)

    if result <> invalid and result.response <> invalid and result.response.code >= 200 and result.response.code < 400
      parsed = ParseJSON(result.response.data)
      if parsed = invalid then
        tubiLog("MetadataFetchTask failed to parse JSON response")
        m.top.error = result.response
      else
        translate = TubiMetadataTranslate(constants)
        parent = CreateObject("roSGNode", "ContentNode")
        for each content in parsed
          node = parent.createChild("TubiContentNode")
          translate.translateRecursive(content, node)
        end for
        tubiLog("UpNextTask Received " + parent.getChildCount().toStr() + " autoplay items for " + m.top.content.id)
        m.top.response = parent
      end if
      exit while
    else
      m.top.error = {
        code: msg.GetResponseCode()
        data: ""
        failReason: "Result is invalid"
      }
      exit while
    end if
  end while
End Function
