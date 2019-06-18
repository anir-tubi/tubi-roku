Function TubiChannel(utils)
  return {
    constants: utils.constants
    tracking: utils.tracking
    experiments: utils.experiments
    auth: utils.auth
    log: utils.log
    requestQueue: utils.requestQueue

    'public methods
    runChannel: tubiChannel_runChannel
    deepLink: tubiChannel_deepLink
    loadRemoteComponents: tubiChannel_loadRemoteComponents
    logCrashes: tubiChannel_logCrashes
    closeUpgradeWindow: tubiChannel_closeUpgradeWindow
  }
End Function


'runs the scene graph portion of the channel
Function tubiChannel_runChannel(args) As Void
  ' Load scene graph
  port = CreateObject("roMessagePort")
  input = CreateObject("roInput")
  input.SetMessagePort(port)
  screen = CreateObject("roSGScreen")
  screen.SetMessagePort(port)

  m.logCrashes(args)

  ' start the scene graph UI
  sgGlobal = screen.getGlobalNode()
  sgGlobal.addField("constants", "assocarray", false)
  sgGlobal.constants = m.constants 
  tubiScene = screen.CreateScene("TubiScene")
  screen.show()

  'run SceneGraph tests if in test mode
  if m.constants.settings.mode = "test"
    Runner = TestRunner()
    Runner.SetTestsDirectory("pkg:/source/tests")
    Runner.logger.SetVerbosity(2)
    Runner.Run()
    return
  end if

  if m.constants.remoteComponents <> false
    maxRetries = 5
    backoffFactor = 1.5
    initialBackoff = 1000 'ms
    pause = initialBackoff
    retries = 0
    loadStatus = m.loadRemoteComponents(screen)
    while loadStatus <> "ready" and retries < maxRetries
      retries += 1
      pause = pause * backoffFactor
      sleep(pause)
      ' To reset state, use a new ComponentLibrary instance
      remoteLibrary = tubiScene.findNode("TubiRemoteLibrary")
      tubiScene.removeChild(remoteLibrary)
      newRemoteLibrary = tubiScene.appendChild("ComponentLibrary")
      print "Retrying loadRemoteComponents: attempt="; retries+1; " pause="; pause
      loadStatus = m.loadRemoteComponents(screen)
    end while

    if loadStatus <> "ready"
      error = {
        message: "Remote components failed to load"
        loadStatus: loadStatus
        url: m.constants.settings.remoteComponentsUrl
      }
      errorPort = CreateObject("roMessagePort")
      m.log.exception("error", error)
      showErrorDialog()
      return
    end if

    'change the client version so tracking knows we are using the remote components
    if rodash().get(m, "constants.settings.version") <> invalid
      m.constants.deviceInfo.clientVersion = m.constants.settings.version.Replace("_", ".")
      versions = m.constants.settings.version.split("_")
      m.constants.deviceInfo.majorVersion = versions[0]
      m.constants.deviceInfo.minorVersion = versions[1]
      m.constants.deviceInfo.buildVersion = versions[2]
    end if
    sgGlobal.setField("constants", m.constants)

    ' Send the active event - this should be the first analytics event sent per session
    ' have to do it after versions are overwritten in constants from remote components
    requestQ = m.requestQueue.create(port)
    m.tracking.trackUserEvent("active", {}, requestQ)

    deepLinkContent = m.deepLink(args, m.tracking, m.auth, true)
    controller = tubiScene.createChild("TubiRemoteLibrary:ContentController")
    controller.id = "ContentController"
  else
    'Send the active event - this should be the first analytics event sent per session
    requestQ = m.requestQueue.create(port)
    m.tracking.trackUserEvent("active", {}, requestQ)

    deepLinkContent = m.deepLink(args, m.tracking, m.auth, false)
    controller = tubiScene.createChild("ContentController")
    controller.id = "ContentController"
  end if
  controller.observeField("exitApp", port)

  modalUpdate = invalid
  '//If the Upgrade constant has not been triggered, then continue startup normally.
  if m.constants.showUpgradeAlert = false
    controller.deepLinkContent = deepLinkContent
    controller.deepLinkTrigger = true
  else
    '//Create upgrade window to inform user that they should upgrade the app
    modalUpdate = CreateObject("roSGNode", "ModalDialogScreen")
    modalUpdate = tubiScene.createChild("ModalDialogScreen")
    modalUpdate.title  = "Please update this app"
    modalUpdate.message  = "This version of Tubi is no longer supported. "
    modalUpdate.message  += "To update, please exit the Tubi app and go to:"
    modalUpdate.message  += chr(10)
    modalUpdate.message  += chr(10)
    modalUpdate.message  += "Settings> System> System update> Check now"
    modalUpdate.buttons = ["Close"]
    modalUpdate.setFocus(true)
    modalUpdate.observeField("exitButton", port)
    modalUpdate.observeField("buttonSelected", port)
  end if

  while true
    msg = wait(0, port)
    msgType = type(msg)

    modalNode = invalid
    if msgType = "roSGNode"
      modalNode = msg  '
    else if msgType = "roSGNodeEvent"
      modalNode = msg.getRoSGNode()
    end if

    if modalNode <> invalid and modalUpdate <> invalid and modalNode.title <> invalid and LEN(modalNode.title) > 0 and modalNode.title = modalUpdate.title and modalUpdate.getParent() <> invalid
      '//this is the upgrade window, so continue the app startup process and call the window's event handler
      controller.deepLinkContent = deepLinkContent
      controller.deepLinkTrigger = true
      m.closeUpgradeWindow(modalNode)
    else if msgType = "roInputEvent"
        if msg.GetInfo().MediaType <> invalid and msg.GetInfo().ContentID <> invalid
          '//a deeplink event has occured while the app was running
          deepLinkContent = m.deepLink(msg.GetInfo(), m.tracking, m.auth, false)
          controller.deepLinkContent = deepLinkContent
          controller.deepLinkTrigger = true
        end if
    else if msgType = "roSGScreenEvent"
      if msg.isScreenClosed()
        return
      end if

    else if msgType = "roSGNodeEvent"
      tubiLog("TubiChannel got roSGNodeEvent for " + msg.GetField())
      if msg.GetField() = "exitApp"
        if msg.GetData() = true
          return
        end if
      end if
    end if
  end while
End Function

'//This function is called when the upgrade window should be closed
Function tubiChannel_closeUpgradeWindow(modalNode)
  if modalNode <> invalid
    tubiLog("closeUpgradeWindow(), The user has shown the Upgrade window")
    focus = false
    if modalNode.isInFocusChain()
      focus = true
    end if
    modalNode.unobserveField("buttonSelected")
    modalNode.unobserveField("exitButton")
    parent = modalNode.getParent()
    parent.removeChild(modalNode)

    if focus = true
      parent.setFocus(true)
    end if

  end if
  return invalid
end Function


Function tubiChannel_loadRemoteComponents(screen)
  tubiScene = screen.getScene()
  port = screen.GetMessagePort()

  ' Dynamic Component Library loading
  remoteLibrary = tubiScene.findNode("TubiRemoteLibrary")

  print "TubiRemoteLibrary loading from " + m.constants.settings.remoteComponentsUrl
  ' NOTE: Dynamically setting uri here only works for HTTPS or signed packages.  HTTP will give loadStatus 'none'
  remoteLibrary.uri = m.constants.settings.remoteComponentsUrl
  print "TubiRemoteLibrary status is " + remoteLibrary.loadStatus


  componentTimer = CreateObject("roTimespan")
  'Listen for when the remote loading has completed
  while remoteLibrary.loadStatus <> "ready" and remoteLibrary.loadStatus <> "failed"
    msg = wait(1000, port)
    if type(msgType) = "roSGScreenEvent" and msg.isScreenClosed() then
      return "closed"
    end if

    loadStatus = remoteLibrary.loadStatus
    print "TubiRemoteLibrary status is " + loadStatus

    if componentTimer.totalMilliseconds() > m.constants.timers.remoteComponentTimeout then
      return "timeout"
    end if
  end while
  return remoteLibrary.loadStatus
End Function


'''''''''''''''
' tubiChannel_deepLink
'
' Parse launch arguments for any deep linking hints then redirect 
' scene graph to that content.
'
' Feed: http://cms.adrise.com/roku/partnerSearch/xml
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
'   mediaType   - "season", "series", "episode", "movie", "shortform", and "live"
'   source      - 'meta-search', 'external-control'
'
' NOTE: 'entry' seems undocumented and may have been added special for adRise by Roku

Function tubiChannel_deepLink(args, tracking, auth, isRemoteComponents)
  'handle/set up any deep linking that may have occurred
  if (args.contentId <> invalid)
    tubiLog("Deep Link detected for content id " + args.contentId)

    if isRemoteComponents
      content = CreateObject("roSGNode", "TubiRemoteLibrary:DeeplinkContentNode")
    else
      content = CreateObject("roSGNode", "DeeplinkContentNode")
    end if

    content.id = args.contentId

    ' default deep link source is search
    content.source = "search"

    ' if there is a parameter called entry with a value, that is the source of the deep link
    ' typically entry = banner from the Roku banner ads ('entry' is a custom parameter)
    ' deep link urls with entry source should look like:
    ' contentID=18267&entry=banner
    if args.entry <> invalid
      content.source = args.entry
    end if

    ' deeplinks coming from ios or android devices need to be authenticated
    if args.refreshToken <> invalid and args.userId <> invalid and args.deviceId <> invalid and args.entry <> invalid
      if args.refreshToken.unescape() <> "" and args.userId.unescape() <> "" and args.deviceId.unescape() <> ""
        if args.entry = "iphone" or args.entry = "ipad" or args.entry = "ios" or args.entry = "android"

          externalAuthInfo = {
            platform: args.entry
            externalDeviceId: args.deviceId.unescape()
            externalRefreshToken: args.refreshToken.unescape()
            userId: args.userId.unescape()
          }


          ' only transfer the refresh token and log the external user in
          ' if there is no one currently logged in on the roku
          if auth.getAuthInfo() = invalid
            auth.transferRefreshToken(externalAuthInfo)
          end if
        end if
      end if
    end if

    if args.deviceId <> invalid and args.deviceId.unescape() <> ""
      content.content = args.deviceId.unescape()
    end if

    ' set up the resume time if we are deeplinking to a specific point in the video
    if args.resumeTime <> invalid
      content.nowPos = args.resumeTime.ToInt()
    end if

    trackingUri = "/video"
    ' if deep linked from Roku search it's possible that we are deep linking to a series, instead of actual video content
    ' deep links from search for series should like:
    ' contentID=335&mediaType=series
    '
    ' See full list of mediaType at https://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide
    if args.mediaType = "series"
      content.type = "series"
      content.deeplinkType = "series"
      trackingUri = "/series"
    else if args.mediaType = "season"
      content.type = "series"
      content.deeplinkType = "season"
      trackingUri = "/series"
    else if args.mediaType = "movie"
      content.type = "video"
      content.deeplinkType = "movie"
    else if args.mediaType = "episode"
      content.type = "video"
      content.deeplinkType = "episode"
    end if


    ' remove any 0s that might be prepended to the content id
    if content.source = "search"
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
    content.medium = "partnership"
    if args.medium <> invalid
      content.medium = args.medium
    end if

    'see tubitv.atlassian.net/wiki/display/EC/Referrals
    content.campaign = "default-campaign"
    if args.campaign <> invalid
      content.campaign = args.campaign
    end if

    return content
  else
    return invalid
  end if
End Function

Function tubiChannel_logCrashes(args)

  ' These are reasons we don't care about
  reasonBlacklist = {
    "EXIT_UNKNOWN":         "EXIT_UNKNOWN"        ' default exit reason
    "EXIT_POWER_MODE":      "EXIT_POWER_MODE"
    "EXIT_DIAL_DELETE":     "EXIT_DIAL_DELETE"
    "EXIT_IDLE_AUTO_EXIT":  "EXIT_IDLE_AUTO_EXIT"
  }

  reason = args.lastExitOrTerminationReason
  if reason <> invalid and reasonBlacklist[reason] = invalid
    messageInfo = {
      message: "Crash detected on previous run"
      reason: reason
      model: m.constants.deviceInfo.model
    }
    errorPort = CreateObject("roMessagePort")
    m.log.exception("warn", messageInfo)
  end if
End Function

