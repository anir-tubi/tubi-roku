' Thin wrapper for CMS API, Autopilot API and Search API requests.  Collected here to facilitate easy
' integration tests
Function CmsApi(constants, apiUtils, experiments=invalid)

  defaultValues = {
    ' dependencies
    constants: constants
    experiments: experiments

    ' public
    setUtmCampaignConfig: cmsApi_setUtmCampaignConfig
    createRelatedContentReqInfo: cmsApi_createRelatedContentReqInfo
    createUpNextContentReqInfo: cmsApi_createUpNextContentReqInfo
    createSingleContentReqInfo: cmsApi_createSingleContentReqInfo
    createThumbnailsReqInfo: cmsApi_createThumbnailsReqInfo
    createCategoriesListReqInfo: cmsApi_createCategoriesListReqInfo
    createHomeScreenReqInfo: cmsApi_createHomeScreenReqInfo
    createMiniHomeScreenOnPlayerReqInfo: cmsApi_createMiniHomeScreenOnPlayerReqInfo
    createCategoryReqInfo: cmsApi_createCategoryReqInfo
    createSearchReqInfo: cmsApi_createSearchRequestInfo
    createHomeScreenBatchReqInfo: cmsApi_createHomeScreenBatchRequestInfo
    createMyStuffScreenBatchReqInfo: cmsApi_createMyStuffScreenBatchReqInfo
    createHomeScreenBatchRequestInfoForContainers: cmsApi_createHomeScreenBatchRequestInfoForContainers
    createContainerForScreensaverReqInfo: cmsApi_createContainerForScreensaverReqInfo
    createHomeScreenContainerIdsForScreensaverReqInfo: cmsApi_createHomeScreenContainerIdsForScreensaverReqInfo

    ' private
    setImageParams: cmsApi_setImageParams
    setTupianPosterParam: cmsApi_setTupianPosterParam
    setTupianLandscapeParam: cmsApi_setTupianLandscapeParam
    setTupianBackgroundParam: cmsApi_setTupianBackgroundParam
    getWindowInfo: cmsApi_getWindowInfo
    getFullCategoryId: cmsApi_getFullCategoryId
    createCategoryRequestInfo: cmsApi_createCategoryRequestInfo
  }

  cmsApi = {}
  cmsApi.append(apiUtils)
  cmsApi.append(defaultValues)
  return cmsApi

End Function


Function cmsApi_setUtmCampaignConfig(utmCampaignConfig)
  m.utmCampaignConfig = utmCampaignConfig
End Function


Function cmsApi_createRelatedContentReqInfo(contentId, bKidsMode = false)
  options = m.getCommonOptions()
  options.params["isKidsMode"] = bKidsMode
  options.params["video_resources"] = m.constants.player.drmOrderWidevineHlsv6
  options.params = m.setTupianPosterParam(options.params)
  options.params["content_id"] = contentId
  url = m.constants.urls.autopilot.relatedContent

  return {
    url: url
    options: options
  }
End Function


' @passedOptions: assocArray, options to be added to the request object as created by Request().createAsync()
Function cmsApi_createUpNextContentReqInfo(passedOptions)
  url = m.constants.urls.autopilot.upNextContent

  options = m.getCommonOptions()
  params = options.params
  headers = options.headers
  params["video_resources"] = m.constants.player.drmOrderWidevineHlsv6
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
  options.params = m.setTupianPosterParam(options.params)
  options.params = m.setTupianLandscapeParam(options.params)

  return {
    url: url
    options: options
  }
End Function


Function cmsApi_createSingleContentReqInfo(contentId, includeChannels=false, bKidsMode = false)
  options = m.getCommonOptions()

  options.params["content_id"] = contentId
  options.params["isKidsMode"] = bKidsMode
  options.params["includeChannels"] = includeChannels
  options.params["video_resources"] = m.constants.player.drmOrderWidevineHlsv6
  options.params["limit_resolutions"] = m.constants.player.limitResolutions
  options.params = m.setTupianLandscapeParam(options.params)
  options.params = m.setTupianBackgroundParam(options.params)

  capability = formatJson({"content_types" :["se"]})
  options.headers.append({"x-capability": capability})
  url = m.constants.urls.content.singleContent

  return {
    url: url
    options: options
  }
End Function


Function cmsApi_createThumbnailsReqInfo(contentId)
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
' cmsApi_createCategoriesListReqInfo()
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
'
Function cmsApi_createCategoriesListReqInfo(bKidsMode = false)
  options = {
    params: {}
    headers: {}
  }

  options.headers["x-tubi-include-browser-list"] = "true"
  options.params["include_browser_list"] = true
  options.params["contents_limit"] = 0
  options.params["include_empty_history"] = "false"
  options.params["include_empty_queue"] = "false"

  return m.createHomeScreenReqInfo(bKidsMode, options)
End Function


'''''''''''''''''''''
' homeScreenReq()
'

' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
' @passedOptions: assocArray, options that are used to create a request (ie, headers, params, method, etc.)
'                 see request.brs for more info
Function cmsApi_createHomeScreenReqInfo(bKidsMode = false, passedOptions = {})

  options = m.getCommonOptions()
  params = options.params
  headers = options.headers
  headers["Accept-Version"] = "6.0.0"

  url = m.constants.urls.tensor.cdn.homescreen

  params["include_empty_history"] = true
  params["include_empty_queue"] = true
  params["include_channels"] = true
  params["include_sponsorships"] = true
  params["is_kids_mode"] = bKidsMode
  ' content_mode is mandatory param and its value needs to be passed as empty for fetching homescreen content
  params["content_mode"] = "" ' default contentMode

  'passing device advertiser id to homescreen request for home screen personalization
  params["idfa"] = m.constants.deviceInfo.deviceAdId

  if passedOptions.params <> invalid AND passedOptions.params["content_mode"] <> invalid AND passedOptions.params["content_mode"] <> ""
    ' This will be overwritten by the same value later in this function
    ' when we append the passedOptions.params to params. We add it here so the default value
    ' is not used in the following logic, if a value was passed in for "contentMode"
    params["content_mode"] = passedOptions.params["content_mode"]
  end if

  if params["content_mode"] <> m.constants.ui.contentMode.linear
    ' don't send the Tupian image params for homescreen requests that are contentMode = "linear"
    if m.experiments <> invalid AND m.experiments.getExperimentResource("roku_spotlight_carousel", "roku_spotlight_carousel_v1").enabled = true
      imageParamTypes = [
        "poster"
        "landscape"
        "hero"
        "background"
        "title"
        "spotlightLandscape"
      ]
    else
      imageParamTypes = [
        "poster"
        "landscape"
        "hero"
        "background"
      ]
    end if

    params = m.setImageParams(imageParamTypes, options.params, m.constants.ui.screenIds.homeScreen)
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
' MiniHomeScreenReqInfo()
'

' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
' @passedOptions: assocArray, options that are used to create a request (ie, headers, params, method, etc.)
'                 see request.brs for more info
Function cmsApi_createMiniHomeScreenOnPlayerReqInfo(bKidsMode = false, passedOptions = {})

  options = m.getCommonOptions()
  params = options.params
  headers = options.headers
  headers["Accept-Version"] = "6.0.0"
  url = m.constants.urls.tensor.cdn.homescreen
  params["is_kids_mode"] = bKidsMode
  ' Disabling showing fox live events in browse while watching.
  params["include_fox_live_events"] = false
  ' content_mode is mandatory param and its value needs to be passed as empty for fetching homescreen content
  params["content_mode"] = "" ' default contentMode

  'passing device advertiser id to homescreen request for home screen personalization
  params["idfa"] = m.constants.deviceInfo.deviceAdId

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
      "hero"
      "background"
    ]
    params = m.setImageParams(imageParamTypes, options.params, m.constants.ui.screenIds.homeScreen)
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
' @screenId: String, id of the screen to which is requesting to get large poster sizes from Tupian.
' @containerGridItemType: String, gridItemType of the container for which we are making the request.
Function cmsApi_createCategoryReqInfo(categoryId, bKidsMode = false, passedOptions = {}, imageParamTypes = invalid, screenId = "", containerGridItemType = invalid)
  options = m.getCommonOptions()
  params = options.params
  url = m.constants.urls.tensor.cdn.container + "/" + categoryId

  params["is_kids_mode"] = bKidsMode
  params["include_channels"] = true
  params["cursor"] = 0
  params["include_sponsorships"] = true
  params["contents_limit"] = m.constants.performance.categoryGridList.finalBlockSize
  params["content_mode"] = ""

  utmCampaignConfig = m.utmCampaignConfig

  if isString(utmCampaignConfig) = true then
    params["utm_campaign_config"] = utmCampaignConfig
  end if

  if imageParamTypes = invalid
    if m.experiments <> invalid AND m.experiments.getExperimentResource("roku_spotlight_carousel", "roku_spotlight_carousel_v1").enabled = true AND categoryId = m.constants.ui.categoryIds.spotlight
      imageParamTypes = [
        "poster"
        "landscape"
        "hero"
        "background"
        "title"
        "spotlightLandscape"
      ]
    else
      imageParamTypes = [
        "poster"
        "landscape"
        "hero"
        "background"
      ]
    end if
  end if

  params = m.setImageParams(imageParamTypes, params, screenId, containerGridItemType)

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
    url: url
    options: options
  }
End Function


' @searchText: string, the text the user is attempting to search for
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
Function cmsApi_createSearchRequestInfo(searchText, bKidsMode = false)
  url = m.constants.urls.search
  options = m.getCommonOptions()
  options.params["search"] = searchText
  options.params["is_kids_mode"] = bKidsMode
  imageParamTypes = [
    "poster"
    "hero"
    "background"
  ]
  options.params = m.setImageParams(imageParamTypes, options.params, m.constants.ui.screenIds.searchScreen)

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
'                      Accepted values are "poster", "landscape", "hero", "background", "title", "spotlightLandscape"
' @existingParams: assocArray, any parameters that have already been defined that need to be added to
' @screenId: id of the screen.
' @containerGridItemType: String, gridItemType of the container for which we are making the request.
Function cmsApi_setImageParams(imageTypes, existingParams = {}, screenId = "", containerGridItemType = invalid)
  imageSizes = m.constants.ui.imageSizes
  posterSize = imageSizes.poster
  landscapeSize = imageSizes.landscape
  background = imageSizes.background
  title = imageSizes.title
  spotlightLandscape = imageSizes.spotlightLandscape
  fullScreenBackground = imageSizes.fullScreenBackground

  '//For now, ensure the large posters do not show up on the search screen
  isNonLargePostersScreen = (isNonEmptyString(screenId) = true AND screenId = m.constants.ui.screenIds.searchScreen)

  if isNonLargePostersScreen = false
    posterSize = imageSizes.largePoster
    landscapeSize = imageSizes.largeLandscape
  end if

  for each imageType in imageTypes
    if imageType = "poster"
      '//Tell backend to provide a specific sized image
      existingParams["images[poster_tb]"] = "w" + posterSize[0].ToStr() + "h" + posterSize[1].ToStr() + "_poster"
    else if imageType = "landscape"
      existingParams["images[landscape_tb]"] = "w" + landscapeSize[0].ToStr() + "h" + landscapeSize[1].ToStr() + "_landscape"
    else if imageType = "hero"
      existingParams["images[hero_tb]"] = "w" + landscapeSize[0].ToStr() + "h" + landscapeSize[1].ToStr() + "_hero"
    else if imageType = "background"
      if containerGridItemType <> m.constants.ui.gridItemTypes.spotlight
        existingParams["images[background_tb]"] = "w" + background[0].ToStr() + "h" + background[1].ToStr() + "_background"
      else
        existingParams["images[background_tb]"] = "w" + fullScreenBackground[0].ToStr() + "h" + fullScreenBackground[1].ToStr() + "_background"
      end if
    else if imageType = "title"
      existingParams["images[title_tb]"] = "w" + title[0].ToStr() + "h" + title[1].ToStr() + "_title"
    else if imageType = "spotlightLandscape"
      existingParams["images[spotlight_landscape_tb]"] = "w" + spotlightLandscape[0].ToStr() + "h" + spotlightLandscape[1].ToStr() + "_landscape"
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


' Wrapper around setImageParams for the specific case of only adding a Tupian background image param
' @existingParams: assocArray, any parameters that have already been defined that need to be added to
Function cmsApi_setTupianBackgroundParam(existingParams = {})
  return m.setImageParams(["background"], existingParams)
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

  requests = []
    'Determine the window start and window size for lazy loading
  windowInfo = m.getWindowInfo(homeScreen, index)
  if windowInfo <> invalid
    ' Adding spotlight or featured row into lazy loading.
    if homeScreen.purpleCarpetContent <> invalid
      category = homeScreen.purpleCarpetContent.getChild(0)
      if category <> invalid
        categoryReqInfo = m.createCategoryRequestInfo(category, homeScreen, bKidsMode, isSignedInUser, uiMode)
        
        if categoryReqInfo <> invalid then
          requests.push(categoryReqInfo)
          category.state = "loading"
        end if
      end if
    end if

    ' Adding spotlight or featured row into lazy loading.
    if homeScreen.spotlightContent <> invalid
      category = homeScreen.spotlightContent.getChild(0)
      if category <> invalid
        categoryReqInfo = m.createCategoryRequestInfo(category, homeScreen, bKidsMode, isSignedInUser, uiMode)
        
        if categoryReqInfo <> invalid then
          requests.push(categoryReqInfo)
          category.state = "loading"
        end if
      end if
    end if

    'Create requests for each category in the window
    for i = windowInfo.start to (windowInfo.start + windowInfo.size)-1
      category = homeScreen.content.getChild(i)
      if category <> invalid
        categoryReqInfo = m.createCategoryRequestInfo(category, homeScreen, bKidsMode, isSignedInUser, uiMode)
        
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

          '// Request both portrait and hero (landscape) image types.
          '//   For the landscape image, request the hero type instead of the regular landscape type, because
          '//   the regular landscape image most likely has the title embedded in the image, and the hero most likely does not.
          '//   The video titles within the Continue watching container have titles overlaid on top of the thumbnail, so using
          '//   a thumbnail w/o a tile would look better in this case.
          imageParamTypes = [
            "poster"
            "hero"
            "background"
          ]

          categoryReqInfo = m.createCategoryReqInfo(categoryId, bKidsMode, options, imageParamTypes)
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

        categoryReqInfo = m.createCategoryReqInfo(containerId, bKidsMode, options, invalid, screenId)
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


'@containerId: string, container id that we should request the list of items for
'@numberOfItemsPerContainer, integer - max number of items to request for each container request
Function cmsApi_createContainerForScreensaverReqInfo(containerId, numberOfItemsPerContainer, isKidsMode)
  reqInfo = m.createCategoryReqInfo(containerId, isKidsMode, {}, [])
  reqInfo.requestType = m.constants.reqNames.getScreensaverContainer

  params = {}
  params.contents_limit = numberOfItemsPerContainer

  imageWidth = 1920
  imageHeight = 1080
  if m.constants.deviceInfo.scaledUi = true then
    imageWidth = 1280
    imageHeight = 720
  end if

  params["images[landscape_tb]"] = "w" + imageWidth.toStr() + "h" + imageHeight.toStr() + "_hero"

  reqInfo.options.params.append(params)

  reqInfo.options.params.delete("include_channels")
  reqInfo.options.params.delete("include_sponsorships")

  return reqInfo
End Function


Function cmsApi_createHomeScreenContainerIdsForScreensaverReqInfo(kidsMode)
  reqInfo = m.createHomeScreenReqInfo(kidsMode)

  reqInfo.requestType = m.constants.reqNames.getScreensaverHomeScreenContainerIds

  params = {}
  params["group_size"] = 2 ' Only want first two container ids
  params["contents_limit"] = 0 ' Do not need any items
  reqInfo.options.params.append(params)

  return reqInfo
End Function


Function cmsApi_createCategoryRequestInfo(category, homeScreen, bKidsMode, isSignedInUser, uiMode)
  categoryReqInfo = invalid
  if category.state = "partial" or category.state = "none"
    reqName = m.constants.reqNames.getCategory

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

      categoryReqInfo = m.createCategoryReqInfo(categoryId, bKidsMode, options, invalid, m.constants.ui.screenIds.homeScreen, category.gridItemType)
      categoryReqInfo.requestType = reqName
      categoryReqInfo.responseType = "node"
      categoryReqInfo.isSignedInUser = isSignedInUser
      categoryReqInfo.screenId = m.constants.ui.screenIds.homeScreen
      categoryReqInfo.uiMode = uiMode
    end if

  end if

  return categoryReqInfo
End Function
