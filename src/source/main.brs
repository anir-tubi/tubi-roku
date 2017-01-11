'Add Library for Roku Ad Framework
Library "Roku_Ads.brs"


'The Main function serves to run any remote config and experiment API calls and then choose the appropriate UI
Function Main(startupArgs as Dynamic)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  tracking = TubiTracking(constants, request, auth)  

  isNewUI = 0 'remote config will send as 1 or 0

  'only run remote config for new UI if we have a model that can handle it
  if constants.deviceInfo.lowMemory = false
    'run config first to see if we get new or old UI
    externalConfig = TubiExternalConfig(request, constants)
    externalConfig.init() 'sets external config values on constants

    isNewUI = constants.externalConfig.info.roku_new_ui
  end if

  if isNewUI = 1
    MainNewUI(startupArgs, constants)
  else
    MainOldUI(startupArgs)
  end if

End Function






Sub MainOldUI(params as Dynamic)
  placeholderCanvas = CreateObject( "roImageCanvas" )
  placeholderCanvas.SetMessagePort(CreateObject("roMessagePort"))
  placeholderCanvas.Show()

  app = AdriseApp(params)
  m.app = app

  ' This will only run for the test mode
  if app.settings.mode = "test"
    print "Starting all the tests..."
    BrsTestMain()
    return
  end if

  ' apply hotpatch to main brightscript thread
  ' this also verifies startup network connectivity
  if Hotpatch(app.settings.hotPatchUrlOldUI) <> 0 then
    showErrorDialog()
    return ' exit the app on error.  scene graph exits anyway once
              ' we destroy a Scene and try to create it again.
  end if

  ' Set up the scene graph that will create a persistent task thread for Facebook recognition
  if m.app.facebookDetection = true
    constants = getConstants()
    screen = CreateObject("roSGScreen")
    fbscene = screen.CreateScene("FBScene")

    if fbscene <> invalid
      sgGlobal = screen.getGlobalNode()
      sgGlobal.addField("constants", "assocarray", false)
      sgGlobal.constants = {
        fban4tvtoken: constants.fban4tvtoken
      }
      screen.show()

      print "Waiting for FBTask thread to be ready..."

      fbReadyTimer = CreateObject("roTimespan")
      while true
        isFbReady = fbscene.getField("ready")
        if isFbReady <> invalid
          if isFbReady = true then exit while
          sleep(500)
        end if
        if fbReadyTimer.totalMilliseconds() > 5000 then
          print "                  ...while loop timed out ..."
          exit while
        end if
      end while
      print "                                        ...done"
    end if
  end if

  app.runApp()
  placeholderCanvas.close()

end Sub








''''''''''''''''''''
' Simple main to launch the unit tests if mode is "test".
' Otherwise, exit immediately.
'
Function MainNewUI(args As Dynamic, constants As Object)

  settings = getSettings()

  if settings.mode = "test" then
    BrsTestMain()
    END
  endif


  ' Set up the global settings.  SceneGraph will receive a clone object, not a reference.
  ' Sources used in both BRS & SG threads will use:
  '     m.global.settings
  '     m.global.manifest
  '     m.global.theme
  '
  m.global = {} ' important syntactically to keep the settings at m.global.settings, whether
                ' used from the main Brightscript thread or the SceneGraph thread
  
  request = TubiRequest()
  requestQueue = TubiRequestQueue()
  auth = TubiAuth(constants, request)
  tracking = TubiTracking(constants, request, auth)
  bookmarks = TubiBookmarks(request, auth, constants)
  log = TubiLogger(constants, request, auth)

  'set up all experiments
  experiments = TubiExperiments(request, constants)
  experiments.init() 'sets experiment values on constants
  
  m.global.utils = {
    constants: constants
    request: request
    requestQueue: requestQueue
    tracking: tracking
    auth: auth
    bookmarks: bookmarks
    experiments: experiments
    log: log
  }

  m.global.player = TubiPlayer(m.global.utils)

  ' Load scene graph
  screen = CreateObject("roSGScreen")
  port = CreateObject("roMessagePort")
  screen.setMessagePort(port)


  ' apply hotpatch to main brightscript thread
  ' this also verifies startup network connectivity
  if Hotpatch(settings.hotPatchUrl) <> 0 then
    showErrorDialog()
    return -1 ' exit the app on error.  scene graph exits anyway once
              ' we destroy a Scene and try to create it again.
  end if

  ' start the scene graph UI
  sgGlobal = screen.getGlobalNode()
  sgGlobal.addField("constants", "assocarray", false)
  sgGlobal.constants = m.global.utils.constants 
  tubiScene = screen.CreateScene("TubiScene")
  screen.show()

  'flag to enable vs. disable remote components loading
  enableRemoteComponents = constants.externalConfig.info.remote_components

  if enableRemoteComponents <> invalid and enableRemoteComponents = 1 then
    ' Dynamic Component Library loading
    remoteLibrary = tubiScene.findNode("TubiRemoteLibrary")

    print "TubiRemoteLibrary loading from " + m.global.utils.constants.settings.remoteComponentsUrl
    ' NOTE: Dynamically setting uri here only works for HTTPS or signed packages.  HTTP will give loadStatus 'none'
    remoteLibrary.uri = m.global.utils.constants.settings.remoteComponentsUrl
    print "TubiRemoteLibrary status is " + remoteLibrary.loadStatus

    'Listen for when the remote loading has completed
    while remoteLibrary.loadStatus <> "ready"
      msg = wait(1000, port)
      if type(msgType) = "roSGScreenEvent" and msg.isScreenClosed() then return 0

      print "TubiRemoteLibrary status is " + remoteLibrary.loadStatus
      if remoteLibrary.loadStatus = "failed"
        showErrorDialog()
        return 0
      end if
    end while
    controller = tubiScene.createChild("TubiRemoteLibrary:ContentController")
  else
    controller = tubiScene.createChild("ContentController")
  end if

  controller.observeField("playContent", port)

  deepLink(args, controller, m.global.utils)

  while(true)
    msg = wait(0, port)
    msgType = type(msg)
    
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() then return 0
    
    else if msgType = "roSGNodeEvent"
      node = msg.getNode()
      field = msg.getField()
      data = msg.getData()

      if field = "playContent"
        playerContent = data
        playerContent.stream = {url: playerContent.url}
        playerResult = m.global.player.playVideo(playerContent)

        'pass the new nowPos and historyId (if necessary) to scenegraph thread
        infoToPass = {
          nowPos: playerContent.nowPos
          result: playerResult
        }

        if playerContent.historyId <> invalid
          infoToPass.historyId = playerContent.historyId
        end if
        if playerContent.parentHistoryId <> invalid
          infoToPass.parentHistoryId = playerContent.parentHistoryId
        end if
        
        controller.playerInfo = infoToPass
      end if 
    end if

  end while

end Function



''''''''''''''
' Hotpatch
'
' Download .brs code from a hotpatch URL and execute it 
'
' return codes:
'  0 patch applied, or no patch available
' -1 network error downloading patch file (not 404)
'
Function Hotpatch(hotPatchUrl) As Integer
  if len(hotPatchUrl) > 5
    port = CreateObject("roMessagePort")
    transfer = CreateObject("roUrlTransfer")
    transfer.SetMessagePort(port)
    transfer.setUrl(hotPatchUrl)
    transfer.AsyncGetToString()
    msg = wait(10000, transfer.GetMessagePort())

    hotpatchResult = 0
    if type(msg) = "roUrlEvent"
      if msg.GetResponseCode() = 200 'all good, server responded back with a hotpatch file
        evalString = msg.GetString()

        ' Eval the downloaded script
        if len(evalString) > 10
          errCode = eval(evalString)
          if Type(errCode) = "Integer" and errCode=252
            print "(hp len: " + str(len(evalString)) + ")"
          else
            print "evalError "; errCode
            hotpatchResult = -1
          end if
        end if

      else if msg.GetResponseCode() > 0 'server responded with 403 error or similar - couldn't find the file but server up
        print "No file at hotpatch location"
        hotpatchResult = -1
      
      else
        ' some network failure
        print "Network error downloading hotpatch file"
        print msg.getFailureReason()
        hotpatchResult = -1
      end if
    else if msg = invalid
      'no response back from hotpatch server - either server completely down or more likely user's internet is not connected
      print "Timeout downloading hotpatch file"
      hotpatchResult = -1
    end if
  end if

  return hotpatchResult
End Function


Function showErrorDialog()
  screen = CreateObject("roSGScreen")
  port = CreateObject("roMessagePort")
  screen.setMessagePort(port)
  sgGlobal = screen.getGlobalNode()
  sgGlobal.addField("constants", "assocarray", false)


  ' make sure there are constants on the global utils (ie. we are using the old UI),
  ' as they are needed for the error message
  if m.global <> invalid
    if m.global.utils <> invalid
      if m.global.utils.constants = invalid
        m.global.utils.constants = getConstants()
      end if
    else
      m.global.utils = {
        constants: getConstants()
      }
    end if
  else
    m.global = {
      utils: {
        constants: getConstants()
      }
    }
  end if


  sgGlobal.constants = m.global.utils.constants
  controller = screen.CreateScene("ErrorController")
  screen.show()
  controller.observeField("buttonSelected", port)
  controller.error = {
    title: "Network Error"
    message: "Please check your network connection and try again"
    buttonText: "Exit"
  }

  while(true)
    msg = wait(0, port)
    msgType = type(msg)
    if msgType <> invalid then exit while
  end while

  screen.close()

End Function

'''''''''''''''
' deepLink
'
' Parse launch arguments for any deep linking hints then redirect 
' scene graph to that content.
'
'
' ARGUMENTS TO ROKU MAIN():
'
' Non-deep link args and example values:
'   splashTime                      - "1600"
'   instant_on_run_mode             - "foreground"
'   lastExitOrTerminationReason     - "EXIT_UNKNOWN"
'
' Deep link args:
'   contentId   - string identifier
'   entry       - 'banner' or omitted for search source
'   mediaType   - "series", "episode", "movie", "shortform", and "live"
'   source      - 'meta-search', 'external-control'
'
' NOTE: 'entry' seems undocumented and may have been added special for adRise by Roku

Function deepLink(args, controller, utils)

  'handle/set up any deep linking that may have occurred
  if (args.contentID <> invalid)
    tubiLog("Deep Link detected for content id " + args.contentId)

    for each key in args
      testLog(key + " = " + tostr(args[key]))
    end for

    content = CreateObject("roSGNode", "TubiContentNode")
    content.id = args.contentId

    ' default deep link source is search
    deepLinkSource = "search"

    ' if there is a parameter called entry with a value, that is the source of the deep link
    ' typically entry = banner from the Roku banner ads ('entry' is a custom parameter)
    ' deep link urls with entry source should look like:
    ' contentID=18267&entry=banner
    if args.entry <> invalid
      deepLinkSource = args.entry
    end if

    trackingUri = "/video"
    ' if deep linked from Roku search it's possible that we are deep linking to a series, instead of actual video content
    ' deep links from search for series should like:
    ' contentID=335&mediaType=series
    '
    ' See full list of mediaType at https://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide
    if args.mediaType = "series"
      content.type = "series"
      trackingUri = "/series"
    else if args.mediaType = "movie"
      content.type = "video"
    else if args.mediaType = "episode"
      content.type = "video"
    end if


    ' remove any 0s that might be prepended to the content id
    if deepLinkSource = "search"
      prepend = "0"
      while prepend = "0"
        prepend = content.id
        if prepend = "0"
          length = content.id.len()
          content.id = content.id.right(length - 1)
        end if
      end while
    end if

    if content.id <> invalid
      trackingUri = trackingUri + "/" + args.contentID
    end if

    'see tubitv.atlassian.net/wiki/display/EC/Referrals
    deeplinkMedium = "partnership"
    if args.medium <> invalid
      deeplinkMedium = args.medium
    end if

    'see tubitv.atlassian.net/wiki/display/EC/Referrals
    deeplinkCampaign = "default-campaign"
    if args.campaign <> invalid
      deeplinkCampaign = args.campaign
    end if

    extraCtx = {
      source: deepLinkSource
      campaign: deeplinkCampaign
      medium: deeplinkMedium
    }

    controller.itemDetail = content

    trackData = utils.tracking.getTrackData("deeplink", invalid, trackingUri, extraCtx)
    trackReq = utils.tracking.getUserTrackingRequest(trackData)
    trackReq.runSynchronous(1)

  end if
End Function
