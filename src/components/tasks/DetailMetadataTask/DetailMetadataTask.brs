Function init()
  m.top.functionName = "execGetDetailMetadata"
End Function

Function execGetDetailMetadata()
  tubiLog("DetailMetadataTask.execGetDetailMetadata")
  ' expect that the content here was the bootstrapped content from category list
  contentId = m.top.contentFragment.id

  if m.top.contentFragment.type <> invalid and m.top.contentFragment.type = "series" then
    contentId = "0" + contentId
  end if

  appName = m.global.constants.settings.shortAppName
  url = m.global.constants.urls.cms.singleContent
  platform = m.global.constants.platform
  options = {
    params: {
      "app_id": appName
      platform: platform
      "content_id": contentId
    }
  }
  request = TubiRequest().createAsync(url, "getSingleContent", options)
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
        translate = TubiMetadataTranslate(m.global.constants)
        detail = CreateObject("roSGNode", "TubiContentNode")
        translate.translateRecursive(parsed, detail)
        m.top.response = detail
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
