'define all the constants, like URLs that will be needed in the app
Function getConstants()
  constants = {}

  ' Compile-time generated
  constants.settings = getSettings()
  
  mode = constants.settings.mode
  if mode = invalid then mode = "dev"

  ' Device info
  constants.deviceInfo = {}
    di = CreateObject("roDeviceInfo")

    firmware = di.GetOSVersion() '{build: "4195", major: "10", minor: "0", revision: "0"}' roAssociativeArray

    if di.GetDisplayType() = "HDTV"
      definition = "hd"
    else
      definition = "sd"
    end if

    ' 256MB models, needed to reduce the number of contents per category
    ' Find details at https://en.wikipedia.org/wiki/Roku#Feature_comparison
    lowMemoryModels = {
      "2400X": true  ' LT (2011)
      "2450X": true  ' LT (2012)
      "2500X": true  ' HD
      "3000X": true  ' 2 HD
      "3050X": true  ' 2 XD
      "3100X": true  ' 2 XS
      "3400X": true  ' MHL Stick
      "3420X": true  ' MHL Stick      
    }

    'models that need some functionality reduced - like backgrounds and animations, etc.
    limitedUIModels = {
      "2400X": true  ' LT (2011)
      "2450X": true  ' LT (2012)
      "2500X": true  ' HD
      "2700X": true  ' LT (2013)
      "2710X": true  ' 1 / SE
      "2720X": true  ' 2 (2013)
      "3000X": true  ' 2 HD
      "3050X": true  ' 2 XD
      "3100X": true  ' 2 XS
      "3400X": true  ' MHL Stick
      "3420X": true  ' MHL Stick
      "3500X": true  ' HDMI Stick (2014)
      "3700X": true  ' Express
      "3710X": true  ' Express+
      "5000X": true  ' TV (low specs)
    }

    ' these are non-OpenGL but CPU significantly faster than the "old" devices
    limitedUIWithFastCPU = {
      "3700X": true
      "3710X": true
      "5000X": true
    }

    lowVram = {
      "3600X": true  ' QuadCore Stick (2016)
      "3800X": true  ' Stick (2017)
      "3900X": true  ' Express (2017)
      "3910X": true  ' Express+ (2017)
      "4200X": true  ' 3 (2013)
      "4210X": true  ' 2 (2015)
      "4230X": true  ' 3 (2015)
    }

    'models that do not run the system CC overlay/dialog during video playback
    noFirmwareCaptionMenuModels = {
      "2400X": true  ' LT (2011)
      "2450X": true  ' LT (2012)
      "2500X": true  ' HD
      "2700X": true  ' LT (2013)
      "2710X": true  ' 1 / SE
      "2720X": true  ' 2 (2013)
      "3000X": true  ' 2 HD
      "3050X": true  ' 2 XD
      "3100X": true  ' 2 XS
      "3400X": true  ' MHL Stick
      "3420X": true  ' MHL Stick
      "3500X": true  ' HDMI Stick (2014)
      "3600X": true  ' QuadCore Stick (2016)
      "3700X": true  ' Express
      "3710X": true  ' Express+
      "4200X": true  ' 3 (2013)
      "4210X": true  ' 2 (2015)
      "4230X": true  ' 3 (2015)
      "4400X": true  ' 4
    }

    ' Firmware 8.0.0 added a system dialog for captions on Roku 4
    if Val(firmware.major) >= 8
      noFirmwareCaptionMenuModels.delete("4400X")
    end if

    if lowMemoryModels[di.GetModel()] <> invalid
      lowMemory = true
    else
      lowMemory = false
    end if

    if limitedUIModels[di.GetModel()] <> invalid
      limitedUi = true
      if limitedUIWithFastCPU[di.GetModel()] <> invalid
        fastCpu = true
      else
        fastCpu = false
      end if
    else
      limitedUi = false
      fastCpu = true
    end if

    if lowVram[di.GetModel()] <> invalid
      lowVram = true
    else
      lowVram = false
    end if

    if noFirmwareCaptionMenuModels[di.GetModel()] <> invalid
      firmwareCaptionMenu = false
    else
      firmwareCaptionMenu = true
    end if

    ' There is a bug with 9-patch handling when FHD is the only ui_resolution entry and display is 720p
    if di.GetDisplaySize().w <> 1920
      scaledUi = true
    else
      scaledUi = false
    end if

    ' get the client version numbers from settings rather than from appInfo, as appInfo contains
    ' info about the submitted release, but we want to store the version of the remote components.
    clientVersion = constants.settings.version.Replace("_",".")
    versionNumbers = constants.settings.version.split("_")
    majorVersion = versionNumbers[0]
    minorVersion = versionNumbers[1]
    buildVersion = versionNumbers[2]

    'Use newer APIs over deprecated APIs when appropriate
    deviceInfoRegSection = "deviceinfo"
    if FindMemberFunction(di, "GetChannelClientId") <> invalid
      storedDeviceId = RegRead("deviceId", deviceInfoRegSection)
      if storedDeviceId <> invalid and storedDeviceId <> "000000000000"
        constants.deviceInfo.deviceId = storedDeviceId
      else
        constants.deviceInfo.deviceId = di.GetChannelClientId()
        RegWrite("deviceId", constants.deviceInfo.deviceId, deviceInfoRegSection)
      end if
    else
      constants.deviceInfo.deviceId = "noid"
    end if

    if FindMemberFunction(di, "GetRIDA") <> invalid
      constants.deviceInfo.deviceAdId = di.GetRIDA()
    end if

    if FindMemberFunction(di, "IsRIDADisabled") <> invalid
      constants.deviceInfo.isAdIdTrackingDisabled = di.IsRIDADisabled()
    end if

    constants.deviceInfo.uiResolution = UCase(di.GetUiResolution().name)
    constants.deviceInfo.ipAddresses = di.GetIPAddrs() 'array of network interface ip addresses (normally will only contain 1 element)
    constants.deviceInfo.firmwareVersion = firmware.major + "." +  firmware.minor
    constants.deviceInfo.firmwareBuild = firmware.build
    constants.deviceInfo.userAgent = "Roku/DVP-" + firmware.major + "." + firmware.minor + " (" + firmware.major + "." + firmware.minor + "." + firmware.revision + "." + firmware.build + ")"
    constants.deviceInfo.userAgentModel = "Roku/DVP-" + firmware.major + "." + firmware.minor + " (" + firmware.major + "." + firmware.minor + "." + firmware.revision + "." + firmware.build + ") " + di.GetModel()
    constants.deviceInfo.model = di.GetModel()
    constants.deviceInfo.vendorName = di.GetModelDetails().VendorName
    constants.deviceInfo.definition = definition
    constants.deviceInfo.displayType = di.GetDisplayType()
    constants.deviceInfo.displayMode = di.GetDisplayMode()
    constants.deviceInfo.aspectRatio = di.GetDisplayAspectRatio()
    constants.deviceInfo.displaySize = di.GetDisplaySize()
    constants.deviceInfo.displayWidth = di.GetDisplaySize().w
    constants.deviceInfo.displayHeight = di.GetDisplaySize().h
    constants.deviceInfo.rokuCountryCode = di.GetUserCountryCode()
    if constants.deviceInfo.rokuCountryCode <> invalid
      'rokuCountryCode will be used for the value of countryCode, unless it is overriden by externalConfig.info.country. 
      'Keep a record of the original rokuCountryCode value in case we ever need to know the non-overwritten value.
      constants.deviceInfo.rokuCountryCode = UCase(constants.deviceInfo.rokuCountryCode)
    end if
    constants.deviceInfo.countryCode = constants.deviceInfo.rokuCountryCode
    constants.deviceInfo.channelStore = di.GetCountryCode()  'some channel store strings look like country codes
    constants.deviceInfo.lowMemory = lowMemory
    constants.deviceInfo.fastCpu = fastCpu
    constants.deviceInfo.lowVram = lowVram
    constants.deviceInfo.firmwareCaptionMenu = firmwareCaptionMenu
    constants.deviceInfo.limitedUi = limitedUi
    constants.deviceInfo.clientVersion = clientVersion
    constants.deviceInfo.majorVersion = majorVersion
    constants.deviceInfo.minorVersion = minorVersion
    constants.deviceInfo.buildVersion = buildVersion
    constants.deviceInfo.language  = di.GetCurrentLocale().Left(2)
    constants.deviceInfo.locale  = di.GetCurrentLocale()
    constants.deviceInfo.scaledUi = scaledUi

  'names given to different request types for identification purposes (for example in the General Task)
  constants.reqNames = {}
    constants.reqNames.searchAPI = "searchAPI"
    constants.reqNames.getHomescreen = "getHomescreen"
    constants.reqNames.getChannelsCategories = "getChannelsCategories"
    constants.reqNames.getSearchDefault = "getSearchDefault"
    constants.reqNames.getCategory = "getCategory"
    constants.reqNames.getSingleContent = "getSingleContent"
    constants.reqNames.getUpNextContent = "getUpNextContent"
    constants.reqNames.getRelatedContent = "getRelatedContent"
    constants.reqNames.getThumbnails = "getThumbnails"
    constants.reqNames.getChannel = "getChannel"
    constants.reqNames.getSSAIAds = "getSSAIAds"
    constants.reqNames.getLiveManifest = "getLiveManifest"
    constants.reqNames.emailExists = "emailExists"
    constants.reqNames.signUp = "signUp"
    constants.reqNames.signIn = "signIn"
    constants.reqNames.deviceRegister = "deviceRegister" 'verify age
    constants.reqNames.checkBirthdayInfo = "checkBirthdayInfo" 'verify age
    constants.reqNames.patchUserSettings = "patchUserSettings"

  constants.thirdParty = {}
    'Nielsen ID token for integrating with Nielsen DAR via RAF
    constants.thirdParty.nielsenToken = "PB8C78BDD-9B1B-4020-B4DD-AE7917C0F396"

    constants.thirdParty.youbora = {}
      constants.thirdParty.youbora.enabled = false
      constants.thirdParty.youbora.debug = false
      constants.thirdParty.youbora.config = {}
        ' DEVELOPMENT
        ' constants.thirdParty.youbora.config.accountCode = "tubitvdev" 'This is the only mandatory param
        ' PRODUCTION
        constants.thirdParty.youbora.config.accountCode = "tubitv" 'This is the only mandatory param

        constants.thirdParty.youbora.config.expectAds = true

    constants.thirdParty.sentry = {}
      constants.thirdParty.sentry.dsn = "https://f8edcfe8baf140b4b91b46dfb8af9a19:acdf43f7c38a47f1ab85583035ff1798@sentry.io/1377102"

    constants.thirdParty.suiteTest = {}

      'toggle for using suitest or not. Should only be set to true for testing situations.
      'for production it should be false  
      constants.thirdParty.suiteTest.enabled = false
      if constants.settings.suitest = true
        constants.thirdParty.suiteTest.enabled = true
  
        ' app_id of suitest application - can be used for any roku device within same organization. update app_id for using different account.
        constants.thirdParty.suiteTest.app_id =  "214cab71-b41b-468d-bcbb-f42732b157c4"

        ' uri of suitest application
        constants.thirdParty.suiteTest.uri = "http://the.suite.st/app/roku.zip" 
      end if

  'platform is used when communitcating with CMS API
  constants.platform = "roku"
  if LCase(constants.deviceInfo.channelStore) = "telstra"
    constants.platform = "telstra"
  end if

  'analyticsPlatform is used when sending analytics events and making raimaker ad requests
  constants.analyticsPlatform = "ROKU"
  if LCase(constants.deviceInfo.channelStore) = "telstra"
    constants.analyticsPlatform = "TELSTRA"
  end if

  'previously found in settings as "shortAppName"
  constants.appName = "tubitv"

  'experiment information will be placed here
  constants.experiments = {}
    constants.experiments.info = invalid    'will be replaced in main.brs

  'external configuration options will be placed here
  constants.externalConfig = {}
    constants.externalConfig.info = invalid   'will be replaced in main.brs

  'toggle for using starter components or not. Should only be set to false in testing situations.
  'production should always use starter components!
  constants.starterComponents = true
  if mode = "qa"
    constants.starterComponents = false
  end if

  'dictates if the channel should use the remote components (or if false, the installed components)
  'only change to false for production in case of emergencies or side load builds that are not connected to a localhost server,
  'as installed components will likely break after many remote releases.
  constants.remoteComponents = true
  if mode = "qa"
    constants.remoteComponents = false
  end if

  ' Should the user be shown the upgrade alert to help them upgrade to the latest version.
  '   Used within the hotpatch after a point release to nudge users to use the latest and
  constants.showUpgradeAlert = false

  'a list of device ids that will send debug and info logs to the logging API - this will be populated by hotpatch
  'idsToLog is expected to look like {
  '  13GSC41289Y: true
  '  YY00763924H: true
  '}  
  constants.idsToLog = {}
  
  constants.urls = {}
    'ad server url
    ' constants.urls.adsBaseUrl = "http://ads.adrise1.tv/" 'use to avoid getting ads during testing
    constants.urls.adsBaseUrl = "http://ads.adrise.tv/"
    ' constants.urls.adsBaseUrlRainmaker = "https://rainmaker.staging-public.tubi.io/rev/"
    constants.urls.adsBaseUrlRainmaker = "https://rainmaker.production-public.tubi.io/rev/"
      
    'contents url
    constants.urls.cms = {}
      constants.urls.cms.urlBase = "https://uapi.adrise.tv/cms"
      if constants.settings.mode <> "production" and constants.settings.stagingApis = true
        constants.urls.cms.urlBase = "https://uapi.staging-public.tubi.io/cms"
      end if
      constants.urls.cms.singleContent = constants.urls.cms.urlBase + "/content"
      constants.urls.cms.categories = constants.urls.cms.urlBase + "/categories"
      constants.urls.cms.upNextContent = constants.urls.cms.urlBase + "/content" ' + content_id + "/next"
      constants.urls.cms.relatedContent = constants.urls.cms.urlBase + "/content" ' + content_id + "/related"
      constants.urls.cms.thumbnails = constants.urls.cms.urlBase + "/content" ' + content_id + "/thumbnail_sprites"
      constants.urls.cms.search = constants.urls.cms.urlBase + "/search"

    'matrix url
    constants.urls.matrix = {}
      constants.urls.matrix.urlBase = "https://uapi.adrise.tv/matrix"
      if constants.settings.mode <> "production" and constants.settings.stagingApis = true
        constants.urls.matrix.urlBase = "https://uapi.staging-public.tubi.io/matrix"
      end if
      constants.urls.matrix.homescreen = constants.urls.matrix.urlBase + "/homescreen"
      constants.urls.matrix.container = constants.urls.matrix.urlBase + "/containers"
      constants.urls.matrix.channel = constants.urls.matrix.urlBase + "/containers" ' + "/:container_id"

    'users url
    constants.urls.users = {}
      constants.urls.users.urlBase = "https://uapi.adrise.tv/user_device"
      if constants.settings.mode <> "production" and constants.settings.stagingApis = true
        constants.urls.users.urlBase = "https://uapi.staging-public.tubi.io/user_device"
      end if
      constants.urls.users.login = constants.urls.users.urlBase + "/login"
      constants.urls.users.signup = constants.urls.users.urlBase + "/signup"
      constants.urls.users.registerCode = constants.urls.users.urlBase + "/code/register"
      constants.urls.users.refreshToken = constants.urls.users.urlBase + "/login/refresh"
      constants.urls.users.transferToken = constants.urls.users.urlBase + "/login/transfer"
      constants.urls.users.migrateLogin = constants.urls.users.urlBase + "/login/migrate"
      constants.urls.users.queues = constants.urls.users.urlBase + "/queues"
      constants.urls.users.history = constants.urls.users.urlBase + "/histories"
      constants.urls.users.config = constants.urls.users.urlBase + "/config/" + constants.platform
      constants.urls.users.settings = constants.urls.users.urlBase + "/users" ' + "/:id/settings"
      constants.urls.users.codeStatus = constants.urls.users.urlBase + "/code/status"

    ' account urls
    constants.urls.account = {}
      constants.urls.account.urlBase = "https://account.production-public.tubi.io"
      if constants.settings.mode <> "production" and constants.settings.stagingApis = true
        constants.urls.account.urlBase = "https://account.staging-public.tubi.io"
      end if
      constants.urls.account.emailExists = constants.urls.account.urlBase + "/user/email_available"
      constants.urls.account.login = constants.urls.account.urlBase + "/user/login"
      constants.urls.account.checkBirthday = constants.urls.account.urlBase + "/user/check_birthday_info"
      constants.urls.account.deviceRegister = constants.urls.account.urlBase + "/device/register"

    'user event tracking url
    constants.urls.dataScience = {}
      constants.urls.dataScience.urlBase = "https://uapi.staging-public.tubi.io/datascience"
      if mode = "production"
        constants.urls.dataScience.urlBase = "https://uapi.adrise.tv/datascience"
      end if
      constants.urls.datascience.logging = constants.urls.dataScience.urlBase + "/logging"
    
    'Experiments API
    constants.urls.experiments = {}
      constants.urls.experiments.baseUrl = "https://popper-engine-roku.staging-public.tubi.io/popper/"
      if mode = "production"
        constants.urls.experiments.baseUrl = "https://popper-engine.production-public.tubi.io/popper/"
      end if
      constants.urls.experiments.evaluate = constants.urls.experiments.baseUrl + "evaluate-namespaces"

    constants.urls.analytics = {}
      constants.urls.analytics.urlBase = "https://analytics-ingestion.staging-public.tubi.io/analytics-ingestion"
      ' QA analytics proxy server
      if mode = "production"
        constants.urls.analytics.urlBase = "https://analytics-ingestion.production-public.tubi.io/analytics-ingestion"
      else if mode = "qa" and constants.settings.suitestjs = true
        constants.urls.analytics.urlBase = "https://qa-proxy.staging-public.tubi.io/analytics-ingestion"
      end if
      constants.urls.analytics.event = constants.urls.analytics.urlBase + "/v2/event"
      constants.urls.analytics.singleEvent = constants.urls.analytics.urlBase + "/v2/single-event" 'preferred by back end team

    'live tv urls
    constants.urls.liveTv = {}
      constants.urls.liveTv.getAll = constants.urls.matrix.urlBase + "/livetv"

    'cuepoints url
    constants.urls.cuepointsBaseUrl = "https://ads.adrise.tv/cue-points/"

    'privacy statement text
    constants.urls.privacyUrl = "https://legal-asset.tubi.tv/privacy-policy.txt"
    constants.urls.termsOfUseUrl = "https://legal-asset.tubi.tv/terms-of-use.txt"
    constants.urls.doNotSellUrl = "https://legal-asset.tubi.tv/do-not-sell.txt"

    'channels poster image urls
    constants.urls.channelPosterUnbranded = "https://cdn.adrise.tv/image/roku_support_images/channel-poster-generic.png"
    constants.urls.channelPosterBrandedPrefix = "https://cdn.adrise.tv/image/roku_support_images/channel-poster-"
    constants.urls.channelPosterBrandedSuffix = ".png"
    'channels logo image urls
    constants.urls.channelLogoBrandedPrefix = "https://cdn.adrise.tv/image/channels/"
    constants.urls.channelLogoBrandedSuffix = "/logo_center.png"
    
    ' animationLogo Url which plays during app launch
    constants.urls.animationLogo = "https://cdn.adrise.tv/video/roku/animation_logo_2.mp4"
    ' The background images on the continue watching container row when the user is signed out
    constants.urls.continueWatchingItemBackground = "https://cdn.adrise.tv/image/roku_support_images/continueWatchingNonRegisteredItemBground.png"
    constants.urls.continueWatchingItemBackground_kidsMode = "https://cdn.adrise.tv/image/roku_support_images/continueWatchingNonRegisteredItemBground_kidsMode.png"

  'http request types
  constants.reqTypes = {}
    constants.reqTypes.get = "GET"
    constants.reqTypes.post = "POST"
    constants.reqTypes.put = "PUT"
    constants.reqTypes.del = "DELETE"
    constants.reqTypes.patch = "PATCH"

  'common http request headers
  constants.headers = {}
    constants.headers.json = {"Content-Type": "application/json"}

  'content type strings that we might get returned from uapi
  constants.uapiContentTypes = {}
    constants.uapiContentTypes.movie = "movie"
    constants.uapiContentTypes.series = "series"
    constants.uapiContentTypes.episode = "episode"
    constants.uapiContentTypes.container = "container"
    constants.uapiContentTypes.channel = "channel"

  'uapi actions - add or delete from user categories
  constants.uapiActions = {}
    constants.uapiActions.add = "add"
    constants.uapiActions.remove = "remove"

  constants.timers = {}
    constants.timers.remoteComponentTimeout = 30000

    ' Time in seconds after which we force a refresh of the categoryscreen
    constants.timers.categoryContentRefreshTimeout = 12 * 60 * 60

    ' Time in seconds after which the linear video player goes fullscreen
    constants.timers.linearFullscreenTimeout = 10

    ' Time in seconds after which stored hasAge info becomes expired for COPPA
    constants.timers.coppaFailTimeout = 24 * 60 * 60  ' 1 day
    constants.timers.coppaPassTimeout = 60 * 24 * 60 * 60  ' 60 days

    ' allow the config to set the expire time for QA purposes
    if constants.settings.mode <> "production" and constants.settings.coppaHasAgeDuration <> invalid
      constants.timers.coppaFailTimeout = constants.settings.coppaHasAgeDuration
    end if

  'constants needed for the video player
  constants.player = {}

    ' number of seconds that the "up next" screen will show
    constants.player.upNextCountdown = 30

    ' default if cuepoint is missing from metadata, or minimum cuepoint
    ' duration for titles whose cuepoint is right at the end.  This will
    ' allow time for UpNext to display before the stream ends.
    constants.player.creditsDuration = 5

    'how often the video player sends play progress events
    constants.player.pingFrequency = 10

    'how often the video player records history
    constants.player.historyFrequency = 60
    
    ' time to fetch next content before credit cuepoints
    constants.player.fetchNextDuration = 15  

    'the max number of distinct speeds at which the player can scrub (fast forward or rewind), 0 based
    constants.player.maxScrub = 2 

    'list of scrub multipliers, the number of options should match the maxScrub above
    constants.player.scrubMultipliers = [8, 64, 128]

    'the number of seconds before the video player transport autohides during playback
    constants.player.transportAutoHideTime = 5
    constants.player.thumbnailFrequency = 5

    'video player returns one of the following
    constants.player.playerResults = {}
      constants.player.playerResults.completed = "COMPLETED"
      constants.player.playerResults.closed = "CLOSED"
      constants.player.playerResults.failed = "FAILED"
      'used internal to the player, should never be returned
      constants.player.playerResults.commercial = "STOPFORCOMMERCIAL"
      constants.player.playerResults.ignore = "IGNORE"
      constants.player.playerResults.resumePlay = "RESUMEPLAY"

    'urls for the images that are required for the transport
    constants.player.transportButtons = {}
      constants.player.transportButtons.fastForward = "pkg:/images/transport/sgplayer/icon-ffw.png"
      constants.player.transportButtons.fastForwardFocus = "pkg:/images/transport/sgplayer/icon-ffw-focus.png"
      constants.player.transportButtons.fastForwardLevels = [
        "pkg:/images/transport/sgplayer/icon-ffw-1.png",
        "pkg:/images/transport/sgplayer/icon-ffw-2.png",
        "pkg:/images/transport/sgplayer/icon-ffw-3.png"
      ]      
      constants.player.transportButtons.fastForwardLevelsFocus = [
        "pkg:/images/transport/sgplayer/icon-ffw-1-focus.png",
        "pkg:/images/transport/sgplayer/icon-ffw-2-focus.png",
        "pkg:/images/transport/sgplayer/icon-ffw-3-focus.png"
      ]

      constants.player.transportButtons.rewind = "pkg:/images/transport/sgplayer/icon-rew.png"
      constants.player.transportButtons.rewindFocus = "pkg:/images/transport/sgplayer/icon-rew-focus.png"
      constants.player.transportButtons.rewindLevels = [
        "pkg:/images/transport/sgplayer/icon-rew-1.png",
        "pkg:/images/transport/sgplayer/icon-rew-2.png",
        "pkg:/images/transport/sgplayer/icon-rew-3.png"
      ]
      constants.player.transportButtons.rewindLevelsFocus = [
        "pkg:/images/transport/sgplayer/icon-rew-1-focus.png",
        "pkg:/images/transport/sgplayer/icon-rew-2-focus.png",
        "pkg:/images/transport/sgplayer/icon-rew-3-focus.png"
      ]

      constants.player.transportButtons.pause = "pkg:/images/transport/sgplayer/icon-pause.png"
      constants.player.transportButtons.pauseFocus = "pkg:/images/transport/sgplayer/icon-pause-focus.png"
      constants.player.transportButtons.play = "pkg:/images/transport/sgplayer/icon-play.png"
      constants.player.transportButtons.playFocus = "pkg:/images/transport/sgplayer/icon-play-focus.png"
      constants.player.transportButtons.toEnd = "pkg:/images/transport/sgplayer/icon-to-end.png"
      constants.player.transportButtons.toEndFocus = "pkg:/images/transport/sgplayer/icon-to-end-focus.png"
      constants.player.transportButtons.toStart = "pkg:/images/transport/sgplayer/icon-to-start.png"
      constants.player.transportButtons.toStartFocus = "pkg:/images/transport/sgplayer/icon-to-start-focus.png"
      constants.player.transportButtons.hopForward = "pkg:/images/transport/sgplayer/icon-fwd-30s.png"
      constants.player.transportButtons.hopBack = "pkg:/images/transport/sgplayer/icon-rew-30s.png"
      constants.player.transportButtons.closedCaption = "pkg:/images/transport/sgplayer/cc-icon.png"
      constants.player.transportButtons.closedCaptionFocus = "pkg:/images/transport/sgplayer/cc-icon-focus.png"
      constants.player.transportButtons.closedCaptionDisabled = "pkg:/images/transport/sgplayer/cc-icon-disabled.png"

      ' Drm types/schemes, as named and supported by UAPI
      constants.player.drmTypes = {}
      constants.player.drmTypes.dashWidevine = "dash_widevine"
      constants.player.drmTypes.dashPlayready = "dash_playready"
      constants.player.drmTypes.hlsv3 = "hlsv3"

      ' Supported schemes, in order of preference
      constants.player.drmOrder = [
        constants.player.drmTypes.dashWidevine
        constants.player.drmTypes.dashPlayready
        constants.player.drmTypes.hlsv3
      ]

  'Default times for which the caches for different content types are valid.
  'These will normally come from the server, these times stored in constants are backup values.
  constants.cacheTimes = {}
    constants.cacheTimes.content = 2 * 60 * 60 ' Time in seconds after which an individual piece of content' cache is not valid
    constants.cacheTimes.category = 4 * 60 * 60 ' Time in seconds after which a category's cache is not valid
    constants.cacheTimes.homescreen = 6 * 60 * 60 ' Time in seconds after which the category screen's cache is not valid

  'This will store the error codes that are needed to be displayed to the user. 
  'Review the following page to see the list of error codes that are used across platforms:
  'https://tubitv.atlassian.net/wiki/spaces/EC/pages/798359880/User+Facing+Error+Codes 
  constants.errors = {}

  '//Where does the error happen?
  constants.errors.context = {}
  constants.errors.context.homeScreen = "1"
  constants.errors.context.videoDetailScreen = "2"
  constants.errors.context.playerScreen = "3"
  constants.errors.context.seriesDetailScreen = "4"
  constants.errors.context.episodeScreen = "5"
  constants.errors.context.channelScreen = "6"
  constants.errors.context.searchScreen = "7"
  constants.errors.context.activateScreen = "8"
  constants.errors.context.channelsScreen = "9"
  constants.errors.context.categoriesScreen = "10"
  constants.errors.context.linearPlayerScreen = "11"

  '//What is the actual error?
  constants.errors.subtypes = {}
  '//Failed to fetch data from backend
  constants.errors.subtypes.fetchError = "100"
  constants.errors.subtypes.expireError = "101"
  constants.errors.subtypes.addBookmarkError = "102"
  constants.errors.subtypes.removeBookmarkError = "103"
  constants.errors.subtypes.removeHistoryError = "104"
  'Could not setup player
  constants.errors.subtypes.playerSetupError = "200"
  constants.errors.subtypes.playerPlaybackError = "201"
  constants.errors.subtypes.networkError = "300"

  'UI properties that should be passed into the scene graph
  constants.ui = {}

    constants.ui.ages = {}
      constants.ui.ages.ageGate = 13

    'static - pre defined text used in the app
    constants.ui.terms = {}
      constants.ui.terms.categories = "Categories"
      constants.ui.terms.channels = "Channels"
      constants.ui.terms.menu = "Menu"
      constants.ui.terms.home = "Home"

    constants.ui.ratings = {}
      aUS = []
      aUS.push("G, TV-Y, TV-G")     '//Group 0, Little Kids
      aUS.push("PG, TV-PG, TV-Y7")  '//Group 1, Big Kids
      aUS.push("PG-13, TV-14")      '//Group 2, Teens 
      aUS.push("R, TV-MA, NC-17")   '//Group 3, Adults
      constants.ui.ratings["US"] = aUS
      aMX = []
      aMX.push("A")      '//Group 0, Little Kids
      aMX.push("B")       '//Group 1, Big Kids
      aMX.push("B15")     '//Group 2, Teens 
      aMX.push("C, D")    '//Group 3, Adults
      constants.ui.ratings["MX"] = aMX

    'what ratings are highly mature and should be treated differently? May not be applicable to all countries.
    constants.ui.matureRatings = {}
      aMX = []
      aMX.push("D")
      constants.ui.matureRatings["MX"] = aMX
      
    constants.ui.categoryList = {}
      constants.ui.categoryList.action = "Action"
      constants.ui.categoryList.recommended_for_you = "Recommended"
      constants.ui.categoryList.anime = "Anime"
      constants.ui.categoryList.award_winners_and_nominees = "Award Winners & Nominees"
      constants.ui.categoryList.continue_watching = "Continue Watching"
      constants.ui.categoryList.black_cinema = "Black Cinema"
      constants.ui.categoryList.bollywood = "Bollywood Dreams"
      constants.ui.categoryList.classics = "Classics"
      constants.ui.categoryList.comedy = "Comedy"
      constants.ui.categoryList.cult_favorites = "Cult Classics"
      constants.ui.categoryList.documentary = "Documentary"
      constants.ui.categoryList.docuseries = "Docuseries"
      constants.ui.categoryList.drama = "Drama"
      constants.ui.categoryList.faith = "Faith"
      constants.ui.categoryList.family_movies = "Family Movies"
      constants.ui.categoryList.foreign_films = "Foreign Language Films"
      constants.ui.categoryList.horror = "Horror"
      constants.ui.categoryList.indie_films = "Indie Films"
      constants.ui.categoryList.kids_shows = "Kids Shows"
      constants.ui.categoryList.leaving_soon = "Leaving Soon!"
      constants.ui.categoryList.lgbt = "LGBTQ"
      constants.ui.categoryList.music_musicals = "Music & Musicals"
      constants.ui.categoryList.new_releases = "New Releases"
      constants.ui.categoryList.reality_tv = "Reality TV"
      constants.ui.categoryList.recently_added = "Recently Added"
      constants.ui.categoryList.romance = "Romance"
      constants.ui.categoryList.sci_fi_and_fantasy = "Scifi & Fantasy"
      constants.ui.categoryList.thrillers = "Thrillers"
      constants.ui.categoryList.westerns = "Westerns"

    constants.ui.categoryIds = {}
      'these map to matrix api container ids
      constants.ui.categoryIds.history = "continue_watching"
      constants.ui.categoryIds.queue = "queue"
      constants.ui.categoryIds.featured = "featured"
      constants.ui.categoryIds.recommendedForYou = "recommended_for_you"
      constants.ui.categoryIds.liveNews = "live_news"

    constants.ui.categoryTypes = {}
      'these map to matrix api container types
      constants.ui.categoryTypes.history = "continue_watching"
      constants.ui.categoryTypes.queue = "queue"
      constants.ui.categoryTypes.regular = "regular"
      constants.ui.categoryTypes.channel = "channel"
      constants.ui.categoryTypes.linear = "linear"
      constants.ui.categoryTypes.preview = "video_preview"
      constants.ui.categoryTypes.utility = "utility"
      constants.ui.categoryTypes.historySignedOutUser = "continue_watching_signed_Out_User"

    constants.ui.contentMode = {}
      constants.ui.contentMode.homescreen = "homescreen"
      constants.ui.contentMode.latino = "latino"
      constants.ui.contentMode.movie = "movie"
      constants.ui.contentMode.tv = "tv"
      constants.ui.contentMode.news = "news"
      constants.ui.contentMode.linear = "linear"

    constants.ui.contentTypes = {}
      constants.ui.contentTypes.series = "series"
      constants.ui.contentTypes.video = "video"
      constants.ui.contentTypes.episode = "episode"
      constants.ui.contentTypes.season = "season"
      constants.ui.contentTypes.category = "category"
      constants.ui.contentTypes.channel = "channel"
      constants.ui.contentTypes.utility = "utility"
      constants.ui.contentTypes.linear = "linear"
      constants.ui.contentTypes.historySignedOutUser = "continue_watching_signed_Out_User"

    constants.ui.backgroundTypes = {}
      constants.ui.backgroundTypes.fullScreen = "fullscreen"
      constants.ui.backgroundTypes.topRight = "topright"
      constants.ui.backgroundTypes.linear = "linear"
      constants.ui.backgroundTypes.feature = "feature"

    constants.ui.modes = {}
      constants.ui.modes.standard = "standard"
      constants.ui.modes.kids = "kids"  'the "normal" kids mode, when a user selects kids from the side nav
      constants.ui.modes.kidsParental = "kidsParental"  'kids mode when a user has little kids or older kids selected via parental controls
      constants.ui.modes.kidsAgeGate = "kidsAgeGate"  'a limited version of kids mode that a user sees if they fail the COPPA age gate
      constants.ui.modes.latino = "latino"

    'Screen levels dictate the hierarchy of the app and prevent scenarios where users can get into infinite screen loops.
    'Screens cannot be pushed on top of a screen whose screenLevel is greater than theirs.
    'For example, if the home screen is screenLevel = 10, and the search screen is screenLevel = 20,
    'the search screen can be pushed on top of the home screen,
    'but the home screen can not be pushed on top of the search screen.
    constants.ui.screenLevels = {}
      ' NOTE : screen level 150 is RESERVED for settings screen when going via signup/signin screen
      constants.ui.screenLevels.homeScreen = 10
      constants.ui.screenLevels.espanolScreen = 20
      constants.ui.screenLevels.newsScreen = 20
      constants.ui.screenLevels.movieScreen = 20
      constants.ui.screenLevels.tvScreen = 20
      constants.ui.screenLevels.channelCategoryGridScreen = 20
      constants.ui.screenLevels.searchScreen = 20
      constants.ui.screenLevels.settingsScreen = 20
      constants.ui.screenLevels.comfirmPasswordScreen = 40
      constants.ui.screenLevels.channelDetailScreen = 40
      constants.ui.screenLevels.detailScreen = 50
      constants.ui.screenLevels.episodeScreen = 50
      constants.ui.screenLevels.videoPlayerScreen = 60
      constants.ui.screenLevels.linearVideoPlayerScreen = 60
      constants.ui.screenLevels.activationCodeScreen = 90
      constants.ui.screenLevels.signUpScreen = 90
      constants.ui.screenLevels.signInScreen = 90
      constants.ui.screenLevels.ageGateScreen = 90
      constants.ui.screenLevels.initialContentScreen = 300
      constants.ui.screenLevels.modalDialogScreen = 1000

    constants.ui.screenIds = {}
      constants.ui.screenIds.homeScreen = "homeScreen"
      constants.ui.screenIds.searchScreen = "searchScreen"
      constants.ui.screenIds.settingsScreen = "settingsScreen"
      constants.ui.screenIds.comfirmPasswordScreen = "comfirmPasswordScreen"
      constants.ui.screenIds.channelDetailScreen = "channelDetailScreen"
      constants.ui.screenIds.channelListScreen = "channelListScreen"
      constants.ui.screenIds.categoryListScreen = "categoryListScreen"
      constants.ui.screenIds.espanolScreen = "espanolScreen"
      constants.ui.screenIds.movieScreen = "movieScreen"
      constants.ui.screenIds.tvScreen = "tvScreen"
      constants.ui.screenIds.detailScreen = "detailScreen"
      constants.ui.screenIds.episodeScreen = "episodeScreen"
      constants.ui.screenIds.activationCodeScreen = "activationCodeScreen"
      constants.ui.screenIds.newsScreen = "newsScreen"
      constants.ui.screenIds.signUpScreen = "signUpScreen"
      constants.ui.screenIds.signInScreen = "signInScreen"
      constants.ui.screenIds.upNextScreen = "upNextScreen"
      constants.ui.screenIds.modalDialogScreen = "modalDialogScreen"
      constants.ui.screenIds.videoPlayerScreen = "videoPlayerScreen"
      constants.ui.screenIds.linearVideoPlayerScreen = "linearVideoPlayerScreen"
      constants.ui.screenIds.ageVerificationScreen = "ageVerificationScreen"
      constants.ui.screenIds.initialContentScreen = "initialContentScreen"

    constants.ui.cacheableScreenIds = {}
      constants.ui.cacheableScreenIds[constants.ui.screenIds.homeScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.channelListScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.categoryListScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.espanolScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.newsScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.movieScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.tvScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.searchScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.videoPlayerScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.linearVideoPlayerScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.signUpScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.signInScreen] = true

    constants.ui.imageSizes = {}
      'Sizes of poster thumbnails that need to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images
      constants.ui.imageSizes.poster = [198,282]
        
      'Sizes of landscape thumbnails that need to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images
      constants.ui.imageSizes.landscape= [408,231]

      'Sizes of landscape VITG that need to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images
      constants.ui.imageSizes.largeVITG = [1248,701]

      'Sizes of the linear background and minmized linear video player
      constants.ui.imageSizes.linearVideoPlayer_minimizedDimension = [1263,710]

    constants.ui.imageTranslations = {}
      'Location of the linear background and minmized linear video player
      constants.ui.imageTranslations.linearVideoPlayer_minimizedTranslation = [657,0]

    constants.ui.sideNavOpenIds = {}
      constants.ui.sideNavOpenIds[constants.ui.screenIds.homeScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.channelListScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.categoryListScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.espanolScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.newsScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.movieScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.tvScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.searchScreen] = true

    constants.ui.keyIds = {}
      constants.ui.keyIds.back = "back"

    constants.ui.sideNavIds = {}
      constants.ui.sideNavIds.home = "home"
      constants.ui.sideNavIds.search = "search"
      constants.ui.sideNavIds.channels = "channels"
      constants.ui.sideNavIds.categories = "categories"
      constants.ui.sideNavIds.espanol = "espanol"
      constants.ui.sideNavIds.movies = "movies"
      constants.ui.sideNavIds.tv = "tv"
      constants.ui.sideNavIds.settings = "settings"
      constants.ui.sideNavIds.exit = "exit"
      constants.ui.sideNavIds.news = "news"
      constants.ui.sideNavIds.profile = "profile"
      constants.ui.sideNavIds.kidsMode = "kidsMode"
      constants.ui.sideNavIds.myList = "myList"
      
    constants.ui.utilityIds = {}
      constants.ui.utilityIds.movies = "u_movies"
      constants.ui.utilityIds.tv = "u_tvshows"
      constants.ui.utilityIds.kidsMode = "u_kids"
      constants.ui.utilityIds.search = "u_search"
      constants.ui.utilityIds.channels = "u_channels"
      constants.ui.utilityIds.categories = "u_categories"

    'a map of screenIds to corresponding sideNavIds
    constants.ui.screenIdToSideNavId = {}
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.homeScreen] = constants.ui.sideNavIds.home
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.searchScreen] = constants.ui.sideNavIds.search
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.channelListScreen] = constants.ui.sideNavIds.channels
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.categoryListScreen] = constants.ui.sideNavIds.categories
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.espanolScreen] = constants.ui.sideNavIds.espanol
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.newsScreen] = constants.ui.sideNavIds.news
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.movieScreen] = constants.ui.sideNavIds.movies
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.tvScreen] = constants.ui.sideNavIds.tv
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.settingsScreen] = constants.ui.sideNavIds.settings

    constants.ui.gridItemTypes = {}
      constants.ui.gridItemTypes.portrait = "portrait"
      constants.ui.gridItemTypes.landscape = "landscape"
      constants.ui.gridItemTypes.linear = "linear"
      constants.ui.gridItemTypes.vitg_small = "vitg_small"  'video in the grid
      constants.ui.gridItemTypes.vitg_large = "vitg_large"  'video in the grid
      constants.ui.gridItemTypes.utility = "utility"
      constants.ui.gridItemTypes.historySignedOutUser = "continue_watching_signed_Out_User"

    constants.ui.uris = {}
      'background gradient urls
      constants.ui.uris.homeBackgroundGradient = "pkg:/images/home-gradient-25.png"
      constants.ui.uris.detailBackgroundGradient = "pkg:/images/detail-gradient-25.png"

      'category background thumbnails
      constants.ui.uris.categoryBackgrounds = {}
      constants.ui.uris.categoryBackgrounds.urlBase = "https://cdn.adrise.tv/image/roku_support_images/category_"
      constants.ui.uris.categoryBackgrounds.urlEnding = "_thumbnail_1x242.png"
      constants.ui.uris.categoryBackgrounds.recommended = constants.ui.uris.categoryBackgrounds.urlBase + "recommended" + constants.ui.uris.categoryBackgrounds.urlEnding
      constants.ui.uris.categoryBackgrounds.continueWatching = constants.ui.uris.categoryBackgrounds.urlBase + "continuewatching" + constants.ui.uris.categoryBackgrounds.urlEnding
      constants.ui.uris.categoryBackgrounds.queue = constants.ui.uris.categoryBackgrounds.urlBase + "queue" + constants.ui.uris.categoryBackgrounds.urlEnding

      'default background image uri
      constants.ui.uris.defaultBackground = "pkg:/images/art-blur-background.png"
      'kidsMode background image uri
      constants.ui.uris.kidsModeBackground = "pkg:/images/art-blur-background_kids.png"
      constants.ui.uris.backgroundFullScreenGradient = "pkg:/images/detail-gradient-25.png"
      constants.ui.uris.backgroundTopRightGradient = "pkg:/images/home-gradient-25.png"
      constants.ui.uris.backgroundFullScreenGradient_kidsMode = "pkg:/images/detail-gradient_kids.png"
      constants.ui.uris.backgroundTopRightGradient_kidsMode = "pkg:/images/home-gradient_kids.png"
      constants.ui.uris.sideNavBackground_kidsMode = "pkg:/images/sideNavBackground_kidsmode.png"

    constants.ui.colors = {}
      'template colors
      constants.ui.colors.transparent = "0x00000000"
      constants.ui.colors.backgroundColor = "0x191919FF"
      constants.ui.colors.focused = "0xFF501AFF"
      constants.ui.colors.unfocused = "0xFFFFFFFF"
      constants.ui.colors.selectedListItem = "0xFFFFFF33"
      constants.ui.colors.primaryText = "0xFFFFFFFF"
      constants.ui.colors.secondaryText = "0x777777FF"
      constants.ui.colors.focusedText = "0xFFFFFFFF"
      '//::NOTE::HARDCODED:: there is a BUG in the built in roku keyboard component'
      '// If the color is white, then it will make the focus color to a nearly-black gray.
      '// To combat this limitation, the color is set to white with a very slight, hardly-noticeable opacity.
      constants.ui.colors.keyboardFocusedText = "0xFFFFFFFE"
      constants.ui.colors.highlightedText = "0xFF501AFF"
      constants.ui.colors.shade = "0x191919FF"
      constants.ui.colors.spinnerBox = "0x2C2C2CFF"

      'textbox text colors
      constants.ui.colors.unselectedEntryText = "0x191919FF"
      constants.ui.colors.selectedEntryText = "0x191919FF"
      constants.ui.colors.selectedEntryBox = "0xF3C4B6FF"
      constants.ui.colors.unselectedEntryBox = "0xFFFFFFFF"
      
      'colors for individual elements - can be made individual or controlled by template colors
      constants.ui.colors.titleHeader = constants.ui.colors.primaryText
      constants.ui.colors.expirationWarning = "0xFF9933FF"
    
    'The IDs of the available themes that can be used for the app 
    constants.ui.themeIDs = {}
    constants.ui.themeIDs.default = "default"
    constants.ui.themeIDs.kidsMode = "kidsMode"

    'available themes that can be used for the app 
    constants.ui.themes = {}
      constants.ui.themes.default = {
        id: constants.ui.themeIDs.default
        focused: constants.ui.colors.focused
        highlightedText: constants.ui.colors.highlightcolor
        keyboard_focused_key: "pkg:/images/keyboard_search_focused_key.9.png"
        scrollbarThumbBitmapUri_hd: "pkg:/images/transport/sgplayer/hd/focused-progress-foreground.9.png"
        scrollbarThumbBitmapUri_fhd: "pkg:/images/transport/sgplayer/fhd/focused-progress-foreground.9.png"
      }
      constants.ui.themes.kidsMode = {
        id: constants.ui.themeIDs.kidsMode
        focused: "0xFEA534FF"
        highlightedText: "0xFEA534FF"
        keyboard_focused_key: "pkg:/images/keyboard_search_focused_key_kidsMode.9.png"
        scrollbarThumbBitmapUri_hd: "pkg:/images/transport/sgplayer/hd/focused-progress-foreground_kidsMode.9.png"
        scrollbarThumbBitmapUri_fhd: "pkg:/images/transport/sgplayer/fhd/focused-progress-foreground_kidsMode.9.png"
      }

    'fonts for UI elmements
    constants.ui.fonts = {}
      constants.ui.fonts.openSans = {}
        constants.ui.fonts.openSans.regular = "pkg:/fonts/OpenSans-Regular.ttf"
        constants.ui.fonts.openSans.bold = "pkg:/fonts/OpenSans-Bold.ttf"
        constants.ui.fonts.openSans.semiBold = "pkg:/fonts/OpenSans-SemiBold.ttf"
        constants.ui.fonts.openSans.italics = "pkg:/fonts/OpenSans-Italic.ttf"
        constants.ui.fonts.openSans.light = "pkg:/fonts/OpenSans-Light.ttf"

      constants.ui.fonts.categoryListFontType = constants.ui.fonts.openSans.light
      constants.ui.fonts.viewTitleAreaHeaderFontType = constants.ui.fonts.openSans.semiBold
      constants.ui.fonts.viewTitleAreaBodyFontType = constants.ui.fonts.openSans.regular
      constants.ui.fonts.posterLabelFontType = constants.ui.fonts.openSans.regular
      constants.ui.fonts.videoOptionsFontType = constants.ui.fonts.openSans.regular
      constants.ui.fonts.seasonFontType = constants.ui.fonts.openSans.regular
      constants.ui.fonts.episodeFontType = constants.ui.fonts.openSans.regular

    ' Set some performance parementers based on device profile
    constants.performance = {}
      constants.performance.categoryGridList = {}
      constants.performance.categoryGridList.initialBlockSize = 12

      if limitedUi
        ' Notes:
        ' - lowMemory devices may have 512MB but will have 256MB minimum.
        ' - the player needs about 70MB headroom to function well (calculated as free+cached)
        ' - the OS on a 256MB device only takes about 70MB on startup
        ' - VRAM on 256MB device is limited to 63MB and starts relieving pressure at ~90% full
        ' - Total app memory available = 256MB - 63MB - 70MB - 70MB = 53MB

        ' Tuning reference: Time to convert 200 metadata items (one category)
        '    2450X:   600 ms   (150 ms for 50 items)
        '    2710X:   500 ms
        '    3500X:   500 ms
        '    3600X:   120 ms
        '    4200X:   100 ms
        '    3710X:   150 ms
        '    5000X:   160 ms
        if lowMemory
          constants.performance.categoryGridList.finalBlockSize = 50
        else
          constants.performance.categoryGridList.finalBlockSize = 200
        end if
        if fastCpu
          constants.performance.categoryGridList.categoryWindowSize = 10
        else
          constants.performance.categoryGridList.categoryWindowSize = 5
        end if
        constants.performance.categoryGridList.initialBlockSize = 0
        constants.performance.categoryGridList.eagerLoad = true
      else
        constants.performance.categoryGridList.finalBlockSize = 200
        constants.performance.categoryGridList.categoryWindowSize = 10
        constants.performance.categoryGridList.eagerLoad = true
      end if
      
      constants.deeplinks = {}
      constants.deeplinks["homescreen"] = "homescreen"
      constants.deeplinks["hs-search"] = "search"
      constants.deeplinks["ad"] = "ad"
      constants.deeplinks["my-feed"] = "my-feed"
      constants.deeplinks["external-control"] = "deeplink-test"
      constants.deeplinks["partner-button"] = "remote-partner-button"
      constants.deeplinks["other-channel"] = "other-channel"
      constants.deeplinks["auto-run-dev"] = "sideload"
      constants.deeplinks["hs-d"] = "feature-free-page"
      constants.deeplinks["dial"] = "dial"
      
  return constants  
end Function
