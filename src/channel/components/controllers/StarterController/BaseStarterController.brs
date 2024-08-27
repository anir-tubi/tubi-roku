Function init()
  m.constants = getConstants()
  m.global.constants = m.constants
  m.global.theme = m.constants.ui.themes.default

  if m.constants.settings.mode = "dev" AND m.constants.settings.processAnimationLogo = false
    m.top.fadeInRemoteComponent = true
  else if m.constants.deviceInfo.isAutoplayEnabled = false 'certification requirement that do not show animation logo if autoplay is disabled in device settings.
    m.top.fadeInRemoteComponent = true
  else
    processAnimationLogo()
  end if

  m.top.observeFieldScoped("getUrl", "runControllerStartSequence")

  m.isExternalConfigReady = false ' Used to know if we have received external config or at least tried and had the request fail
  m.isExperimentsConfigReady = false ' Used to know if we have received experiments config or at least tried and had the request fail

  if m.constants.settings.useFullStarterController = true then
    setupFullStarterController() 'bs:disable-line 1140 LINT1001
  else
    m.isExperimentsConfigReady = true
    m.isExternalConfigReady = true
  end if
End Function


' Proceed with loading comp lib after experiments and external config is ready for use.
Function runControllerStartSequence()
  if m.isExternalConfigReady <> true OR m.isExperimentsConfigReady <> true then
    ' Wait for external and experiments config to be ready before proceeding
  else if m.top.getUrl <> true then
    ' Wait for getUrl to be called
  else
    if m.constants.settings.useRemoteComponents = false
      m.top.useRemoteComponents = m.constants.settings.useRemoteComponents
    else
      ' This needs to be set before m.top.remoteComponentsUrl as we are getting m.top.remoteComponentLibProvided as part of that observer's additional fields
      m.top.remoteComponentLibProvided = m.constants.settings.remoteComponentLibProvided

      remoteComponentsUrl = getRemoteComponentsUrl()
      print "remoteComponentsUrl "; remoteComponentsUrl
      m.top.remoteComponentsUrl = remoteComponentsUrl
    end if
  end if
End Function


' Called in StarterController's runControllerStartSequence. Used to specify what remote components URL to use
Function getRemoteComponentsUrl()
  return m.constants.settings.remoteComponentsUrl
End Function


Function processAnimationLogo()
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

  m.top.observeField("removeStartUpScreens", "onRemoveStartUpScreens")

  '//Used to ensure there is no black screen in between splash screen and animated logo
  m.videoImageTransition = m.top.findNode("videoImageTransition")

  m.startupScreens = m.top.findNode("startupScreens")

  m.customSplashTimer = m.top.findNode("customSplashTimer")
  m.customSplashTimer.ObserveField("fire","onCustomSplashTimerFired")
  m.customSplashTimer.control = "start"

  videoContent = createObject("RoSGNode", "ContentNode")

  if m.request <> invalid then
    videoContent.url = m.request.passThroughCharlesProxy(m.constants.urls.animationLogo)
  else
    videoContent.url = m.constants.urls.animationLogo
  end if

  videoContent.title = "AnimationLogo"
  videoContent.streamformat = "mp4"

  m.animationLogo = m.top.findNode("animationLogo")
  m.animationLogo.content = videoContent
  m.animationLogo.observeField("bufferingStatus", "onBufferingStatus")
  m.animationLogo.observeField("position", "onPositionChange")
  m.animationLogo.observeField("state", "onAnimationLogoChange")
  m.animationLogo.control = "prebuffer"
End Function


' onPositionChange callback triggered every 0.5s of animationLogo playback
Function onPositionChange(msg)

  position = msg.GetData()
  duration = m.animationLogo.duration
  ' fading the video once the animation part is completed in video [currently animation ends 1s before video ends]
  remaining = duration - position

  if m.videoImageTransition.opacity = 1 AND position > .01
    fade(m.videoImageTransition, "out", 0.5)
  end if

  if remaining <= 0.5
    m.animationLogo.unobserveField("position")
    customFadeOut(m.startupScreens, 1, 0)
  end if

End Function


Function playAnimationLogo()

  if m.bufferingCompleted = true AND m.customSplashTimerCount >= m.splashScreenMin
    m.top.fadeOutCustomSplash = true
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

  m.top.fadeOutCustomSplash = true
  m.videoPlayed = true
  m.animationLogo.control = "stop"

End Function


' onCustomSplashTimerFired fired on every second after customSplashTimer started
Function onCustomSplashTimerFired()

  m.customSplashTimerCount = m.customSplashTimerCount + 0.5
  if m.customSplashTimerCount >= m.splashScreenMax
    ' after reaching splashScreenMax time, manually stopping animationLogo if state is stopped or buffering
    m.customSplashTimer.unobserveField("fire")
    m.customSplashTimer.control = "stop"
    if m.animationLogo <> invalid AND m.animationLogo.state <> "playing"
      stopAnimationLogo()
    end if
  else if m.videoPlayed = false
    ' will only play if video has pre buffered and m.splashScreenMin has been surpassed
    playAnimationLogo()
  end if

End Function


' onAnimationLogoChange callback triggered  when video state changes
Function onAnimationLogoChange(msg)

  state = msg.GetData()
  if (state = "finished" or state = "stopped") AND m.videoPlayed = true
    m.top.fadeInRemoteComponent = true
  end if

End Function


' onRemoveStartUpScreens is used to remove animationLogo node
Function onRemoveStartUpScreens()

  m.animationLogo.visible = false
  m.top.removeChild(m.animationLogo)
  m.animationLogo = invalid

  m.videoImageTransition.visible = false
  m.top.removeChild(m.videoImageTransition)
  m.videoImageTransition = invalid

  m.startupScreens.visible = false
  m.top.removeChild(m.startupScreens)
  m.startupScreens = invalid

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
