' Thin wrapper for CMS API requests.  Collected here to facilitate easy
' integration tests
Function CmsApi(constants, request, auth)
  return {
    ' dependencies
    constants: constants
    request_: request
    auth_: auth

    ' public
    relatedContentReq: cmsApi_getRelatedContentRequest
    relatedContentReqInfo: cmsApi_getRelatedContentRequestInfo
    upNextContentReq: cmsApi_getUpNextContentRequest
    getUpNextContentRequestInfo: cmsApi_getUpNextContentRequestInfo
    singleContentReq: cmsApi_getSingleContentRequest
    singleContentReqInfo: cmsApi_getSingleContentRequestInfo
    thumbnailsReq: cmsApi_getThumbnailsRequest
    thumbnailsReqInfo: cmsApi_getThumbnailsRequestInfo
    channelReq: cmsApi_getChannelRequest
    homeScreenReq: cmsApi_getHomeScreenRequest
    channelsCategoriesScreenReq: cmsApi_getChannelsCategoriesScreenRequest
    categoryReq: cmsApi_getCategoryRequest
    searchReq: cmsApi_getSearchRequest

    ' private
    commonOptions: cmsApi_commonOptions
    createAuthRequest: cmsApi_createAuthRequest
    setImageParams: cmsApi_setImageParams
    setTupianPosterParam: cmsApi_setTupianPosterParam
    setTupianLandscapeParam: cmsApi_setTupianLandscapeParam
    setTupianLargeVitgParam: cmsApi_setTupianVitgParam
  }
End Function


Function cmsApi_commonOptions()
  return {
    params: {
      "app_id": m.constants.settings.shortAppName
      "platform": m.constants.platform
      "device_id": m.constants.deviceInfo.deviceId
    }
  }
End Function


'''''''''''''''''''''''
' relatedContentReq()
'
Function cmsApi_getRelatedContentRequest(contentId, bKidsMode = false)
  url = m.constants.urls.cms.relatedContent + "/" + contentId + "/related"

  options = m.commonOptions()
  options.params["isKidsMode"] = bKidsMode
  options.params["video_resources"] = m.constants.player.drmOrder
  options.params = m.setTupianPosterParam(options.params)

  return m.createAuthRequest(url, m.constants.reqNames.getRelatedContent, options)
End Function


Function cmsApi_getRelatedContentRequestInfo(contentId, bKidsMode = false)
  url = m.constants.urls.cms.relatedContent + "/" + contentId + "/related"

  options = m.commonOptions()
  options.params["isKidsMode"] = bKidsMode
  options.params["video_resources"] = m.constants.player.drmOrder
  options.params = m.setTupianPosterParam(options.params)

  return {
    url: url
    options: options
  }
End Function


'''''''''''''''''''''''
' upNextContentReq()
'
' TODO: This function is only used in CmsApiIntegrationTests.brs currently.
'       Update the integration test to use the GeneralTask and cmsApi_getUpNextContentRequestInfo()
'       and then delete this function.
Function cmsApi_getUpNextContentRequest(contentId, categoryId=invalid)
  url = m.constants.urls.cms.upNextContent + "/" + contentId + "/next"
  
  options = m.commonOptions()
  if categoryId <> invalid and categoryId <> ""
    options.params.container_id = categoryId
  end if
  return m.createAuthRequest(url, m.constants.reqNames.getUpNextContent, options)
End Function


Function cmsApi_getUpNextContentRequestInfo(contentId, params)
  url = m.constants.urls.cms.upNextContent + "/" + contentId + "/next"
  options = m.commonOptions()
  options.params["video_resources"] = m.constants.player.drmOrder

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
Function cmsApi_getSingleContentRequest(contentId, includeChannels=false, bKidsMode = false)
  url = m.constants.urls.cms.singleContent

  options = m.commonOptions()
  options.params["content_id"] = contentId
  options.params["isKidsMode"] = bKidsMode
  options.params["includeChannels"] = includeChannels
  options.params["video_resources"] = m.constants.player.drmOrder
  options.params["gn_fields"] = "tms_id"  'request the Gracenote id
  options.params = m.setTupianLandscapeParam(options.params) 'used on episode list screens

  return m.createAuthRequest(url, m.constants.reqNames.getSingleContent, options)
End Function


Function cmsApi_getSingleContentRequestInfo(contentId, includeChannels=false, bKidsMode = false)
  options = m.commonOptions()
  options.params["content_id"] = contentId
  options.params["isKidsMode"] = bKidsMode
  options.params["includeChannels"] = includeChannels
  options.params["video_resources"] = m.constants.player.drmOrder
  options.params["gn_fields"] = "tms_id"  'request the Gracenote id
  options.params = m.setTupianLandscapeParam(options.params)

  return {
    url: m.constants.urls.cms.singleContent
    options: options
  }
End Function


'''''''''''''''''''''''
' thumbnailsReq()
'
Function cmsApi_getThumbnailsRequest(contentId)
  '//This function is only being used in a unit test. Should ensure this and cmsApi_getThumbnailsRequestInfo() ar kept in sync 
  url = m.constants.urls.cms.thumbnails + "/" + contentId + "/thumbnail_sprites"
  
  options = m.commonOptions()
  options.params.type = "5x"
  options.params.max_width = m.constants.deviceInfo.displayWidth
  return m.request_.createAsync(url, m.constants.reqNames.getThumbnails, options)
End Function


Function cmsApi_getThumbnailsRequestInfo(contentId)
  url = m.constants.urls.cms.thumbnails + "/" + contentId + "/thumbnail_sprites"
  options = m.commonOptions()
  options.params.type = "5x"
  options.params.max_width = m.constants.deviceInfo.displayWidth
  return {
    url: url
    options: options
  }
End Function


'''''''''''''''''''''''
' channelReq()
'
Function cmsApi_getChannelRequest(channelId, limit, bKidsMode = false)
  url = m.constants.urls.matrix.channel + "/" + channelId
  
  options = m.commonOptions()
  options.params.expand = 1
  options.params.cursor = 0
  options.params.limit = limit
  options.params["isKidsMode"] = bKidsMode
  options.params["includeChannels"] = true
  options.params = m.setTupianPosterParam(options.params)
  
  return m.createAuthRequest(url, m.constants.reqNames.getChannel, options)
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
' @passedOptions: assocArray, options that are used to create a request (ie, headers, params, method, etc.)
'                 see request.brs for more info
Function cmsApi_getHomeScreenRequest(limit, bKidsMode = false, passedOptions = {}, expand = 2)
  url = m.constants.urls.matrix.homescreen 
  
  options = m.commonOptions()
  options.params["expand"] = expand
  options.params["includeEmptyHistory"] = true
  options.params["includeEmptyQueue"] = true
  options.params["isKidsMode"] = bKidsMode
  options.params["includeVideoInGrid"] = true
  options.params["limit"] = limit

  if passedOptions.params <> invalid and passedOptions.params.contentMode <> invalid and passedOptions.params.contentMode <> ""
    options.params["contentMode"] = passedOptions.params.contentMode

    if passedOptions.params.contentMode <> m.constants.ui.contentMode.news
      ' don't send the Tupian image params for homescreen requests that are contentMode = "news"
      imageParamTypes = [
        "poster"
        "landscape"
        "large_vitg"
      ]
      options.params = m.setImageParams(imageParamTypes, options.params)
    end if

    if passedOptions.params.contentMode = m.constants.ui.contentMode.news or passedOptions.params.contentMode = m.constants.ui.contentMode.homescreen
      '//request and display live news if the experiement calls for it.
      if options.headers = invalid
        options.headers = {}
      end if
      options.headers["x-tubi-inject-live-news"] = "true"
    end if
  end if

  if m.constants.settings.mode = "dev" and m.constants.settings.numContainers <> invalid
    options.params["groupSize"] = m.constants.settings.numContainers
  end if
  
  return m.createAuthRequest(url, m.constants.reqNames.getHomescreen, options)
End Function


'''''''''''''''''''''
' categoryReq()
'
Function cmsApi_getCategoryRequest(categoryId, limit, name = invalid, bKidsMode = false, passedOptions = {})
  url = m.constants.urls.matrix.container + "/" + categoryId
  
  if name = invalid
    name = m.constants.reqNames.getCategory
  end if

  options = m.commonOptions()
  options.params["isKidsMode"] = bKidsMode
  options.params["includeChannels"] = true
  options.params["includeVideoInGrid"] = true
  options.params["expand"] = 1
  options.params["cursor"] = 0
  options.params["limit"] = limit

  ' add custom linear content header for linear content
  if categoryId = m.constants.ui.categoryIds.liveNews
    if options.headers = invalid
      options.headers = {}
    end if
    options.headers["x-tubi-inject-live-news"] = "true"
  end if

  if passedOptions.params <> invalid
    if passedOptions.params.contentMode <> invalid and passedOptions.params.contentMode <> ""
      options.params["contentMode"] = passedOptions.params.contentMode
    end if
  end if

  imageParamTypes = [
    "poster"
    "landscape"
    "large_vitg"
  ]
  options.params = m.setImageParams(imageParamTypes, options.params)

  return m.createAuthRequest(url, name, options)
End Function


''''''''''''''''''''''
' searchreq()
'
Function cmsApi_getSearchRequest(searchText, bKidsMode = false)
  url = m.constants.urls.cms.search
  options = m.commonOptions()
  options.params["search"] = searchText
  options.params["isKidsMode"] = bKidsMode
  m.setTupianPosterParam(options.params)
  return m.createAuthRequest(url, m.constants.reqNames.searchAPI, options)
End Function


''''''''''''''''''''''
' setImageParams()
' returns the params AA that is passed in with any additional Tupian style image params appended on to it
' Tupian style image params ask the backend to return images of a specific size.
' For more info on Tupian image parameters, please see:
' https://docs.google.com/document/d/1T9qL5otwgjIAEW4pPwvKiq0PxIYEK-ExKrFBYRkx6BY
'
' @imageTypes, array - an array of strings corresponding to which types of images to request from Tupian
'                      Accepted values are "poster", "landscape", "large_vitg"
' @existingParams: assocArray, any parameters that have already been defined that need to be added to
Function cmsApi_setImageParams(imageTypes, existingParams = {})
  posterSize = m.constants.ui.imageSizes.poster
  landscapeSize = m.constants.ui.imageSizes.landscape
  largeVitgSize = m.constants.ui.imageSizes.largeVITG

  for each imageType in imageTypes
    if imageType = "poster"
      '//Tell backend to provide a specific sized image
      existingParams["images[poster_tb]"] = "w" + posterSize[0].ToStr() + "h" + posterSize[1].ToStr() + "_poster"
    else if imageType = "landscape"
      existingParams["images[landscape_tb]"] = "w" + landscapeSize[0].ToStr() + "h" + landscapeSize[1].ToStr() + "_hero"
    else if imageType = "large_vitg"
      existingParams["images[vitg_tb]"] = "w" + largeVitgSize[0].ToStr() + "h" + largeVitgSize[1].ToStr() + "_hero"
    end if
  end for

  return existingParams
End Function


' Wrapper around setImageParams for the specific case of only adding a Tupian poster param
' @existingParams: assocArray, any parameters that have already been defined that need to be added to
Function cmsApi_setTupianPosterParam(existingParams = {})
  return m.setImageParams(["poster"], existingParams)
End Function


' Wrapper around setImageParams for the specific case of only adding a Tupian landscape param
' @existingParams: assocArray, any parameters that have already been defined that need to be added to
Function cmsApi_setTupianLandscapeParam(existingParams = {})
  return m.setImageParams(["landscape"], existingParams)
End Function


' Wrapper around setImageParams for the specific case of only adding a Tupian VITG param
' @existingParams: assocArray, any parameters that have already been defined that need to be added to
Function cmsApi_setTupianVitgParam(existingParams = {})
  return m.setImageParams(["large_vitg"], existingParams)
End Function


'''''''''''''''''''''
' create an auth request if user is logged in, otherwise use a normal request
Function cmsApi_createAuthRequest(url, reqName, options)
  request = m.auth_.createAuthRequest(url, reqName, options)
  if request = invalid
    request = m.request_.createAsync(url, reqName, options)
  end if
  return request
End Function

