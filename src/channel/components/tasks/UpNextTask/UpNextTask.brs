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
  requestLib = TubiRequest()
  auth = TubiAuth(constants, requestLib)
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

  if m.top.request.kidsMode <> invalid and m.top.request.kidsMode = true
    '//::TODO::KIDS-MODE only send kids mode if kidsMode=true. This may need to be changed\ so it is being passed no matter what.
    options.params["isKidsMode"] = true
  end if

  if m.top.request.categoryId <> invalid and m.top.request.categoryId <> ""
    categoryId = m.top.request.categoryId
    ' for categories that were originally nested categories in the matrix api, their category id can look like:
    ' parent_id/sub/nested_id or as a specific example foreign_favories/sub/international_films
    ' for the moment, the API can only handle the parent_id
    categoryId = categoryId.split("/sub/")[0]
    options.params.container_id = categoryId
  end if

  request = auth.createAuthRequest(url, constants.reqNames.getUpNextContent, options)
  if request = invalid
    request = requestLib.createAsync(url, constants.reqNames.getUpNextContent, options)
  end if
  port = CreateObject("roMessagePort")
  request.start(port)

  while true
    msg = wait(0, port)
    result = request.handleEvent(msg)
    if result <> invalid and result.response <> invalid and result.response.code >= 200 and result.response.code < 400
      parsed = ParseJSON(result.response.data)
      if parsed = invalid then
        tubiLog("UpNextTask failed to parse JSON response")
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
