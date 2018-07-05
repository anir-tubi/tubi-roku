' Thin wrapper for CMS API requests.  Collected here to facilitate easy
' integration tests
Function CmsApi(constants, request, auth)
  return {
    ' dependencies
    constants_: constants
    request_: request
    auth_: auth

    ' private
    commonOptions_: cmsApi_commonOptions_
    createAuthRequest_: cmsApi_createAuthRequest_
    
    ' public
    relatedContentReq: cmsApi_getRelatedContentRequest
    upNextContentReq: cmsApi_getUpNextContentRequest
    singleContentReq: cmsApi_getSingleContentRequest
    thumbnailsReq: cmsApi_getThumbnailsRequest
    channelReq: cmsApi_getChannelRequest
    homeScreenReq: cmsApi_getHomeScreenRequest
    categoryReq: cmsApi_getCategoryRequest
    searchReq: cmsApi_getSearchRequest
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
  return m.createAuthRequest_(url, m.constants_.reqNames.getRelatedContent, options)
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
  return m.createAuthRequest_(url, m.constants_.reqNames.getUpNextContent, options)
End Function


'''''''''''''''''''''''
' singleContentReq()
'
Function cmsApi_getSingleContentRequest(contentId, includeChannels=false)
  url = m.constants_.urls.cms.singleContent
  options = m.commonOptions_()
  options.params.content_id = contentId
  options.params["includeChannels"] = includeChannels
  return m.request_.createAsync(url, m.constants_.reqNames.getSingleContent, options)
End Function


'''''''''''''''''''''''
' thumbnailsReq()
'
Function cmsApi_getThumbnailsRequest(contentId)
  url = m.constants_.urls.cms.thumbnails + "/" + contentId + "/thumbnail_sprites"
  options = m.commonOptions_()
  options.params.type = "5x"
  return m.request_.createAsync(url, m.constants_.reqNames.getThumbnails, options)
End Function


'''''''''''''''''''''''
' channelReq()
'
Function cmsApi_getChannelRequest(channelId, limit)
  url = m.constants_.urls.matrix.channel + "/" + channelId
  options = m.commonOptions_()
  options.params.expand = 1
  options.params.cursor = 0
  options.params.limit = limit
  return m.createAuthRequest_(url, m.constants_.reqNames.getChannel, options)
End Function


'''''''''''''''''''''
' homeScreenReq()
'
' @limit: number of items in each category
Function cmsApi_getHomeScreenRequest(limit)
  url = m.constants_.urls.matrix.homescreen
  options = m.commonOptions_()
  options.params.expand = 2
  options.params.includeEmpty = true
  options.params.limit = limit
  return m.createAuthRequest_(url, m.constants_.reqNames.getHomescreen, options)
End Function


'''''''''''''''''''''
' categoryReq()
'
Function cmsApi_getCategoryRequest(categoryId, limit)
  url = m.constants_.urls.matrix.container + "/" + categoryId
  options = m.commonOptions_()
  options.params.expand = 1
  options.params.cursor = 0
  options.params.limit = limit
  return m.createAuthRequest_(url, m.constants_.reqNames.getCategory, options)
End Function


''''''''''''''''''''''
' searchreq()
'
Function cmsApi_getSearchRequest(searchText, limit)
  url = m.constants_.urls.cms.search
  options = m.commonOptions_()
  options.params.search = searchText
  return m.createAuthRequest_(url, m.constants_.reqNames.searchAPI, options)
End Function


'''''''''''''''''''''
' create an auth request if user is logged in, otherwise use a normal request
Function cmsApi_createAuthRequest_(url, reqName, options)
  request = m.auth_.createAuthRequest(url, reqName, options)
  if request = invalid
    request = m.request_.createAsync(url, reqName, options)
  end if
  return request
End Function

