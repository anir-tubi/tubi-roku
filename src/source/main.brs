'Add Library for Roku Ad Framework
Library "Roku_Ads.brs"

''''''''''''''''''''
' Simple main to launch the unit tests if mode is "test".
' Otherwise, exit immediately.
'
Function Main(args As Dynamic)

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
  
  constants = getConstants()
  request = TubiRequest()
  requestQueue = TubiRequestQueue()
  auth = TubiAuth(constants, request)
  tracking = TubiTracking(constants, request, auth)
  bookmarks = TubiBookmarks(request, auth, constants)
  experiments = TubiExperiments(request, constants)
  experiments.init()
  externalConfig = TubiExternalConfig(request, constants)
  externalConfig.init()

  m.global.utils = {
    constants: constants
    request: request
    requestQueue: requestQueue
    tracking: tracking
    auth: auth
    bookmarks: bookmarks
    experiments: experiments
    ' log: TubiLog()
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
  controller = screen.CreateScene("ContentController")
  screen.show()

  ' THIS ONLY WORKS ON 7.1+ firmware!
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
          end if
        end if
      else if msg.GetResponseCode() > 0 'server responded with 403 error or similar - couldn't find the file but server up
        print "No file at hotpatch location"
      else
        ' some network failure
        print "Network error downloading hotpatch file"
        return -1
      end if
    else if msg = invalid
      'no response back from hotpatch server - either server completely down or more likely user's internet is not connected
      print "Timeout downloading hotpatch file"
      return -1
    end if
  end if
  return 0
End Function


Function showErrorDialog()
  screen = CreateObject("roSGScreen")
  port = CreateObject("roMessagePort")
  screen.setMessagePort(port)
  sgGlobal = screen.getGlobalNode()
  sgGlobal.addField("constants", "assocarray", false)
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
