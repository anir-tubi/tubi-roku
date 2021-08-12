' Thin wrapper for CMS API requests.  Collected here to facilitate easy
' integration tests
Function CmsApi(constants, request, auth)
  return {
    ' dependencies
    constants: constants
    request: request
    auth: auth

    ' public
    relatedContentReqInfo: cmsApi_getRelatedContentRequestInfo
    upNextContentRequestInfo: cmsApi_getUpNextContentRequestInfo
    singleContentReqInfo: cmsApi_getSingleContentRequestInfo
    thumbnailsReqInfo: cmsApi_getThumbnailsRequestInfo
    channelReq: cmsApi_getChannelRequest
    channelReqInfo: cmsApi_getChannelRequestInfo
    channelsCategoriesScreenReq: cmsApi_getChannelsCategoriesScreenRequest
    homeScreenReq: cmsApi_getHomeScreenRequest
    homeScreenReqInfo: cmsApi_getHomeScreenRequestInfo
    categoryReq: cmsApi_getCategoryRequest
    categoryReqInfo: cmsApi_getCategoryRequestInfo
    searchReq: cmsApi_getSearchRequest
    searchReqInfo: cmsApi_getSearchRequestInfo

    ' private
    commonOptions: cmsApi_commonOptions
    createAuthRequest: cmsApi_createAuthRequest
    setImageParams: cmsApi_setImageParams
    setTupianPosterParam: cmsApi_setTupianPosterParam
    setTupianLandscapeParam: cmsApi_setTupianLandscapeParam
    setTupianLargeVitgParam: cmsApi_setTupianLargeVitgParam
  }
End Function


Function cmsApi_commonOptions()
  headers = {}
  ' appending in this style is neccessary to prevent m.constants.headers.json from being
  ' mutated by potential later appends, since assoc arrays are passed by reference.
  headers.append(m.constants.headers.json)
  headers.append(m.constants.headers.commonUapi)

  options = {
    params: {
      "app_id": m.constants.settings.shortAppName
      "platform": m.constants.platform
      "device_id": m.constants.deviceInfo.deviceId
    }
    headers: headers
  }
  return options
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


' @passedOptions: assocArray, options to be added to the request object as created by Request().createAsync()
Function cmsApi_getUpNextContentRequestInfo(contentId, passedOptions)
  url = m.constants.urls.cms.upNextContent + "/" + contentId + "/next"
  options = m.commonOptions()
  params = options.params
  headers = options.headers

  params["video_resources"] = m.constants.player.drmOrder

  if passedOptions <> invalid
    if passedOptions.params <> invalid
      params.append(passedOptions.params)
    end if

    if passedOptions.headers <> invalid
      headers.append(passedOptions.headers)
    end if
  end if

  if passedOptions <> invalid
    options.append(passedOptions)
  end if

  options.params = params

  return {
    url: url
    options: options
  }
End Function


Function cmsApi_getSingleContentRequestInfo(contentId, includeChannels=false, bKidsMode = false)
  options = m.commonOptions()
  options.params["content_id"] = contentId
  options.params["isKidsMode"] = bKidsMode
  options.params["includeChannels"] = includeChannels
  options.params["video_resources"] = m.constants.player.drmOrder
  options.params = m.setTupianLandscapeParam(options.params)

  return {
    url: m.constants.urls.cms.singleContent
    options: options
  }
End Function


Function cmsApi_getThumbnailsRequestInfo(contentId)
  url = m.constants.urls.cms.thumbnails + "/" + contentId + "/thumbnail_sprites"
  options = m.commonOptions()
  options.params["type"] = "5x"
  options.params["max_width"] = m.constants.deviceInfo.displayWidth
  return {
    url: url
    options: options
  }
End Function


' @channelId: string, id of the channel ex: "shout_factory"
' @limit: int, the max number of contents in the response
' @bKidsMode: boolean, is the app in kids mode
Function cmsApi_getChannelRequest(channelId, limit, bKidsMode = false)
  channelReqInfo = m.channelReqInfo(channelId, limit, bKidsMode)
  url = channelReqInfo.url
  options = channelReqInfo.options
  return m.createAuthRequest(url, m.constants.reqNames.getChannel, options)
End Function


' @channelId: string, id of the channel ex: "shout_factory"
' @limit: int, the max number of contents in the response
' @bKidsMode: boolean, is the app in kids mode
Function cmsApi_getChannelRequestInfo(channelId, limit, bKidsMode = false)
  url = m.constants.urls.matrix.channel + "/" + channelId
  
  options = m.commonOptions()
  options.params["cursor"] = 0
  options.params["limit"] = limit
  options.params["isKidsMode"] = bKidsMode
  options.params["includeChannels"] = true
  options.params = m.setTupianPosterParam(options.params)

  return {
    url: url
    options: options
  }
End Function


'''''''''''''''''''''
' channelsCategoriesScreenReq()
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
'
Function cmsApi_getChannelsCategoriesScreenRequest(bKidsMode = false)
  options = {
    params: {
      limit: 0
    }
  }
  return m.homeScreenReq(bKidsMode, options)
End Function


'''''''''''''''''''''
' homeScreenReq()
'
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
' @passedOptions: assocArray, options that are used to create a request (ie, headers, params, method, etc.)
'                 see request.brs for more info
Function cmsApi_getHomeScreenRequest(bKidsMode = false, passedOptions = {})
  homeScreenReqInfo = m.homeScreenReqInfo(bKidsMode, passedOptions)
  url = homeScreenReqInfo.url
  options = homeScreenReqInfo.options
  return m.createAuthRequest(url, m.constants.reqNames.getHomescreen, options)
End Function


' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
' @passedOptions: assocArray, options that are used to create a request (ie, headers, params, method, etc.)
'                 see request.brs for more info
Function cmsApi_getHomeScreenRequestInfo(bKidsMode = false, passedOptions = {})
  url = m.constants.urls.matrix.homescreen
  
  options = m.commonOptions()
  params = options.params
  headers = options.headers

  params["includeEmptyHistory"] = true
  params["includeEmptyQueue"] = true
  params["isKidsMode"] = bKidsMode
  params["includeVideoInGrid"] = true
  params["contentMode"] = m.constants.ui.contentMode.homescreen ' default contentMode

  if passedOptions.params <> invalid and passedOptions.params["contentMode"] <> invalid and passedOptions.params["contentMode"] <> ""
    ' This will be overwritten by the same value later in this function
    ' when we append the passedOptions.params to params. We add it here so the default value
    ' is not used in the following logic, if a value was passed in for "contentMode"
    params["contentMode"] = passedOptions.params["contentMode"]
  end if

  if params["contentMode"] <> m.constants.ui.contentMode.linear
    ' don't send the Tupian image params for homescreen requests that are contentMode = "linear"
    imageParamTypes = [
      "poster"
      "landscape"
      "large_vitg"
    ]
    params = m.setImageParams(imageParamTypes, options.params)
  end if

  if passedOptions <> invalid
    if passedOptions.params <> invalid
      params.append(passedOptions.params)
    end if

    if passedOptions.headers <> invalid
      headers.append(passedOptions.headers)
    end if
  end if

  if passedOptions <> invalid
    options.append(passedOptions)
  end if

  options.params = params
  options.headers = headers

  return {
    url: url
    options: options
  }
End Function


'''''''''''''''''''''
' categoryReq()
'
Function cmsApi_getCategoryRequest(categoryId, name = invalid, bKidsMode = false, passedOptions = {})
  categoryReqInfo = m.categoryReqInfo(categoryId, name, bKidsMode, passedOptions)
  url = categoryReqInfo.url
  options = categoryReqInfo.options
  return m.createAuthRequest(url, name, options)
End Function


' @categoryId, string, the UAPI id for the category
' @name: string, identifier for the type of request (found in constants)
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
' @passedOptions: assocArray, options that are used to create a request (ie, headers, params, method, etc.)
'                 see request.brs for more info
Function cmsApi_getCategoryRequestInfo(categoryId, name = invalid, bKidsMode = false, passedOptions = {})
  url = m.constants.urls.matrix.container + "/" + categoryId

  if name = invalid
    name = m.constants.reqNames.getCategory
  end if

  options = m.commonOptions()
  params = options.params

  params["isKidsMode"] = bKidsMode
  params["includeChannels"] = true
  params["includeVideoInGrid"] = true
  params["cursor"] = 0
  params["limit"] = m.constants.performance.categoryGridList.finalBlockSize

  if passedOptions.params <> invalid
    if passedOptions.params.contentMode <> invalid and passedOptions.params.contentMode <> ""
      params["contentMode"] = passedOptions.params.contentMode
    end if
  end if

  imageParamTypes = [
    "poster"
    "landscape"
    "large_vitg"
  ]
  params = m.setImageParams(imageParamTypes, params)

  headers = options.headers

  headers["x-tubi-inject-live-news"] = "false"
  if passedOptions <> invalid and passedOptions.params <> invalid
    contentMode = passedOptions.params.contentMode

    if contentMode = m.constants.ui.contentMode.homescreen or contentMode = m.constants.ui.contentMode.linear
      if bKidsMode = false
        ' add custom linear content header for all homescreen or news category fetches
        ' per a request from back end team, in order to facilitate better caching.
        headers["x-tubi-inject-live-news"] = "true"
      end if
    end if
  end if

  if passedOptions <> invalid
    if passedOptions.params <> invalid
      params.append(passedOptions.params)
    end if

    if passedOptions.headers <> invalid
      headers.append(passedOptions.headers)
    end if
  end if

  if passedOptions <> invalid
    options.append(passedOptions)
  end if

  options.params = params
  options.headers = headers

  return {
    url: url
    options: options
  }
End Function


''''''''''''''''''''''
' searchreq()
'
Function cmsApi_getSearchRequest(searchText, bKidsMode = false)
  searchReqInfo = m.searchReqInfo(searchText, bKidsMode)
  url = searchReqInfo.url
  options = searchReqInfo.options
  return m.createAuthRequest(url, m.constants.reqNames.searchAPI, options)
End Function


' @searchText: string, the text the user is attempting to search for
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
Function cmsApi_getSearchRequestInfo(searchText, bKidsMode = false)
  url = m.constants.urls.cms.search
  options = m.commonOptions()
  options.params["search"] = searchText
  options.params["isKidsMode"] = bKidsMode
  options.params = m.setTupianPosterParam(options.params)

  return {
    url: url
    options: options
  }
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
Function cmsApi_setTupianLargeVitgParam(existingParams = {})
  return m.setImageParams(["large_vitg"], existingParams)
End Function


'''''''''''''''''''''
' create an auth request if user is logged in, otherwise use a normal request
Function cmsApi_createAuthRequest(url, reqName, options)
  request = m.auth.createAuthRequest(url, reqName, options)
  if request = invalid
    request = m.request.createAsync(url, reqName, options)
  end if
  return request
End Function

