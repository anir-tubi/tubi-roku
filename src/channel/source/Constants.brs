'define all the constants, like URLs that will be needed in the app
Function getConstants()
  constants = {}

  ' Compile-time generated
  constants.settings = getSettings()

  ' Device info
  constants.deviceInfo = {}
    di = CreateObject("roDeviceInfo")

    firmware = di.GetVersion() '034.08E01185A' string
    firmwareVersion = Val(Mid(firmware, 3, 4)) '4.08'  float
    firmwareVersionMajor = Val(Mid(firmware, 3, 1))  '4'  integer
    firmwareVersionMinor = Val(Mid(firmware, 5, 2))  '8'  integer
    firmwareBuild = Mid(firmware, 9, 4) '01185'  string

    if firmwareVersion >= 4.3
      countryCode = di.GetCountryCode()
    else
      countryCode = invalid
    end if

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

    'models that can run the new ui, but need some functionality reduced - like backgrounds and animations, etc.
    limitedNewUIModels = {
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
    if firmwareVersionMajor >= 8
      noFirmwareCaptionMenuModels.delete("4400X")
    end if

    if lowMemoryModels[di.GetModel()] <> invalid
      lowMemory = true
    else
      lowMemory = false
    end if

    if limitedNewUIModels[di.GetModel()] <> invalid
      limitedNewUi = true
    else
      limitedNewUi = false
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

    'get client version from manifest
    clientVersionNums = ["", "", ""]

    manifest = ReadASCIIFile("pkg:/manifest")
    lines = manifest.Tokenize(Chr(10))
    for each line in lines
      props = line.Tokenize("=")
      if props[0] = "major_version"
        clientVersionNums[0] = props[1]

      else if props[0] = "minor_version"
        clientVersionNums[1] = props[1]

      else if props[0] = "build_version"
        clientVersionNums[2] = props[1]
      end if
    end for

    clientVersion = ""
    for i=0 to clientVersionNums.count()-1
      clientVersion = clientVersion + clientVersionNums[i] + "."
    end for
    clientVersion = clientVersion + "newui.local"

    constants.deviceInfo.deviceId = di.GetDeviceUniqueId()
    constants.deviceInfo.deviceAdId = di.GetAdvertisingId()
    constants.deviceInfo.isAdIdTrackingDisabled = di.IsAdIdTrackingDisabled()
    constants.deviceInfo.ipAddresses = di.GetIPAddrs() 'array of network interface ip addresses (normally will only contain 1 element)
    constants.deviceInfo.firmwareVersion = firmwareVersion
    constants.deviceInfo.firmwareBuild = firmwareBuild
    constants.deviceInfo.userAgent = "Roku/DVP-" + firmwareVersionMajor.toStr() + "." + firmwareVersionMinor.toStr() + " (" + firmware + ")"
    constants.deviceInfo.userAgentModel = "Roku/DVP-" + firmwareVersionMajor.toStr() + "." + firmwareVersionMinor.toStr() + " (" + firmware + ") " + di.GetModel() 
    constants.deviceInfo.model = di.GetModel()
    constants.deviceInfo.definition = definition
    constants.deviceInfo.displayType = di.GetDisplayType()
    constants.deviceInfo.displayMode = di.GetDisplayMode()
    constants.deviceInfo.aspectRatio = di.GetDisplayAspectRatio()
    constants.deviceInfo.displaySize = di.GetDisplaySize()
    constants.deviceInfo.displayWidth = di.GetDisplaySize().w
    constants.deviceInfo.displayHeight = di.GetDisplaySize().h
    constants.deviceInfo.captionsMode = di.GetCaptionsMode()
    constants.deviceInfo.countryCode = countryCode ' will be invalid if old version of firmware
    constants.deviceInfo.lowMemory = lowMemory
    constants.deviceInfo.firmwareCaptionMenu = firmwareCaptionMenu
    constants.deviceInfo.limitedNewUi = limitedNewUi
    constants.deviceInfo.clientVersion = clientVersion
    constants.deviceInfo.language  = di.GetCurrentLocale().Left(2)
    constants.deviceInfo.scaledUi = scaledUi
    

  'the names of the registry memory sections that will save bookmark and previously viewed info
  constants.reqNames = {}
    constants.reqNames.searchAPI = "searchAPI"
    constants.reqNames.getCategory = "getCategory"
    constants.reqNames.getAllCategories = "getAllCategories"
    constants.reqNames.getFullBookmarks = "getFullBookmarks" 
    constants.reqNames.getFullHistory = "getFullHistory"
    constants.reqNames.getSingleContent = "getSingleContent"

  'Nielsen ID token for integrating with Nielsen DAR
  constants.nielsenToken = "PC60BD376-8551-4688-BEF4-E8B45A39D4C7"

  'platform is used when communitcating with CMS API
  constants.platform = "roku"

  'previously found in settings as "shortAppName"
  constants.appName = "tubitv"

  'experiment information will be placed here
  constants.experiments = {}
    constants.experiments.info = invalid    'will be replaced in main.brs

  'external configuration options will be placed here
  constants.externalConfig = {}
    constants.externalConfig.info = invalid   'will be replaced in main.brs

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

    'contents url
    constants.urls.cms = {}
      constants.urls.cms.urlBase = "https://uapi.adrise.tv/cms"
      constants.urls.cms.contents = constants.urls.cms.urlBase + "/contents"
      constants.urls.cms.singleContent = constants.urls.cms.urlBase + "/content"
      constants.urls.cms.categories = constants.urls.cms.urlBase + "/categories"

    'users url
    constants.urls.users = {}
      constants.urls.users.urlBase = "https://uapi.adrise.tv/user_device"
      constants.urls.users.login = constants.urls.users.urlBase + "/login"
      constants.urls.users.refreshToken = constants.urls.users.urlBase + "/login/refresh"
      constants.urls.users.transferToken = constants.urls.users.urlBase + "/login/transfer"
      constants.urls.users.migrateLogin = constants.urls.users.urlBase + "/login/migrate"
      constants.urls.users.queues = constants.urls.users.urlBase + "/queues"
      constants.urls.users.history = constants.urls.users.urlBase + "/histories"
      constants.urls.users.config = constants.urls.users.urlBase + "/config/" + constants.platform


    'search url
    constants.urls.searchBaseUrl = "http://cms.adrise.com/"

    'user event tracking url
    constants.urls.dataScience = {}
      ' constants.urls.dataScience.urlBase = "https://staging-uapi.adrise.tv/datascience"
      constants.urls.dataScience.urlBase = "https://uapi.adrise.tv/datascience"
      constants.urls.datascience.event = constants.urls.dataScience.urlBase + "/event"
      constants.urls.datascience.experiment = constants.urls.dataScience.urlBase + "/evaluate/namespaces"
      constants.urls.datascience.logging = constants.urls.dataScience.urlBase + "/logging"

    'matrix API urls
    constants.urls.matrix = {}
      constants.urls.matrix.urlBase = "https://uapi.adrise.tv/matrix"

    'live tv urls
    constants.urls.liveTv = {}
      constants.urls.liveTv.getAll = constants.urls.matrix.urlBase + "/livetv"

    'cuepoints url
    constants.urls.cuepointsBaseUrl = "http://ads.adrise.tv/cue-points/"

    'linear schedule url
    constants.urls.linearUrl = "http://cms.adrise.com/v3/livetv?cid=roku&platform=roku&id=tubitv"

    'linear poster art urls'
    constants.urls.linearPosterSDUrl = "http://cdn.adrise.com/hotpatches/roku/LinearTV-beta-SD.jpg"
    constants.urls.linearPosterHDUrl = "http://cdn.adrise.com/hotpatches/roku/LinearTV-beta-HD.jpg"

    'privacy statement text
    constants.urls.privacyUrl = "http://cdn.adrise.tv/legal/TubiTVPrivacyPolicy.txt"

    constants.urls.transportButtons = {}
      constants.urls.transportButtons.fastForward = "pkg:/images/transport/sgplayer/icon-ffw.png"
      constants.urls.transportButtons.rewind = "pkg:/images/transport/sgplayer/icon-rew.png"
      constants.urls.transportButtons.pause = "pkg:/images/transport/sgplayer/icon-pause.png"
      constants.urls.transportButtons.play = "pkg:/images/transport/sgplayer/icon-play.png"
      constants.urls.transportButtons.toEnd = "pkg:/images/transport/sgplayer/icon-to-end.png"
      constants.urls.transportButtons.toStart = "pkg:/images/transport/sgplayer/icon-to-start.png"

  'http request types
  constants.reqTypes = {}
    constants.reqTypes.get = "GET"
    constants.reqTypes.post = "POST"
    constants.reqTypes.put = "PUT"
    constants.reqTypes.del = "DELETE"

  'common http request headers
  constants.headers = {}
    constants.headers.json = {"Content-Type": "application/json"}

  'content type strings that we might get returned from uapi
  constants.uapiContentTypes = {}
    constants.uapiContentTypes.movie = "movie"
    constants.uapiContentTypes.series = "series"
    constants.uapiContentTypes.episode = "episode"

  'uapi actions - add or delete from user categories
  constants.uapiActions = {}
    constants.uapiActions.add = "add"
    constants.uapiActions.remove = "remove"

  constants.timers = {}
    constants.timers.remoteComponentTimeout = 30000

  'constants needed for the video player
  constants.player = {}

    constants.player.creditsDuration = 180

    'how often the video player sends play progress events
    constants.player.pingFrequency = 10

    'how often the video player records history
    constants.player.historyFrequency = 60

    'the max number of distinct speeds at which the player can scrub (fast forward or rewind), 0 based
    constants.player.maxScrub = 2 

    'list of scrub multipliers, the number of options should match the maxScrub above
    constants.player.scrubMultipliers = [8, 64, 128]

    'the number of seconds before the video player transport autohides during playback
    constants.player.transportAutoHideTime = 5

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

  'UI properties that should be passed into the scene graph
  constants.ui = {}

    'constants needed for on now UI
    constants.ui.onNow = {}
      constants.ui.onNow.disableOnNow = false
      constants.ui.onnow.on = false
      constants.ui.onNow.channelId = "livetv_clips"

    'constants needed for sign in flow experimentation
    constants.ui.signIn = {}
      constants.ui.signIn.skipContinueScreen = false
      constants.ui.signIn.skipSignInRegisterScreen = false
      constants.ui.signIn.backExitsSignIn = false
      constants.ui.signIn.skipSignInOption = true    ' if true, suppress the "Sign in via Email" button on reg code screen

    'static - pre defined category names
    constants.ui.categoryNames = {}
      constants.ui.categoryNames.topCategory = "Featured"
      constants.ui.categoryNames.signedOutTools = "Search & Sign In"
      constants.ui.categoryNames.signedInTools = "Search & Sign Out"
      constants.ui.categoryNames.history = "Continue Watching"
      constants.ui.categoryNames.queue = "My Queue"

    constants.ui.categoryIds = {}
      constants.ui.categoryIds.history = "continue_watching"
      constants.ui.categoryIds.queue = "my_queue"

    constants.ui.contentTypes = {}
      constants.ui.contentTypes.series = "series"
      constants.ui.contentTypes.video = "video"
      constants.ui.contentTypes.episode = "episode"
      constants.ui.contentTypes.season = "season"
      constants.ui.contentTypes.category = "category"

    'screen ids in the UI
    constants.ui.screenIds = {}
      constants.ui.screenIds.details = "detailScreen"
      constants.ui.screenIds.category = "categoryScreen"

    constants.ui.uris = {}
      'background gradient urls
      constants.ui.uris.homeBackgroundGradient = "pkg:/images/home-gradient-25.png"
      constants.ui.uris.detailBackgroundGradient = "pkg:/images/detail-gradient-25.png"

      'default background image uri
      constants.ui.uris.defaultBackground = "pkg:/images/art-blur-background.png"

    constants.ui.colors = {}
      'template colors
      constants.ui.colors.transparent = "0x00000000"
      constants.ui.colors.backgroundColor = "0x191919FF"
      constants.ui.colors.focused = "0xFF501AFF"
      constants.ui.colors.unfocused = "0xFFFFFFFF"
      constants.ui.colors.primaryText = "0xFFFFFFFF"
      constants.ui.colors.secondaryText = "0x777777FF"
      constants.ui.colors.focusedText = "0xFFFFFFFF"
      constants.ui.colors.highlightedText = "0xFF501AFF"
      constants.ui.colors.shade = "0x191919FF"
      constants.ui.colors.spinnerBox = "0x2C2C2CFF"

      'textbox text colors
      constants.ui.colors.unselectedEntryText = "0x191919FF"
      constants.ui.colors.selectedEntryText = "0x191919FF"
      constants.ui.colors.selectedEntryBox = "0xF3C4B6FF"
      constants.ui.colors.unselectedEntryBox = "0xFFFFFFFF"
      
      'colors for individual elements - can be made individual or controlled by template colors
      constants.ui.colors.heroFilter = constants.ui.colors.backgroundColor
      constants.ui.colors.titleHeader = constants.ui.colors.primaryText
      constants.ui.colors.titleMetaData = constants.ui.colors.secondaryText
      constants.ui.colors.titleDescription = constants.ui.colors.primaryText
      constants.ui.colors.focusedCategoryList = constants.ui.colors.focused
      constants.ui.colors.unfocusedCategoryList = constants.ui.colors.unfocused
      constants.ui.colors.categoryContentBorder = constants.ui.colors.focused
      constants.ui.colors.categoryContentInnerBorder = constants.ui.colors.backgroundColor
      constants.ui.colors.categoryListCursor = constants.ui.colors.focused
      constants.ui.colors.posterLabel = constants.ui.colors.primaryText
      constants.ui.colors.videoOptionsMainSelection = constants.ui.colors.focused
      constants.ui.colors.videoOptionsHistoryIndicator = constants.ui.colors.unfocused
      constants.ui.colors.videoOptionsMainSelectionText = constants.ui.colors.unfocused
      constants.ui.colors.focusedVideoOptions = constants.ui.colors.focused
      constants.ui.colors.unfocusedVideoOptions = constants.ui.colors.unfocused
      constants.ui.colors.videoOptionsCursor = constants.ui.colors.focused
      constants.ui.colors.seasonContentTitle = constants.ui.colors.primaryText
      constants.ui.colors.episodeBorder = constants.ui.colors.focused
      constants.ui.colors.episodeInnerBorder = constants.ui.colors.backgroundColor
      constants.ui.colors.searchUpdatingText = constants.ui.colors.secondaryText

    'fonts for UI elmements
    constants.ui.fonts = {}
      constants.ui.fonts.openSans = {}
        constants.ui.fonts.openSans.regular = "pkg:/fonts/OpenSans-Regular.ttf"
        constants.ui.fonts.openSans.bold = "pkg:/fonts/OpenSans-Bold.ttf"
        constants.ui.fonts.openSans.semiBold = "pkg:/fonts/OpenSans-Semibold.ttf"
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
      if limitedNewUi
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
        if lowMemory
          constants.performance.categoryGridList.blockSize = 50
          constants.performance.categoryGridList.categoryWindowSize = 5
        else
          constants.performance.categoryGridList.blockSize = 200
          constants.performance.categoryGridList.categoryWindowSize = 5
        end if
        constants.performance.categoryGridList.eagerLoad = false
      else
        constants.performance.categoryGridList.blockSize = 200
        constants.performance.categoryGridList.categoryWindowSize = 10
        constants.performance.categoryGridList.eagerLoad = true
      end if
  return constants  
end Function
