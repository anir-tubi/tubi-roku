Function TubiTracking (constants, request, auth)
  return {
    constants: constants
    request: request
    auth: auth
    trackUserEvent: tubiTracking_trackUserEvent
    getClientEvent: tubiTracking_getClientEvent
    getUserTrackingRequest: tubiTracking_getUserTrackingRequest

    getAnalyticsRequestIdempotency: tubiTracking_getAnalyticsRequestIdempotency
    getAnalyticsTimestamp: tubiTracking_getAnalyticsTimestamp
    getAnalyticsUser: tubiTracking_getAnalyticsUser
    getAnalyticsDevice: tubiTracking_getAnalyticsDevice
    getAnalyticsApp: tubiTracking_getAnalyticsApp
    getAnalyticsConnection: tubiTracking_getAnalyticsConnection
    getAnalyticsEvent: tubiTracking_getAnalyticsEvent
    getAnalyticsPage: tubiTracking_getAnalyticsPage
    getAnalyticsComponent: tubiTracking_getAnalyticsComponent
    getAnalyticsDestinationComponent: tubiTracking_getAnalyticsDestinationComponent
    getAnalyticsSelector: tubiTracking_getAnalyticsSelector
    getAnalyticsTile: tubiTracking_getAnalyticsTile
    getAnalyticsAd: tubiTracking_getAnalyticsAd
    getAnalyticsHomePageContentMode: tubiTracking_getAnalyticsHomePageContentMode

    populateMessage: tubiTracking_populateMessage
    isEmptyValue: tubiTracking_isEmptyValue
    isNumeric: tubiTracking_isNumeric
    isString: tubiTracking_isString
    getHomePageContentModeMap: tubiTracking_getHomePageContentModeMap

    ' an AA structure of the valid "Oneofs" that are needed in various protos messages
    allOneofs: tubiTracking_getOneOfs()

    ' an AA map of page ids to their corresponding enum values for the LeftSideNavComponent Section
    sideNavPageMap: tubiTracking_getSideNavPageMap(constants)
  }
End Function


' Please see https://github.com/adRise/protos/analytics for details and event structures
' ClientEvent is the main event that we will be building, with different AppEvents added for each type of trackable even
'
' tubiTracking_trackUserEvent() is a wrapper around getClientEvent() that will take the generated client event and
' send it to the analytics server.
'
' @eventType: string: one of the fields defined in the "oneof" definition within AppEvent. For example: "active" or "page_load"
' @eventValues: assocArray, keys/values that correspond to the fields within the event type specified in @eventType
' @requestQueue: assocArray, a request queue as returned by TubiRequestQueue().create()
Function tubiTracking_trackUserEvent(eventType="", eventValues=invalid, requestQueue=invalid)
  if eventType <> ""
    trackData = m.getClientEvent(eventType, eventValues)
    userRequest = m.getUserTrackingRequest(eventType, trackData)
    if userRequest <> invalid AND requestQueue <> invalid
      requestQueue.pushRequest(userRequest)
    end if
  end if
End Function


Function tubiTracking_getClientEvent(eventType, eventValues) as Object
  clientEvent = {
    request: m.getAnalyticsRequestIdempotency()
    sent_timestamp: m.getAnalyticsTimestamp()
    user: m.getAnalyticsUser()
    device: m.getAnalyticsDevice(eventValues)
    app: m.getAnalyticsApp(eventValues)
    connection: m.getAnalyticsConnection(eventValues)
    event: m.getAnalyticsEvent(eventType, eventValues)
    ' location: {} 'roku unable to provide location
  }
  return clientEvent
End Function


'@eventType: string, the type of event we are sending, will be used as part of the request identifier
'@trackData: assocArray, object returned from m.getTrackData()
Function tubiTracking_getUserTrackingRequest(eventType, trackData) as Object
  trackUrl = m.constants.urls.analytics.singleEvent

    options = {
      method: m.constants.reqTypes.post
      body: FormatJson(trackData)
    }

    userRequest = m.request.createAsync(trackUrl, "track_" + eventType, options)

    return userRequest
End Function


' Returns an Idempotency message that fulfills the requirements of the "request" field on the ClientEvent message
' See protos.analytics.events.protos -> ClientEvent
Function tubiTracking_getAnalyticsRequestIdempotency()
  deviceInfo = CreateObject("roDeviceInfo")
  idempotency = {   'see protos.headers.request.proto -> Idempotency
    key: deviceInfo.GetRandomUUID()
    ' ttl_hint: "5s"    'see protos.google.protobuf.duration.proto -> Duration but not necessary to send
  }
  return idempotency
End Function


' Returns a Timestamp message that fulfills the requirements of the "sent_timestamp" field on the ClientEvent message
' See protos.analytics.events.protos -> ClientEvent
Function tubiTracking_getAnalyticsTimestamp()
  time = CreateObject("roDateTime")
  timestamp =  time.ToISOString()  'see protos.google.protobuf.timestamp.protos -> Timestamp
  return timestamp
End Function


' Returns a User message that fulfills the requirements of the "user" field on the ClientEvent message
' See protos.analytics.events.protos -> ClientEvent
' See protos.analytics.client.protos -> User
Function tubiTracking_getAnalyticsUser()
  authInfo = m.auth.getAuthInfo()
  if authInfo <> invalid AND m.isString(authInfo.userId) = true
    userId = authInfo.userId.toInt()
    authType = authInfo.authType
  else
    userId = 0
    authType = "NOT_AUTHED"
  end if

  user = {
    user_id: userId
    auth_type: authType
  }
  return user
End Function


' Returns a Device message that fulfills the requirement of the "device" field on the ClientEvent message
' See protos.analytics.events.protos -> ClientEvent
' See protos.analytics.client.protos -> Device
Function tubiTracking_getAnalyticsDevice(eventValues = invalid)

  currentLocale = {
    identifier : m.constants.deviceInfo.locale
    language : UCase(m.constants.deviceInfo.language)
  }

  device = {
    device_id: m.constants.deviceInfo.deviceId
    manufacturer: m.constants.deviceInfo.vendorName
    model: m.constants.deviceInfo.model
    os: "Roku OS"
    os_version: m.constants.deviceInfo.firmwareVersion
    user_agent: m.constants.deviceInfo.userAgent
    is_mobile: false
    device_height: m.constants.deviceInfo.displayHeight
    device_width: m.constants.deviceInfo.displayWidth
    advertiser_id: "00000000-0000-0000-0000-000000000000"
    locale: currentLocale
  }
  if m.constants.deviceInfo.isAdIdTrackingDisabled <> true AND (eventValues = invalid or eventValues.appMode <> "KIDS_MODE")
    device.advertiser_id = m.constants.deviceInfo.deviceAdId
  end if
  return device
End Function


' Returns an App message that fulfills the requirement of the "app" field on the ClientEvent message
' See protos.analytics.events.protos -> ClientEvent
' See protos.analytics.client.protos -> App
Function tubiTracking_getAnalyticsApp(eventValues)
  majorVersion = m.constants.deviceInfo.majorVersion
  minorVersion = m.constants.deviceInfo.minorVersion
  buildVersion = m.constants.deviceInfo.buildVersion

  app = {
    platform: m.constants.analyticsPlatform
    app_version: m.constants.deviceInfo.clientVersion
    app_version_numeric: (majorVersion.toInt() * 1000000) + (minorVersion.toInt() * 1000) + buildVersion.toInt()
    app_height: m.constants.deviceInfo.displayHeight
    app_width: m.constants.deviceInfo.displayWidth
    app_mode: eventValues.appMode
  }
  return app
End Function


' Returns an Connection message that fulfills the requirement of the "connection" field on the ClientEvent message
' See protos.analytics.events.protos -> ClientEvent
' See protos.analytics.client.protos -> Connection
Function tubiTracking_getAnalyticsConnection(eventValues)
  deviceInfo = CreateObject("roDeviceInfo")
  connectionType = deviceInfo.getConnectionType()
  if connectionType = "WiFiConnection"
    network = "WIFI"
  else if connectionType = "WiredConnection"
    network = "ETHERNET"
  else
    network = "UNKNOWN_NETWORK"
  end if

  connection = {
    network: network
    ' isp: ""   'not attainable by Roku device
    'carrier: ""  'not attainable by Roku device
  }

  if eventValues.nominal_speed <> invalid
    connection["nominal_speed"] = eventValues.nominal_speed   'expect this only to be the case for play_progress events
  end if

  return connection
End Function


' Returns an AppEvent message that fulfills the requirement of the "event" field on the ClientEvent message
' See protos.analytics.events.protos -> ClientEvent
' See protos.analytics.events.protos -> AppEvent
'
' @eventType: string, the name of the analytics event type we want to build (ie. "active", "page_load", etc.)
' @eventValues: assocArray, the information that will fill in the values for the keys of each event type as defined within the function.
'                           For example: if the eventType = "search", then eventValues = {query: "abc", search_type: "PAGE"}
'
' Note: eventTypes with keys that end in "Oneof" (ie. "pageOneof") will be overwritten with one of the allowed page types as
'       defined in events.protos. For example: with respect to the "page_load" event type, the eventValues should look like:
'
'       {
'         pageOneof: {
'           category_page: {
'             category_slug: ""
'           }
'         }
'         load_time: 125
'         status: "SUCCESS"
'       }
'
Function tubiTracking_getAnalyticsEvent(eventType, eventValues = {})
  ' The eventTypes below act as a source of truth for the varios information to be collected for each event type on the client.
  ' They should be updated as the protobufs spec is updated.
  eventTypes = {
    active: {
      resume: false 'optional
    }

    inactive: {
    }

    exit: {
    }

    referred: {
      referred_type: "" 'ReferredType enum
      campaign: ""
      source: ""
      medium: ""
      source_device_id: "" 'The source_device_id field is used to store device id of ios or android devices that deeplink to roku.
      content: ""   ' This is not the content deep linked to, but is intended to store promotional copy related to the deeplink.
                    ' The content field is also co-opted to store device ids of ios or android devices that deeplink to roku.
      pageOneof: {}  'a valid page type (see ReferredEvent in events.protos)
      ' adjust_id: ""   'not relevant for roku
    }

    page_load: {
      pageOneof: {}  'a valid page type (see PageLoadEvent in events.protos)
      load_time: -1
      status: ""  'ActionStatus enum
    }

    navigate_to_page: {
      pageOneof: {}  'page navigating from - a valid page type (see NavigateToPageEvent in events.protos)
      componentOneof: {} 'a valid component type (see NavigateToPageEvent in events.protos)
      dest_pageOneof: {} 'page navigating to - a valid page type (see NavigateToPageEvent in events.protos)
    }

    navigate_within_page: {
      pageOneof: {}  'a valid page type (see NavigateWithinPageEvent in events.protos)
      componentOneof: {} 'a valid component type (see NavigateWithinPageEvent in events.protos)
      means_of_navigation: "" 'MeansOfNavigation enum
      vertical_location: -1
      vertical_location_mode: ""  'LocationMode enum
      horizontal_location: -1
      horizontal_location_mode: ""  'LocationMode enum
      dest_componentOneof: {}  '(see dest_component in events.protos to see possible values. Right now it is just referring to top and side navigations )
    }

    bookmark: {
      contentOneOf: {} 'content message with either video_id or series_id
      pageOneof: {}  'a valid page type (see BookmarkEvent in events.protos)
      componentOneof: {} 'a valid component type (see BookmarkEvent in events.protos)
      op: ""  'Operation enum
    }

    explicit_feedback: {
      targetOneOf: {} 'a valid target, see ExplicitFeedbackEvent in events.protos.
      pageOneof: {}  'a valid page type (see ExplicitFeedbackEvent in events.protos)
    }

    search: {
      query: ""
      search_type: "" 'SearchType enum
    }

    start_video: {
      video_id: -1
      start_position: -1
      current_cdn: ""   'not possible for Roku client
      has_subtitles: false  'the video player will show subtititles at start
      is_livetv: false
      is_embedded: false
      is_fullscreen: true
      playback_source: ""
      video_resource_type: "" ' The type of video resource
      video_resource_url: "" 'The playable url in video resource
      video_player: ""  'VideoPlayer enum
    }

    play_progress: {
      video_id: -1
      position: -1   'ms
      view_time: -1  'ms
      playback_source: ""
      video_player: ""  'VideoPlayer enum
    }

    start_live_video: {
      video_id: -1
      current_cdn: ""   'not possible for Roku client
      has_subtitles: false  'the video player will show subtititles at start
      video_resource_url: "" 'The playable url in video resource
      video_resource_type: "" ' The type of video resource
      video_player: ""  'VideoPlayer enum
    }

    live_play_progress: {
      video_id: -1
      view_time: -1  'ms
      video_player: ""  'VideoPlayer enum
      page_type: "" 'current screen
    }

    seek: {
      video_id: -1
      from_position: -1  'ms
      to_position: -1    'ms
      video_player: ""  'VideoPlayer enum
    }

    pause_toggle: {
      video_id: -1
      pause_state: "" 'PauseState enum
      video_player: ""  'VideoPlayer enum
    }

    subtitles_toggle: {
      video_id: -1
      toggle_state: ""  'ToggleState enum
      language_code: ""  'LanguageCode enum
    }

    fullscreen_toggle: {  'Not used by Roku client
      video_id: -1
      toggle_state: "" 'ToggleState enum
    }

    auto_play: {   'This event is fired when a user interacts with the autoplay/Up Next UI, not when an autoplay occurs
      video_id: -1
      auto_play_action: "" 'AutoPlayAction enum
    }

    resume_after_break: {
      video_id: -1
      position: -1 'ms
    }

    start_trailer: {
      video_id: -1   'the content id of the trailer
      is_fullscreen: true
      video_player: ""  'VideoPlayer enum
    }

    trailer_play_progress: {
      video_id: -1   'the content id of the trailer
      position: -1   'ms
      view_time: -1  'ms
      video_player: ""  'VideoPlayer enum
    }

    finish_trailer: {
      video_id: -1   'the content id of the trailer
      end_position: -1
    }

    start_ad: {
      ad_started: {}  'Ad
      video_id: -1
      start_position: -1
      is_fullscreen: true
    }

    ad_click: {
      ad_clicked: {} 'Ad
      video_id: -1
      position: -1 'ms
      ad_interaction: "" 'AdInteraction enum
    }

    finish_ad: {
      ad_finished: {} 'Ad
      video_id: -1
      end_position: -1
      exit_type: "" 'ExitType enum
    }

    dialog: {
      dialog_type: "" 'DialogType enum
      pageOneof: {}  'a valid page type (see DialogEvent in events.protos)
      dialog_action: ""  'Action enum
      dialog_sub_type: ""  'max 20 character string
    }

    component_interaction: {
      pageOneof: {}  'a valid page type (see ComponentInteractionEvent in events.protos)
      componentOneof: {}  'a valid component type (see ComponentInteractionEvent in events.protos)
      user_interaction: ""  'Interaction enum
    }

    account: {
      manip: "" 'Manipulation enum - we only use "REGISTER_DEVICE" currently
      current: "" 'User.AuthType enum
      linked: ""  'User.AuthType enum - not relevant for roku channel
      user_type: "" 'UserType enum
      message: ""
      status: {} 'ActionStatus enum
    }

    exposure: {
      experiment: {}  'Experiment
    }

    viewable_impression: {   'TODO: not part of V1
      impression_type: {} 'ViewableImpressionType
      contents: {}  'TODO: Figure out what this looks like
    }

    request_for_info: {
      request_for_info_action: "" 'RequestForInfoAction enum
      prompt: "" 'optional, describes the question being asked
      selectorOneOf: {} 'a valid selector component
    }

    start_preview: {
      video_id: -1
      is_fullscreen: false
      video_player: "BANNER"
      page_type: "" 'current screen
    }

    finish_preview: {
      video_id: -1
      end_position: -1 'ms
      page_type: "" 'current screen
      has_completed: false
    }

    preview_play_progress: {
      video_id: -1
      position: -1 'ms
      view_time: -1  'ms
      video_player: "BANNER"
      page_type: "" 'current screen
    }

  }

  eventBase = eventTypes[eventType]
  event = m.populateMessage(eventType, eventValues, eventBase)

  return event
End Function


' Build the structure for the various page types that belong to some of the events
Function tubiTracking_getAnalyticsPage(pageType, pageValues)
  if m.isString(pageType)
    pageBase = m.allOneofs.pageOneof[pageType]

    if pageBase = invalid
      pageBase = m.allOneofs.dest_pageOneof[pageType]
    end if
    page = m.populateMessage(pageType, pageValues, pageBase)
    return page
  else
    return {}
  end if
End Function


Function tubiTracking_getAnalyticsComponent(componentType, componentValues)
  'see tubiTracking_getOneOfs() for a list of all available analytics component messages
  componentTypes = m.allOneofs.componentOneof
  componentBase = componentTypes[componentType]
  component = m.populateMessage(componentType, componentValues, componentBase)
  return component
End Function


Function tubiTracking_getAnalyticsDestinationComponent(componentType, componentValues)
  'see tubiTracking_getOneOfs() for a list of all available analytics component messages
  componentTypes = m.allOneofs.dest_componentOneof
  componentBase = componentTypes[componentType]
  component = m.populateMessage(componentType, componentValues, componentBase)
  return component
End Function


Function tubiTracking_getAnalyticsSelector(selectorType, selectorValues)
  selectorTypes = m.allOneofs.selectorOneOf
  selectorBase = selectorTypes[selectorType]
  selector = m.populateMessage(selectorType, selectorValues, selectorBase)

  ' populate message will remove the "selections" field if it is there are no items in the array.
  ' Analytics expects an empty array if the user does not select anything, so add the empty array back.
  if selector[selectorType].selections = invalid
    selector[selectorType].selections = []
  end if

  return selector
End Function


' Build the structure for a ContentTile message
Function tubiTracking_getAnalyticsTile(contentNode, colPos=1, rowPos=1)
  tile = invalid

  if contentNode <> invalid
    tile = {}
    contentId = contentNode.id
    if contentNode.type = m.constants.ui.contentTypes.series
      if Left(contentNode.id, 1) = "0"
        contentId = Mid(contentNode.id, 2)
      end if
      tile.series_id = contentId.toInt()
    else if contentNode.type = m.constants.ui.contentTypes.video or contentNode.type = m.constants.ui.contentTypes.linear
      tile.video_id = contentId.toInt()
    end if

    tile.col = colPos
    tile.row = rowPos

  end if

  return tile
End Function


' Build the structure for an ad message based on info collected from Rainmaker ad server
' @ctx: AA, the ctx passed to TubiAds.adTrackingCallback
Function tubiTracking_getAnalyticsAd(ctx)
  adEvent = {
    ad_type: "VAST"    'adType enum
    ' advertiser_id: ""   'not currently available
    ' vendor_id: ""       'not currently available
    ' creative_duration: 0  'not currently available
  }
  if ctx <> invalid AND ctx.ad <> invalid
    ad = ctx.ad
    isInteractive = false
    if type(ad.companionads) = "roArray" AND ad.companionads.count() > 0
      isInteractive = true
    end if


    if type(ad.streams) = "roArray" AND ad.streams[0] <> invalid
      if m.isString(ad.streams[0].url) = true
        adEvent.creative_url = ad.streams[0].url   'expect adVideoUrl to be of the form "http://paella.adrise.tv/011127/3256277/v1004184820-,426x240-HD-366,640x360-HD-730,854x480-HD-1111,854x480-HD-1479,1280x720-HD-2139,1280x720-HD-2832,k.mp4.m3u8"
      end if
      if m.isString(ad.streams[0].id) = true
        adEvent.ad_video_id = ad.streams[0].id
      end if
    end if

    if isInteractive = true AND ad.companionads[0] <> invalid
      if ad.companionads[0].provider = "INNOVID"
        adEvent.ad_type = "INNOVID"
      else if ad.companionads[0].provider = "brightline_RSG"
        adEvent.ad_type = "BRIGHTLINE"
      end if
    end if

    if ad.creativeAdId <> invalid then adEvent.ad_id = ad.creativeAdId
    if ad.creativeId <> invalid then adEvent.creative_id = ad.creativeId.toInt()
    if ad.adId <> invalid then adEvent.parent_id = ad.adId
    if ad.duration <> invalid then adEvent.reported_duration = ad.duration * 1000  'ms
    if ctx.adIndex <> invalid then adEvent.index = ctx.adIndex
    if ctx.adCount <> invalid then adEvent.pod_size = ctx.adCount
  end if
  return adEvent
End Function


' @screenId: string, an id of an instance of the home screen
' @returns: string, the analytics content mode corresponding to the passed in screen id
Function tubiTracking_getAnalyticsHomePageContentMode(screenId)
  homePageContentModeMap = m.getHomePageContentModeMap(m.constants)
  analyticsContentMode = "CONTENT_MODE_UNKNOWN"

  if homePageContentModeMap[screenId] <> invalid
    analyticsContentMode = homePageContentModeMap[screenId]
  end if

  return analyticsContentMode
End Function


' tubiTracking_populateMessage populates a "protobuf message" structure with passed in content based on the defined structure.
' The defined structure may have more fields than the passed in content has to populate it with, so this function returns a structure only
' with fields that have been populated. tubiTracking_populateMessage also overwrites any "Oneof" fields if the values for the "Oneof"
' fields are valid message types.
'
' @messageType: string, the name of the field the message will be attached to ("play_progress" in the return example below)
' @messageValues: assocArray, the values corresponding to the fields of the protobuf message
' @messageBase: assocArray, a list of fields for each message as defined in this file (which should match the protos specs on the server)
' (each "object" in protobufs are called messages)
' (the "keys" of the messages are called fields)
'
' returns something like:
' {
'   play_progress: {
'      content: {
'       content_id: 123456
'       content_type: "VIDEO"
'      }
'      position: 0
'      view_time: 0
'   }
' }
'
Function tubiTracking_populateMessage(messageType, messageValues, messageBase)
  if messageBase <> invalid
    message = {}
    messageFields = {}
    for each prop in messageValues

      'only allow values that exist on the messageBase (ie. the source of truth for the data format)
      if messageBase[prop] <> invalid

        'check if the passed in value is a "Oneof" (ie. "pageOneof"),
        'if so, add the valid key that exists inside the "Oneof" to the message
        if m.allOneofs[prop] <> invalid
          if messageValues[prop] <> invalid
            for each key in messageValues[prop]  'should only actually be one key, something like "home_page"
              if m.allOneofs[prop][key] <> invalid  'ex. m.allOneofs["pageOneof"]["home_page"]
                messageFields.addReplace(key, messageValues[prop][key])
              end if
            end for
          end if
        else
          messageFields.addReplace(prop, messageValues.Lookup(prop))
        end if
      end if
    end for

    for each prop in messageBase
      if m.isEmptyValue(messageFields[prop])
        messageFields.Delete(prop)
      end if
    end for

    message.addReplace(messageType, messageFields)
    return message
  else
    return invalid
  end if
End Function


Function tubiTracking_isEmptyValue(value)
  if value <> invalid
    if m.isString(value) = true AND value = ""
      return true
    else if (type(value) = "roArray" or type(value) = "roAssociativeArray") AND value.isEmpty()
      return true
    else if m.isNumeric(value) AND value < 0
      return true
    else
      return false
    end if
  else
    return true
  end if
End Function


' Returns an AA with all the various valid choices where "Oneof" is required by protos
' This should be kept updated as protos updates
Function tubiTracking_getOneOfs()
  ' pageTypes
  current_page = {
    i: "i"  'filler because empty fields are removed
  }

  static_page = {
    name: ""
  }

  home_page = {
    content_mode: "CONTENT_MODE_UNKNOWN"  'filler because empty fields are removed
  }

  news_browse_page = {
    i: "i"  'filler because empty fields are removed
  }

  sports_browse_page = {
    i: "i"  'filler because empty fields are removed
  }

  worldcup_browse_page = {
    i: "i" 'filler because empty fields are removed
  }

  entertainment_browse_page = {
    i: "i"  'filler because empty fields are removed
  }

  category_page = {
    category_slug: ""
  }

  sub_category_page = {  'TODO: Determine if we need this - I think no.
    category_slug: ""
    sub_category_slug: ""
  }

  category_list_page = {}

  channel_list_page = {}

  video_page = {  'This corresponds to our details page
    video_id: -1
  }

  video_player_page = {
    video_id: -1
  }

  series_detail_page = {
    series_id: -1
  }

  episode_video_list_page = {
    series_id: -1
  }

  search_page = {
    query: ""   'There is no query associated with the search page
  }

  auth_page = {  'TODO: Find out if we need this page - I think no
    auth_action:  ""  'Action enum
  }

  login_page = {   'TODO: Find out if we need this page - I think no
    choice: ""  'Choice enum
  }

  register_page = {
    auth_method: ""   'AuthMethod enum
    register_action: ""   'Action enum
  }

  account_page = {
    account_page_type: ""   'PageType enum
  }

  access_menu_page = {}

  onboarding_page = {
    page_sequence: -1
    name: ""
  }

  section_leftNav = {
    left_nav_section: ""  ' Section enum
  }

  section_topNav = {
    top_nav_section: ""  ' Section enum
  }

  linear_browse_page = {
    i: "i"
  }

  landing_page = {}

  age_gate_page = {}

  upcoming_content_page = {
    video_id: -1
  }

  ' splash_page = {}   'not currently used
  ' forget_page = {}   'not currently used

  contentOneof = {
    series_id: -1
    video_id: -1
  }

  targetOneof = {
    content: {
      series_id: -1
      video_id: -1
      user_interaction: ""
    }
  }

  'set up the page "Oneofs" with the available page types
  pageOneof = {
    current_page: current_page
    static_page: static_page
    home_page: home_page
    category_page: category_page
    sub_category_page: sub_category_page
    category_list_page: category_list_page
    channel_list_page: channel_list_page
    video_page: video_page
    video_player_page: video_player_page
    series_detail_page: series_detail_page
    episode_video_list_page: episode_video_list_page
    search_page: search_page
    auth_page: auth_page
    login_page: login_page
    linear_browse_page: linear_browse_page
    register_page: register_page
    account_page: account_page
    access_menu_page: access_menu_page
    news_browse_page: news_browse_page
    sports_browse_page: sports_browse_page
    entertainment_browse_page: entertainment_browse_page
    onboarding_page: onboarding_page
    landing_page: landing_page
    age_gate_page: age_gate_page
    worldcup_browse_page: worldcup_browse_page
    upcoming_content_page: upcoming_content_page
    ' splash_page: splash_page
    ' forget_page: forget_page
  }

  dest_pageOneof = {
    dest_current_page: current_page
    dest_static_page: static_page
    dest_home_page: home_page
    dest_category_page: category_page
    dest_category_page: category_page
    dest_sub_category_page: sub_category_page
    dest_category_list_page: category_list_page
    dest_channel_list_page: channel_list_page
    dest_video_page: video_page
    dest_video_player_page: video_player_page
    dest_series_detail_page: series_detail_page
    dest_episode_video_list_page: episode_video_list_page
    dest_search_page: search_page
    dest_auth_page: auth_page
    dest_login_page: login_page
    dest_register_page: register_page
    dest_account_page: account_page
    dest_access_menu_page: access_menu_page
    dest_news_browse_page: news_browse_page
    dest_sports_browse_page: sports_browse_page
    dest_entertainment_browse_page: entertainment_browse_page
    dest_linear_browse_page: linear_browse_page
    dest_onboarding_page: onboarding_page
    dest_landing_page: landing_page
    dest_age_gate_page: age_gate_page
    dest_worldcup_browse_page: worldcup_browse_page
    dest_upcoming_content_page: upcoming_content_page
    ' dest_splash_page: splash_page
    ' dest_forget_page: forget_page
  }




  dest_componentOneof = {
    dest_left_side_nav_component: section_leftNav

    dest_top_nav_component: section_topNav
  }

  ' At some point we may need to split the component "Oneof" like we did with the page and dest_page "Oneof"
  ' but for now this is sufficient
  componentOneof = {
    ' browse_menu_component: {    ' Does not currently exist in roku UI
    '   category_slug: ""
    ' }

    generic_component: {   ' Used for components that are not yet defined in protos
      generic_component_type: ""  ' GenericComponentType enum
    }

    left_side_nav_component: section_leftNav

    top_nav_component: section_topNav

    channel_guide_component: {
      category_slug: ""
      category_row: -1   ' 1 based index
      category_col: -1   ' 1 based index
      content_tile: {}  ' ContentTile message - optional
    }

    category_component: {   ' Used for category screen, channel details screen, channel/category grid screen
      category_slug: ""
      category_row: -1   ' 1 based index
      category_col: -1   ' 1 based index
      content_tile: {}  ' ContentTile message - optional
    }

    ' sub_category_component: {   'Does not currently exist in roku UI
    '   category_slug: ""
    '   sub_category_slug: ""
    '   category_row: 1   ' 1 based index
    '   content_tile: {}  ' ContentTile message
    ' }

    auto_play_component: {
      content_tile: {}  ' ContentTile message
    }

    related_component: {
      content_tile: {}  ' ContentTile message
    }

    episode_video_list_component: {
      content_tile: {}  ' ContentTile message
    }

    search_result_component: {
      content_tile: {}  ' ContentTile message
    }

    epg_component: {
      content_tile: {}  ' ContentTile message
    }

    button_component: {
      button_type: ""  'ButtonType enum
      button_value: ""
    }

    reminder_component: {
      video_id: -1
      series_id: -1
    }

    content: {
      series_id: -1
      video_id: -1
    }
  }

  selectorOneOf = {
    content_selector: {
      tiles: []
      selections: []

    }
    string_selector: {
      options: ""
      selections: []
      string_selector_type: "" 'StringSelectorComponent.type enum
      sub_type: ""
    }
  }

  return {
    targetOneof: targetOneof
    pageOneof: pageOneof
    dest_pageOneof: dest_pageOneof
    dest_componentOneof: dest_componentOneof
    componentOneof: componentOneof
    contentOneof: contentOneof
    selectorOneOf: selectorOneOf
  }
End Function


Function tubiTracking_getSideNavPageMap(constants)
  map = {}
  if constants <> invalid AND constants.ui <> invalid AND constants.ui.sideNavIds <> invalid
    sideNavIds = constants.ui.sideNavIds
    if sideNavIds.home <> invalid then map[sideNavIds.home] = "HOME"
    if sideNavIds.channels <> invalid then map[sideNavIds.channels] = "CHANNEL"
    if sideNavIds.categories <> invalid then map[sideNavIds.categories] = "CATEGORIES"
    if sideNavIds.movies <> invalid then map[sideNavIds.movies] = "MOVIES"
    if sideNavIds.tv <> invalid then map[sideNavIds.tv] = "SERIES"
    if sideNavIds.espanol <> invalid then map[sideNavIds.espanol] = "ESPANOL"
    if sideNavIds.mylist <> invalid then map[sideNavIds.mylist] = "QUEUE"
    if sideNavIds.settings <> invalid then map[sideNavIds.settings] = "SETTINGS"
    if sideNavIds.search <> invalid then map[sideNavIds.search] = "SEARCH"
    if sideNavIds.exit <> invalid then map[sideNavIds.exit] = "EXIT"
    if sideNavIds.kidsMode <> invalid then map[sideNavIds.kidsMode] = "KIDS"
    if sideNavIds.profile <> invalid then map[sideNavIds.profile] = "ACCOUNT"
    if sideNavIds.linearEPG <> invalid then map[sideNavIds.linearEPG] = "LINEAR"
    if sideNavIds.subtitles <> invalid then map[sideNavIds.subtitles] = "SUBTITLES"
    if sideNavIds.back <> invalid then map[sideNavIds.back] = "BACK"
    if sideNavIds.tournament <> invalid then map[sideNavIds.tournament] = "SPORTS"
  end if
  return map
End Function


' returns an AA that maps screen ids of homescreen instances to the appropriate analytics content mode
Function tubiTracking_getHomePageContentModeMap(constants)
  map = {}
  if constants <> invalid AND constants.ui <> invalid AND constants.ui.screenIds <> invalid
    screenIds = constants.ui.screenIds
    if screenIds.homeScreen <> invalid then map[screenIds.homeScreen] = "CONTENT_MODE_UNKNOWN"
    if screenIds.movieScreen <> invalid then map[screenIds.movieScreen] = "CONTENT_MODE_MOVIE"
    if screenIds.tvScreen <> invalid then map[screenIds.tvScreen] = "CONTENT_MODE_TV"
    if screenIds.epgScreen <> invalid then map[screenIds.epgScreen] = "CONTENT_MODE_LINEAR"
    if screenIds.espanolScreen <> invalid then map[screenIds.espanolScreen] = "CONTENT_MODE_LATINO"
  end if
  return map
End Function


'helper function to determine if the value can be compared to a number
Function tubiTracking_isNumeric(value)
  if type(value) = "roInteger" or type(value) = "roInt" or type(value) = "Integer" or type(value) = "roFloat" or type(value) = "Float" or type(value) = "roDouble" or type(value) = "Double"
    return true
  end if

  return false
End Function


' Helper functtion to determine if the value is a string
Function tubiTracking_isString(value)
  return type(value) = "String" or type(value) = "roString"
End Function
