' Thin wrapper for the old UAPI user_device requests and the new account API requests
Function UserDeviceApi(constants, apiUtils)

  defaultValues = {
    ' dependencies
    constants: constants

    ' public
    emailExistsReqInfo: userDeviceApi_emailExistsReqInfo
    signUpReqInfo: userDeviceApi_signUpReqInfo
    signInReqInfo: userDeviceApi_signInReqInfo
    deviceRegisterInfo: userDeviceApi_deviceRegisterInfo
    checkBirthdayInfo: userDeviceApi_checkBirthdayInfo
    patchSettingsInfo: userDeviceApi_patchSettingsInfo
    setContentRating: userDeviceApi_setContentRating
    magicLink: userDeviceApi_magicLink
    deleteHistory: userDeviceApi_deleteHistory
    queryStatusOfMagicLink: userDeviceApi_queryStatusOfMagicLink
    updateParentalRatingReqInfo: userDeviceApi_updateParentalRatingReqInfo
    removeFromQueueReqInfo: userDeviceApi_removeFromQueueReqInfo
    addToQueueReqInfo: userDeviceApi_addToQueueReqInfo
    getQueueReqInfo: userDeviceApi_getQueueReqInfo
    getHistoryReqInfo: userDeviceApi_getHistoryReqInfo
    getAddHistoryRequestInfo: userDeviceApi_getAddHistoryRequestInfo

    ' preference related methods.
    createUserSettingsReqInfo: userDeviceApi_createUserSettingsReqInfo
    createDeviceSettingsReqInfo: userDeviceApi_createDeviceSettingsReqInfo
    createUserAndDeviceSettingsBatchRequests: userDeviceApi_createUserAndDeviceSettingsBatchRequests
    createPatchUserSettingsReqInfo: userDeviceApi_createPatchUserSettingsReqInfo
    createPatchDeviceSettingsReqInfo: userDeviceApi_createPatchDeviceSettingsReqInfo
  }

  userDeviceApi = {}
  userDeviceApi.append(apiUtils)
  userDeviceApi.append(defaultValues)
  return userDeviceApi

End Function


''''''''''''''''''''''
'emailExistsReqInfo()
'
Function userDeviceApi_emailExistsReqInfo(passedOptions = {})
  url = m.constants.urls.account.emailExists
  options = m.getCommonOptions()
  if passedOptions.params <> invalid
    options.params["email"] = passedOptions.params.email
  end if
  return {
    url: url
    options: options
  }
End Function


''''''''''''''''''''''
'deleteHistory()
'
Function userDeviceApi_deleteHistory(historyId)
  url = m.constants.urls.lishi.viewHistory

  url = url + "/" + historyId

  options = m.getCommonOptions()
  options["method"] = m.constants.reqTypes.del

  return {
    url: url
    options: options
  }
End Function


''''''''''''''''''''''
'signUpReqInfo()
'
Function userDeviceApi_signUpReqInfo(passedOptions = {})
  url = m.constants.urls.account.signup
  options = {}
  headers = {}
  headers.append(m.getCommonOptions().headers)
  body = FormatJSON(passedOptions.body)
  options["method"] = m.constants.reqTypes.post
  options["body"] = body
  options["headers"] = headers
  return {
    url: url
    options: options
  }
End Function


''''''''''''''''''''''
'signInReqInfo()
'
Function userDeviceApi_signInReqInfo(passedOptions = {})
  url = m.constants.urls.account.login
  options = {}
  body = FormatJSON(passedOptions.body)
  headers = {}
  headers.append(m.getCommonOptions().headers)
  options["method"] = m.constants.reqTypes.post
  options["body"] = body
  options["headers"] = headers
  return {
    url: url
    options: options
  }
End Function


' send a POST with a birthdate, get back an age
' 422 HTTP response code means user is below the minimum allowed age in the US (COPPA)
' 451 HTTP response code means user is below the minimum allowed age for some international reason
'
' @birthdate: string, date formatted as "YYYY-MM-DD"
Function userDeviceApi_deviceRegisterInfo(birthdate)
  url = m.constants.urls.account.deviceRegister
  options = {}
  body = {
    platform: m.constants.platform
    device_id: m.constants.deviceInfo.deviceId
    birthday: birthdate
  }
  headers = {}
  headers.append(m.getCommonOptions().headers)
  body = FormatJSON(body)
  options["method"] = m.constants.reqTypes.post
  options["body"] = body
  options["headers"] = headers

  return {
    url: url
    options: options
  }
End Function


Function userDeviceApi_checkBirthdayInfo()
  url = m.constants.urls.account.checkBirthday

  options = {
    params: {}
    headers: {}
  }
  options.headers.append(m.getCommonOptions().headers)

  return {
    url: url
    options: options
  }
End Function


' @passedOptions: AA, options to be passed to TubiRequest().createAsync. The value for the "body"
'                     key must be an AA (which will be turned into a JSON string)
Function userDeviceApi_patchSettingsInfo(passedOptions)
  url = m.constants.urls.account.userSettings

  options = passedOptions

  if passedOptions <> invalid AND type(passedOptions.body) = "roAssociativeArray"
    options["body"] = FormatJSON(passedOptions.body)
  end if
  headers = {}
  headers.append(m.getCommonOptions().headers)
  options["method"] = m.constants.reqTypes.patch
  options["headers"] = headers
  return {
    url: url
    options: options
  }
End Function


' @email : string,  (either taken from roku account or user entered email)
Function userDeviceApi_magicLink(email)
  url = m.constants.urls.account.magicLink
  options = m.getCommonOptions()
  options.params["email"] = email
  options["method"] = m.constants.reqTypes.post
  return {
    url: url
    options: options
  }
End Function


'@uid: string, unique identifier generated through magicLink for each user
Function userDeviceApi_queryStatusOfMagicLink(uid)
  url = m.constants.urls.account.magicLink + "/" + uid
  options = m.getCommonOptions()
  options["method"] = m.constants.reqTypes.get
  return {
    url: url
    options: options
  }
End Function


' Set a rating for a given video ID
' @param sContentID: the ID of the video/series
' @param sRatingAction: string, user selection of like/dislike
'         like - associate title with a like (constants.ui.likeDislikeActions.like)
'         dislike - associate title with a dislike (constants.ui.likeDislikeActions.dislike)
'         remove-like - disassociate title with a like (constants.ui.likeDislikeActions.removeLike)
'         remove-dislike - disassociate title with a dislike (constants.ui.likeDislikeActions.removeDislike)
Function userDeviceApi_setContentRating(sContentID, sRatingAction)
  url = m.constants.urls.account.contentRating
  options = {}
  body = {
    action: sRatingAction,
    target: "title",
    data: [sContentID]
  }

  options["body"] = FormatJson(body)
  headers = {}
  headers.append(m.getCommonOptions().headers)
  options["method"] = m.constants.reqTypes.patch
  options["headers"] = headers
  return {
    url: url
    options: options
  }
End Function


'@parentalRating: integer, selected parentalRating from the settings screen
'password: string, user entered password
Function userDeviceApi_updateParentalRatingReqInfo(parentalRating, password)

  url = m.constants.urls.account.parentalRating
  options = {}
  headers = m.getCommonOptions().headers
  body = {
    parental_rating: parentalRating,
    password: password
  }
  options["method"] = m.constants.reqTypes.put
  options["body"] = FormatJson(body)
  options["headers"] = headers

  return {
    url: url
    options: options
  }
End Function


Function userDeviceApi_addToQueueReqInfo(userId, contentId, contentType, typeOfQueue)
  url = m.constants.urls.userQueues.queues

  options = {}
  headers = m.getCommonOptions().headers
  body = {
    content_id: contentId
    content_type: contentType
    type: typeOfQueue
  }

  options["method"] = m.constants.reqTypes.post
  options["body"] = FormatJson(body)
  options["headers"] = headers

  return {
    url: url
    options: options
  }
End Function


Function userDeviceApi_removeFromQueueReqInfo(bookmarkId, contentId, contentType)
  url = m.constants.urls.userQueues.queues
  options = m.getCommonOptions()
  options.params["queue_id"] = bookmarkId
  options.params["content_id"] = contentId
  options.params["content_type"] = contentType
  options["method"] = m.constants.reqTypes.del

  return {
    url: url
    options: options
  }
End Function


Function userDeviceApi_getQueueReqInfo()
  url = m.constants.urls.userQueues.queues
  options = m.getCommonOptions()
  options.method = m.constants.reqTypes.get
  options.params["page_enabled"] = false

  return {
    url: url
    options: options
  }
End Function


Function userDeviceApi_getHistoryReqInfo()
  url = m.constants.urls.lishi.viewHistory
  options = m.getCommonOptions()
  options.method = m.constants.reqTypes.get
  options.params["page_enabled"] = false

  return {
    url: url
    options: options
  }
End Function


' @content: roSGNode, content of Video Player
' @nowPos : integer, video position in seconds
'
' returns url & options for making API request
Function userDeviceApi_getAddHistoryRequestInfo(content as Object, nowPos as Integer) as Object
  url = m.constants.urls.lishi.viewHistory

  body = {
    content_id: content.id
    position: nowPos
  }

  contentType = m.constants.uapiContentTypes.movie
  parentId = content.parentId

  'set the parentId to an integer or invalid as needed (expect to receive it as a string which is not compatible with API)
  if isString(parentId) = true then
    if parentId.len() = 0
      body.parent_id = invalid  'is ok if parentId is invalid (ie. for movies)
      if content.type = m.constants.uapiContentTypes.sportsEvent
        contentType = m.constants.uapiContentTypes.sportsEvent
      end if
    else
      body.parent_id = parentId.toInt()
      contentType = m.constants.uapiContentTypes.episode
    end if
  else if isInteger(parentId) = true then
    body.parent_id = parentId
    contentType = m.constants.uapiContentTypes.episode
  else if content.type = m.constants.uapiContentTypes.sportsEvent
    body.parent_id = invalid
    contentType = m.constants.uapiContentTypes.sportsEvent
  else
    body.parent_id = invalid
  end if

  body.content_type = contentType

  options = m.getCommonOptions()
  options["body"] = FormatJSON(body)
  options["method"] = m.constants.reqTypes.post

  return {
    url: url
    options: options
  }
End Function


Function userDeviceApi_createUserAndDeviceSettingsBatchRequests()
  requests = []

  userSettingsReqInfo = m.createUserSettingsReqInfo()
  userSettingsReqInfo.id = "userSettingsReqInfo"
  userSettingsReqInfo.requestType = m.constants.reqNames.getPreferences
  userSettingsReqInfo.responseType = "assocarray"
  requests.push(userSettingsReqInfo)

  deviceSettingsReqInfo = m.createDeviceSettingsReqInfo()
  deviceSettingsReqInfo.id = "deviceSettingsReqInfo"
  deviceSettingsReqInfo.requestType = m.constants.reqNames.getPreferences
  deviceSettingsReqInfo.responseType = "assocarray"
  requests.push(deviceSettingsReqInfo)

  return requests
End Function


Function userDeviceApi_createUserSettingsReqInfo()
  options = {
    params: {
      platform: m.constants.platform
    }
  }

  return {
    url: m.constants.urls.account.userSettings
    options: options
  }
End Function


Function userDeviceApi_createDeviceSettingsReqInfo()
  options = {
    params: {
      platform: m.constants.platform
    }
  }

  return {
    url: m.constants.urls.account.deviceSettings
    options: options
  }
End Function


' @body: assocarray, contains a key value pair for ex: {"enable_video_preview": true}
Function userDeviceApi_createPatchUserSettingsReqInfo(body)
  headers = m.getCommonOptions().headers
  options = {
    method: m.constants.reqTypes.patch
    body: FormatJson(body)
    headers: headers
  }

  return {
    url: m.constants.urls.account.userSettings
    options: options
  }
End Function


' @body: assocarray, contains a key value pair for ex: {"enable_video_preview": true}
Function userDeviceApi_createPatchDeviceSettingsReqInfo(body)
  headers = m.getCommonOptions().headers
  options = {
    method: m.constants.reqTypes.patch
    body: FormatJson(body)
    headers: headers
  }

  return {
    url: m.constants.urls.account.deviceSettings
    options: options
  }
End Function
