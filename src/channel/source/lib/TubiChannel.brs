Function TubiChannel(utils)
  return {
    metadataFetch: utils.metadataFetch
    constants: utils.constants
    tracking: utils.tracking
    experiments: utils.experiments

    'public methods
    runChannel: tubiChannel_runChannel
    deepLink: tubiChannel_deepLink
  }
End Function


'runs the scene graph portion of the channel
Function tubiChannel_runChannel(args, adShim, port)
  ' Load scene graph
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)

  ' get live tv content metadata if necessary
  ' will getExperimentValue() again in ContentController which will send the tracking event
  onNowContent = invalid
  if not m.constants.deviceInfo.limitedNewUi
    experimentInfo = m.experiments.getExperimentValue("UserNamespace", "roku_on_now")
    if experimentInfo <> invalid and experimentInfo.experimentValue = 1
      m.constants.ui.onnow.on = true
      onNowContent = m.metadataFetch.liveTv()
    end if
  end if

  ' start the scene graph UI
  sgGlobal = screen.getGlobalNode()
  sgGlobal.addField("constants", "assocarray", false)
  sgGlobal.constants = m.constants 
  tubiScene = screen.CreateScene("TubiScene")
  screen.show()

  'flag to enable vs. disable remote components loading
  enableRemoteComponents = m.constants.externalConfig.info.remote_components

  if enableRemoteComponents = 1 then
    ' Dynamic Component Library loading
    remoteLibrary = tubiScene.findNode("TubiRemoteLibrary")

    print "TubiRemoteLibrary loading from " + m.constants.settings.remoteComponentsUrl
    ' NOTE: Dynamically setting uri here only works for HTTPS or signed packages.  HTTP will give loadStatus 'none'
    remoteLibrary.uri = m.constants.settings.remoteComponentsUrl
    print "TubiRemoteLibrary status is " + remoteLibrary.loadStatus


    componentTimer = CreateObject("roTimespan")
    'Listen for when the remote loading has completed
    while remoteLibrary.loadStatus <> "ready"
      msg = wait(1000, port)
      if type(msgType) = "roSGScreenEvent" and msg.isScreenClosed() then return 0

      loadStatus = remoteLibrary.loadStatus
      print "TubiRemoteLibrary status is " + loadStatus

      if componentTimer.totalMilliseconds() > m.constants.timers.remoteComponentTimeout then
        loadStatus = "failed"
      end if

      if loadStatus = "failed"
        showErrorDialog()
        return 0
      end if
    end while

    'change the client version so we tracking knows we are using the remote components
    if rodash().get(m, "constants.settings.version") <> invalid
      m.constants.deviceInfo.clientVersion = m.constants.settings.version.Replace("_", ".") + ".newui.remote"
    end if
    sgGlobal.setField("constants", m.constants)

    controller = tubiScene.createChild("TubiRemoteLibrary:ContentController")
    controller.onNowContent = onNowContent
  else
    controller = tubiScene.createChild("ContentController")
    controller.onNowContent = onNowContent
  end if
  controller.observeField("exitApp", port)

  m.deepLink(args, controller, m.tracking)

  adShim.run(controller)
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

Function tubiChannel_deepLink(args, controller, tracking)

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

    trackData = tracking.getTrackData("deeplink", invalid, trackingUri, extraCtx)
    trackReq = tracking.getUserTrackingRequest(trackData)
    trackReq.runSynchronous(1)

    ' Normalize the content id since our internal data model expects "0" prefix for series
    if content.deeplinkType = "series" and Left(content.id, 1) <> "0" then
      content.id = "0" + content.id
    end if
    controller.deepLinkContent = content
  else
    controller.deepLinkContent = invalid
  end if
End Function
