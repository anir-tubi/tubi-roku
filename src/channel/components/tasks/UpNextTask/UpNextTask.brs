Function init()
  m.top.functionName = "execGetUpNextContent"
End Function

Function execGetUpNextContent() As Void
  tubiLog("UpNextTask.execGetUpNextContent")
  
  if type(m.top.request) <> "roAssociativeArray" or m.top.request.contentId = invalid
    m.top.error = {
      code: -1
      data: ""
      failReason: "Content was invalid"
    }
    return
  end if

  constants = m.global.constants
  appName = constants.settings.shortAppName
  url = constants.urls.cms.upNextContent + "/" + m.top.request.contentId + "/next"
  platform = constants.platform
  options = {
    params: {
      "app_id": appName
      "platform": platform
      "device_id": constants.deviceInfo.deviceId
    }
  }
  if m.top.request.userId <> invalid and m.top.request.userId <> ""
    options.params.user_id = m.top.request.userId
  end if
  if m.top.request.categoryId <> invalid and m.top.request.categoryId <> ""
    options.params.container_id = m.top.request.categoryId
  end if
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
        tubiLog("UpNextTask Received " + parent.getChildCount().toStr() + " autoplay items for " + m.top.request.contentId)
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
