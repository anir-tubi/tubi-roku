function BL_InteractivePreroll () as Object
  blGlobal = BL()

  loadingTextAttr = {
    Color:     "#FFCCCCCC"
    Font:      "Medium"
    HAlign:    "HCenter"
    VAlign:    "VCenter"
    Direction: "LeftToRight"
  }

  introMessage = [{
    Text:            "Advertisement: Your video will begin soon"
    TextAttr:        loadingTextAttr
    CompositionMode: "Source_Over"
  }]

  loadingMessage = [{
    Text:            "Loading..."
    TextAttr:        loadingTextAttr
    CompositionMode: "Source_Over"
  }]

  this = {
    ' properties
    className:                "[ BL_InteractivePreroll ]"
    port:                     blGlobal.port
    fs:                       CreateObject("roFileSystem")
    overlayShown:             false
    introMessage:             introMessage
    loadingMessage:           loadingMessage
    shouldWaitForMessages:    true
    ad:                       invalid
    analytics:                invalid
    canvas:                   invalid
    videoPlayer:              invalid
    overlay:                  invalid

    ' methods
    initialize:                    BL__interactivePrerollInitialize
    createCanvas:                  BL__interactivePrerollCreateCanvas
    createVideoPlayer:             BL__interactivePrerollCreateVideoPlayer
    showLoader:                    BL__interactivePrerollShowLoader
    destroyLoader:                 BL__interactivePrerollDestroyLoader
    showOverlay:                   BL__interactivePrerollShowOverlay
    destroyOverlay:                BL__interactivePrerollDestroyOverlay
    launchMicrosite:               BL__interactivePrerollLaunchMicrosite
    close:                         BL__interactivePrerollClose
    fireCompanionEvent:            BL__interactivePrerollFireCompanionEvent
    waitForMessages:               BL__interactivePrerollWaitForMessages
    onUrlEvent:                    BL__interactivePrerollOnUrlEvent
    onCanvasEvent:                 BL__interactivePrerollOnCanvasEvent
    onVideoPlayerEvent:            BL__interactivePrerollOnVideoPlayerEvent
    onVideoPlayerStreamStarted:    BL__interactivePrerollOnVideoPlayerStreamStarted
    onVideoPlayerPlaybackPosition: BL__interactivePrerollOnVideoPlayerPlaybackPosition
    onVideoPlayerFullResult:       BL__interactivePrerollOnVideoPlayerFullResult
    onVideoPlayerPartialResult:    BL__interactivePrerollOnVideoPlayerPartialResult
    onVideoPlayerPaused:           BL__interactivePrerollOnVideoPlayerPaused
    onVideoPlayerResumed:          BL__interactivePrerollOnVideoPlayerResumed
    onVideoPlayerRequestFailed:    BL__interactivePrerollOnVideoPlayerRequestFailed
    onVideoPlayerStatusMessage:    BL__interactivePrerollOnVideoPlayerStatusMessage
  }

  print this.className

  return this
end function



' DO NOT CALL THE BELOW METHODS DIRECTLY



sub BL__interactivePrerollInitialize ( ad as Object )
  m.ad = ad
  m.createCanvas()
  m.showLoader( m.introMessage )
  m.createVideoPlayer()
  m.waitForMessages()
end sub

function BL__interactivePrerollCreateVideoPlayer () as Object
  m.videoPlayer = CreateObject("roVideoPlayer")
  m.videoPlayer.SetMessagePort(m.port)
  m.videoPlayer.SetLoop(false)
  m.videoPlayer.SetPositionNotificationPeriod(1)
  m.videoPlayer.SetDestinationRect(m.canvas.GetCanvasRect())
  m.videoPlayer.AddContent( m.ad )
  m.videoPlayer.Play()
end function

' ----- ---- ----- ----- ----- ---- ----- -----
' CANVAS METHODS
' ----- ---- ----- ----- ----- ---- ----- -----

sub BL__interactivePrerollCreateCanvas ()
  m.canvas = CreateObject("roImageCanvas")
  m.canvas.SetMessagePort(m.port)
  m.canvas.SetRequireAllImagesToDraw(true)
  m.canvas.SetLayer(0, { Color: "#00000000", CompositionMode: "Source" })
  m.canvas.Show()
end sub

sub BL__interactivePrerollShowLoader ( loaderContent as Object )
  m.canvas.SetLayer(1, loaderContent)
end sub

sub BL__interactivePrerollDestroyLoader ()
  m.canvas.ClearLayer(1)
end sub

sub BL__interactivePrerollShowOverlay ()
  print "BL__interactivePrerollShowOverlay | "; m.ad.companionOverlay.url

  if type(m.ad.companionOverlay) = "roAssociativeArray" and ( type(m.ad.companionOverlay.url) = "String" or type(m.ad.companionOverlay.url) = "roString" ) then
    m.overlayShown = true

    url            = m.ad.companionOverlay.url
    cb             = CreateObject("roDateTime").AsSeconds().ToStr()
    cbRegEx        = CreateObject("roRegEx", "%%CACHEBUSTER%%", "i")
    url            = cbRegEx.Replace( url, cb )

    adString       = BL_httpGetWithTimeout( url )

    if type(adString) = "String" or type(adString) = "roString" then
      ad = ParseJson( adString )

      if type(ad) = "roAssociativeArray" then
        if type(ad.meta) = "roAssociativeArray" then
          m.analytics = BL_Analytics( ad.meta, {}, true )
        end if
        m.fireCompanionEvent( "CREATIVEVIEW" )

        m.overlay = BL_Overlay( ad, m.canvas, m )
      end if
    else
      print m.className; " > ERROR - ad request failed"
    end if
  end if
end sub

sub BL__interactivePrerollFireCompanionEvent ( eventName as String )
  eventName = UCase( eventName )

  if type(m.ad.companionOverlay.trackingEvents) = "roAssociativeArray" then
    trackingEvents = m.ad.companionOverlay.trackingEvents
    if type(trackingEvents[eventName]) = "roArray" then
      for each url in trackingEvents[eventName]
        if ( type(url) = "String" or type(url) = "roString" ) and url <> "" then
          print "BL__interactivePrerollFireCompanionEvent | event = "; eventName; " | url = "; url
          BL_httpGetAndForget( url )
        end if
      end for
    end if
  end if
end sub

sub BL__interactivePrerollDestroyOverlay ()
  if m.overlay <> invalid then
    m.analytics.endImpression()
    m.overlay.clear()
    m.overlay = invalid
  end if
end sub

sub BL__interactivePrerollClose ()
  m.destroyLoader()
  m.destroyOverlay()
  m.canvas.Close()
end sub

' ----- ---- ----- ----- ----- ---- ----- -----
' MICROSITE METHODS
' ----- ---- ----- ----- ----- ---- ----- -----

sub BL__interactivePrerollLaunchMicrosite ( microsite as Object )
  if microsite.url <> invalid and microsite.id <> invalid
    filename = "tmp:/" + microsite.id + ".brs"

    print "BL__interactivePrerollLaunchMicrosite | "; filename

    ' if file isn't cached, fetch it
    if not m.fs.Exists( filename ) then
      BL_httpGetToFileWithTimeout( microsite.url, filename )
    end if

    ' check for successful fetch
    if m.fs.Exists( filename ) then
      m.analytics.adClick()
      m.fireCompanionEvent( "CLICK" )

      m.destroyOverlay()

      m.videoPlayer.Stop()

      m.onVideoPlayerPartialResult( true )

      m.showLoader( m.loadingMessage )

      metadata = {}

      if m.analytics <> invalid and m.analytics.baseData <> invalid then
        metadata.session_id = m.analytics.baseData.id
        metadata.referrer_ad_id = m.analytics.baseData.ad_id
      end if

      params = {}

      if type(microsite.params) = "roAssociativeArray" then
        params = microsite.params
      end if

      if type(microsite.includeCore) = "Boolean" and microsite.includeCore then
        Run( [ "pkg:/source/brightline/bl.core.brs", filename ], metadata, params )
      else
        Run( filename, metadata, params )
      end if

      m.close()
    end if
  end if
end sub

' ----- ---- ----- ----- ----- ---- ----- -----
' EVENT METHODS
' ----- ---- ----- ----- ----- ---- ----- -----

' event loop
sub BL__interactivePrerollWaitForMessages ()
  while m.shouldWaitForMessages
    msg = wait( 0, m.port )

    ' print m.className; " > MESSAGE | type = "; type(msg); ":"; msg.GetType(); " | msg = "; msg.getMessage(); " | index = "; msg.GetIndex()

    if type(msg) = "roUrlEvent" then
      m.onUrlEvent( msg )
    else if type(msg) = "roVideoPlayerEvent" then
      m.onVideoPlayerEvent( msg )
    else if type(msg) = "roImageCanvasEvent" then
      m.onCanvasEvent( msg )
    ' else if type(msg) = "roUrlEvent" then
      ' m.onUrlEvent( msg )
    end if
  end while

  m.videoPlayer.Stop()
end sub

sub BL__interactivePrerollOnVideoPlayerEvent ( msg as Object )
  if msg.isStreamStarted() then
    m.onVideoPlayerStreamStarted( msg )

  else if msg.isPlaybackPosition() then
    m.destroyLoader()

    if m.overlayShown = false then
      m.showOverlay()
    else
      if m.overlay <> invalid then
        m.overlay.onVideoPlayerPlaybackPosition( msg.GetIndex() )
      end if
    end if

    m.onVideoPlayerPlaybackPosition( msg )

  else if msg.isFullResult() then
    m.onVideoPlayerFullResult( msg )
    m.close()

  else if msg.isPartialResult() then
    m.onVideoPlayerPartialResult( msg )

  else if msg.isPaused() then
    m.onVideoPlayerPaused( msg )

  else if msg.isResumed() then
    m.onVideoPlayerResumed( msg )

  else if msg.isRequestFailed() then
    m.onVideoPlayerRequestFailed( msg )
    m.close()

  else if msg.isStatusMessage() then
    m.onVideoPlayerStatusMessage( msg )

  end if
end sub

sub BL__interactivePrerollOnVideoPlayerStreamStarted ( msg as Object )
  ' print "BL__interactivePrerollOnVideoPlayerStreamStarted"
end sub

sub BL__interactivePrerollOnVideoPlayerPlaybackPosition ( msg as Object )
  ' print "BL__interactivePrerollOnVideoPlayerPlaybackPosition"
end sub

sub BL__interactivePrerollOnVideoPlayerFullResult ( msg as Object )
  ' print "BL__interactivePrerollOnVideoPlayerFullResult"
end sub

sub BL__interactivePrerollOnVideoPlayerPartialResult ( msg = {} as Object )
  ' print "BL__interactivePrerollOnVideoPlayerPartialResult"
end sub

sub BL__interactivePrerollOnVideoPlayerPaused ( msg as Object )
  ' print "BL__interactivePrerollOnVideoPlayerPaused"
end sub

sub BL__interactivePrerollOnVideoPlayerResumed ( msg as Object )
  ' print "BL__interactivePrerollOnVideoPlayerResumed"
end sub

sub BL__interactivePrerollOnVideoPlayerRequestFailed ( msg as Object )
  ' print "BL__interactivePrerollOnVideoPlayerRequestFailed"
end sub

sub BL__interactivePrerollOnVideoPlayerStatusMessage ( msg as Object )
  ' print "BL__interactivePrerollOnVideoPlayerStatusMessage"
end sub

sub BL__interactivePrerollOnCanvasEvent ( msg as Object )
  if msg.isRemoteKeyPressed() then
    if m.overlay <> invalid then
      m.overlay.onKeyPressed( msg.GetIndex() )
    end if

  else if msg.isScreenClosed() then
    print "isScreenClosed"
    m.shouldWaitForMessages = false
  end if
end sub

sub BL__interactivePrerollOnUrlEvent ( msg as Object )
  BL_cleanupHttpRequests( msg )
end sub