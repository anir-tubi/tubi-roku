'************************************************************
'** BL_Analytics
'************************************************************

function BL_Analytics ( app = {} as Object, pages = {} as Object, isPromoPoint = false as Boolean ) as Object
  this = {
    ' properties
    className:       "[ BL_Analytics ]"
    url:             "http://events.brightline.tv/track"
    baseData:        {}
    isPromoPoint:    isPromoPoint
    pages:           pages
    currentPageView: invalid
    pageViewCount:   0
    timers:          {}
    lastHeartbeat:   CreateObject("roDateTime").AsSeconds()
    ' methods
    appendBaseData:  BL__analyticsAppendBaseData
    track:           BL__analyticsTrack
    startTimer:      BL__analyticsStartTimer
    endTimer:        BL__analyticsEndTimer
    startImpression: BL__analyticsStartImpression
    endImpression:   BL__analyticsEndImpression
    adClick:         BL__analyticsAdClick
    startSession:    BL__analyticsStartSession
    endSession:      BL__analyticsEndSession
    startPageView:   BL__analyticsStartPageView
    endPageView:     BL__analyticsEndPageView
    startVideoView:  BL__analyticsStartVideoView
    endVideoView:    BL__analyticsEndVideoView
    sendHeartbeat:   BL__analyticsSendHeartbeat
  }

  deviceInfo         = CreateObject( "roDeviceInfo" )
  deviceDisplaySize  = deviceInfo.GetDisplaySize()

  appInfo            = CreateObject( "roAppInfo" )

  this.baseData.Append( {
    device_id:       deviceInfo.GetDeviceUniqueId()
    device_v:        deviceInfo.GetVersion()
    device_model:    deviceInfo.GetModel()
    client_height:   deviceDisplaySize.h
    client_width:    deviceDisplaySize.w
    platform_app_id: appInfo.GetID()
    platform_app_v:  appInfo.GetVersion()
    client_offset:   BL_getTimeZoneOffset()
  } )

  this.baseData.Append( app )

  print this.className

  if this.isPromoPoint then
    blGlobal = BL()
    this.baseData.app_session_id = blGlobal.appSessionId
    this.startImpression()
  else
    this.startSession()
  end if

  return this
end function



' DO NOT CALL THE BELOW METHODS DIRECTLY



' ----- ---- ----- ----- ----- ---- ----- -----
' HELPER METHODS
' ----- ---- ----- ----- ----- ---- ----- -----

function BL__analyticsAppendBaseData ( eventData as Object ) as Object
  ' create a new object and append to it so as not to pollute the original object
  data = {}
  data.Append( eventData )

  ' no basedata for heartbeat events
  if data.type = "heartbeat" then
    data.session_id = m.baseData.session_id
  else
    data.Append( m.baseData )
    data.client_time = BL_toIsoDate()

    ' hacky exception for session / duration( type=session ) events
    if data.type = "session" or data.duration_type = "session" then
      data.Delete( "session_id" )
    else if data.type = "video_view" or data.duration_type = "video_view" then
      data.Delete( "totalDuration" )
    end if
  end if

  return data
end function

' returns timerData Object : { id, eventData, timeStamp }
function BL__analyticsStartTimer ( eventData as Object ) as Object
  ' use eventData.id if present, else create an id
  if eventData.id <> invalid then
    id = eventData.id
  else
    id = BL_generateGuid()
  end if

  timerData = {
    id    : id
    eventData : eventData
    timeStamp : CreateObject("roDateTime").AsSeconds()
  }

  ' store timerData for later
  m.timers[ id ] = timerData

  return timerData
end function

function BL__analyticsEndTimer ( timerId  as String )
  if m.timers[timerId] <> invalid then
    timerData      = m.timers[timerId]
    eventData      = timerData.eventData
    currentTimeStamp   = CreateObject("roDateTime").AsSeconds()
    eventData.duration = currentTimeStamp - timerData.timeStamp

    ' purge timerData
    m.timers.Delete( timerId )

    return eventData
  else
    return invalid
  end if
end function

sub BL__analyticsTrack ( eventData as Object )
  data = m.appendBaseData( eventData )

  print "----- "; data.type; " -----"
  print data
  print "----- -----"

  payload = { data : FormatJson( data ) }

  postString = BL_createPostString( payload )

  BL_httpPostAndForget( m.url , postString )
end sub

' ----- ---- ----- ----- ----- ---- ----- -----
' EVENT METHODS
' ----- ---- ----- ----- ----- ---- ----- -----

sub BL__analyticsSendHeartbeat ()
  currentTimeStamp = CreateObject("roDateTime").AsSeconds()

  if ( currentTimeStamp - m.lastHeartbeat ) >= 10 then
    ' print "BL__analyticsSendHeartbeat"

    m.lastHeartbeat = currentTimeStamp

    m.track({
      type : "heartbeat"
    })
  end if

end sub

sub BL__analyticsStartSession ()
  ' print "BL__analyticsStartSession"

  if m.baseData.session_id = invalid then
    sessionId = BL_generateGuid()
    m.baseData.session_id = sessionId
  else
    sessionId = m.baseData.session_id
  end if

  eventData = {
    type : "session"
    id : sessionId
  }

  ' start timer
  m.startTimer( eventData )

  ' send tracking event
  m.track( eventData )
end sub

sub BL__analyticsEndSession ()
  if m.baseData.session_id <> invalid then
    ' print "BL__analyticsEndSession"

    ' end timer
    sessionId = m.baseData.session_id
    eventData = m.endTimer( sessionId )

    if eventData <> invalid then
      eventData.type = "duration"
      eventData.duration_type = "session"

      ' send tracking event
      m.track( eventData )
    end if
  end if
end sub

sub BL__analyticsStartImpression ()
  ' print "BL__analyticsStartSession"

  m.baseData.id = BL_generateGuid()

  eventData = {
    id:   m.baseData.id
    type: "impression"
  }

  ' start timer
  m.startTimer( eventData )

  ' send tracking event
  m.track( eventData )
end sub

sub BL__analyticsEndImpression ()
  if m.baseData.id <> invalid then
    ' print "BL__analyticsEndImpression"

    ' end timer
    eventData = m.endTimer( m.baseData.id )

    if eventData <> invalid then
      eventData.type = "duration"
      eventData.duration_type = "impression"

      ' send tracking event
      m.track( eventData )
    end if
  end if
end sub

sub BL__analyticsAdClick ()
  ' print "BL__analyticsAdClick"

  eventData = {
    type : "ad_click"
  }

  ' send tracking event
  m.track( eventData )
end sub

' return eventId if successfull
' return invalid if failed
function BL__analyticsStartPageView ( pageName as String )
  ' print "BL__analyticsStartPageView"

  prevPageView = m.currentPageView

  ' close previous page view
  if type( prevPageView ) = "roAssociativeArray" and prevPageView.id <> invalid then
    m.endPageView( prevPageView.id )
  end if

  ' create new page view
  if m.pages.DoesExist( pageName ) then
    eventId = BL_generateGuid()

    ' increment page view count
    m.pageViewCount = m.pageViewCount + 1

    eventData = {
      type:      "page_view"
      id:        eventId
      page_view_count: m.pageViewCount
    }

    eventData.Append( m.pages[ pageName ] )

    if prevPageView <> invalid then
      eventData.referrer_page_id = prevPageView.page_id
    end if

    ' store page view
    m.currentPageView = eventData

    ' start timer
    m.startTimer( eventData )

    ' send tracking event
    m.track( eventData )

    return eventId
  end if

  return invalid
end function

sub BL__analyticsEndPageView ( pageViewId as String )
  ' print "BL__analyticsEndPageView"

  if pageViewId <> invalid then
    ' end timer
    eventData = m.endTimer( pageViewId )

    if eventData <> invalid then
      eventData.type = "duration"
      eventData.duration_type = "page_view"

      ' send tracking event
      m.track( eventData )
    end if
  end if
end sub

' return eventId if successfull
' return invalid if failed
function BL__analyticsStartVideoView ( video as Object )
  ' print "BL__analyticsStartVideoView"

  eventId = BL_generateGuid()

  eventData = {}

  ' include page data
  if m.currentPageView <> invalid then
    eventData.Append( m.currentPageView )
  end if

  eventData.Append({
    type:  "video_view"
    id:  eventId
  })

  if video["_meta"] <> invalid then
    eventData["_meta"] = video["_meta"]
  end if

  videoDurationType = type(video.duration)

  if videoDurationType = "roInt" or videoDurationType = "roInteger" or videoDurationType = "Integer" or videoDurationType = "roFloat" or videoDurationType = "Float" then
    eventData.totalDuration = video.duration
  end if

  ' start timer
  m.startTimer( eventData )

  ' send tracking event
  m.track( eventData )

  return eventId
end function

sub BL__analyticsEndVideoView ( videoViewId as String )
  ' print "BL__analyticsEndVideoView"

  if videoViewId <> invalid then
    ' end timer
    eventData = m.endTimer( videoViewId )

    if eventData <> invalid then
      eventData.type = "duration"
      eventData.duration_type = "video_view"

      if eventData.totalDuration <> invalid then
        eventData.percent_complete = Int( ( eventData.duration / eventData.totalDuration )  * 100 )

        ' don't allow duration and percent_complete values greater than 100%
        if eventData.percent_complete > 100 then
          eventData.percent_complete = 100
          eventData.duration = eventData.totalDuration
        end if
      end if

      ' send tracking event
      m.track( eventData )
    end if
  end if
end sub

'************************************************************
'** BL_CMS
'************************************************************

function BL_CMS ( config = {} as Object ) as Object
    this = {
        ' saved arguments
        config: config
        ' methods
        fetch:  BL__cmsFetch
    }

    return this
end function



' DO NOT CALL THE BELOW METHODS DIRECTLY



function BL__cmsFetch ( modelName as String, postData as String ) as Object
    cmsUrl      = m.config.baseUrl + m.config.key + "/" + modelName
    cmsResponse = BL_httpPostWithTimeout( cmsUrl, postData )
    cmsData     = ParseJson( cmsResponse )

    return cmsData.data
end function
'************************************************************
'** BL_GridScreen
'************************************************************

function BL_GridScreen ( analytics = invalid as Object, pageName = "" as String, port = CreateObject("roMessagePort") as Object ) as Object
  this = {
    ' saved arguments
    className:          "[ BL_GridScreen ]"
    port:               port
    analytics:          analytics
    pageName:           pageName
    ' saved roGridScreen
    screen:             invalid
    ' settings
    gsStyle:            "mixed-aspect-ratio"
    gsDisplayMode:      "photo-fit"
    ' methods
    initialize:         BL__gridScreenInitialize
    getTheme:           BL__gridScreenGetTheme
    createScreen:       BL__gridScreenCreateScreen
    setContent:         BL__gridScreenSetContent
    showScreen:         BL__gridScreenShowScreen
    startPageView:      BL__gridScreenStartPageView
    waitForMessages:    BL__gridScreenWaitForMessages
    onUrlEvent:         BL__gridScreenOnUrlEvent
    onItemFocused:      BL__gridScreenOnItemFocused
    onItemSelected:     BL__gridScreenOnItemSelected
    onRemoteKeyPressed: BL__gridScreenOnRemoteKeyPressed
    onScreenClosed:     BL__gridScreenOnScreenClosed
  }

  print this.className

  return this
end function



' DO NOT CALL THE BELOW METHODS DIRECTLY



sub BL__gridScreenInitialize ()
  ' set app theme
  m.app = CreateObject( "roAppManager" )
  m.app.SetTheme( m.getTheme() )

  ' create and show roGridScreen
  m.createScreen()
  m.setContent()
  m.showScreen()
  m.startPageView()
  m.waitForMessages()
end sub

' @placeholder
function BL__gridScreenGetTheme () as Object
  return {}
end function

sub BL__gridScreenCreateScreen ()
  ' print "creating roGridScreen | style = "; gsStyle; " | displayMode = "; gsDisplayMode

  screen = CreateObject( "roGridScreen" )

  screen.SetMessagePort( m.port )
  screen.SetDisplayMode( m.gsDisplayMode )
  screen.SetGridStyle( m.gsStyle )

  m.screen = screen
end sub

' @placeholder
sub BL__gridScreenSetContent ()
end sub

sub BL__gridScreenShowScreen ()
  ' show the screen
  m.screen.Show()
end sub

sub BL__gridScreenStartPageView ()
  if m.pageName <> "" and m.analytics <> invalid then
    m.analytics.startPageView( m.pageName )
  end if
end sub

' event loop
sub BL__gridScreenWaitForMessages ()
  while true
    msg = wait( 0, m.port )

    if m.analytics <> invalid then
      m.analytics.sendHeartbeat()
    end if

    if type(msg) = "roUrlEvent" then
      m.onUrlEvent( msg )

    else if type(msg) = "roGridScreenEvent"
      ' print m.className; " > MESSAGE | type = "; type(msg); ":"; msg.GetType(); " | msg = "; msg.getMessage(); " | index = "; msg.GetIndex()

      if msg.isListItemFocused() then
        m.onItemFocused( msg )

      else if msg.isListItemSelected() then
        m.onItemSelected( msg )

      else if msg.isRemoteKeyPressed() then
        m.onRemoteKeyPressed( msg )

      else if msg.isScreenClosed() then
        if m.onScreenClosed( msg ) then
          exit while
        end if
      end if
    end if
  end while
end sub

' ----- ---- ----- ----- ----- ---- ----- -----
' EVENT METHODS
' ----- ---- ----- ----- ----- ---- ----- -----

' @placeholder
sub BL__gridScreenOnItemFocused ( msg as Object )
  categoryIndex = msg.GetIndex()
  videoIndex  = msg.GetData()

  ' print "BL__gridScreenOnItemFocused | category = "; categoryIndex; " | video = "; videoIndex
end sub

' @placeholder
sub BL__gridScreenOnItemSelected ( msg as Object )
  categoryIndex = msg.GetIndex()
  videoIndex  = msg.GetData()

  ' print "BL__gridScreenOnItemSelected | category = "; categoryIndex; " | video = "; videoIndex
end sub

' @placeholder
sub BL__gridScreenOnRemoteKeyPressed ( msg as Object )
  keyIndex = msg.GetIndex()

  ' print "BL__gridScreenOnRemoteKeyPressed | key = "; keyIndex
end sub

function BL__gridScreenOnScreenClosed ( msg as Object ) as Boolean
  ' print "BL__gridScreenOnScreenClosed"
  return true
end function

sub BL__gridScreenOnUrlEvent ( msg as Object )
  BL_cleanupHttpRequests( msg )
end sub
'************************************************************
'** BL_VideoScreen
'************************************************************

function BL_VideoScreen ( analytics = invalid as Object, port = CreateObject("roMessagePort") as Object ) as Object
  this = {
    ' saved arguments
    className:          "[ BL_VideoScreen ]"
    port:               port
    analytics:          analytics
    ' saved roVideoScreen
    screen:             invalid
    ' properties
    videoViewId:        invalid
    episode:            invalid
    position:           0
    ' methods
    initialize:         BL__videoScreenInitialize
    createScreen:       BL__videoScreenCreateScreen
    setContent:         BL__videoScreenSetContent
    showScreen:         BL__videoScreenShowScreen
    startVideoView:     BL__videoScreenStartVideoView
    endVideoView:       BL__videoScreenEndVideoView
    waitForMessages:    BL__videoScreenWaitForMessages
    onUrlEvent:         BL__videoScreenOnUrlEvent
    onStreamStarted:    BL__videoScreenOnStreamStarted
    onPlaybackPosition: BL__videoScreenOnPlaybackPosition
    onFullResult:       BL__videoScreenOnFullResult
    onPartialResult:    BL__videoScreenOnPartialResult
    onPaused:           BL__videoScreenOnPaused
    onResumed:          BL__videoScreenOnResumed
    onRequestFailed:    BL__videoScreenOnRequestFailed
    onScreenClosed:     BL__videoScreenOnScreenClosed
  }

  print this.className

  return this
end function



' DO NOT CALL THE BELOW METHODS DIRECTLY



sub BL__videoScreenInitialize ( episode as Object )
  if type(episode) <> "roAssociativeArray" then
    print "BL__videoScreenInitialize | invalid episode object"
    return
  end if

  ' create and show roVideoScreen
  m.createScreen()
  m.setContent( episode )
  m.showScreen()
  m.startVideoView()
  m.waitForMessages()
end sub

sub BL__videoScreenCreateScreen ()
  ' print "creating roVideoScreen"

  screen = CreateObject( "roVideoScreen" )

  screen.SetMessagePort( m.port )
  screen.SetPositionNotificationPeriod( 1 )

  m.screen = screen
end sub

sub BL__videoScreenSetContent ( episode )
  if type(episode) <> "roAssociativeArray" then
    print "BL__videoScreenInitialize | invalid episode object"
    return
  end if

  m.episode = episode

  m.screen.SetContent( episode )
end sub

sub BL__videoScreenShowScreen ()
  ' show the screen
  m.screen.Show()
end sub

sub BL__videoScreenStartVideoView ()
  if m.analytics <> invalid then
    m.videoViewId = m.analytics.startVideoView( m.episode )
  end if
end sub

sub BL__videoScreenEndVideoView ()
  if m.analytics <> invalid and m.videoViewId <> invalid then
    m.analytics.endVideoView( m.videoViewId )
  end if
end sub

' event loop
sub BL__videoScreenWaitForMessages ()
  while true
    msg = wait( 0, m.port )

    if m.analytics <> invalid then
      m.analytics.sendHeartbeat()
    end if

    if type(msg) = "roUrlEvent" then
      m.onUrlEvent( msg )

    else if type(msg) = "roVideoScreenEvent" then
      ' print m.className; " > MESSAGE | type = "; type(msg); ":"; msg.GetType(); " | msg = "; msg.getMessage(); " | index = "; msg.GetIndex()

      if msg.isStreamStarted() then
        m.onStreamStarted( msg )

      else if msg.isPlaybackPosition() then
        m.onPlaybackPosition( msg )

      else if msg.isFullResult() then
        m.onFullResult( msg )

      else if msg.isPartialResult() then
        m.onPartialResult( msg )

      else if msg.isPaused() then
        m.onPaused( msg )

      else if msg.isResumed() then
        m.onResumed( msg )

      else if msg.isRequestFailed() then
        if m.onRequestFailed( msg ) then
          exit while
        end if

      else if msg.isScreenClosed() then
        if m.onScreenClosed( msg ) then
          exit while
        end if

      end if
    end if
  end while
end sub

' ----- ---- ----- ----- ----- ---- ----- -----
' EVENT METHODS
' ----- ---- ----- ----- ----- ---- ----- -----

sub BL__videoScreenOnStreamStarted ( msg as Object )
  ' print "BL__videoScreenOnStreamStarted"
end sub

sub BL__videoScreenOnPlaybackPosition ( msg as Object )
  m.position = msg.GetIndex()

  ' print "BL__videoScreenOnPlaybackPosition | position = "; m.position
end sub

sub BL__videoScreenOnFullResult ( msg as Object )
  ' print "BL__videoScreenOnFullResult"
end sub

sub BL__videoScreenOnPartialResult ( msg as Object )
  ' print "BL__videoScreenOnPartialResult"
end sub

sub BL__videoScreenOnPaused ( msg as Object )
  ' print "BL__videoScreenOnPaused"
end sub

sub BL__videoScreenOnResumed ( msg as Object )
  ' print "BL__videoScreenOnResumed"
end sub

function BL__videoScreenOnRequestFailed ( msg as Object ) as Boolean
  ' print "BL__videoScreenOnRequestFailed"
  return true
end function

function BL__videoScreenOnScreenClosed ( msg as Object ) as Boolean
  m.endVideoView()
  ' print "BL__videoScreenOnScreenClosed"
  return true
end function

sub BL__videoScreenOnUrlEvent ( msg as Object )
  BL_cleanupHttpRequests( msg )
end sub
'************************************************************
'** Utils
'************************************************************

function BL_getRemoteKeys () as Object
  keys = []
  keys[0] = "back"
  keys[2] = "up"
  keys[3] = "down"
  keys[4] = "left"
  keys[5] = "right"
  keys[6] = "enter"
  keys[7] = "replay"
  keys[8] = "rewind"
  keys[9] = "fast-forward"
  keys[10] = "info"
  keys[11] = "play"
  return keys
end function

function BL_createNewHTTP ( url as String, port = CreateObject("roMessagePort") as Object ) as Object
  http = CreateObject( "roUrlTransfer" )
  http.SetMessagePort( port )
  http.SetUrl( url )
  return http
end function

function BL_httpAsyncCallback ( http as Object, timeout% = 5000 as Integer ) as Dynamic
  res = invalid

  msg = wait( timeout%, http.GetMessagePort() )

  if type(msg) = "roUrlEvent" then
    if msg.GetResponseCode() = 200 then
      res = msg.GetString()
      print "BL_httpAsyncCallback | SUCCESS"

    else
      res = msg.GetResponseCode()
      print "BL_httpAsyncCallback | ERROR - "; msg.GetFailureReason()

    end if

  else if msg = invalid then
    print "BL_httpAsyncCallback | ERROR - Timeout"
    http.AsyncCancel()
  end if

  return res
end function

function BL_httpGetToFileWithTimeout ( url as String, fileName as String, seconds = 5 as Integer ) as Dynamic
  http = BL_createNewHTTP( url )
  timeout% = 1000 * seconds

  res = invalid

  if (http.AsyncGetToFile( fileName )) then
    res = BL_httpAsyncCallback( http, timeout% )
  end if

  return res
end function

function BL_httpGetWithTimeout ( url as String, seconds = 5 as Integer ) as Dynamic
  http = BL_createNewHTTP( url )
  timeout% = 1000 * seconds

  res = invalid

  if (http.AsyncGetToString()) then
    res = BL_httpAsyncCallback( http, timeout% )
  end if

  return res
end function

function BL_httpPostWithTimeout ( url as String, postData as String, seconds = 5 as Integer ) as Dynamic
  http = BL_createNewHTTP( url )
  timeout% = 1000 * seconds

  res = invalid

  if (http.AsyncPostFromString( postData )) then
    res = BL_httpAsyncCallback( http, timeout% )
  end if

  return res
end function

function BL_httpGetAndForget ( url as String ) as Boolean
  blGlobal = BL()
  http     = BL_createNewHTTP( url, blGlobal.port )
  success  = http.AsyncGetToString()

  if (success) then
    blGlobal.httpRequests[ http.GetIdentity().ToStr() ] = http
    print "BL_httpGetAndForget | "; http.GetIdentity().ToStr()
  end if

  return success
end function

function BL_httpPostAndForget ( url as String, postData as String ) as Boolean
  blGlobal = BL()
  http     = BL_createNewHTTP( url, blGlobal.port )
  success  = http.AsyncPostFromString( postData )

  if (success) then
    blGlobal.httpRequests[ http.GetIdentity().ToStr() ] = http
    print "BL_httpPostAndForget | "; http.GetIdentity().ToStr()
  end if

  return success
end function

sub BL_cleanupHttpRequests ( msg )
  blGlobal = BL()
  msgId    = msg.GetSourceIdentity().ToStr()

  if msg.GetResponseCode() = 200 then
    print "BL_cleanupHttpRequests | "; msgId; " SUCCESS"

  else
    print "BL_cleanupHttpRequests | "; msgId; " ERROR - "; msg.GetFailureReason()

  end if

  if blGlobal.httpRequests.DoesExist( msgId ) then
    blGlobal.httpRequests.Delete( msgId )
  end if
end sub

function BL_createPostString ( postData as Object ) as String
  ' print "BL_createPostString - > "; postData

  postString = ""
  http = CreateObject( "roUrlTransfer" )

  for each param in postData
    paramType = type( postData[param] )
    paramValue = invalid

    ' print param; " "; paramType

    if paramType = "roAssociativeArray" then
      paramValue = FormatJson( postData[param] )

    else if paramType = "roInt" or paramType = "roInteger" or paramType = "Integer" then
      paramValue = Stri( postData[param] )

    else if paramType = "roFloat" or paramType = "Float" then
      paramValue = Str( postData[param] )

    else if paramType = "roString" or paramType = "String" then
      paramValue = postData[param]

    else if paramType = "roBoolean" or paramType = "Boolean" then
      ' Is there a better way to do this?
      if postData[param] then
        paramValue = "true"
      else
        paramValue = "false"
      end if

    end if

    if paramValue <> invalid then
      if postString <> "" then
        postString = postString + "&"
      end if

      postString = postString + param + "=" + http.Escape( paramValue )
    end if
  end for

  ' print "BL_createPostString - > "; postString

  return postString
end function

function BL_generateGuid () as String
  ' ex. 5EF8541E-C9F7-CFCD-4BD4-036AF6C145DA
  return BL_getRandomHexString(8) + "-" + BL_getRandomHexString(4) + "-" + BL_getRandomHexString(4) + "-" + BL_getRandomHexString(4) + "-" + BL_getRandomHexString(12)
end function

function BL_getRandomHexString (length As Integer) as String
  hexChars = "0123456789abcdef"
  hexString = ""
  for i = 1 to length
    hexString = hexString + hexChars.Mid(Rnd(16) - 1, 1)
  next

  return hexString
end function

function BL_toIsoDate (date = CreateObject("roDateTime") as Object) as String
  ' ex. 2014-10-24T20:39:40.414Z

  isoDate = Stri(date.GetYear()).trim() + "-" + Stri(date.GetMonth()).trim() + "-" + Stri(date.GetDayOfMonth()).trim()
  isoDate = isoDate + "T" + Stri(date.GetHours()).trim() + ":" + Stri(date.GetMinutes()).trim() + ":" + Stri(date.GetSeconds()).trim() + "." + Stri(date.GetMilliseconds()).trim() + "Z"

  return isoDate
end function

function BL_getTimeZoneOffset () as Integer
  date = CreateObject("roDateTime")
  dateAsSeconds = date.AsSeconds()
  date.ToLocalTime()
  localDateAsSeconds = date.AsSeconds()

  return ( ( dateAsSeconds - localDateAsSeconds ) / 60 )
end function

function BL () as Object
  if m.BL = invalid then
    m.BL = {
      appSessionId : BL_generateGuid()
      httpRequests : {}
      port:          CreateObject("roMessagePort")
    }
  end if

  return m.BL
end function