' Thin wrapper for CMS API requests.  Collected here to facilitate easy
' integration tests
Function CmsApi(constants, request)
  return {
    ' private
    constants_: constants
    request_: request
    commonOptions_: cmsApi_commonOptions_
    
    ' public
    relatedContentReq: cmsApi_getRelatedContentRequest
    upNextContentReq: cmsApi_getUpNextContentRequest
    singleContentReq: cmsApi_getSingleContentRequest
  }
End Function

Function cmsApi_commonOptions_()
  return {
    params: {
      "app_id": m.constants_.settings.shortAppName
      "platform": m.constants_.platform
      "device_id": m.constants_.deviceInfo.deviceId
    }
  }
End Function


'''''''''''''''''''''''
' relatedContentReq()
'
Function cmsApi_getRelatedContentRequest(contentId, userId=invalid)
  url = m.constants_.urls.cms.upNextContent + "/" + contentId + "/related"
  options = m.commonOptions_()
  if userId <> invalid and userId <> ""
    options.params.user_id = userId
  end if
  return m.request_.createAsync(url, m.constants_.reqNames.getRelatedContent, options)
End Function


'''''''''''''''''''''''
' upNextContentReq()
'
Function cmsApi_getUpNextContentRequest(contentId, categoryId=invalid, userId=invalid)
  url = m.constants_.urls.cms.upNextContent + "/" + contentId + "/next"
  options = m.commonOptions_()
  if userId <> invalid and userId <> ""
    options.params.user_id = userId
  end if
  if categoryId <> invalid and categoryId <> ""
    options.params.container_id = categoryId
  end if
  return m.request_.createAsync(url, m.constants_.reqNames.getUpNextContent, options)
End Function


'''''''''''''''''''''''
' singleContentReq()
'
Function cmsApi_getSingleContentRequest(contentId)
  url = m.constants_.urls.cms.singleContent
  options = m.commonOptions_()
  options.params.content_id = contentId
  return m.request_.createAsync(url, m.constants_.reqNames.getSingleContent, options)
End Function