Function init()
  m.screenSaverScreen = m.top.findNode("screenSaverScreen")

  m.constants = getConstantsFromGlobal()

  m.auth = TubiAuth(m.constants, TubiRequest(m.constants.settings))
  m.apiUtils = ApiUtils(m.constants)

  m.global.addField("authInfo", "assocarray", false)
  m.global.authInfo = m.auth.getAuthInfoNoUpdate()

  m.guestUserHasAgeInfo = m.auth.getGuestUserHasAgeInfo()

  generalTask = createObject("roSGNode", "ControllerGeneralTask") ' initiate GeneralTask
  ' Initiate GeneralTaskModule by passing caller context.
  ' Calling GeneralTaskModule() will append methods to the local m.
  ' DO NOT overwrite m variable methods/properties which belongs to GeneralTaskModule.
  GeneralTaskModule(m, generalTask)

  countryCode = UCase(m.constants.deviceInfo.countryCode)
  ' In the US and Canada we use a preset list of containers but for others we use the first two rows from homescreen instead
  if countryCode = "US" OR countryCode = "CA" then
    if isKidsMode() = true then
      sendBatchRequestForContainers([
        m.constants.ui.categoryIds.featured
        m.constants.ui.categoryIds.mostPopular
      ], 30)
    else
      sendBatchRequestForContainers([
        m.constants.ui.categoryIds.featured
        m.constants.ui.categoryIds.movieNight
        m.constants.ui.categoryIds.seriesSpotlight
      ], 20)
    end if
  else
    sendHomescreenRequest()
  end if
End Function

'@containerIds: stringarray, list of container ids that we should request the list of items for
'@numberOfItemsPerContainer: integer, max number of items to request for each container request
Function sendBatchRequestForContainers(containerIds, numberOfItemsPerContainer)
  batchRequests = []

  for each containerId in containerIds
    request = getContainerRequestInfoForScreensaver(containerId, numberOfItemsPerContainer)
    batchRequests.push(request)
  end for

  m.makeBatchRequest({
    "requests": batchRequests
    "responseType": "array" ' Don't want to do nodearray as if a request fails it will be an AA response
    "successCallback": onContainersRequestsSuccessResponse
    "errorCallback": onRequestErrorResponse
  })
End Function


Function onContainersRequestsSuccessResponse(containerResponses)
  ' Loop through in reverse order and remove any failed responses before passing along
  for i = containerResponses.count() - 1 to 0 step -1
    containerResponse = containerResponses[i]
    if isNode(containerResponse) = false then
      containerResponses.delete(i)
    end if
  end for
  m.screenSaverScreen.containerResponses = containerResponses
End Function


Function sendHomescreenRequest()
  options = m.apiUtils.getCommonOptions()
  params = options.params
  params["is_kids_mode"] = isKidsMode() = true
  params["group_size"] = 2 ' Only want first two container ids
  m.makeRequest({
    url: m.constants.urls.tensor.homescreen
    requestType: m.constants.reqNames.getScreenSaverHomeScreenContainerIds
    options: options
    successCallback: onHomescreenRequestSuccessResponse
    errorCallback: onRequestErrorResponse
    responseType: "node"
  })
End Function


Function onHomescreenRequestSuccessResponse(response)
  sendBatchRequestForContainers(response.containerIds, 30)
End Function


Function onRequestErrorResponse(_response)
  tubiLog("Failed to load screen saver feed. Falling back")
  m.top.loadStatus = "failed"
End Function


Function isKidsMode()
  if isLoggedInUser() = true then
    authInfo = m.global.authInfo
    if authInfo.parentalrating <> invalid AND authInfo.parentalrating < 2 then
      return true
    end if
  else if m.guestUserHasAgeInfo.hasAge = false AND m.guestUserHasAgeInfo.expired = false then
    return true
  end if
  ' Note this currently returns an incomplete picture of kids mode being enabled for a user but is ok for now with Edward.
  return false
End Function


'@containerId: string, container id that we should request the list of items for
'@numberOfItemsPerContainer, integer - max number of items to request for each container request
Function getContainerRequestInfoForScreensaver(containerId, numberOfItemsPerContainer)
  options = m.apiUtils.getCommonOptions()
  params = options.params
  params["is_kids_mode"] = (isKidsMode() = true)
  params["contents_limit"] = numberOfItemsPerContainer

  imageWidth = 1920
  imageHeight = 1080
  if m.constants.deviceInfo.limitedUi = true then
    imageWidth = 1280
    imageHeight = 720
  end if
  params["images[landscape_tb]"] = "w" + imageWidth.toStr() + "h" + imageHeight.toStr() + "_hero"
  request = {
    "id": containerId
    "url": m.constants.urls.tensor.container + "/" + containerId
    "requestType": m.constants.reqNames.getScreenSaverContainer
    "options": options
  }
  return request
End Function
