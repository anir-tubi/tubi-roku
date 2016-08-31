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

  ' Load scene graph
  screen = CreateObject("roSGScreen")
  port = CreateObject("roMessagePort")
  screen.setMessagePort(port)

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
  tracking = TubiTracking(request)
  auth = TubiAuth(constants, request)


  m.global.utils = {
    constants: constants
    request: request
    requestQueue: requestQueue
    tracking: tracking
    auth: auth
    ' log: TubiLog()
  }

  m.global.player = TubiPlayer(m.global.utils)

  sgGlobal = screen.getGlobalNode()
  sgGlobal.addField("constants", "assocarray", false)
  sgGlobal.constants = m.global.utils.constants

  controller = screen.CreateScene("ContentController")
  screen.show()

  ' THIS ONLY WORKS ON 7.1+ firmware!
  controller.observeField("playContent", port)

  deepLink(args, controller)

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
        playerContent = data.getFields()
        playerContent.stream = {url: playerContent.url}
        playerResult = m.global.player.playVideo(playerContent)

        if playerResult = m.global.utils.constants.player.playerResult.completed
          'TODO: BRYAN, Update a field (TBD) to tell the scene graph that the video has completed
          '             So that the scene graph can advance the episode or category grids
        end if

        'TODO: BRYAN, Update the content node with new nowPos/playStart values so the scene graph can update the resume views
      end if 
    end if

  end while

end Function


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

Function deepLink(args, controller)

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

    ' if deep linked from Roku search it's possible that we are deep linking to a series, instead of actual video content
    ' deep links from search for series should like:
    ' contentID=335&mediaType=series
    '
    ' See full list of mediaType at https://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide
    if args.mediaType = "series"
      content.type = "series"
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

    controller.itemDetail = content

  end if
End Function