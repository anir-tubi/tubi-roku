Function TubiTracking (request)
  return {
    request: request
    trackEvent: tubiTracking_trackEvent
    getTrackingTags: tubiTracking_getTrackingTags
    getTrackData: tubiTracking_getTrackData
  }
End Function

' --------------------------------------------------------
' .trackEvent(evt)
' --------------------------------------------------------
function tubiTracking_trackEvent(evt)

  ' ------------AdUnit Events------------------
  if evt.trackType = "click" then
    For Each trackUrl in evt.adUnit.clickTrack
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      clickRequest = m.request.createAsync(trackUrl, "trackClick")
      evt.requestQ.pushRequest(clickRequest)
    end for

  else if evt.trackType = "imp" then
    For Each trackUrl in evt.adUnit.impTrack
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      impRequest = m.request.createAsync(trackUrl, "trackImp")
      evt.requestQ.pushRequest(impRequest)
    end for

  else if evt.trackType = "viewthru" then
    For Each trackUrl in evt.adUnit.viewthru[evt.adPercentage]
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      evt.adUnit.viewthru[evt.adPercentage] = "" ' making sure it doesn't get fired again
      viewThruRequest = m.request.createAsync(trackUrl, "trackViewThru")
      evt.requestQ.pushRequest(viewThruRequest)      
    end for

  'event tracking for non ad events
  else if evt.trackType <> invalid
    ' trackData = m.getTrackData(evt.trackType, evt.value, evt.ctx, evt.extraCtx)

    ' options = {
    '   method: "POST"
    '   body: FormatJson(trackData)
    ' }

    ' userRequest = m.request.createAsync(trackUrl, "track" + evt.trackType, options)
    ' evt.requestQ.pushRequest(userRequest)
  end if

end function

' --------------------------------------------------------
' .getTrackingTags (xml_tags)
' --------------------------------------------------------
function tubiTracking_getTrackingTags(xml_tags)
  ret = []
  count = 0
  For Each item in xml_tags
      ret[count] = item.GetText()
      count = count + 1
  next
  return ret
end function


'function tubiTracking_getTrackData(eventType, contentId = 0, progressPercent = 0, playerPosition = 0, deepLinkSource = "", errorMessage = "")
function tubiTracking_getTrackData(eventType, value=0, ctx=invalid, extraCtx=invalid)
  authInfo = m.getAuthInfo()
  if authInfo <> invalid and authInfo.userId <> invalid
    userID = authInfo.userId
  else
    userID = 0
  end if

  eventTypes = {
    startApp: {
      value: m.deviceInfo.userAgent + " " + m.deviceInfo.model
      key: "active"
      ctx: m.deviceInfo.model
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
    }
    subtitles: {
      value: value
      key: "subtitles_toggle"
      ctx: ctx
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
    registerFail:{
      key: "register_device_fail"
      value: value
    }
    registerSuccess:{
      key: "register_device_success"
      value: value
    }
    search:{
      value: value
      key: "search"
      ctx: "search_dialog"
    }
  }

  trackData = CreateObject("roAssociativeArray")
  trackData.SetModeCaseSensitive()
  trackData.AddReplace("app_id", m.appName + "-roku")
  trackData.AddReplace("value", eventTypes[eventType].value)
  trackData.AddReplace("key", eventTypes[eventType].key)
  if eventTypes[eventType].ctx <> invalid
    trackData.AddReplace("ctx", eventTypes[eventType].ctx)
  end if
  if eventTypes[eventType].extraCtx <> invalid
    trackData.AddReplace("extra_ctx", eventTypes[eventType].extraCtx)
  end if
  trackData.AddReplace("user_id", userID)
  trackData.AddReplace("device_id", m.deviceInfo.deviceId)
  'trackData looks like:
  ' trackData = {
  '   app : "tubitv-roku",
  '   value : eventTypes[eventType].value
  '   key : eventTypes[eventType].key
  '   ctx : eventTypes[eventType].ctx
  '   extra_ctx: eventTypes[eventType].extraCtx
  '   userID : userID
  '   deviceID : m.deviceInfo.deviceId
  ' }.SetModeCaseSensitive()
  return trackData
end function