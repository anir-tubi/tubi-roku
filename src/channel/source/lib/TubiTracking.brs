Function TubiTracking (constants, request, auth)
  return {
    constants: constants
    request: request
    auth: auth
    trackUserEvent: tubiTracking_trackUserEvent
    getTrackData: tubiTracking_getTrackData
    getUserTrackingRequest: tubiTracking_getUserTrackingRequest
  }
End Function


'@evt: assocArray: has the following fields
'           trackType: string, corresponds to one of the eventTypes found in getTrackData
'           value: dynamic, depends on the eventType
'           ctx: dynamic, depends on the eventType
'           extraCtx: dynamic, depends on the eventType
'           requestQ: a requestQueue object as created by TubiRequestQueue().create()
'
' please refer to the following url for more info on evt.value, evt.ctx, evt.extraCtx:
' https://tubitv.atlassian.net/wiki/pages/viewpage.action?spaceKey=EC&title=Analytics+Events
'
function tubiTracking_trackUserEvent(evt as Object)
  if evt.trackType <> invalid
    trackData = m.getTrackData(evt.trackType, evt.value, evt.ctx, evt.extraCtx)

    userRequest = m.getUserTrackingRequest(trackData)

    if userRequest <> invalid and evt.requestQ <> invalid
      evt.requestQ.pushRequest(userRequest)
    end if
  end if

end function


function tubiTracking_getTrackData(eventType as String, value=0 as Dynamic, ctx=invalid as Dynamic, extraCtx=invalid as Dynamic) as Object
  authInfo = m.auth.getAuthInfo()
  if authInfo <> invalid and authInfo.userId <> invalid
    userID = authInfo.userId
  else
    userID = 0
  end if

  eventTypes = {
    startApp: {
      value: m.constants.deviceInfo.userAgentModel
      key: "active"
      ctx: m.constants.deviceInfo.model
    }
    pageLoad: {
      value: value
      key: "page_load"
    }
    navigate: {
      value: value
      key: "navigate_to_page"
      ctx: ctx
    }
    navigateInPage: {
      value: value
      key: "navigate_within_page"
      ctx: ctx
    }    
    videoPlay: {
      value: value
      key: "start_video"
      ctx: ctx
      extraCtx: extraCtx
    }
    resumeAfterAds: {
      value: value
      key: "resume_after_break"
      ctx: ctx
      extraCtx: extraCtx
    }
    playProgress: {
      value: value
      key: "play_progress"
      ctx: ctx
      extraCtx: extraCtx
    }
    seek: {
      value: value
      key: "seek"
      ctx: ctx      
    }
    pauseToggle: {
      value: value
      key: "pause_toggle"
      ctx: ctx      
      extraCtx: extraCtx
    }
    subtitles: {
      value: value
      key: "subtitles_toggle"
      ctx: ctx
      extraCtx: extraCtx
    }    
    deepLink: {
      value: "deeplink"
      key: "referred"
      ctx: ctx
      extraCtx: extraCtx
    }
    addBookmark: {
      value: value
      key: "add_bookmark"
      ctx: ctx
    }
    deleteBookmark: {
      value: value
      key: "remove_bookmark"
    }
    registerFail: {
      value: value
      key: "register_device_fail"
      ctx: ctx
    }
    registerSuccess: {
      value: "/deviceregistration/code"
      key: "register_device_success"
    }
    signIn: {
      value: "email"
      key: "sign_in"
    }
    search: {
      value: value
      key: "search"
      ctx: "search_dialog"
    }
    experiment: {
      value: value
      key: "exposure"
      ctx: ctx
      extraCtx: extraCtx
    }
    startTrailer: {
      value: value
      key: "start_trailer"
    }
    generic: {
      value: value
      key: "generic_action"
      ctx: ctx
    }
  }

  trackData = CreateObject("roAssociativeArray")
  trackData.SetModeCaseSensitive()
  trackData.AddReplace("app_id", m.constants.appName + "-roku")
  trackData.AddReplace("key", eventTypes[eventType].key)
  if eventTypes[eventType].value <> invalid
    trackData.AddReplace("value", eventTypes[eventType].value)
  end if
  if eventTypes[eventType].ctx <> invalid
    trackData.AddReplace("ctx", eventTypes[eventType].ctx)
  end if
  if eventTypes[eventType].extraCtx <> invalid
    trackData.AddReplace("extra_ctx", eventTypes[eventType].extraCtx)
  end if
  trackData.AddReplace("user_id", userID)
  trackData.AddReplace("device_id", m.constants.deviceInfo.deviceId)
  trackData.AddReplace("client_version", m.constants.deviceInfo.clientVersion)
  'trackData looks like:
  ' trackData = {
  '   app : "tubitv-roku",
  '   value : eventTypes[eventType].value
  '   key : eventTypes[eventType].key
  '   ctx : eventTypes[eventType].ctx
  '   extra_ctx: eventTypes[eventType].extraCtx
  '   user_id : userID
  '   device_id : m.constants.deviceInfo.deviceId
  '   client_version: m.constants.deviceInfo.clientVersion
  ' }.SetModeCaseSensitive()
  return trackData
end function



'@trackData: assocArray, object returned from m.getTrackData()
function tubiTracking_getUserTrackingRequest(trackData as Object) as Object
  trackUrl = m.constants.urls.datascience.event

    options = {
      method: m.constants.reqTypes.post
      body: FormatJson(trackData)
      headers: {"Content-Type": "application/json"}
    }

    userRequest = m.request.createAsync(trackUrl, "track" + trackData.key, options)

    return userRequest
end function
