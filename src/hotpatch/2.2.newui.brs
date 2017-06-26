print "Hot Patch 2.2.newui dev"

'settings.version must be updated manually in the new ui hotpatch file
'when a new remote components version is released
m.global.utils.constants.settings.version = "2_2_14"


m.global.utils.constants.settings.allowAfterHours = true
m.global.utils.constants.ui.signIn.skipContinueScreen = true


' m.global.utils.constants.idsToLog = {
'   "YY00G1976937": true
' }

'correct the client version sent to the active tracking event when using remote components
if m.global.utils.constants.externalConfig.info.remote_components = 1
  m.global.utils.constants.deviceInfo.clientVersion = m.global.utils.constants.deviceInfo.clientVersion.Replace("local", "remote")
end if

' Set the most current remote components URL.  These should only increment build number.  Minor or major version number differences indicate
' incompatible architectural changes.
m.global.utils.constants.settings.remoteComponentsUrl = "http://cdn.adrise.com/hotpatches/roku/components/tubitv_remote_components_" + m.global.utils.constants.settings.version + ".pkg"

' Patch the deep link to set controller.deepLinkContent field even if there is no deep link
m.global.channel.deepLink = Function(args, controller, tracking)

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

    controller.deepLinkContent = content

    trackData = tracking.getTrackData("deeplink", invalid, trackingUri, extraCtx)
    trackReq = tracking.getUserTrackingRequest(trackData)
    trackReq.runSynchronous(1)
  else
    controller.deepLinkContent = invalid
  end if
End Function