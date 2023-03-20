' Thin wrapper for CMS API and Search API requests.  Collected here to facilitate easy
' integration tests
Function CmsApi(constants, request, auth, apiUtils, experiments=invalid)

  defaultValues = {
    ' dependencies
    constants: constants
    request: request
    auth: auth
    experiments: experiments

    ' public
    setUtmCampaignConfig: cmsApi_setUtmCampaignConfig
    relatedContentReqInfo: cmsApi_getRelatedContentRequestInfo
    upNextContentRequestInfo: cmsApi_getUpNextContentRequestInfo
    singleContentReqInfo: cmsApi_getSingleContentRequestInfo
    thumbnailsReqInfo: cmsApi_getThumbnailsRequestInfo
    getCategoriesListRequestInfo: cmsApi_getCategoriesListRequestInfo
    homeScreenReqInfo: cmsApi_getHomeScreenRequestInfo
    categoryReqInfo: cmsApi_getCategoryRequestInfo
    searchReq: cmsApi_getSearchRequest
    searchReqInfo: cmsApi_getSearchRequestInfo
    createHomeScreenBatchReqInfo: cmsApi_createHomeScreenBatchRequestInfo
    createMyStuffScreenBatchReqInfo: cmsApi_createMyStuffScreenBatchReqInfo
    createHomeScreenBatchRequestInfoForContainers: cmsApi_createHomeScreenBatchRequestInfoForContainers

    ' private
    createAuthRequest: cmsApi_createAuthRequest
    setImageParams: cmsApi_setImageParams
    setTupianPosterParam: cmsApi_setTupianPosterParam
    setTupianLandscapeParam: cmsApi_setTupianLandscapeParam
    setTupianVitgParam: cmsApi_setTupianVitgParam
    getWindowInfo: cmsApi_getWindowInfo
    getFullCategoryId: cmsApi_getFullCategoryId
    getVideoResources: cmsApi_getVideoResources
  }

  cmsApi = {}
  cmsApi.append(apiUtils)
  cmsApi.append(defaultValues)
  return cmsApi

End Function


Function cmsApi_setUtmCampaignConfig(utmCampaignConfig)
  m.utmCampaignConfig = utmCampaignConfig
End Function


Function cmsApi_getRelatedContentRequestInfo(contentId, bKidsMode = false)
  url = m.constants.urls.cms.relatedContent + "/" + contentId + "/related"
  options = m.getCommonOptions()
  options.params["isKidsMode"] = bKidsMode
  options.params["video_resources"] = m.getVideoResources()
  options.params = m.setTupianPosterParam(options.params)

  return {
    url: url
    options: options
  }
End Function


' @passedOptions: assocArray, options to be added to the request object as created by Request().createAsync()
Function cmsApi_getUpNextContentRequestInfo(contentId, passedOptions)
  url = m.constants.urls.cms.upNextContent + "/" + contentId + "/next"
  options = m.getCommonOptions()
  params = options.params
  headers = options.headers
  'adding accept-version=6.0.0 in header will include series recommendations at the end of a movie
  headers["accept-version"] = "6.0.0"
  params["video_resources"] = m.getVideoResources()
  params["limit_resolutions"] = m.constants.player.limitResolutions

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
  options = m.getCommonOptions()

  options.params["content_id"] = contentId
  options.params["isKidsMode"] = bKidsMode
  options.params["includeChannels"] = includeChannels
  options.params["video_resources"] = m.getVideoResources()
  options.params["limit_resolutions"] = m.constants.player.limitResolutions
  options.params = m.setTupianLandscapeParam(options.params)
  capability = formatJson({"content_types" :["se"]})
  options.headers.append({"x-capability": capability})

  return {
    url: m.constants.urls.cms.singleContent
    options: options
  }
End Function


Function cmsApi_getThumbnailsRequestInfo(contentId)
  url = m.constants.urls.cms.thumbnails + "/" + contentId + "/thumbnail_sprites"
  options = m.getCommonOptions()
  options.params["type"] = "5x"
  options.params["max_width"] = m.constants.deviceInfo.displayWidth
  return {
    url: url
    options: options
  }
End Function


'''''''''''''''''''''
' cmsApi_getCategoriesListRequestInfo()
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
'
Function cmsApi_getCategoriesListRequestInfo(bKidsMode = false)
  options = {
    params: {}
    headers: {}
  }

  options.headers["x-tubi-include-browser-list"] = "true"
  options.params["include_browser_list"] = true
  options.params["contents_limit"] = 0
  options.params["include_empty_history"] = "false"
  options.params["include_empty_queue"] = "false"

  return m.homeScreenReqInfo(bKidsMode, options)
End Function


'''''''''''''''''''''
' homeScreenReq()
'

' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
' @passedOptions: assocArray, options that are used to create a request (ie, headers, params, method, etc.)
'                 see request.brs for more info
Function cmsApi_getHomeScreenRequestInfo(bKidsMode = false, passedOptions = {})

  options = m.getCommonOptions()
  params = options.params
  headers = options.headers
  headers["Accept-Version"] = "6.0.0"

  url = m.constants.urls.tensor.homescreen

  params["include_empty_history"] = true
  params["include_empty_queue"] = true
  params["include_channels"] = true
  params["include_sponsorships"] = true
  params["is_kids_mode"] = bKidsMode
  ' content_mode is mandatory param and its value needs to be passed as empty for fetching homescreen content
  params["content_mode"] = "" ' default contentMode

  if passedOptions.params <> invalid AND passedOptions.params["content_mode"] <> invalid AND passedOptions.params["content_mode"] <> ""
    ' This will be overwritten by the same value later in this function
    ' when we append the passedOptions.params to params. We add it here so the default value
    ' is not used in the following logic, if a value was passed in for "contentMode"
    params["content_mode"] = passedOptions.params["content_mode"]
  end if

  if params["content_mode"] <> m.constants.ui.contentMode.linear
    ' don't send the Tupian image params for homescreen requests that are contentMode = "linear"
    imageParamTypes = [
      "poster"
      "landscape"
      "vitg"
    ]
    params = m.setImageParams(imageParamTypes, options.params)
  end if

  utmCampaignConfig = m.utmCampaignConfig
  if isString(utmCampaignConfig) = true then
    params["utm_campaign_config"] = utmCampaignConfig
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


' @categoryId, string, the UAPI id for the category
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
' @passedOptions: assocArray, options that are used to create a request (ie, headers, params, method, etc.)
'                 see request.brs for more info
' @imageParamTypes: Array, What image types/sizes should be requested from the backend. If none are passed, then a default set of types will be used.
Function cmsApi_getCategoryRequestInfo(categoryId, bKidsMode = false, passedOptions = {}, imageParamTypes = invalid)
  options = m.getCommonOptions()
  params = options.params

  url = m.constants.urls.tensor.container + "/" + categoryId

  params["is_kids_mode"] = bKidsMode
  params["include_channels"] = true
  params["cursor"] = 0
  params["include_sponsorships"] = true
  params["contents_limit"] = m.constants.performance.categoryGridList.finalBlockSize

  if passedOptions.params <> invalid AND isNonEmptyString(passedOptions.params.content_mode) = true
    params["content_mode"] = passedOptions.params.content_mode
  end if

  utmCampaignConfig = m.utmCampaignConfig
  if isString(utmCampaignConfig) = true then
    params["utm_campaign_config"] = utmCampaignConfig
  end if

  if imageParamTypes = invalid
    imageParamTypes = [
      "poster"
      "landscape"
      "vitg"
    ]
  end if

  params = m.setImageParams(imageParamTypes, params)

  headers = options.headers
  headers["Accept-Version"] = "6.0.0"

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
    id: categoryId
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
  return m.createAuthRequest(url, m.constants.reqNames.getSearchScreen, options)
End Function


' @searchText: string, the text the user is attempting to search for
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
Function cmsApi_getSearchRequestInfo(searchText, bKidsMode = false)
  url = m.constants.urls.search
  options = m.getCommonOptions()
  options.params["search"] = searchText
  options.params["is_kids_mode"] = bKidsMode
  options.params = m.setTupianPosterParam(options.params)

  if bKidsMode = false
    'setting the include_linear param to true will enable the linear content available for search screen from backend
    options.params["include_linear"] = true
  end if

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
'                      Accepted values are "poster", "landscape", "landscapeLarge", "vitg"
' @existingParams: assocArray, any parameters that have already been defined that need to be added to
Function cmsApi_setImageParams(imageTypes, existingParams = {})
  posterSize = m.constants.ui.imageSizes.poster
  landscapeSize = m.constants.ui.imageSizes.landscape
  landscapeLargeSize = m.constants.ui.imageSizes.landscapeLarge
  vitgSize = m.constants.ui.imageSizes.vitg

  for each imageType in imageTypes
    if imageType = "poster"
      '//Tell backend to provide a specific sized image
      existingParams["images[poster_tb]"] = "w" + posterSize[0].ToStr() + "h" + posterSize[1].ToStr() + "_poster"
    else if imageType = "landscape"
      existingParams["images[landscape_tb]"] = "w" + landscapeSize[0].ToStr() + "h" + landscapeSize[1].ToStr() + "_landscape"
    else if imageType = "landscapeLarge"
      existingParams["images[landscapeLarge_tb]"] = "w" + landscapeLargeSize[0].ToStr() + "h" + landscapeLargeSize[1].ToStr() + "_landscape"
    else if imageType = "vitg"
      existingParams["images[vitg_tb]"] = "w" + vitgSize[0].ToStr() + "h" + vitgSize[1].ToStr() + "_hero"
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
  return m.setImageParams(["vitg"], existingParams)
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


' cmsApi_createHomeScreenBatchRequestInfo
'
' @homeScreen: roSGNode, homescreen
' @index: integer
' @bKidsMode : boolean
' @isSignedInUser: boolean, value based on user loggedIn or not
' @uiMode: string, one of the allowed values from constants.ui.modes
'
' returns batch requests
Function cmsApi_createHomeScreenBatchRequestInfo(homeScreen, index, bKidsMode = false, isSignedInUser = false, uiMode="standard")

  m.categoryWindowSize = m.constants.performance.categoryGridList.categoryWindowSize

  reqName = m.constants.reqNames.getCategory

  requests = []
    'Determine the window start and window size for lazy loading
  windowInfo = m.getWindowInfo(homeScreen, index)
  if windowInfo <> invalid
    'Create requests for each category in the window
    for i = windowInfo.start to (windowInfo.start + windowInfo.size)-1
      category = homeScreen.content.getChild(i)
      if category <> invalid
        categoryReqInfo = invalid
        if category.state = "partial" or category.state = "none"

          categoryId = m.getFullCategoryId(category)

          if isNonEmptyString(categoryId) = true
            tubiLog("CategoryGridList.fetch whole: Asking GeneralTask for " + categoryId)

            options = {
              params: {}
            }

            if homeScreen.contentMode = m.constants.ui.contentMode.homescreen
              contentModeValue = ""
            else
              contentModeValue = homeScreen.contentMode
            end if

            contentModeParam = {
              "content_mode": contentModeValue
            }

            options.params.append(contentModeParam)
            categoryReqInfo = m.categoryReqInfo(categoryId, bKidsMode, options)
            categoryReqInfo.requestType = reqName
            categoryReqInfo.responseType = "node"
            categoryReqInfo.isSignedInUser = isSignedInUser
            categoryReqInfo.screenId = m.constants.ui.screenIds.homeScreen
            categoryReqInfo.uiMode = uiMode
          end if

        end if
        if categoryReqInfo <> invalid then
          requests.push(categoryReqInfo)
          category.state = "loading"
        end if
      end if
    end for

  end if

  return requests

End Function


' cmsApi_createMyStuffScreenBatchReqInfo
' @sideEffect: In addition to creating the batch request, this function will also set the state of the categories within the passed content
' param to "loading"
'
' @content: roSGNode, A parent ContentNode containing a child node for each container to be fetched.
'   Each child node should be of a CategoryContentNode type, with the ID assigned to the desired constant that maps
'   to a container id on the backend: i.e. constants.ui.categoryIds.queue
' @bKidsMode : boolean
' @isSignedInUser: boolean, value based on user loggedIn or not
'
' returns batch requests
Function cmsApi_createMyStuffScreenBatchReqInfo(content, bKidsMode = false, isSignedInUser = false)

  reqName = m.constants.reqNames.getMyStuffContainers

  requests = []
  'Create requests for each category in the window
  for i = 0 to content.getChildCount() - 1
    category = content.getChild(i)
    if category <> invalid
      categoryReqInfo = invalid

      if category.state = "partial" OR category.state = "none"
        categoryId = m.getFullCategoryId(category)

        if isNonEmptyString(categoryId) = true
          options = {
            params: {}
          }
          imageParamTypes = [
            "poster"
            "landscapeLarge"
          ]
          categoryReqInfo = m.categoryReqInfo(categoryId, bKidsMode, options, imageParamTypes)
          categoryReqInfo.requestType = reqName
          categoryReqInfo.responseType = "node"
          categoryReqInfo.isSignedInUser = isSignedInUser
        end if
      end if

      if categoryReqInfo <> invalid then
        requests.push(categoryReqInfo)
        category.state = "loading"
      end if
    end if
  end for

  return requests
End Function



'Helper function to retrieve the starting index for the window to be loaded, as well as the number of categories in the window
'
'@homescreen: roSGNode, the node for homescreen
'@index: integer, the index of the category within the category grid
'
'Returns an assocArray with the keys: "start", "size"
Function cmsApi_getWindowInfo(homescreen, index)

  currentCategory = homescreen.content.getChild(index)
  if currentCategory <> invalid
    windowSize = m.categoryWindowSize
    if currentCategory.state = "partial" or currentCategory.state = "none"
      windowStart = (index \ m.categoryWindowSize) * m.categoryWindowSize
      if (index + 1) MOD m.categoryWindowSize = 0
        ' if the user lands on an empty category that is also the last category in its window,
        ' add some more categories to the batch in order to fill the "next" category
        windowSize = m.categoryWindowSize + (m.categoryWindowSize \ 2)
      end if
    else
      ' attempt to load the current window, or next window depending on the index of the current category
      nextBatchIndex = (m.categoryWindowSize \ 2)
      windowStart = ((index + m.categoryWindowSize - (nextBatchIndex)) \ (m.categoryWindowSize)) * m.categoryWindowSize
    end if

    return {
      start: windowStart
      size: windowSize
    }
  end if
  return invalid
End Function


'''''''''''''''''''''
' cmsApi_getFullCategoryId
'
'
' Helper function to build category ids for nested categories that matrix API can recognize
' @category: sgNode, a CategoryContentNode
' if a nested category returns an id in the form of 'parentCat/sub/childCat'
' if not a nested category, returns the categoryId
' if there is no categoryId, returns invalid
Function cmsApi_getFullCategoryId(category)
  categoryId = invalid
  if type(category) = "roSGNode" AND category.id <> ""
    categoryId = category.id
    if category.parentId <> invalid AND category.parentId <> ""
      categoryId = category.parentId + "/sub/" + category.id
    end if
  end if
  return categoryId
End Function



' This Function will pull the contents for container array
' @containerIds: Array of container ids
' @contentMode: one of enum values constants.ui.contentMode
' @bKidsMode : boolean
' @isSignedInUser: boolean, value based on user loggedIn or not
' @uiMode: string, one of the allowed values from constants.ui.modes
'
' returns batch requests
Function cmsApi_createHomeScreenBatchRequestInfoForContainers(containerIds, contentMode = "", bKidsMode = false, isSignedInUser = false, uiMode="standard", screenId="")

  reqName = m.constants.reqNames.getCategory
  if screenId = ""
    screenId = m.constants.ui.screenIds.homeScreen
  end if

  requests = []

    for each containerId in containerIds
      categoryReqInfo = invalid
      if isNonEmptyString(containerId) = true
        options = {
          params: {}
        }

        contentModeParam = {
          "content_mode": contentMode
        }

        options.params.append(contentModeParam)
        categoryReqInfo = m.categoryReqInfo(containerId, bKidsMode, options)
        categoryReqInfo.requestType = reqName
        categoryReqInfo.responseType = "node"
        categoryReqInfo.isSignedInUser = isSignedInUser
        categoryReqInfo.screenId = screenId
        categoryReqInfo.uiMode = uiMode
      end if

      if categoryReqInfo <> invalid then
        requests.push(categoryReqInfo)
      end if
    end for

  return requests

End Function


' cmsApi_getVideoResources returns video resources order based on experiment response
Function cmsApi_getVideoResources()

  if m.experiments <> invalid AND m.experiments.getExperimentResource("roku_hlsv6", "roku_hlsv6_v1").enabled = true
    videoResources = m.constants.player.drmOrderHlsv6
  else
    videoResources = m.constants.player.drmOrder
  end if

  return videoResources
End Function
