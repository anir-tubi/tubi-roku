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
    setImageParams_: cmsApi_setImageParams_
    
    ' public
    relatedContentReq: cmsApi_getRelatedContentRequest
    upNextContentReq: cmsApi_getUpNextContentRequest
    getUpNextContentRequestInfo: cmsApi_getUpNextContentRequestInfo
    singleContentReq: cmsApi_getSingleContentRequest
    thumbnailsReq: cmsApi_getThumbnailsRequest
    thumbnailsReqInfo: cmsApi_getThumbnailsRequestInfo
    channelReq: cmsApi_getChannelRequest
    homeScreenReq: cmsApi_getHomeScreenRequest
    channelsCategoriesScreenReq: cmsApi_getChannelsCategoriesScreenRequest
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
Function cmsApi_getRelatedContentRequest(contentId, bKidsMode = false, params = {})
  url = m.constants_.urls.cms.relatedContent + "/" + contentId + "/related"

  options = m.commonOptions_()
  options.params["isKidsMode"] = bKidsMode
  options.params["video_resources"] = m.constants_.player.drmOrder

  '//update options.params based on the passed in params AA
  m.setImageParams_(params, options.params)

  return m.createAuthRequest_(url, m.constants_.reqNames.getRelatedContent, options)
End Function


'''''''''''''''''''''''
' upNextContentReq()
'
' TODO: This function is only used in CmsApiIntegrationTests.brs currently.
'       Update the integration test to use the GeneralTask and cmsApi_getUpNextContentRequestInfo()
'       and then delete this function.
Function cmsApi_getUpNextContentRequest(contentId, categoryId=invalid)
  url = m.constants_.urls.cms.upNextContent + "/" + contentId + "/next"
  
  options = m.commonOptions_()
  if categoryId <> invalid and categoryId <> ""
    options.params.container_id = categoryId
  end if
  return m.createAuthRequest_(url, m.constants_.reqNames.getUpNextContent, options)
End Function


Function cmsApi_getUpNextContentRequestInfo(contentId, params)
  url = m.constants_.urls.cms.upNextContent + "/" + contentId + "/next"
  options = m.commonOptions_()
  options.params["video_resources"] = m.constants_.player.drmOrder

  for each param in params
    if params[param] <> invalid
      options.params[param] = params[param]
    end if
  end for

  return {
    url: url
    options: options
  }
End Function


'''''''''''''''''''''''
' singleContentReq()
'
Function cmsApi_getSingleContentRequest(contentId, includeChannels=false, bKidsMode = false, params = invalid)
  url = m.constants_.urls.cms.singleContent

  options = m.commonOptions_()
  options.params.content_id = contentId
  options.params["isKidsMode"] = bKidsMode
  options.params["includeChannels"] = includeChannels
  options.params["video_resources"] = m.constants_.player.drmOrder

  '//update options.params based on the passed in params AA
  m.setImageParams_(params, options.params)

  return m.createAuthRequest_(url, m.constants_.reqNames.getSingleContent, options)
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


Function cmsApi_getThumbnailsRequestInfo(contentId)
  url = m.constants_.urls.cms.thumbnails + "/" + contentId + "/thumbnail_sprites"
  options = m.commonOptions_()
  options.params.type = "5x"
  return {
    url: url
    options: options
  }
End Function


'''''''''''''''''''''''
' channelReq()
'
Function cmsApi_getChannelRequest(channelId, limit, bKidsMode = false, params = {})
  url = m.constants_.urls.matrix.channel + "/" + channelId
  
  options = m.commonOptions_()
  options.params.expand = 1
  options.params.cursor = 0
  options.params.limit = limit
  options.params["isKidsMode"] = bKidsMode
  options.params["includeChannels"] = true

  '//update options.params based on the passed in params AA
  m.setImageParams_(params, options.params)
  
  return m.createAuthRequest_(url, m.constants_.reqNames.getChannel, options)
End Function


'''''''''''''''''''''
' channelsCategoriesScreenReq()
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
'
Function cmsApi_getChannelsCategoriesScreenRequest(bKidsMode = false)
  return m.homeScreenReq(0, bKidsMode, {}, 1)
End Function

'''''''''''''''''''''
' homeScreenReq()
'
' @limit: number of items in each category
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
Function cmsApi_getHomeScreenRequest(limit, bKidsMode = false, params = {}, expand = 2)
  url = m.constants_.urls.matrix.homescreen 
  
  options = m.commonOptions_()
  options.params.expand = expand

  '//update options.params based on the passed in params AA
  m.setImageParams_(params, options.params)

  options.params["includeEmpty"] = true
  options.params.limit = limit
  if params <> invalid and params.contentMode <> invalid and params.contentMode <> ""
    options.params["contentMode"] = params.contentMode
  end if
  options.params["isKidsMode"] = bKidsMode
  options.params["includeVideoInGrid"] = true
  return m.createAuthRequest_(url, m.constants_.reqNames.getHomescreen, options)
End Function

'''''''''''''''''''''
' categoryReq()
'
Function cmsApi_getCategoryRequest(categoryId, limit, name = invalid, bKidsMode = false, params = {})
  url = m.constants_.urls.matrix.container + "/" + categoryId
  
  if name = invalid
    name = m.constants_.reqNames.getCategory
  end if
  options = m.commonOptions_()
  options.params.expand = 1
  options.params.cursor = 0 
  options.params.limit = limit
  if params <> invalid 
    if params.contentMode <> invalid and params.contentMode <> ""
      options.params["contentMode"] = params.contentMode
    end if
  end if

  '//update options.params based on the passed in params AA
  m.setImageParams_(params, options.params)

  options.params["isKidsMode"] = bKidsMode
  options.params["includeChannels"] = true
  options.params["includeVideoInGrid"] = true
  return m.createAuthRequest_(url, name, options)
End Function


''''''''''''''''''''''
' searchreq()
'
Function cmsApi_getSearchRequest(searchText, limit, bKidsMode = false, params = {})
  url = m.constants_.urls.cms.search
  
  options = m.commonOptions_()

  '//update options.params based on the passed in params AA
  m.setImageParams_(params, options.params)
  options.params.search = searchText
  options.params["isKidsMode"] = bKidsMode
  return m.createAuthRequest_(url, m.constants_.reqNames.searchAPI, options)
End Function


'//::TODO::SafeZone - see if this function is necessary or should be changed once the safe zone experiement is done and intergrated with the rest of the code
''''''''''''''''''''''
' setImageParams_()
' update your options.params (paramsOut) that are found in your request functions of this file 
' If the input params associative array asks for new sized images, then this function will ask the backend
' to resize the images according to the parameters within the paramsIn AA.
'
' @param paramsIn - this is the raw associative array that is passed to the functions within this file
' @param paramsOut - this should be the "params" associative array of your requets options assoicative array
Function cmsApi_setImageParams_(paramsIn, paramsOut)
  if paramsIn <> invalid 
    if paramsIn.posterSize <> invalid and paramsIn.posterSize.count() = 2 
    '//Tell backend to provide a specific sized image
      paramsOut["images[poster_tb]"] = "w" + paramsIn.posterSize[0].ToStr() + "h" + paramsIn.posterSize[1].ToStr() + "_poster"
    end if
    if paramsIn.landscapeSize <> invalid and paramsIn.landscapeSize.count() = 2 
      paramsOut["images[landscape_tb]"] = "w" + paramsIn.landscapeSize[0].ToStr() + "h" + paramsIn.landscapeSize[1].ToStr() + "_hero"
    end if
    if paramsIn.largeVitgSize <> invalid and paramsIn.largeVitgSize.count() = 2 
      paramsOut["images[vitg_tb]"] = "w" + paramsIn.largeVitgSize[0].ToStr() + "h" + paramsIn.largeVitgSize[1].ToStr() + "_hero"
    end if
  end if
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

