'define all the constants, like URLs that will be needed in the app
Function getConstants()
  constants = {}

  ' Compile-time generated
  constants.settings = getSettings()

  'content IDs used to store things in the registry
  constants.registryIDs = {}
    constants.registryIDs.deviceId = "deviceId"

  'Registry Section IDs used to store things in a particular section of the registry
  constants.registrySectionIDs = {}
    constants.registrySectionIDs.deviceInfoSectionId = "deviceinfo"

    ' Creating a section to store all fallbacks in future to start with we are using for blocked analytics events.
    constants.registrySectionIDs.fallbacks = "fallbacks"

    ' Creating a section to store user sign up information in case of registration failure.
    constants.registrySectionIDs.registrationByPass = "registrationByPass"

    ' Used for storing proxy settings
    constants.registrySectionIDs.settingsOverride = "settingsOverride"

    ' Used to store overrides like for the external config like for disabling magiclink for Roku. Stores a json inside that needs to be parsed.
    constants.registrySectionIDs.overrides = "overrides"

    settingsOverride = RegReadAll(constants.registrySectionIDs.settingsOverride)
  if type(settingsOverride) = "roAssociativeArray" AND settingsOverride.charlesProxyEnabled <> invalid AND settingsOverride.charlesProxyUrl <> invalid  then
    constants.settings.charlesProxyEnabled = (settingsOverride.charlesProxyEnabled = "true")
    constants.settings.charlesProxyUrl = settingsOverride.charlesProxyUrl
  end if

  if type(settingsOverride) = "roAssociativeArray" AND settingsOverride.sudoCountry <> invalid then
    constants.settings.sudoCountry = settingsOverride.sudoCountry
  end if

  ' Roku's channel/app id for the production Tubi app. It is used with the continue watching feature to enable testing the feature in sideloaded/beta channels.
  constants.productionApplicationId = "41468"

  mode = constants.settings.mode
  if mode = invalid then mode = "dev"

  constants.audioGuideHints = {}
    constants.audioGuideHints.emailOkHint = "Press ok to enter your email"
    constants.audioGuideHints.buttonHint = "Button"
    constants.audioGuideHints.transportBarIcons = {}
      constants.audioGuideHints.transportBarIcons.skipTrailerButtonHint = "Skip Trailer Button"
      constants.audioGuideHints.transportBarIcons.playFromBeginningButtonHint = "Play from Beginning Button"
      constants.audioGuideHints.transportBarIcons.goToNextVideoButtonHint = "Go to next video Button"
      constants.audioGuideHints.transportBarIcons.rewindButtonHint = "Rewind Button"
      constants.audioGuideHints.transportBarIcons.playButtonHint = "Play Button"
      constants.audioGuideHints.transportBarIcons.pauseButtonHint = "Pause Button"
      constants.audioGuideHints.transportBarIcons.hopForwardButtonHint = "Fast Forward"
      constants.audioGuideHints.transportBarIcons.hopBackButtonHint = "Rewind"
      constants.audioGuideHints.transportBarIcons.fastForwardButtonHint = "Fast Forward Button"
      constants.audioGuideHints.transportBarIcons.closedCaptionAudioButtonHint = "Closed Caption And Audio Track Selection Button"
      constants.audioGuideHints.transportBarIcons.sendFeedbackButtonHint = "Send Feedback Button"


  ' Device info
  constants.deviceInfo = {}
    di = CreateObject("roDeviceInfo")

    firmware = di.GetOSVersion() '{build: "4195", major: "10", minor: "0", revision: "0"}' roAssociativeArray

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
      "3600X":  true  ' QuadCore Stick (2016)
      "3800X": 	true  ' Stick (2017)
      "3900X": 	true  ' Express (2017)
      "3910X": 	true  ' Express+ (2017)
      "3930X": 	true  ' Express (2019)
      "3931X": 	true  ' Express+ 	(2019)
      "3960X": 	true  ' Express (2022)
      "4200X": 	true  ' 3 (2013)
      "4210X": 	true  ' 2 (2015)
      "4230X": 	true  ' 3 (2015)
      "8000X": 	true  ' Roku TV midland
      "D000X": 	true  ' Roku TV Roma
      "H000X": 	true  ' 2K Roku TV Miami
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
    }

    ' List all devices with analog output that we support still
    devicesWithAnalogOutput = {
      "2700X": true
      "2710X": true
      "2720X": true
      "3710X": true
      "3910X": true
    }

    deviceModel = di.GetModel()

    isAnalogOutputDevice = (devicesWithAnalogOutput[deviceModel] = true)

    ' Firmware 8.0.0 added a system dialog for captions on Roku 4
    if Val(firmware.major) >= 8
      noFirmwareCaptionMenuModels.delete("4400X")
    end if

    if lowMemoryModels[deviceModel] <> invalid
      lowMemory = true
    else
      lowMemory = false
    end if

    if limitedUIModels[deviceModel] <> invalid
      limitedUi = true
      if limitedUIWithFastCPU[deviceModel] <> invalid
        fastCpu = true
      else
        fastCpu = false
      end if
    else
      limitedUi = false
      fastCpu = true
    end if

    if lowVram[deviceModel] <> invalid
      lowVram = true
    else
      lowVram = false
    end if

    if noFirmwareCaptionMenuModels[deviceModel] <> invalid
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

    ' get the version numbers from settings rather than from appInfo, as appInfo contains
    ' info about the submitted release, but we want to store the version of the remote components.
    versionNumbers = constants.settings.version.split("_")
    majorVersion = versionNumbers[0]
    minorVersion = versionNumbers[1]
    buildVersion = versionNumbers[2]
    revisionVersion = versionNumbers[3]
    '//ensure the client number does not include the revisionVersion so the the rest of the app does not see it.
    clientVersion = majorVersion + "." + minorVersion + "." + buildVersion

    'Use newer APIs over deprecated APIs when appropriate
    if FindMemberFunction(di, "GetChannelClientId") <> invalid
      storedDeviceId = RegRead(constants.registryIDs.deviceId, constants.registrySectionIDs.deviceInfoSectionId)
      if storedDeviceId <> invalid AND storedDeviceId <> "000000000000"
        constants.deviceInfo.deviceId = storedDeviceId
      else
        constants.deviceInfo.deviceId = di.GetChannelClientId()
        RegWrite(constants.registryIDs.deviceId, constants.deviceInfo.deviceId, constants.registrySectionIDs.deviceInfoSectionId)
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

    constants.deviceInfo.operatingSystem = "Roku OS"
    constants.deviceInfo.firmwareVersion = firmware.major + "." + firmware.minor + "." + firmware.revision + "." + firmware.build
    constants.deviceInfo.userAgent = "Roku/DVP-" + firmware.major + "." + firmware.minor + " (" + firmware.major + "." + firmware.minor + "." + firmware.revision + "." + firmware.build + ")"
    constants.deviceInfo.userAgentModel = "Roku/DVP-" + firmware.major + "." + firmware.minor + " (" + firmware.major + "." + firmware.minor + "." + firmware.revision + "." + firmware.build + ") " + deviceModel
    constants.deviceInfo.model = deviceModel
    constants.deviceInfo.vendorName = di.GetModelDetails().VendorName
    constants.deviceInfo.displayWidth = di.GetDisplaySize().w
    constants.deviceInfo.displayHeight = di.GetDisplaySize().h
    constants.deviceInfo.rokuCountryCode = di.GetUserCountryCode()
    'This will return true for any remote that has voice input
    constants.deviceInfo.hasVoiceRemoteFeature = (di.HasFeature("voice_remote") or di.HasFeature("handsfree_voice"))
    if constants.deviceInfo.rokuCountryCode <> invalid
      'rokuCountryCode will be used for the value of countryCode, unless it is overridden by externalConfig.info.country.
      'Keep a record of the original rokuCountryCode value in case we ever need to know the non-overwritten value.
      constants.deviceInfo.rokuCountryCode = UCase(constants.deviceInfo.rokuCountryCode)
    end if
    constants.deviceInfo.countryCode = constants.deviceInfo.rokuCountryCode
    constants.deviceInfo.channelStore = di.GetCountryCode()  'some channel store strings look like country codes
    constants.deviceInfo.fastCpu = fastCpu
    constants.deviceInfo.lowVram = lowVram
    constants.deviceInfo.firmwareCaptionMenu = firmwareCaptionMenu
    constants.deviceInfo.limitedUi = limitedUi
    constants.deviceInfo.isAnalogOutputDevice = isAnalogOutputDevice
    constants.deviceInfo.clientVersion = clientVersion
    constants.deviceInfo.majorVersion = majorVersion
    constants.deviceInfo.minorVersion = minorVersion
    constants.deviceInfo.buildVersion = buildVersion
    constants.deviceInfo.revisionVersion = revisionVersion
    constants.deviceInfo.language  = di.GetCurrentLocale().Left(2)
    constants.deviceInfo.locale  = di.GetCurrentLocale()
    constants.deviceInfo.scaledUi = scaledUi
    constants.deviceInfo.videoMode = di.GetVideoMode()
    if FindMemberFunction(di, "IsAutoplayEnabled") <> invalid
      constants.deviceInfo.isAutoplayEnabled = di.IsAutoplayEnabled()
    else
      constants.deviceInfo.isAutoplayEnabled = true
    end if
    videoResolution = constants.deviceInfo.videoMode.toInt()

  'names given to different request types for identification purposes (for example in the General Task)
  constants.reqNames = {}
    constants.reqNames.getAutocomplete = "getAutocomplete"
    constants.reqNames.getSearchScreen = "getSearchScreen"
    constants.reqNames.getHomescreen = "getHomescreen"
    constants.reqNames.getMiniHomescreen = "getMiniHomescreen"
    constants.reqNames.getCategoriesListScreen = "getCategoriesListScreen"
    constants.reqNames.getCategoryDetailsScreen = "getCategoryDetailsScreen"
    constants.reqNames.getSearchDefault = "getSearchDefault"
    constants.reqNames.getCategory = "getCategory"
    constants.reqNames.getMyStuffContainers = "getMyStuffContainers"
    constants.reqNames.getSingleContent = "getSingleContent"
    constants.reqNames.getMultipleContent = "getMultipleContent"
    constants.reqNames.getUpNextContent = "getUpNextContent"
    constants.reqNames.getRelatedContent = "getRelatedContent"
    constants.reqNames.getThumbnails = "getThumbnails"
    constants.reqNames.getLiveManifest = "getLiveManifest"
    constants.reqNames.emailExists = "emailExists"
    constants.reqNames.signUp = "signUp"
    constants.reqNames.signIn = "signIn"
    constants.reqNames.deviceRegister = "deviceRegister" 'verify age
    constants.reqNames.checkBirthdayInfo = "checkBirthdayInfo" 'verify age
    constants.reqNames.patchUserSettings = "patchUserSettings"
    constants.reqNames.sponsorPixel = "sponsorPixel"
    constants.reqNames.skinAdPixel = "skinAdPixel"
    constants.reqNames.getEPGChannelIds = "getEPGChannelIds"
    constants.reqNames.getEPGPrograms = "getEPGPrograms"
    constants.reqNames.postUserHistory = "postUserHistory"
    constants.reqNames.getQueue = "getQueue"
    constants.reqNames.getHistory = "getHistory"
    constants.reqNames.generic = "generic"
    constants.reqNames.genericWithResponseContext = "genericWithResponseContext"
    constants.reqNames.magicLink = "magicLink"
    constants.reqNames.queryStatusOfMagicLink = "queryStatusOfMagicLink"
    constants.reqNames.getContentRating = "getContentRating"
    constants.reqNames.setContentRating = "setContentRating"
    constants.reqNames.updateParentalRating = "updateParentalRating"
    constants.reqNames.deleteFromQueue = "deleteFromQueue"
    constants.reqNames.postToQueue = "postToQueue"
    constants.reqNames.deleteHistory = "deleteHistory"
    constants.reqNames.getScreenSaverContainer = "getScreenSaverContainer"
    constants.reqNames.getScreenSaverHomeScreenContainerIds = "getScreenSaverHomeScreenContainerIds"
    constants.reqNames.getNamespaces = "getNamespaces"
    constants.reqNames.getExternalConfigs = "getExternalConfigs"
    constants.reqNames.getServerPersistentData = "getServerPersistentData"
    constants.reqNames.patchServerPersistentData = "patchServerPersistentData"
    constants.reqNames.getPauseAd = "getPauseAd"
    constants.reqNames.postPauseAdPixel = "postPauseAdPixel"
    constants.reqNames.getConsent = "getConsent"
    constants.reqNames.patchConsent = "patchConsent"
    constants.reqNames.postRokuContinueWatching = "postRokuContinueWatching"
    constants.reqNames.deleteRokuContinueWatching = "deleteRokuContinueWatching"
    constants.reqNames.clearRokuContinueWatching = "clearRokuContinueWatching"
    constants.reqNames.getUserSettings = "getUserSettings"
    constants.reqNames.postAnalytics = "postAnalytics"
    constants.reqNames.postBrazeMergeUsers = "postBrazeMergeUsers"
    constants.reqNames.postLogout = "postLogout"
    constants.reqNames.postViewableImpression = "postViewableImpression"

    ' a list of reqnames that the general task will inject auth headers and should expect to handle 403 errors for
    constants.reqNames.acceptsTubiAuth = {}
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getQueue] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getHistory] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.patchUserSettings] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.checkBirthdayInfo] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getAutocomplete] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getSearchScreen] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getHomescreen] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getMiniHomescreen] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getCategoriesListScreen] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getCategoryDetailsScreen] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getSearchDefault] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getCategory] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getMyStuffContainers] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getSingleContent] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getUpNextContent] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getRelatedContent] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getThumbnails] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getLiveManifest] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.emailExists] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.magicLink] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.queryStatusOfMagicLink] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.postUserHistory] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.signup] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.signIn] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getContentRating] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.setContentRating] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.updateParentalRating] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.deleteFromQueue] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.postToQueue] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.deviceRegister] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.deleteHistory] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getEPGChannelIds] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getServerPersistentData] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.patchServerPersistentData] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getConsent] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.patchConsent] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getUserSettings] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.postLogout] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.postAnalytics] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.postViewableImpression] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getPauseAd] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getNamespaces] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getExternalConfigs] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getLiveManifest] = true
      constants.reqNames.acceptsTubiAuth[constants.reqNames.getEPGPrograms] = true

  constants.anonymous = {}
    constants.anonymous.algorithm = "TUBI-HMAC-SHA256"

  constants.thirdParty = {}
    'Nielsen ID token for integrating with Nielsen DAR via RAF
    constants.thirdParty.nielsen = {}
      constants.thirdParty.nielsen.rafToken = "PB8C78BDD-9B1B-4020-B4DD-AE7917C0F396"
      constants.thirdParty.nielsen.pingToken = "PB8C78BDD-9B1B-4020-B4DD-AE7917C0F396"
      constants.thirdParty.nielsen.intId = "v1pi01kzclhgle4jmjek1ihmoe" 'a hard coded integration ID to be used in nielsen pings

      constants.thirdParty.nielsen.pingTypes = {}
        constants.thirdParty.nielsen.pingTypes.sessionStart = "session_start"
        constants.thirdParty.nielsen.pingTypes.sessionEnd = "session_end"
        constants.thirdParty.nielsen.pingTypes.streamStart = "stream_start"
        constants.thirdParty.nielsen.pingTypes.streamEnd = "stream_end"

    constants.thirdParty.youbora = {}
      constants.thirdParty.youbora.config = {}
        ' DEVELOPMENT
        ' constants.thirdParty.youbora.config.accountCode = "tubitvdev" 'This is the only mandatory param
        ' PRODUCTION
        constants.thirdParty.youbora.config.accountCode = "tubitv" 'This is the only mandatory param

        constants.thirdParty.youbora.config.expectAds = true

        constants.thirdParty.youbora.trackingKeys = {}
          ' If the content is coming from a titan endpoint, then a generator_version will be set to this field.
          constants.thirdParty.youbora.trackingKeys.generatorVersion = "generatorVersion"
          ' If the content is coming from a titan endpoint, then a titan_version will be set to this field.
          ' Or if any experiment is running on client side related to video stream formats, then experiment and treatment names will be set to this field
          constants.thirdParty.youbora.trackingKeys.titanVersionOrExperimentVersion = "titanVersionOrExperimentVersion"
          ' which ssai is used
          constants.thirdParty.youbora.trackingKeys.ssaiVersion = "ssaiVersion"

    constants.thirdParty.sentry = {}
      constants.thirdParty.sentry.dsn = "https://f8edcfe8baf140b4b91b46dfb8af9a19:acdf43f7c38a47f1ab85583035ff1798@sentry.io/1377102"

    constants.thirdParty.braze = {}
      constants.thirdParty.braze.apiKey = "a97de018-d2c3-47a4-ada4-7b12dc579255"
      constants.thirdParty.braze.restApiKey = "d2271dbb-5cc7-4e08-b5d1-f4effe673390"
      ' All non production environments will use staging api key.
      if constants.settings.mode <> "production"
        constants.thirdParty.braze.apiKey = "be27ec5f-5d30-4014-94cd-009a0a0d1c48"
        constants.thirdParty.braze.restApiKey = "a57e485c-157a-4cca-8cb1-7dda9018c83d"
      end if
      constants.thirdParty.braze.endpoint = "https://sdk.iad-01.braze.com/"
      ' Configurable starting with 1 hour will adjust based on feedback.
      ' We have to be conservative with this time since every time refresh happens their is registry read/write.
      constants.thirdParty.braze.refreshFrequency = 3600

    constants.thirdParty.suiteTest = {}

      'toggle for using suitest or not. Should only be set to true for testing situations.
      'for production it should be false
      constants.thirdParty.suiteTest.enabled = false
      if constants.settings.suitest = true
        constants.thirdParty.suiteTest.enabled = true

        ' app_id of suitest application - can be used for any roku device within same organization. update app_id for using different account.
        constants.thirdParty.suiteTest.app_id =  "214cab71-b41b-468d-bcbb-f42732b157c4"

      end if
    constants.thirdParty.oneTrust = {}
      constants.thirdParty.oneTrust.applicationId = "018fc642-7625-7794-9589-c36d2f0bb32c"
      ' All non production environments will use staging api key.
      ' There is no cache when we use test mode, meaning changes can be viewed immediately.
      if constants.settings.mode <> "production"
        constants.thirdParty.oneTrust.applicationId = "018fc642-7625-7794-9589-c36d2f0bb32c-test"
      end if
      constants.thirdParty.oneTrust.location = "cdn.cookielaw.org"
      constants.thirdParty.oneTrust.version = "202405.1.0"

  'platform is used when communitcating with CMS API
  constants.platform = "roku"
  if LCase(constants.deviceInfo.channelStore) = "telstra"
    constants.platform = "telstra"
  end if

  'analyticsPlatform is used when sending analytics events and making rainmaker ad requests
  constants.analyticsPlatform = "ROKU"
  if LCase(constants.deviceInfo.channelStore) = "telstra"
    constants.analyticsPlatform = "TELSTRA"
  end if

  'Types of actions for modal dialogs.
  ' "restartApp" - will clear screen stack and restarts the app from beginning.
  ' "closeDialog" - user attention modal(signout modal, app exit modal etc), we are closing the modal and resume the app
  ' "startChannel" - will bring the user to the default homescreen
  constants.instantResumeActions = {}
    constants.instantResumeActions.closeDialog = "closeDialog"
    constants.instantResumeActions.startChannel = "startChannel"
    constants.instantResumeActions.restartApp = "restartApp"

  'Types of modal dialogs
  constants.modalDialogTypes = {}
    constants.modalDialogTypes.multiStyle = "multiStyle"


  'Styles of modal Dialogs
  constants.modalDialogStyles = {}
    constants.modalDialogStyles.multiMessageGroup = "multiMessageGroup"

  'previously found in settings as "shortAppName"
  constants.appName = "tubitv"

  constants.logoType = {}
    constants.logoType.tubi = "tubi"
    constants.logoType.tubiKids = "tubi_kids"
    constants.logoType.tubiEspanol = "tubi_espanol"
    constants.logoType.hide = "hide"

  ' Should the user be shown the upgrade alert to help them upgrade to the latest version.
  '   Used within the hotpatch after a point release to nudge users to use the latest app
  constants.showUpgradeAlert = false

  'a list of device ids that will send debug and info logs to the logging API - this will be populated by hotpatch
  'idsToLog is expected to look like {
  '  13GSC41289Y: true
  '  YY00763924H: true
  '}
  constants.idsToLog = {}

  constants.urls = {}
    'ad server url
    constants.urls.adsBaseUrlRainmaker = "https://rainmaker.staging-public.tubi.io/api/v2/rev/vod/"
    'if constants.settings.mode = "production" or constants.settings.mode = "staging"
      constants.urls.adsBaseUrlRainmaker = "https://rainmaker.production-public.tubi.io/api/v2/rev/vod/"
    'end if

    'pause ad server url
    constants.urls.pauseAdsUrl = "https://ads.production-public.tubi.io/pause/v1/" + constants.analyticsPlatform
    if constants.settings.mode <> "production" AND constants.settings.stagingApis = true
      constants.urls.pauseAdsUrl = "https://ads.staging-public.tubi.io/pause/v1/" + constants.analyticsPlatform
    end if

    'contents cms url
    constants.urls.cms = {}

      constants.urls.cms.urlBase = "https://content-cdn.production-public.tubi.io/cms"
      if constants.settings.mode <> "production" AND constants.settings.stagingApis = true
        constants.urls.cms.urlBase = "https://content-cdn.staging-public.tubi.io/cms"
      end if

      constants.urls.cms.thumbnails = constants.urls.cms.urlBase + "/content" ' + content_id + "/thumbnail_sprites"

    'contents content url
    constants.urls.content = {}

      constants.urls.content.urlBase = "https://content-cdn.production-public.tubi.io/api"
      if constants.settings.mode <> "production" AND constants.settings.stagingApis = true
        constants.urls.content.urlBase = "https://content-cdn.staging-public.tubi.io/api"
      end if
      constants.urls.content.singleContent = constants.urls.content.urlBase + "/v2/content"

      'epgProgram url
      constants.urls.content.epgProgramContentUrlBase = "https://epg-cdn.production-public.tubi.io"
      if constants.settings.mode <> "production" AND constants.settings.stagingApis = true
        constants.urls.content.epgProgramContentUrlBase = "https://epg-cdn.staging-public.tubi.io"
      end if
      constants.urls.content.epgProgramContent = constants.urls.content.epgProgramContentUrlBase + "/content/epg/programming"

      'autopilot url
    constants.urls.autopilot = {}
      constants.urls.autopilot.urlBase = "https://autopilot-cdn.production-public.tubi.io/api"

      if constants.settings.mode <> "production" AND constants.settings.stagingApis = true
        constants.urls.autopilot.urlBase = "https://autopilot-cdn.staging-public.tubi.io/api"
      end if

      constants.urls.autopilot.relatedContent = constants.urls.autopilot.urlBase + "/v1/related"
      constants.urls.autopilot.upNextContent = constants.urls.autopilot.urlBase + "/v3/autoplay"

    'search url
    constants.urls.search = "https://search.production-public.tubi.io/api/v2/search"
    if constants.settings.mode <> "production" AND constants.settings.stagingApis = true
      constants.urls.search = "https://search.staging-public.tubi.io/api/v2/search"
    end if

    'autocomplete search url
    constants.urls.autocomplete = "https://search.production-public.tubi.io/api/v1/autocomplete"
    if constants.settings.mode <> "production" AND constants.settings.stagingApis = true
      constants.urls.autocomplete = "https://search.staging-public.tubi.io/api/v1/autocomplete"
    end if

    'tensor url
    constants.urls.tensor = {}
      ' tensor cdn url
      constants.urls.tensor.cdn = {}
        constants.urls.tensor.cdn.urlBase = "https://tensor-cdn.production-public.tubi.io/api"
        if constants.settings.mode <> "production" AND constants.settings.stagingApis = true
          constants.urls.tensor.cdn.urlBase = "https://tensor-cdn.staging-public.tubi.io/api"
        end if
        constants.urls.tensor.cdn.homescreen = constants.urls.tensor.cdn.urlBase + "/v6/homescreen"
        constants.urls.tensor.cdn.container = constants.urls.tensor.cdn.urlBase + "/v6/containers"
        constants.urls.tensor.cdn.epgChannelIds = constants.urls.tensor.cdn.urlBase + "/v2/epg"
        constants.urls.tensor.cdn.browserList = constants.urls.tensor.cdn.urlBase + "/v1/browse_list"

    'remote Config hub url
    constants.urls.configHub = {}
      constants.urls.configHub.urlBase = "https://config-hub-cdn.production-public.tubi.io"

      if constants.settings.mode <> "production" AND constants.settings.stagingApis = true
        constants.urls.configHub.urlBase = "https://config-hub-cdn.staging-public.tubi.io"
      end if

      constants.urls.configHub.config = constants.urls.configHub.urlBase + "/api/v1/remote_config/" + constants.platform


    'use queue urls
    constants.urls.userQueues = {}
    constants.urls.userQueues.urlBase = "https://user-queue.production-public.tubi.io/api/"
      if constants.settings.mode <> "production" AND constants.settings.stagingApis = true
        constants.urls.userQueues.urlBase = "https://user-queue.staging-public.tubi.io/api/"
      end if

      constants.urls.userQueues.queues = constants.urls.userQueues.urlBase + "v2/queues"

    ' account urls
    constants.urls.account = {}
      constants.urls.account.urlBase = "https://account.production-public.tubi.io"
      if constants.settings.mode <> "production" AND constants.settings.stagingApis = true
        constants.urls.account.urlBase = "https://account.staging-public.tubi.io"
      end if
      constants.urls.account.emailExists = constants.urls.account.urlBase + "/user/email_available"
      constants.urls.account.login = constants.urls.account.urlBase + "/user/login"
      constants.urls.account.checkBirthday = constants.urls.account.urlBase + "/user/check_birthday_info"
      constants.urls.account.deviceRegister = constants.urls.account.urlBase + "/device/register"
      constants.urls.account.userSettings = constants.urls.account.urlBase + "/user/settings"
      constants.urls.account.contentRating = constants.urls.account.urlBase + "/user/preferences/rate"
      constants.urls.account.parentalRating = constants.urls.account.userSettings + "/parental_rating"
      constants.urls.account.magicLink = constants.urls.account.urlBase + "/device/magic_link"
      constants.urls.account.signup = constants.urls.account.urlBase + "/user/signup"
      constants.urls.account.deviceSettings = constants.urls.account.urlBase + "/device/settings"
      constants.urls.account.consent = constants.urls.account.urlBase + "/consent"

      constants.urls.account.anonymousSigningKey = constants.urls.account.urlBase + "/device/anonymous/signing_key"
      constants.urls.account.anonymousToken = constants.urls.account.urlBase + "/device/anonymous/token"
      constants.urls.account.anonymousRefreshToken = constants.urls.account.urlBase + "/device/anonymous/refresh"

      ' Moving userDevice urls under account for error standardization as these forward to the user device endpoints
      constants.urls.account.refreshToken = constants.urls.account.urlBase + "/user_device/login/refresh"
      constants.urls.account.transferToken = constants.urls.account.urlBase + "/user_device/login/transfer"
      constants.urls.account.resetPassword = constants.urls.account.urlBase + "/user_device/password/reset"
      constants.urls.account.logout = constants.urls.account.urlBase + "/user_device/logout"

    constants.urls.lishi = {}
      constants.urls.lishi.baseUrl = "https://lishi.production-public.tubi.io"
      if constants.settings.mode <> "production" AND constants.settings.stagingApis = true then
        constants.urls.lishi.baseUrl = "https://lishi.staging-public.tubi.io"
      end if
      constants.urls.lishi.viewHistory = constants.urls.lishi.baseUrl + "/api/v2/view_history"

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

    ' Configuring the live news manifest proxy url.
    constants.urls.qaProxy = {}
      constants.urls.qaProxy.urlBase = "https://qa-proxy.staging-public.tubi.io"
      constants.urls.qaProxy.linearManifest = constants.urls.qaProxy.urlBase + "/live-news-manifest/"
      constants.urls.qaProxy.analytics = constants.urls.qaProxy.urlBase + "/analytics-ingestion"

    constants.urls.analytics = {}
      constants.urls.analytics.urlBase = "https://analytics-ingestion.staging-public.tubi.io/analytics-ingestion"
      ' QA analytics proxy server
      if mode = "production"
        constants.urls.analytics.urlBase = "https://analytics-ingestion.production-public.tubi.io/analytics-ingestion"
      else if mode = "qa"
        #if useQaAnalyticsProxy
          constants.urls.analytics.urlBase = constants.urls.qaProxy.analytics
        #end if
      end if

      constants.urls.analytics.singleEvent = constants.urls.analytics.urlBase + "/v2/single-event" 'preferred by back end team

    constants.urls.analyticsV3 = {}
      constants.urls.analyticsV3.sendEvent = "https://analytics-ingestion-v3.main-staging-custom.staging.k8s.tubi.io/ingestion/v3/events"
      if mode = "production"
        constants.urls.analyticsV3.sendEvent = "https://analytics-ingestion-v3.main-production-custom.production.k8s.tubi.io/ingestion/v3/events"
      end if

    constants.urls.impressionEvents = {}
      constants.urls.impressionEvents.urlBase = "https://user-signals.staging-public.tubi.io/user-signals"
      ' QA analytics proxy server
      if mode = "production"
        constants.urls.impressionEvents.urlBase = "https://user-signals.production-public.tubi.io/user-signals"
      end if

      constants.urls.impressionEvents.singleEvent = constants.urls.impressionEvents.urlBase + "/v1/single-event"

    'privacy statement text
    constants.urls.yourPrivacyChoicesUrl = "https://legal-asset.tubi.tv/your-privacy-choices.txt"

    'channels poster image urls
    constants.urls.channelPosterUnbranded = "https://mcdn.tubitv.com/image/roku_support_images/channel-poster-generic.png"
    constants.urls.channelPosterBrandedPrefix = "https://mcdn.tubitv.com/image/roku_support_images/channel-poster-"
    constants.urls.channelPosterBrandedSuffix = ".png"
    'channels logo image urls
    constants.urls.channelLogoBrandedPrefix = "https://mcdn.tubitv.com/image/channels/"
    constants.urls.channelLogoBrandedSuffix = "/logo_center.png"

    ' animationLogo Url which plays during app launch
    constants.urls.animationLogo = "https://mcdn.tubitv.com/video/roku/animation_logo_3.mp4"

    ' The background large images on the continue watching container row when the user is signed out
    constants.urls.continueWatchingItemBackground_largePoster = "https://mcdn.tubitv.com/image/roku_support_images/continueWatchingItemBackground_largePoster.webp"
    constants.urls.continueWatchingItemBackground_largePoster_kidsMode = "https://mcdn.tubitv.com/image/roku_support_images/continueWatchingItemBackground_largePoster_kids.webp"

    ' url for pinging Nielsen
    constants.urls.nielsenPing = "https://audit.imrworldwide.com/cgi-bin/gn"

    constants.urls.rokuContinueWatchingEndpoint = "https://userdata.sr.roku.com/user-data/v1/content/continueWatching"

    constants.urls.clientErrorConfigEndpoint = "https://md0.tubitv.com/error-handler/v2/client-error-config.json"

    if constants.settings.stagingApis = true
      constants.urls.foxApiBaseUrl = "https://qa.api.haw.digitalvideoplatform.com"
    else
      constants.urls.foxApiBaseUrl = "https://prod.api.haw.digitalvideoplatform.com"
    end if

    constants.urls.foxListingEndpoint = constants.urls.foxApiBaseUrl + "/v3.0/listings"

  'http request types
  constants.reqTypes = {}
    constants.reqTypes.get = "GET"
    constants.reqTypes.post = "POST"
    constants.reqTypes.put = "PUT"
    constants.reqTypes.del = "DELETE"
    constants.reqTypes.patch = "PATCH"

  'userQueue types
  constants.userQueueType = {}
    constants.userQueueType.watchLater = "watch_later"
    constants.userQueueType.remindMe = "remind_me"

  'common http request headers
  constants.headers = {}
    locale = constants.deviceInfo.locale.replace("_", "-")
    constants.headers.language = {"Accept-Language": locale}
    constants.headers.json = {"Content-Type": "application/json"}
    constants.headers.platform =  {"x-client-platform": constants.platform}
    constants.headers.clientVersion = {"x-client-version": constants.deviceInfo.clientVersion}
    constants.headers.tubiPlatform =  {"X-TUBI-PLATFORM": constants.analyticsPlatform}
    constants.headers.triggerFailSafe =  {"X-TRIGGER-FAILSAFE": "GAME_DAY_EXPERIENCE"}

    constants.headers.commonUapi = {}
      constants.headers.commonUapi.append(constants.headers.platform)
      constants.headers.commonUapi.append(constants.headers.clientVersion)
      constants.headers.commonUapi.append(constants.headers.json)
      constants.headers.commonUapi.append(constants.headers.language)

  'content type strings that we might get returned from uapi
  constants.uapiContentTypes = {}
    constants.uapiContentTypes.movie = "movie"
    constants.uapiContentTypes.series = "series"
    constants.uapiContentTypes.episode = "episode"
    constants.uapiContentTypes.channel = "channel"
    constants.uapiContentTypes.sportsEvent = "sports_event"

  constants.timers = {}
    constants.timers.skinAdTimeout = 6

    ' Time in seconds after which we force a refresh of the categoryscreen
    constants.timers.categoryContentRefreshTimeout = 12 * 60 * 60

    ' Time in seconds after which stored hasAge info becomes expired for COPPA
    constants.timers.coppaFailTimeout = 24 * 60 * 60  ' 1 day
    constants.timers.coppaPassTimeout = 60 * 24 * 60 * 60  ' 60 days

    ' allow the config to set the expire time for QA purposes
    if constants.settings.mode <> "production" AND constants.settings.coppaHasAgeDuration <> invalid
      constants.timers.coppaFailTimeout = constants.settings.coppaHasAgeDuration
    end if

  'constants needed for the video player
  constants.player = {}

    'The analyticsVersion helps determine the specific version of the log in use. we may increment when we do bigger change in logging.
    constants.player.analyticsVersion = "1.0"

    ' number of seconds that the "up next" screen will show
    constants.player.upNextCountdown = 30

    ' number of seconds that the "up next" screen will show for series
    constants.player.upNextCountdownForSeries = 15

    ' default if cuepoint is missing from metadata, or minimum cuepoint
    ' duration for titles whose cuepoint is right at the end.  This will
    ' allow time for UpNext to display before the stream ends.
    constants.player.creditsDuration = 5

    'how often the video player sends play progress events
    constants.player.pingFrequency = 10

    'how often the video player records history
    '   This doubles as the number of seconds after which the video player should save/display the resume/progress point.
    '   This is the client side minimum point. The server side minimum may be different. If the server side minimum is less than this number, the progress point will not be displayed.
    constants.player.historyFrequency1Min = 60
    constants.player.historyFrequency3Mins = 180

    ' time to fetch next content before credit cuepoints
    constants.player.fetchNextDuration = 15

    'the max number of distinct speeds at which the player can scrub (fast forward or rewind), 0 based
    constants.player.maxScrub = 2

    'list of scrub multipliers, the number of options should match the maxScrub above
    constants.player.scrubMultipliers = [8, 64, 128]

    'the number of seconds before the video player transport autohides during playback
    constants.player.transportAutoHideTime = 5
    constants.player.thumbnailFrequency = 5
    constants.player.browseWhileWatchingAutoHideTime = 12

    constants.player.playbackSource = {}
    constants.player.playbackSource.autoplayDeliberate = "AUTOPLAY_DELIBERATE"
    constants.player.playbackSource.autoplayAutomatic = "AUTOPLAY_AUTOMATIC"
    constants.player.playbackSource.videoPreviews = "VIDEO_PREVIEWS"
    constants.player.playbackSource.unknown = "UNKNOWN_PLAYBACK_SOURCE"

    constants.player.playbackOrigin = {}
    constants.player.playbackOrigin.autoplay_auto = "ap_auto"
    constants.player.playbackOrigin.autoplay_select = "ap_select"
    constants.player.playbackOrigin.container = "container"
    constants.player.playbackOrigin.ymal = "ymal"
    constants.player.playbackOrigin.search = "search"
    constants.player.playbackOrigin.deeplink = "deeplink"
    constants.player.playbackOrigin.unknown = "unknown"
    constants.player.playbackOrigin.epg = "epg"

    constants.player.subtitle = {}

      constants.player.subtitle.language = {}
        constants.player.subtitle.language.english = "English"
        constants.player.subtitle.language.spanish = "Spanish"
        constants.player.subtitle.language.castilian = "Castilian"
        constants.player.subtitle.language.french = "French"
        constants.player.subtitle.language.portuguese = "Portuguese"
        constants.player.subtitle.language.german = "German"
        constants.player.subtitle.language.italian = "Italian"

      constants.player.subtitle.languageMap = [
        constants.player.subtitle.language.english
        constants.player.subtitle.language.spanish
        constants.player.subtitle.language.castilian
        constants.player.subtitle.language.french
        constants.player.subtitle.language.portuguese
        constants.player.subtitle.language.german
        constants.player.subtitle.language.italian
      ]

      constants.player.subtitle.localizedLanguage = {}
        constants.player.subtitle.localizedLanguage.english = "English"
        constants.player.subtitle.localizedLanguage.spanish = "Español"
        constants.player.subtitle.localizedLanguage.castilian = "Castellano"
        constants.player.subtitle.localizedLanguage.french = "Français"
        constants.player.subtitle.localizedLanguage.portuguese = "Português"
        constants.player.subtitle.localizedLanguage.german = "Deutsch"
        constants.player.subtitle.localizedLanguage.italian = "Italiano"

    constants.player.audioTrack = {}

      constants.player.audioTrack.audioDescriptionTrackNamePrefix = "Audio Description"
      constants.player.audioTrack.audioDescriptionTrackName = "English - Audio Description"

      constants.player.audioTrack.localizedLanguage = {}
      constants.player.audioTrack.localizedLanguage.EN = "English"
      constants.player.audioTrack.localizedLanguage.ES = "Español"
      constants.player.audioTrack.localizedLanguage.FR = "Français"
      constants.player.audioTrack.localizedLanguage.DE = "Deutsch"
      constants.player.audioTrack.localizedLanguage.PO = "Português"
      constants.player.audioTrack.localizedLanguage.IT = "Italiano"
      constants.player.audioTrack.localizedLanguage.JA = "Japanese"
      constants.player.audioTrack.localizedLanguage.KO = "Korean"
      constants.player.audioTrack.localizedLanguage.ZH = "Chinese"

      constants.player.audioTrack.roles = {}
        constants.player.audioTrack.roles.main = "main"
        constants.player.audioTrack.roles.description = "description"


    'video player returns one of the following
    constants.player.playerResults = {}
      constants.player.playerResults.completed = "COMPLETED"
      constants.player.playerResults.closed = "CLOSED"

    'urls for the images that are required for the transport
    constants.player.transportButtons = {}
      constants.player.transportButtons.fastForward = "pkg:/images/transport/sgplayer/icon-ffw.webp"
      constants.player.transportButtons.fastForwardLevels = [
        "pkg:/images/transport/sgplayer/icon-ffw-1.webp",
        "pkg:/images/transport/sgplayer/icon-ffw-2.webp",
        "pkg:/images/transport/sgplayer/icon-ffw-3.webp"
      ]

      constants.player.transportButtons.rewind = "pkg:/images/transport/sgplayer/icon-rew.webp"
      constants.player.transportButtons.rewindLevels = [
        "pkg:/images/transport/sgplayer/icon-rew-1.webp",
        "pkg:/images/transport/sgplayer/icon-rew-2.webp",
        "pkg:/images/transport/sgplayer/icon-rew-3.webp"
      ]

      constants.player.transportButtons.pause = "pkg:/images/transport/sgplayer/icon-pause.webp"
      constants.player.transportButtons.play = "pkg:/images/transport/sgplayer/icon-play.webp"

      ' "ids" for the different skip button texts
      constants.player.skipCuepointsButtonTypes = {}
      constants.player.skipCuepointsButtonTypes.intro = "skipIntro"
      constants.player.skipCuepointsButtonTypes.recap = "skipRecap"
      constants.player.skipCuepointsButtonTypes.earlyCredits = "skipEarlyCredits"

      ' Drm types/schemes, as named and supported by UAPI
      constants.player.drmTypes = {}
      constants.player.drmTypes.dashWidevine = "dash_widevine_psshv0"
      constants.player.drmTypes.dashPlayready = "dash_playready_psshv0"
      constants.player.drmTypes.dash = "dash"
      constants.player.drmTypes.hlsv6 = "hlsv6"
      constants.player.drmTypes.hlsv3 = "hlsv3"

      ' Supported schemes, in order of preference
      constants.player.drmOrderWidevineHlsv6 = [
        constants.player.drmTypes.dashWidevine
        constants.player.drmTypes.hlsv6
      ]

      ' H265 is one of the video compression standards. This information is passed on api request in order to get the H265 transcoded manifests from backend.
      ' H265 codec is supported only on higher end modals.
      hevcCodec = "H265"
      constants.hevcCodec = hevcCodec

      ' H264 is one of the video compression standards. This information is passed on api request in order to get the H264 transcoded manifests from backend.
      ' H264 codec is supported by all modals.
      avcCodec = "H264"
      constants.avcCodec = avcCodec

      maxH265Resolution = videoResolution
      if videoResolution >= 2160
        ' max supported resolution is 2160p for H265 from backend
        maxH265Resolution = 2160  'bs:disable-line LINT1005
      end if

      maxH264Resolution = videoResolution
      if videoResolution >= 1080
        maxH264Resolution = 1080 ' max supported resolution is 1080p for H264 from backend
      end if

      ' if the device only supports H264, then we are sending limitResolutions as "H264_<maxH264Resolution>".
      ' Backend will respond with multiple manifests (but all are H264)
      if maxH264Resolution >= 1080
        constants.player.limitResolutions = [
          avcCodec + "_" + "1080" + "p"
          avcCodec + "_" + "720" + "p"
        ]
      else
        constants.player.limitResolutions = [
          avcCodec + "_" + maxH264Resolution.toStr() + "p"
      ]
      end if

      ' if the device supports H265, then we are sending limitResolutions as "H265_<maxH265Resolution>" & "H264_<maxH264Resolution>"
      ' Backend will respond with multiple manifests (both H265 & H264)
      if di.CanDecodeVideo({Codec: "hevc"}).result = true ' checking whether device is capable of playing H265 transcoded content
        constants.player.limitResolutions = [
          hevcCodec + "_" + "1080" + "p"
          hevcCodec + "_" + "720" + "p"
          avcCodec + "_" + "1080" + "p"
          avcCodec + "_" + "720" + "p"
        ]
      end if

      'Video ResourceType
      constants.player.videoResourcetype = {}
        constants.player.videoResourcetype.unknown = 0
        constants.player.videoResourcetype.hlsv3 = 1
        constants.player.videoResourcetype.hlsv6 = 2
        constants.player.videoResourcetype.dash_widevine = 3
        constants.player.videoResourcetype.dash_playready = 4
        constants.player.videoResourcetype.dash_fairplay = 5
        constants.player.videoResourcetype.hlsv6_widevine = 6
        constants.player.videoResourcetype.dash = 7
        constants.player.videoResourcetype.hlsv6_playready = 8
        constants.player.videoResourcetype.hlsv6_fairplay = 9
        constants.player.videoResourcetype.hlsv6_playready_nonclearlead = 10
        constants.player.videoResourcetype.dash_playready_psshv0 = 11
        constants.player.videoResourcetype.hlsv6_widevine_nonclearlead = 12
        constants.player.videoResourcetype.hlsv6_widevine_psshv0 = 13
        constants.player.videoResourcetype.hlsv6_playready_psshv0 = 14
        constants.player.videoResourcetype.dash_widevine_nonclearlead = 15
        constants.player.videoResourcetype.playready_nonclearlead = 16
        constants.player.videoResourcetype.dash_widevine_psshv0 = 17

      'Video CodecType
      constants.player.videoCodecType = {}
        constants.player.videoCodecType.unknown = 0
        constants.player.videoCodecType.h264 = 1
        constants.player.videoCodecType.h265 = 2

      'Video Resolution
      constants.player.videoResolution = {}
        constants.player.videoResolution.unknown = 0
        constants.player.videoResolution["240"] = 1
        constants.player.videoResolution["360"] = 2
        constants.player.videoResolution["480"] = 3
        constants.player.videoResolution["576"] = 4
        constants.player.videoResolution["720"] = 5
        constants.player.videoResolution["1080"] = 6
        constants.player.videoResolution["2160"] = 7
        constants.player.videoResolution["AUTO"] = 8

      '//TODO: Remove unsed constants.player.linear* with our next submission release.
      'constants needed for the linear video player
      constants.player.linear = {}
        ' duration (in seconds) of coming up panel displayed within info panel
        constants.player.linear.comingUpInsideInfoPanelDuration = 300
        ' duration (in seconds) of coming up panel displayed outside info panel
        constants.player.linear.comingUpOutsideInfoPanelDuration = 15

        'Linear ssai version
        constants.player.linear.ssaiVersion = {}
        constants.player.linear.ssaiVersion.unknown = 0
        constants.player.linear.ssaiVersion.apollo = 1
        constants.player.linear.ssaiVersion.youspace = 2

        'Linear player_type
        constants.player.linear.player_type_unspecified = 0
        constants.player.linear.player_type_default = 1
        constants.player.linear.player_type_banner = 2

      'Hdcp version
      constants.player.hdcpVersion = {}
        constants.player.hdcpVersion.hdcp_unknown = 0
        constants.player.hdcpVersion.hdcp_v1 = 1
        constants.player.hdcpVersion.hdcp_v2 = 2
        constants.player.hdcpVersion.hdcp_disabled = 3

      constants.player.browseContent = {}
        constants.player.browseContent.numContainers = 10
        constants.player.browseContent.numContents = 50

      constants.player.videoPreviewDebounce = 0.5

  ' constants used for EPG
  constants.EPGChannelPlayMode = {}
  constants.EPGChannelPlayMode.playItemOnSelect = "playItemOnSelect"
  constants.EPGChannelPlayMode.playItemOnFocus = "playItemOnFocus"

  'Default times for which the caches for different content types are valid.
  'These will normally come from the server, these times stored in constants are backup values.
  constants.cacheTimes = {}
    constants.cacheTimes.content = 2 * 60 * 60 ' Time in seconds after which an individual piece of content' cache is not valid
    constants.cacheTimes.category = 4 * 60 * 60 ' Time in seconds after which a category's cache is not valid
    constants.cacheTimes.homescreen = 6 * 60 * 60 ' Time in seconds after which the category screen's cache is not valid
    constants.cacheTimes.epgscreen = 6 * 60 * 60 ' Time in seconds after which the epg screen's cache is not valid

  'This will store the error codes that are needed to be displayed to the user.
  'Review the following page to see the list of error codes that are used across platforms:
  'https://tubitv.atlassian.net/wiki/spaces/EC/pages/798359880/User+Facing+Error+Codes
  constants.errors = {}

  '//Where does the error happen?
  constants.errors.context = {}
  constants.errors.context.homeScreen = "1"
  constants.errors.context.videoDetailScreen = "2"
  constants.errors.context.playerScreen = "3"
  constants.errors.context.episodeScreen = "5"
  constants.errors.context.categoryDetailsScreen = "6"
  constants.errors.context.categoriesScreen = "10"
  constants.errors.context.linearPlayerScreen = "11"
  constants.errors.context.epgScreen = "12"
  constants.errors.context.emailVerificationScreen = "13"
  constants.errors.context.forgotPasswordProcessingScreen = "15"
  constants.errors.context.myStuffScreen = "16"

  '//What is the actual error?
  constants.errors.subtypes = {}
  '//Failed to fetch data from backend
  constants.errors.subtypes.fetchError = "100"
  constants.errors.subtypes.expireError = "101"
  constants.errors.subtypes.addBookmarkError = "102"
  constants.errors.subtypes.removeBookmarkError = "103"
  constants.errors.subtypes.removeHistoryError = "104"
  constants.errors.subtypes.ratingAddLikeError = "105"
  constants.errors.subtypes.ratingAddDislikeError = "106"
  constants.errors.subtypes.ratingRemoveLikeError = "107"
  constants.errors.subtypes.ratingRemoveDislikeError = "108"
  'Could not setup player
  constants.errors.subtypes.playerPlaybackError = "201"
  constants.errors.subtypes.networkError = "300"

  ' errors will be grouped by the combination of constants.errors.type and constants.errors.message in sentry dashboard
  ' error types are passed to sentry api as exception->type and displayed in sentry dashboard
  constants.errors.type = {}
    constants.errors.type.videoError = "Video Error"
    constants.errors.type.adError = "Ad Error"
    constants.errors.type.timedOut = "Timed Out"
    constants.errors.type.loadFailed = "Failed to Load"
    constants.errors.type.crashOnPreviousRun = "Crash detected on previous run"

  ' errors will be grouped by the combination of constants.errors.type and constants.errors.message in sentry dashboard
  ' error messages are passed to sentry api as exception->value and displayed in sentry dashboard
  constants.errors.message = {}
    constants.errors.message.videoPlayer = "Video Player"
    constants.errors.message.invalidVideoUrl = "Invalid Video URL"
    constants.errors.message.badResponse = "Bad Response"
    constants.errors.message.noResponse = "No Response"

  ' creating mapping to backend error codes.
  constants.errors.codes = {}
    constants.errors.codes.expiredToken = "EXPIRED_TOKEN"
    constants.errors.codes.invalidParams = "INVALID_PARAMS"
    constants.errors.codes.invalidEmailDomain = "INVALID_EMAIL_DOMAIN"
    constants.errors.codes.blockedEmailDomain = "BLOCKED_EMAIL_DOMAIN"
    constants.errors.codes.emailExists = "EMAIL_USER_EXISTS"
    ' TODO remove in next submission release
    constants.errors.codes.userNotFound = "USER_NOT_FOUND"
    constants.errors.codes.invalidToken = "INVALID_TOKEN"

  ' IDs for input devices, https://docs.tubi.io/protos/index#analytics.SearchEvent.input_device
  constants.inputDevices = {}
    constants.inputDevices.unknown = "UNKNOWN_DEVICE"
    constants.inputDevices.remote = "NATIVE"
    constants.inputDevices.externalKeyboard = "KEYBOARD"
    constants.inputDevices.voice = "VOICE"

  ' pixel fires when static Ad is shown on video player during pause
  constants.pauseAd = {}
    constants.pauseAd.pixelTypes = {}
    constants.pauseAd.pixelTypes.startPixel = "startPixel"
    constants.pauseAd.pixelTypes.impTrackingPixel = "impTrackingPixel"
    constants.pauseAd.pixelTypes.endPixel = "endPixel"
    constants.pauseAd.pixelTypes.notUsedPixel = "notUsedPixel"
    constants.pauseAd.pixelTypes.errorPixel = "errorPixel"

  'UI properties that should be passed into the scene graph
  constants.ui = {}

    constants.ui.ages = {}
      constants.ui.ages.ageGate = 13

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

    constants.ui.categoryIds = {}
      'these map to tensor api container ids
      constants.ui.categoryIds.history = "continue_watching"
      constants.ui.categoryIds.queue = "queue"
      constants.ui.categoryIds.featured = "featured"
      constants.ui.categoryIds.networks = "networks"
      constants.ui.categoryIds.myLikes = "my_likes"
      constants.ui.categoryIds.recommendedForYou = "recommended_for_you"
      constants.ui.categoryIds.mostPopular = "most_popular"
      constants.ui.categoryIds.movieNight = "movie_night"
      constants.ui.categoryIds.seriesSpotlight = "series_spotlight"
      constants.ui.categoryIds.topSearched = "top_searched"
      constants.ui.categoryIds.topTenSeries = "top_10_tv_shows_on_tubi"
      constants.ui.categoryIds.certifiedFresh = "certified_fresh"
      ' Adding a constant entry so that it is easier to change for testing or future use if we need to pick other container outside of featured.
      constants.ui.categoryIds.skinAd = "skinAd"

    constants.ui.categoryTypes = {}
      'these map to tensor api container types
      constants.ui.categoryTypes.history = "continue_watching"
      constants.ui.categoryTypes.queue = "queue"
      constants.ui.categoryTypes.regular = "regular"
      constants.ui.categoryTypes.channel = "channel"
      constants.ui.categoryTypes.linear = "linear"
      constants.ui.categoryTypes.historySignedOutUser = "continue_watching_signed_out_user"

    constants.ui.likeDislikeActions = {}
      'these map to account api like/dislike rating actions
      constants.ui.likeDislikeActions.like = "like"
      constants.ui.likeDislikeActions.dislike = "dislike"
      constants.ui.likeDislikeActions.removeLike = "remove-like"
      constants.ui.likeDislikeActions.removeDislike = "remove-dislike"

    constants.ui.likeDislikeStates = {}
      'these map to like/dislike rating states
      constants.ui.likeDislikeStates.liked = "liked"
      constants.ui.likeDislikeStates.disliked = "disliked"
      constants.ui.likeDislikeStates.changing = "changing"

    constants.ui.infoPanelModes = {}
      'these map to different InfoPanel modes/types
      constants.ui.infoPanelModes.item = "item"
      constants.ui.infoPanelModes.continueWatching = "continueWatching"
      constants.ui.infoPanelModes.channel = "channel"
      constants.ui.infoPanelModes.movie = "movie"
      constants.ui.infoPanelModes.series = "series"
      constants.ui.infoPanelModes.season = "season"
      constants.ui.infoPanelModes.episode = "episode"
      constants.ui.infoPanelModes.linearHomeScreen = "linearHomeScreen"
      constants.ui.infoPanelModes.epg = "epg"
      constants.ui.infoPanelModes.linearSearch = "linearSearch"
      constants.ui.infoPanelModes.linearProgramHomescreen = "linearProgramHomescreen"  'v4 api
      constants.ui.infoPanelModes.sportsEvent = "sportsEvent"

    constants.ui.contentMode = {}
      ' these are also used for the content experience choices but are the value that is sent to the back end in our api requests
      constants.ui.contentMode.homescreen = "homescreen"
      constants.ui.contentMode.latino = "latino"
      constants.ui.contentMode.movie = "movie"
      constants.ui.contentMode.tv = "tv"
      constants.ui.contentMode.linear = "linear"
      constants.ui.contentMode.epgScreen = "tubitv_us_linear" 'this value is used as input query param, and the value of the param expected is tubitv_us_linear .

    constants.ui.contentTypes = {}
      constants.ui.contentTypes.series = "series"
      constants.ui.contentTypes.video = "video"
      constants.ui.contentTypes.season = "season"
      constants.ui.contentTypes.category = "category"
      constants.ui.contentTypes.channel = "channel"
      constants.ui.contentTypes.linear = "linear"
      constants.ui.contentTypes.historySignedOutUser = "continue_watching_signed_out_user"
      constants.ui.contentTypes.emptyContainer = "emptyContainer"
      constants.ui.contentTypes.epg = "epg"
      constants.ui.contentTypes.sportsEvent = "sports_event"
      constants.ui.contentTypes.skinAd = "skinAd"

    constants.ui.playerTypes = {}
      constants.ui.playerTypes.fox = "fox"

    '// Check if these are required for sports events
    constants.ui.contentTimings = {}
      constants.ui.contentTimings.upcoming = "upcoming"
      constants.ui.contentTimings.replay = "replay"

    constants.ui.backgroundTypes = {}
      constants.ui.backgroundTypes.fullScreen = "fullscreen"
      constants.ui.backgroundTypes.fullScreen2 = "fullscreen2"
      constants.ui.backgroundTypes.topRight = "topright"
      constants.ui.backgroundTypes.epg = "epg"
      constants.ui.backgroundTypes.rightScreen = "rightScreen"
      ' Introducing a new type of background due to difference of gradient between fullscreen version and spotlight variant.
      constants.ui.backgroundTypes.spotlight = "spotlight"
      ' This acts the same as spotlight but makes changes to allow a seemless transition to a looping background video
      constants.ui.backgroundTypes.skinAd = "skinAd"

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
      constants.ui.screenLevels.epgScreen = 20
      constants.ui.screenLevels.movieScreen = 20
      constants.ui.screenLevels.tvScreen = 20
      constants.ui.screenLevels.searchScreen = 20
      constants.ui.screenLevels.myStuffScreen = 20
      constants.ui.screenLevels.settingsScreen = 20
      constants.ui.screenLevels.categoryPanelListScreen = 20
      constants.ui.screenLevels.confirmPasswordScreen = 40
      constants.ui.screenLevels.categoryDetailsScreen = 40
      constants.ui.screenLevels.detailScreen = 50
      constants.ui.screenLevels.episodeScreen = 50
      constants.ui.screenLevels.eventDetailScreen = 50
      constants.ui.screenLevels.videoPlayerScreen = 60
      constants.ui.screenLevels.adPlayerScreen = 60
      constants.ui.screenLevels.linearVideoPlayerScreen = 60
      constants.ui.screenLevels.signInSignUpErrorScreen = 60
      constants.ui.screenLevels.emailInputScreen = 90
      constants.ui.screenLevels.signInScreen = 90
      constants.ui.screenLevels.ageGateScreen = 90
      constants.ui.screenLevels.consentScreen = 120
      constants.ui.screenLevels.rokuContinueWatchingConsentScreen = 120
      constants.ui.screenLevels.managePreferencesScreen = 130

    constants.ui.screenIds = {}
      constants.ui.screenIds.homeScreen = "homeScreen"
      constants.ui.screenIds.searchScreen = "searchScreen"
      constants.ui.screenIds.settingsScreen = "settingsScreen"
      constants.ui.screenIds.categoryDetailsScreen = "categoryDetailsScreen"
      constants.ui.screenIds.channelListScreen = "channelListScreen"
      constants.ui.screenIds.categoryPanelListScreen = "categoryPanelListScreen"
      constants.ui.screenIds.espanolScreen = "espanolScreen"
      constants.ui.screenIds.movieScreen = "movieScreen"
      constants.ui.screenIds.myStuffScreen = "myStuffScreen"
      constants.ui.screenIds.tvScreen = "tvScreen"
      constants.ui.screenIds.detailScreen = "detailScreen"
      constants.ui.screenIds.episodeScreen = "episodeScreen"
      constants.ui.screenIds.emailInputScreen = "emailInputScreen"
      constants.ui.screenIds.signInScreen = "signInScreen"
      constants.ui.screenIds.videoPlayerScreen = "videoPlayerScreen"
      constants.ui.screenIds.adPlayerScreen = "adPlayerScreen"
      constants.ui.screenIds.linearVideoPlayerScreen = "linearVideoPlayerScreen"
      constants.ui.screenIds.epgScreen = "epgScreen"
      constants.ui.screenIds.emailVerificationScreen = "emailVerificationScreen"
      constants.ui.screenIds.forgotPasswordProcessingScreen = "forgotPasswordProcessingScreen"
      constants.ui.screenIds.consentScreen = "consentScreen"
      constants.ui.screenIds.managePreferencesScreen = "managePreferencesScreen"
      constants.ui.screenIds.rokuContinueWatchingConsentScreen = "rokuContinueWatchingConsentScreen"
      constants.ui.screenIds.eventDetailScreen = "eventDetailScreen"

    ' notAllowedContainerIds are the containers which are not allowed to be displayed on category screen,
    ' because currently we support only portrait style in category detail screen
    ' TODO: Remove in submission release.
    constants.ui.notAllowedContainerIds = {}
      constants.ui.notAllowedContainerIds[constants.ui.categoryIds.featured] = true

    constants.ui.excludedCategories = [constants.ui.categoryIds.featured]

    constants.ui.cacheableScreenIds = {}
      constants.ui.cacheableScreenIds[constants.ui.screenIds.homeScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.channelListScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.categoryPanelListScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.espanolScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.movieScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.myStuffScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.tvScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.searchScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.videoPlayerScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.linearVideoPlayerScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.emailInputScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.signInScreen] = true
      constants.ui.cacheableScreenIds[constants.ui.screenIds.epgScreen] = true

      ' top level content ids for parent content nodes that don't have a content id from the backend
    constants.ui.contentIds = {}
      constants.ui.contentIds.homegrid = "homegrid"
      constants.ui.contentIds.categoryList = "categoriesList"
      constants.ui.contentIds.channelList = "channelsList"
      constants.ui.contentIds.timeGridContent = "timeGridContent"

    constants.ui.loginReasons = {}
    constants.ui.loginReasons.matureContentGating = "MATURE_CONTENT_GATING"
    constants.ui.loginReasons.unknown = "UNKNOWN"

    ' content ids of contents that should not be removed from the content cache
    constants.ui.permanentlyCachedContentIds = {}
      constants.ui.permanentlyCachedContentIds[constants.ui.contentIds.homegrid] = true

    'X/Y placement of app-wide elements. Typically x/y placement should be done in XML, but when there is an element that spans many components/screens, then pixel placement can be set here.
    constants.ui.translations = {}
    constants.ui.translations.marginX = 165

    constants.ui.translations.player = {}
      constants.ui.translations.player.marginX = 192

    constants.ui.logoSizes = {}
      constants.ui.logoSizes.skinAds = {}

        constants.ui.logoSizes.skinAds.homeScreen = {}
          constants.ui.logoSizes.skinAds.homeScreen.width = "174"

        constants.ui.logoSizes.skinAds.infoPanel = {}
          constants.ui.logoSizes.skinAds.infoPanel.width = "594"
          constants.ui.logoSizes.skinAds.infoPanel.height = "249"

    constants.ui.imageSizes = {}

      'Sizes of poster thumbnails that need to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images
      constants.ui.imageSizes.poster = [186, 267]

      'Sizes of video title image (if available) that need to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images. The video title image is an image representation of the title metadata of the video. Not all videos may have this image.
      constants.ui.imageSizes.title = [600, 201]

      'Sizes of large poster thumbnails that need to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images
      constants.ui.imageSizes.largePoster = [252, 360]

      'Sizes of featured row  poster thumbnails that need to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images
      constants.ui.imageSizes.featuredRowPoster = [789, 442]

      'Size of the thumbnail/background of the single element representing an empty container that we wish to show: i.e. on the MyStuff Screen
      constants.ui.imageSizes.emptyContainer = [1572, 267]

      'Sizes of landscape thumbnails that need to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images
      constants.ui.imageSizes.landscape = [386, 217]

      'Sizes of large landscape thumbnails that need to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images
      constants.ui.imageSizes.largeLandscape = [520, 292]

      'Sizes of large landscape thumbnails that need to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images
      constants.ui.imageSizes.largestLandscape = [661, 372]

      'Sizes of linear to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images
      constants.ui.imageSizes.linear = [384, 144]

      'Sizes of the linear background and minimized linear video player
      constants.ui.imageSizes.epgLinearVideoPlayerOnEPGScreen_minimizedDimension = [1120,630]

      ' Sizes for the full width banner component. It is currently going to be used for purple carpet banner.
      ' Will be removed when purple carpet code is cleaned up.
      constants.ui.imageSizes.banner = [1693, 162]

      'Sizes of featured row  poster thumbnails that need to sent to the backend so Tupian, the dynamic image sizer tool, can provide the correct sized images
      constants.ui.imageSizes.featuredPortraitSmall = [310, 442]

      ' Size for the background image.
      if limitedUi = true
        constants.ui.imageSizes.background = [399, 225]
      else if lowVram = true
        constants.ui.imageSizes.background = [798, 450]
      else
        constants.ui.imageSizes.background = [1197, 675]
      end if

      constants.ui.imageSizes.skinAdLandscape = [520, 292]

      ' Size for the background image.
      if limitedUi = true
        constants.ui.imageSizes.fullScreenBackground = [639, 357]
      else if lowVram = true
        constants.ui.imageSizes.fullScreenBackground = [1278, 717]
      else
        constants.ui.imageSizes.fullScreenBackground = [1920, 1080]
      end if

    constants.ui.featuredRow = {}
      constants.ui.featuredRow.playerSize = [constants.ui.imageSizes.featuredRowPoster[0] + 4, constants.ui.imageSizes.featuredRowPoster[1] + 10]

    constants.ui.imageTranslations = {}
      'Location of the linear background and minimized linear video player
      constants.ui.imageTranslations.epgLinearVideoPlayerOnEPGScreen_minimizedTranslation = [800,0]

    constants.ui.sideNavOpenIds = {}
      constants.ui.sideNavOpenIds[constants.ui.screenIds.homeScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.categoryPanelListScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.espanolScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.epgScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.tvScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.movieScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.myStuffScreen] = true
      constants.ui.sideNavOpenIds[constants.ui.screenIds.searchScreen] = true

    constants.ui.sideNavIds = {}
      constants.ui.sideNavIds.home = "home"
      constants.ui.sideNavIds.search = "search"
      constants.ui.sideNavIds.channels = "channels"
      constants.ui.sideNavIds.categories = "categories"
      constants.ui.sideNavIds.espanol = "espanol"
      constants.ui.sideNavIds.settings = "settings"
      constants.ui.sideNavIds.exit = "exit"
      constants.ui.sideNavIds.profile = "profile"
      constants.ui.sideNavIds.kidsMode = "kidsMode"
      constants.ui.sideNavIds.myList = "myList"
      constants.ui.sideNavIds.movies = "movies"
      constants.ui.sideNavIds.tv = "tv"
      constants.ui.sideNavIds.linearEPG = "linearEPG"

    constants.ui.linearSideNavIds = {}
      constants.ui.linearSideNavIds.epg = "epg"
      constants.ui.linearSideNavIds.subtitles = "subtitles"

    'a map of screenIds to corresponding sideNavIds
    constants.ui.screenIdToSideNavId = {}
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.homeScreen] = constants.ui.sideNavIds.home
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.searchScreen] = constants.ui.sideNavIds.search
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.channelListScreen] = constants.ui.sideNavIds.channels
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.categoryPanelListScreen] = constants.ui.sideNavIds.categories
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.espanolScreen] = constants.ui.sideNavIds.espanol
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.myStuffScreen] = constants.ui.sideNavIds.myList
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.settingsScreen] = constants.ui.sideNavIds.settings
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.tvScreen] = constants.ui.sideNavIds.tv
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.movieScreen] = constants.ui.sideNavIds.movies
      constants.ui.screenIdToSideNavId[constants.ui.screenIds.epgscreen] = constants.ui.sideNavIds.linearEPG

    constants.ui.detailScreenMenuItemIds = {}
      constants.ui.detailScreenMenuItemIds.playMenuItem = "PlayMenuItem"
      constants.ui.detailScreenMenuItemIds.resumeMenuItem = "ResumeMenuItem"
      constants.ui.detailScreenMenuItemIds.watchTrailerMenuItem = "WatchTrailerMenuItem"
      constants.ui.detailScreenMenuItemIds.likeMenuItem = "LikeMenuItem"
      constants.ui.detailScreenMenuItemIds.dislikeMenuItem = "DislikeMenuItem"
      constants.ui.detailScreenMenuItemIds.likeDislikeMenuItem = "LikeDislikeMenuItem"
      constants.ui.detailScreenMenuItemIds.episodesMenuItem = "EpisodesMenuItem"
      constants.ui.detailScreenMenuItemIds.addQueueMenuItem = "AddQueueMenuItem"
      constants.ui.detailScreenMenuItemIds.removeQueueMenuItem = "RemoveQueueMenuItem"
      constants.ui.detailScreenMenuItemIds.removeHistoryMenuItem = "RemoveHistoryMenuItem"
      constants.ui.detailScreenMenuItemIds.signUpMenuItem = "SignUpMenuItem"
      constants.ui.detailScreenMenuItemIds.channelMenuItem = "ChannelMenuItem"
      constants.ui.detailScreenMenuItemIds.setReminderMenuItem  = "SetReminderMenuItem"
      constants.ui.detailScreenMenuItemIds.removeReminderMenuItem  = "RemoveReminderMenuItem"
      constants.ui.detailScreenMenuItemIds.likeRemoveRatingMenuItem  = "LikeRemoveRatingMenuItem"
      constants.ui.detailScreenMenuItemIds.dislikeRemoveRatingMenuItem  = "DislikeRemoveRatingMenuItem"
      constants.ui.detailScreenMenuItemIds.startFromBeginningMenuItem  = "StartFromBeginningMenuItem"

    constants.ui.gridItemTypes = {}
      constants.ui.gridItemTypes.portrait = "portrait"
      constants.ui.gridItemTypes.landscape = "landscape"
      constants.ui.gridItemTypes.landscapeInnerMetadata = "landscapeInnerMetadata"
      constants.ui.gridItemTypes.landscapeWithMetadata = "landscapeWithMetadata"
      constants.ui.gridItemTypes.landscapeNoTitle = "landscapeNoTitle"
      constants.ui.gridItemTypes.linear = "linear"
      constants.ui.gridItemTypes.historySignedOutUser = "continue_watching_signed_out_user"
      constants.ui.gridItemTypes.emptyContainer = "emptyContainer"
      constants.ui.gridItemTypes.portraitTopTen = "portraitTopTen"
      constants.ui.gridItemTypes.skinAd = "skinAd"
      constants.ui.gridItemTypes.featuredPortraitSmall = "featuredPortraitSmall"
      constants.ui.gridItemTypes.certifiedFresh = "certifiedFresh"

    constants.ui.uris = {}

      constants.ui.uris.defaultContentBackgroundUri = "https://mcdn.tubitv.com/image/roku_support_images/bgroundMyStuffDefault.webp"

      'category background thumbnails
      constants.ui.uris.categoryBackgrounds = {}
        constants.ui.uris.categoryBackgrounds.urlBase = "https://mcdn.tubitv.com/image/roku_support_images/category_"
        constants.ui.uris.categoryBackgrounds.urlEnding = "_thumbnail_1x242.png"
        constants.ui.uris.categoryBackgrounds.recommended = constants.ui.uris.categoryBackgrounds.urlBase + "recommended" + constants.ui.uris.categoryBackgrounds.urlEnding
        constants.ui.uris.categoryBackgrounds.continueWatching = constants.ui.uris.categoryBackgrounds.urlBase + "continuewatching" + constants.ui.uris.categoryBackgrounds.urlEnding
        constants.ui.uris.categoryBackgrounds.queue = constants.ui.uris.categoryBackgrounds.urlBase + "queue" + constants.ui.uris.categoryBackgrounds.urlEnding

      constants.ui.uris.emptyContainerMyStuffBackground = "pkg:/images/screenMyStuffEmptyContainer.9.png"
      constants.ui.uris.myStuffMyListIcon = "pkg:/images/screenMyStuffMyListIcon.webp"
      constants.ui.uris.myStuffContinueWatchingIcon = "pkg:/images/screenMyStuffContinueWatchingIcon.webp"

    constants.ui.consentActionButtonIds = {}
      constants.ui.consentActionButtonIds.manage = "manage"
      constants.ui.consentActionButtonIds.accept = "accept"
      constants.ui.consentActionButtonIds.reject = "reject"

    constants.ui.rokuCWConsentActionButtonIds = {}
      constants.ui.rokuCWConsentActionButtonIds.accept = "accept"
      constants.ui.rokuCWConsentActionButtonIds.reject = "reject"

    ' Holds the container index on tensor api home screen response that we need to use as spotlight content.
    ' Adding a constant entry so that it is easier to change for testing or future use if we need to pick other container outside of featured.
    constants.ui.spotlightContainerIndex = 0

  constants.consentKeys = {}
    constants.consentKeys.essential = "C0001"
    constants.consentKeys.analytics = "C0002"
    constants.consentKeys.personalization = "C0004"
    constants.consentKeys.marketing = "C0005"
    constants.consentKeys.continueWatching = "data_sharing"
    constants.consentKeys.functional = "C0003"

  constants.configHubFallbacks = {}
    constants.configHubFallbacks.majorEventStart = "2025-02-09T05:00:00.000000Z"
    constants.configHubFallbacks.majorEventEnd = "2025-02-10T08:00:00.000000Z"
    constants.configHubFallbacks.majorEventNameTranslationKey = "game"

  constants.serverValues = {}

  ' Creates mapping against parental rating to a header string.
  constants.serverValues.parentalControls = ["YOUNGER_CHILD", "OLDER_CHILD", "TEEN", "ADULT"]

  constants.serverValues.contentModeHeaders = {}
    constants.serverValues.contentModeHeaders[constants.ui.contentMode.latino] = "LATINO"
    constants.serverValues.contentModeHeaders[constants.ui.contentMode.movie] = "MOVIE"
    constants.serverValues.contentModeHeaders[constants.ui.contentMode.tv] = "TV"
    constants.serverValues.contentModeHeaders.kids = "KIDS"


'THEME/COLOR START///////////////////////
'//::TODO::colors - the following constants should be moved to themes. The app should not call these constants
'//The use of the "THEME_" constants will be replaced with hexadecimal color strings during the gulp install process.
'//Source of JSON theme colors are located in /themes/theme.json which is sourced from a design JSON file.
'//::NOTE:: See the ReadMe on how to update the JSON.


'//default theme
    '//default dark sub theme
    defaultDarkPrimaryAccent = "THEME_defaultDarkPrimaryAccent_THEME"
    defaultDarkPrimaryBackground = "THEME_defaultDarkPrimaryBackground_THEME"
    defaultDarkPrimaryForeground = "THEME_defaultDarkPrimaryForeground_THEME"
    defaultDarkTransparentBackground50 = "THEME_defaultDarkTransparentBackground50_THEME"
    defaultDarkTransparentBackground75 = "THEME_defaultDarkTransparentBackground75_THEME"
    defaultDarkTransparentForeground5 = "THEME_defaultDarkTransparentForeground5_THEME"
    defaultDarkTransparentForeground10 = "THEME_defaultDarkTransparentForeground10_THEME"
    defaultDarkTransparentForeground20 = "THEME_defaultDarkTransparentForeground20_THEME"
    defaultDarkTransparentForeground50 = "THEME_defaultDarkTransparentForeground50_THEME"
    defaultDarkTransparentForeground75 = "THEME_defaultDarkTransparentForeground75_THEME"
    defaultDarkTransparentScrim = "THEME_defaultDarkTransparentScrim_THEME"
    defaultDarkSolidSurface10 = "THEME_defaultDarkSolidSurface10_THEME"
    defaultDarkSolidSurface20 = "THEME_defaultDarkSolidSurface20_THEME"
    defaultDarkStatusSuccess = "THEME_defaultDarkStatusSuccess_THEME"
    defaultDarkStatusCaution = "THEME_defaultDarkStatusCaution_THEME"
    defaultDarkStatusAlert = "THEME_defaultDarkStatusAlert_THEME"
    defaultDarkStatusOnNow = "THEME_defaultDarkStatusOnNow_THEME"

    '//This will be replaced by an array of associative arrays which contain the gradient color info. See the getColorKeyValue() function in colorreplace.js for formating of this array
    defaultDarkGradientBrand = "THEME_defaultDarkGradientBrand_THEME"

    '//default light sub theme
    defaultLightPrimaryForeground = "THEME_defaultLightPrimaryForeground_THEME"
    defaultLightTransparentForeground10 = "THEME_defaultLightTransparentForeground10_THEME"

    defaultDarkTransparentAccent20 = "THEME_defaultDarkTransparentAccent20_THEME"

    '//kids theme constants
    kidsDarkPrimaryAccent = "THEME_kidsDarkPrimaryAccent_THEME"
    kidsDarkPrimaryBackground = "THEME_kidsDarkPrimaryBackground_THEME"
    kidsDarkPrimaryForeground = "THEME_kidsDarkPrimaryForeground_THEME"
    kidsDarkTransparentBackground50 = "THEME_kidsDarkTransparentBackground50_THEME"
    kidsDarkTransparentBackground75 = "THEME_kidsDarkTransparentBackground75_THEME"
    ' kidsDarkTransparentForeground0 = "THEME_kidsDarktransparentforeground0_THEME"   '//::NOTE:: not currently being used
    kidsDarkTransparentForeground5 = "THEME_kidsDarkTransparentForeground5_THEME"
    kidsDarkTransparentForeground10 = "THEME_kidsDarkTransparentForeground10_THEME"
    kidsDarkTransparentForeground20 = "THEME_kidsDarkTransparentForeground20_THEME"
    kidsDarkTransparentForeground50 = "THEME_kidsDarkTransparentForeground50_THEME"
    kidsDarkTransparentForeground75 = "THEME_kidsDarkTransparentForeground75_THEME"
    kidsDarkTransparentScrim = "THEME_kidsDarkTransparentScrim_THEME"
    kidsDarkSolidSurface10 = "THEME_kidsDarkSolidSurface10_THEME"
    kidsDarkSolidSurface20 = "THEME_kidsDarkSolidSurface20_THEME"
    'kidsDarkStatusSuccess = "THEME_kidsDarkStatusSuccess_THEME"   '//::NOTE:: not currently being used
    kidsDarkStatusCaution = "THEME_kidsDarkStatusCaution_THEME"
    kidsDarkStatusAlert = "THEME_kidsDarkStatusAlert_THEME"

    '//This will be replaced by an array of associative arrays which contain the gradient color info. See the getColorKeyValue() function in colorreplace.js for formating of this array
    kidsDarkGradientBrand = "THEME_kidsDarkGradientBrand_THEME"

    '//kids light sub theme
    kidsLightPrimaryForeground = "THEME_kidsLightPrimaryForeground_THEME"

  constants.ui.colors = {}
    constants.ui.colors.transparent = "0x00000000"

  'The IDs of the available themes that can be used for the app
  constants.ui.themeIDs = {}
  constants.ui.themeIDs.default = "default"
  constants.ui.themeIDs.kidsMode = "kidsMode"

  'available themes that can be used for the app
  constants.ui.themes = {}
    constants.ui.themes.default = {
      id: constants.ui.themeIDs.default
      focusedColor: defaultDarkPrimaryAccent
      highlightedTextColor: defaultDarkPrimaryAccent
      scrollbarThumbBitmapUri_hd: "pkg:/images/transport/sgplayer/hd/focused-progress-foreground.9.png"
      scrollbarThumbBitmapUri_fhd: "pkg:/images/transport/sgplayer/fhd/focused-progress-foreground.9.png"
      gradientBlendColors: defaultDarkGradientBrand   '//value will be an array of associaive arrays that contain the gradient color info

      successColor: defaultDarkStatusSuccess
      cautionColor: defaultDarkStatusCaution
      backgroundColor: defaultDarkPrimaryBackground
      neutralColor: defaultDarkTransparentForeground20
      neutralColor2: defaultDarkTransparentForeground10
      neutralColor3: defaultDarkTransparentForeground5
      neutralSolidColor: defaultDarkSolidSurface10
      neutralSolidColor2: defaultDarkSolidSurface20
      backgroundColorLight: defaultDarkPrimaryForeground
      backgroundColorLight2: defaultDarkTransparentForeground75
      shadeColor: defaultDarkTransparentBackground75
      shadeColor2: defaultDarkTransparentBackground50
      shadeColor3:  defaultDarkTransparentScrim
      focused2Color: defaultDarkStatusAlert
      unfocusedColor: defaultDarkPrimaryForeground
      selectedListItemColor: defaultDarkTransparentForeground5
      primaryTextColor: defaultDarkPrimaryForeground
      textDarkColor: defaultDarkPrimaryBackground
      secondaryTextColor: defaultDarkTransparentForeground75
      tertiaryTextColor: defaultDarkTransparentForeground50
      focusedTextColor: defaultDarkPrimaryBackground
      keyboardFocusedTextColor: defaultDarkPrimaryBackground
      blueBadgeColor: defaultDarkStatusOnNow

      inversePrimaryTextColor: defaultLightPrimaryForeground
      inverseNeutralColor2: defaultLightTransparentForeground10
      defaultDarkTransparentAccent20: defaultDarkTransparentAccent20
    }

    constants.ui.themes.kidsMode = {
      id: constants.ui.themeIDs.kidsMode
      focusedColor: kidsDarkPrimaryAccent
      highlightedTextColor: kidsDarkPrimaryAccent
      scrollbarThumbBitmapUri_hd: "pkg:/images/transport/sgplayer/hd/focused-progress-foreground_kidsMode.9.png"
      scrollbarThumbBitmapUri_fhd: "pkg:/images/transport/sgplayer/fhd/focused-progress-foreground_kidsMode.9.png"
      gradientBlendColors: kidsDarkGradientBrand  '//value will be an array of associaive arrays that contain the gradient color info

      cautionColor: kidsDarkStatusCaution
      backgroundColor: kidsDarkPrimaryBackground
      neutralColor: kidsDarkTransparentForeground20
      neutralColor2: kidsDarkTransparentForeground10
      neutralColor3: kidsDarkTransparentForeground5
      neutralSolidColor: kidsDarkSolidSurface10
      neutralSolidColor2: kidsDarkSolidSurface20
      backgroundColorLight: kidsDarkPrimaryForeground
      backgroundColorLight2: kidsDarkTransparentForeground75
      shadeColor: kidsDarkTransparentBackground75
      shadeColor2: kidsDarkTransparentBackground50
      shadeColor3:  kidsDarkTransparentScrim
      focused2Color: kidsDarkStatusAlert
      unfocusedColor: kidsDarkPrimaryForeground
      selectedListItemColor: kidsDarkTransparentForeground5
      primaryTextColor: kidsDarkPrimaryForeground
      textDarkColor: kidsDarkPrimaryBackground
      secondaryTextColor: kidsDarkTransparentForeground75
      tertiaryTextColor: kidsDarkTransparentForeground50
      focusedTextColor: kidsDarkPrimaryBackground
      keyboardFocusedTextColor: kidsDarkPrimaryBackground

      inversePrimaryTextColor: kidsLightPrimaryForeground
    }

    '//::NOTE::HARDCODED:: there is a BUG in the built in roku keyboard component
    '// If the color is white, then it will make the focus color to a nearly-black gray.
    '// To combat this limitation, the color is set to white with a very slight, hardly-noticeable opacity.
    if UCase(constants.ui.themes.default.keyboardFocusedTextColor) = "0XFFFFFFFF"
    constants.ui.themes.default.keyboardFocusedTextColor  = "0xFFFFFFFE"
    end if
    if UCase(constants.ui.themes.kidsMode.keyboardFocusedTextColor) = "0XFFFFFFFF"
    constants.ui.themes.kidsMode.keyboardFocusedTextColor  = "0xFFFFFFFE"
    end if


'THEME/COLOR END///////////////////////
    ' Set some performance parameters based on device profile
    constants.performance = {}
      constants.performance.categoryGridList = {}
      constants.performance.categoryGridList.initialBlockSize = 7

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
          constants.performance.categoryGridList.lazyLoadBatchSize = 48
          constants.performance.categoryGridList.finalLazyLoadSize = 200
        else
          constants.performance.categoryGridList.finalBlockSize = 200
          constants.performance.categoryGridList.lazyLoadBatchSize = 48
          constants.performance.categoryGridList.finalLazyLoadSize = 500
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
        constants.performance.categoryGridList.lazyLoadBatchSize = 200
        constants.performance.categoryGridList.finalLazyLoadSize = 1000
        constants.performance.categoryGridList.categoryWindowSize = 10
        constants.performance.categoryGridList.eagerLoad = true
      end if

      constants.performance.categoryGridList.lazyLoadItemsPerBatch = 30

      constants.deeplinks = {}
      constants.deeplinks["homescreen"] = "homescreen"
      constants.deeplinks["homescreen-menu"] = "continue-watching"
      constants.deeplinks["hs-search"] = "search"
      constants.deeplinks["ad"] = "ad"
      constants.deeplinks["my-feed"] = "my-feed"
      constants.deeplinks["external-control"] = "deeplink-test"
      constants.deeplinks["partner-button"] = "remote-partner-button"
      constants.deeplinks["other-channel"] = "other-channel"
      constants.deeplinks["auto-run-dev"] = "sideload"
      constants.deeplinks["hs-d"] = "feature-free-page"
      constants.deeplinks["dial"] = "dial"

      constants.deeplinks.entrypoints = {}
      constants.deeplinks.entrypoints.detail = "detail"
      constants.deeplinks.entrypoints.home = "home"
      constants.deeplinks.entrypoints.epg = "epg"
      constants.deeplinks.entrypoints.category = "category"
      constants.deeplinks.entrypoints.channel = "channel"
      constants.deeplinks.entrypoints.espanol = "espanol"
      constants.deeplinks.entrypoints.movies = "movies"
      constants.deeplinks.entrypoints.tv = "tv"
      constants.deeplinks.entrypoints.categoryDetail = "categoryDetail"
      constants.deeplinks.entrypoints.news = "news"
      constants.deeplinks.entrypoints.episodeList =  "episodeList"
      constants.deeplinks.entrypoints.video = "video"

      ' Creating Backend/Frontend mapping for preference keys.
      ' ****** IMPORTANT - PLEASE DO NOT FORGOT *********
      ' Whenever we add any new field to either device or user setting we need to make sure to add corresponding consent key mapping below.
      ' *************************************************
      constants.serverPersistentDataKeys = {}
      constants.serverPersistentDataKeys.isVideoPreviewOn = "enable_video_preview"
      constants.serverPersistentDataKeys.isAutoPlayTimerOn = "enable_autoplay_timer"
      constants.serverPersistentDataKeys.subtitleTrack = "subtitle_track"
      constants.serverPersistentDataKeys.audioTrack = "audio_track"
      constants.serverPersistentDataKeys.isLikeToastNotificationShown = "enable_like_toast_notification"
      constants.serverPersistentDataKeys.isDisLikeToastNotificationShown = "enable_dislike_toast_notification"
      constants.serverPersistentDataKeys.email = "email"
      constants.serverPersistentDataKeys.parentalRating = "parental_rating"
      constants.serverPersistentDataKeys.hasPassword = "has_password"
      constants.serverPersistentDataKeys.hasPreviouslyRegistered = "has_previously_registered"
      constants.serverPersistentDataKeys.isLinearBlocked = "is_linear_blocked"

      constants.persistentDataKeyConsentKeyMapping = {
        "enable_video_preview": constants.consentKeys.essential
        "enable_autoPlay_timer": constants.consentKeys.essential
        "audio_track": constants.consentKeys.essential
        "subtitle_track": constants.consentKeys.essential
        "enable_like_toast_notification": constants.consentKeys.essential
        "enable_dislike_toast_notification": constants.consentKeys.essential
        "email": constants.consentKeys.essential
        "parental_rating": constants.consentKeys.essential
        "has_password": constants.consentKeys.essential
        "has_previously_registered": constants.consentKeys.essential
        "is_linear_blocked": constants.consentKeys.essential
      }

  return constants
End Function
