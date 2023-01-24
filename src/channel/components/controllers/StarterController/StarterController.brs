Function init()
  m.constants = getConstants()
  m._ = rodash()

  if m.constants.settings.mode = "dev" AND m.constants.settings.processAnimationLogo = false
    m.top.fadeInRemoteComponent = true
  else
    processAnimationLogo()
  end if

  m.hasExperiments = false
  m.hasRemoteConfigs = false
  m.experimentsTask = m.top.createChild("ExperimentsTask")
  m.experimentsTask.observeField("experimentsInfo", "onExperimentsInfoReturned")
  m.experimentsTask.observeField("externalConfigInfo", "onExternalConfigInfoReturned")
  m.experimentsTask.constants = m.constants
  m.experimentsTask.control = "RUN"

  m.top.observeField("getUrl", "onUrlRequest")
End Function


Function onUrlRequest()
  if m.top.getUrl = true AND m.hasExperiments = true AND m.hasRemoteConfigs = true
    'Handle any remote config updates here:
    'Let youbora be enabled by the remote config

    youboraEnabled = m._.get(m.constants, "externalConfig.info.youbora_enabled")
    if youboraEnabled = true
      m.constants.thirdParty.youbora.enabled = youboraEnabled
    end if

    m.top.newBuildConstants = m.constants

    if m.constants.settings.useRemoteComponents = false
      m.top.useRemoteComponents = m.constants.settings.useRemoteComponents
    else
      remoteComponentsUrl = m.constants.settings.remoteComponentsUrl

      ' if an experiment or remote config needs to update the remoteComponentsUrl, do it here.
      ' (experiment tracking should not happen here. It should happen when the user encounters the experiment!)
      '-------------------------------------------------------------------------------------'
      ' experiment example:
      ' request = TubiRequest(m.constants.settings)
      ' experiments = TubiExperiments(m.constants)
      ' sideNavEnabled = m.experiments.getExperimentResource("RokuNamespace", "roku_side_nav").enabled
      ' if sideNavEnabled = true
      '   remoteComponentsUrl = "someUrl"
      ' else
      '   remoteComponentsUrl = "someOtherUrl"
      ' end if
      '
      ' remote/external config example:
      ' remoteComponentsUrl = m.constants.externalConfig.sideNavRemoteComponentsUrl


      '-------------------------------------------------------------------------------------'
      print "remoteComponentsUrl "; remoteComponentsUrl
      m.top.remoteComponentsUrl = remoteComponentsUrl
    end if

  end if
End Function


Function onExperimentsInfoReturned(msg)
  m.constants.experiments.info = msg.getData()
  m.experiments = TubiExperiments(m.constants)
  m.hasExperiments = true
  onUrlRequest()
End Function


Function onExternalConfigInfoReturned(msg)
  m.constants.externalConfig.info = msg.getData()
  if m.constants.externalConfig.info <> invalid
    if m.constants.externalConfig.info.country <> invalid AND m.constants.externalConfig.info.country <> ""
      m.constants.deviceInfo.countryCode = UCase(m.constants.externalConfig.info.country)
    end if
  end if

  m.hasRemoteConfigs = true
  onUrlRequest()
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

  m.startupScreens = m.top.findNode("startupScreens")

  m.animationLogo = m.top.findNode("animationLogo")

  m.customSplashTimer = m.top.findNode("customSplashTimer")
  m.customSplashTimer.ObserveField("fire","onCustomSplashTimerFired")
  m.customSplashTimer.control = "start"

  videoContent = createObject("RoSGNode", "ContentNode")
  videoContent.url = m.constants.urls.animationLogo
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

  if remaining <= 0.5
    m.animationLogo.unobserveField("position")
    customFadeOut(m.startupScreens, 1, 0)
  end if

End Function


Function playAnimationLogo()

  if m.bufferingCompleted = true AND m.customSplashTimerCount >= m.splashScreenMin
    m.top.fadeOutCustomSplash = true
    m.videoPlayed = true
    m.animationLogo.control = "play"
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
