' Thin wrapper for CMS API requests.  Collected here to facilitate easy
' integration tests
Function CmsApi(constants, request, auth)
  return {
    ' private
    constants_: constants
    request_: request
    auth_: auth
    commonOptions_: cmsApi_commonOptions_
    
    ' public
    relatedContentReq: cmsApi_getRelatedContentRequest
    upNextContentReq: cmsApi_getUpNextContentRequest
    singleContentReq: cmsApi_getSingleContentRequest
    thumbnailsReq: cmsApi_getThumbnailsRequest
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
Function cmsApi_getRelatedContentRequest(contentId)
  url = m.constants_.urls.cms.upNextContent + "/" + contentId + "/related"
  options = m.commonOptions_()
  'create an auth request if user is logged in, otherwise use a normal request
  request = m.auth_.createAuthRequest(url, m.constants_.reqNames.getRelatedContent, options)
  if request = invalid
    request = m.request_.createAsync(url, m.constants_.reqNames.getRelatedContent, options)
  end if
  return request
End Function


'''''''''''''''''''''''
' upNextContentReq()
'
Function cmsApi_getUpNextContentRequest(contentId, categoryId=invalid)
  url = m.constants_.urls.cms.upNextContent + "/" + contentId + "/next"
  options = m.commonOptions_()
  if categoryId <> invalid and categoryId <> ""
    options.params.container_id = categoryId
  end if
  'create an auth request if user is logged in, otherwise use a normal request
  request = m.auth_.createAuthRequest(url, m.constants_.reqNames.getUpNextContent, options)
  if request = invalid
    request = m.request_.createAsync(url, m.constants_.reqNames.getUpNextContent, options)
  end if
  return request
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



Function cmsApi_getThumbnailsRequest(contentId)
  url = m.constants_.urls.cms.thumbnails + "/" + contentId + "/thumbnail_sprites"
  options = m.commonOptions_()
  options.params.type = "5x"
  return m.request_.createAsync(url, m.constants_.reqNames.getThumbnails, options)
End Function
