Function init()
  addGlobalFields()

  m.animationLogo = m.top.findNode("animationLogo")
  m.global.appVideoNode = m.animationLogo

  ' TODO should eventually experiment if it is beneficial to only keep this on as needed
  m.top.allowBackgroundTask = true

  m.starterConfig = invalid

  m.waitingOnAnimationLogoToFinish = true

  m.tubiStarterLibrary = m.top.findNode("TubiStarterLibrary")
  m.tubiRemoteLibrary = m.top.findNode("TubiRemoteLibrary")

  m.startupScreens = m.top.findNode("startupScreens")

  m.customSplashTimer = m.top.findNode("customSplashTimer")
  m.customSplashTimer.observeFieldScoped("fire", "onCustomSplashTimerFired")

  m.top.observeFieldScoped("baseChannelConstants", "onBaseChannelConstantsChange")

  m.customSplashPoster = m.top.findNode("customSplashPoster")
  m.top.backgroundUri = "pkg:/images/background-masks/mask-layer-1-0.webp"
End Function


' addGlobalFields adds global fields to the scene. Values except for appVideoNode will get set in ContentController init
Function addGlobalFields()
  m.global.addField("constants", "assocarray", false)
  m.global.addField("theme", "assocarray", false)
  m.global.addField("externalConfigInfo", "assocarray", false)
  m.global.addField("experimentsInfo", "assocarray", false)
  m.global.addField("translationAA", "assocarray", false)
  m.global.addField("appVideoNode", "node", false)
End Function


Function onBaseChannelConstantsChange(msg)
  m.baseChannelConstants = msg.getData()
  loadStarterLibrary(m.baseChannelConstants)
End Function


Function loadStarterLibrary(constants)
  m.tubiStarterLibrary.observeFieldScoped("loadStatus", "onStarterLibraryLoadStatusChange")

  starterLibUrl = constants.settings.starterComponentsUrl
  print "attempting to load TubiStarterLibrary "; starterLibUrl

  m.tubiStarterLibrary.uri = starterLibUrl
End Function


Function onStarterLibraryLoadStatusChange(msg)
  loadStatus = msg.getData()
  if loadStatus = "ready" then
    starterConfigNode = createObject("roSGNode", "TubiStarterLibrary:StarterConfig")
    if starterConfigNode = invalid then
      loadContentController("ContentController", msg.getNode())
    else
      starterConfig = starterConfigNode.config

      ' For future capability to prevent app loading if needed in the future
      if starterConfig.preventAppLoad = true then
        print "TubiScene: StarterConfig preventAppLoad is true, not continuing"
      else
        onStarterConfigAvailable(starterConfig)
      end if
    end if
  else if loadStatus = "failed" then
    loadContentController("ContentController", msg.getNode())
  end if
End Function


Function onStarterConfigAvailable(starterConfig)
  m.starterConfig = starterConfig
  settings = starterConfig.settings

  if settings.mode = "dev" AND settings.processAnimationLogo = false
    m.waitingOnAnimationLogoToFinish = false
  else if m.baseChannelConstants.deviceInfo.isAutoplayEnabled = false 'certification requirement that do not show animation logo if autoplay is disabled in device settings.
    m.waitingOnAnimationLogoToFinish = false
  else
    processAnimationLogo(settings.animationLogoUrl)
  end if

  if settings.mode <> "production" then
    ' Check if we are overwriting the remote components url via registry for testing purposes
    registrySection = createObject("roRegistrySection", "configurationOverrides")

    configurationOverrides = registrySection.ReadMulti([
      "remoteComponentsUrl"
      "remoteComponentLibProvided"
    ])

    if isNonEmptyString(configurationOverrides.remoteComponentsUrl) = true AND isNonEmptyString(configurationOverrides.remoteComponentLibProvided) = true then
      settings["remoteComponentLibProvided"] = configurationOverrides.remoteComponentLibProvided
      settings["remoteComponentsUrl"] = configurationOverrides.remoteComponentsUrl
      print "TubiScene: Overriding remoteComponentsUrl to "; settings["remoteComponentsUrl"]

      m.global.update({
        "remoteComponentLibraryOverridden": true
      }, true)
    end if
  end if

  if settings.useRemoteComponents = true then
    m.tubiRemoteLibrary.observeFieldScoped("loadStatus", "onRemoteLibraryLoadStatusChange")
    m.tubiRemoteLibrary.uri = settings.remoteComponentsUrl
  else
    loadContentController("ContentController")
  end if
End Function


Function onRemoteLibraryLoadStatusChange(msg)
  loadStatus = msg.getData()
  if loadStatus = "ready" then
    loadContentController(m.starterConfig.settings.remoteComponentLibProvided + ":ContentController")
  else if loadStatus = "failed" then
    loadContentController("ContentController", msg.getNode())
  end if
End Function


Function loadContentController(nodeType, componentLibraryIdThatFailedToLoad = invalid)
  m.tubiStarterLibrary.unobserveFieldScoped("loadStatus")
  m.tubiRemoteLibrary.unobserveFieldScoped("loadStatus")

  contentController = m.top.createChild(nodeType)

  if contentController = invalid then
    contentController = m.top.createChild("ContentController")
  end if

  m.contentController = contentController

  ' Starter library could have failed to load so we didn't play the starter animation logo
  if componentLibraryIdThatFailedToLoad <> invalid then
    constants = m.baseChannelConstants

    message = {
      message: componentLibraryIdThatFailedToLoad + " failed to load due to timeout. Loading Packed Components"
      model: constants.deviceInfo.model
      name: componentLibraryIdThatFailedToLoad
      type: constants.errors.type.loadFailed
    }

    'Send error info to sentry
    m.top.sendLogToServer = {
      "type": "exception"
      "level": "warn"
      "message": message
      "samplePercent": 0.1
    }

    'Send error info to clientLog
    m.top.sendLogToServer = {
      "type": "warn"
      "message": message
      "serverTypeName": "apiTimeout"
      "subtype": "RO-1-300"
    }

    contentController.isComponentLibFailedToLoad = true
    m.waitingOnAnimationLogoToFinish = false
  end if

  if m.waitingOnAnimationLogoToFinish = false then
    fadeInContentController()
  end if
End Function


' customSuspend is the callback for suspendhandler customization tag,
' will be triggered when user presses Home/Labeled channel key
Function customSuspend(args)
  if m.contentController <> invalid
    m.contentController.customSuspend = args
  end if
End Function


' customResume is the callback for resumehandler customization tag,
' every app launch, roku firmware checks whether the customSuspend.lastSuspendOrResumeReason has value as "Home",
' if exists, then triggers customResume callback to make necessary action
Function customResume(args)
  if args <> invalid
    if m.contentController <> invalid
      m.contentController.customResume = args
    end if
  end if
End Function


Function processAnimationLogo(url)
  ' bufferingCompleted tells whether buffering reached 33% or more
  m.bufferingCompleted = false

  appInfo = createObject("roAppInfo")
  initialSplashScreenDuration = Val(appInfo.getValue("splash_min_time")) / 1000

  ' minimum seconds the custom splash poster is displayed
  m.splashScreenMin = initialSplashScreenDuration + 0

  ' maximum seconds the custom splash poster is displayed
  m.splashScreenMax = initialSplashScreenDuration + 3

  ' customSplashTimerCount is number of timer the timer event got fired
  m.customSplashTimerCount = 0

  ' videoPlayed helps to set fadeInRemoteComponent=true
  m.videoPlayed = false

  m.customSplashTimer.control = "start"

  videoContent = createObject("RoSGNode", "ContentNode")
  videoContent.url = url

  videoContent.title = "AnimationLogo"
  videoContent.streamformat = "mp4"

  m.animationLogo.content = videoContent
  m.animationLogo.observeField("bufferingStatus", "onBufferingStatus")
  m.animationLogo.observeField("position", "onPositionChange")
  m.animationLogo.observeField("state", "onAnimationLogoStateChange")
  m.animationLogo.control = "prebuffer"
End Function


' onPositionChange callback triggered every 0.5s of animationLogo playback
Function onPositionChange(msg)
  position = msg.GetData()
  duration = m.animationLogo.duration
  ' fading the video once the animation part is completed in video [currently animation ends 1s before video ends]
  remaining = duration - position

  if remaining <= 0.5
    m.animationLogo.unobserveField("position")
    customFadeOut(m.startupScreens, 1, 0)
  end if
End Function


Function playAnimationLogo()
  if m.bufferingCompleted = true AND m.customSplashTimerCount >= m.splashScreenMin
    fadeOutCustomSplash()
    m.videoPlayed = true

    if m.animationLogo <> invalid
      m.animationLogo.control = "play"
    end if
  end if
End Function


' onBufferingStatus callback triggered on every videoplayer buffering percent
' When the buffering percentage reaches 33%, we call playAnimationLogo() will sets the animationLogo
' video node control to play. The buffering percent will only go above 33% if control is set to play.
' Then, once the buffering percentage has reached 99% we fade in the video player as part of the
' m.startupScreens group.
Function onBufferingStatus(msg)
  buffering = msg.GetData()
  ' we are fadingIn startupScreens(VideoNode) only when the buffering percent is >= 99%
  ' this is to avoid black(videoNode) screen appearing before the video starts playing especially on slow internet connection
  ' The image videoImageTransition is further insurance a black screen will not appear
  if buffering <> invalid AND buffering.percentage >= 99
    m.animationLogo.unobserveField("bufferingStatus")

    customFadeIn(m.startupScreens, 0.5, 0)
    ' starting the playback when the buffering percent is >= 33%
  else if buffering <> invalid AND buffering.percentage >= 33 AND m.bufferingCompleted = false
    m.bufferingCompleted = true
    playAnimationLogo()
  end if
End Function


Function stopAnimationLogo()
  fadeOutCustomSplash()
  m.videoPlayed = true
  m.animationLogo.control = "stop"
End Function


Function fadeOutCustomSplash()
  customFadeOut(m.customSplashPoster, 1, 0)
End Function


' onCustomSplashTimerFired fired on every second after customSplashTimer started
Function onCustomSplashTimerFired()
  m.customSplashTimerCount = m.customSplashTimerCount + 0.5
  if m.customSplashTimerCount >= m.splashScreenMax
    ' after reaching splashScreenMax time, manually stopping animationLogo if state is stopped or buffering
    m.customSplashTimer.unobserveFieldScoped("fire")
    m.customSplashTimer.control = "stop"
    if m.animationLogo <> invalid AND m.animationLogo.state <> "playing"
      stopAnimationLogo()
    end if
  else if m.videoPlayed = false
    ' will only play if video has pre buffered and m.splashScreenMin has been surpassed
    playAnimationLogo()
  end if
End Function


' onAnimationLogoStateChange callback triggered  when video state changes
Function onAnimationLogoStateChange(msg)
  state = msg.GetData()
  if (state = "finished" OR state = "stopped") AND m.videoPlayed = true then
    m.waitingOnAnimationLogoToFinish = false
    if m.contentController <> invalid then
      fadeInContentController()
    end if
  end if
End Function


Function fadeInContentController()
  if m.contentController <> invalid then
    m.contentController.observeFieldScoped("removeStartUpScreens", "onRemoveStartUpScreens")
    m.contentController.fadeInContentController = true
  else
    print "TubiScene: fadeInContentController: contentController is invalid"
  end if
End Function


' onRemoveStartUpScreens is used to remove animationLogo node
Function onRemoveStartUpScreens()
  ' Cleaning up start up screens to avoid extra resources being used that are no longer needed
  m.animationLogo = invalid
  m.videoImageTransition = invalid

  m.top.removeChild(m.startupScreens)
  m.startupScreens = invalid

  m.top.removeChild(m.customSplashPoster)
  m.customSplashPoster = invalid
End Function


Function customFadeIn(target, duration, delay)
  animationOptions = {
    easeFunction: "inCubic"
    opacity: 1
    duration: duration
    delay: delay
    allowOnLowSpecDevices: true
  }
  return animate(target, animationOptions)
End Function


Function customFadeOut(target, duration, delay)
  animationOptions = {
    easeFunction: "inCubic"
    opacity: 0
    duration: duration
    delay: delay
    allowOnLowSpecDevices: true
  }
  return animate(target, animationOptions)
End Function
