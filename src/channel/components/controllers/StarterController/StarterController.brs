Function init()
  m.constants = getConstants()
  m.global.constants = m.constants
  m.request = TubiRequest(m.constants.settings)
  m._ = rodash()

  if m.constants.settings.mode = "dev" AND m.constants.settings.processAnimationLogo = false
    m.top.fadeInRemoteComponent = true
  else
    processAnimationLogo()
  end if

  '//TODO : after the experiment roku_new_cdn set both m.isExperimentConfigReady and m.isExternalConfigReady to false to start with.

  m.isExperimentConfigReady = (m.constants <> invalid AND m.constants.experiments <> invalid AND m.constants.experiments.info <> invalid)
  m.isExternalConfigReady = (m.constants <> invalid AND m.constants.externalConfig <> invalid AND m.constants.externalConfig.info <> invalid)

  m.top.observeFieldScoped("getUrl", "onUrlRequest")

  starterTask = createObject("roSGNode", "StarterGeneralTask") ' initiate StarterTask
  GeneralTaskModule(m, starterTask)

  if m.isExperimentConfigReady = true AND m.isExternalConfigReady = true
    checkIfExperimentAndRemoteConfigReadyAndProceed()
  else
    sendRequestForExperimentsAndConfig()
  end if

End Function


Function onUrlRequest()
  checkIfExperimentAndRemoteConfigReadyAndProceed()
End Function


' Proceed with loading comp lib after experiments and external config is ready for use.
Function checkIfExperimentAndRemoteConfigReadyAndProceed()
  if m.top.getUrl = true AND m.isExperimentConfigReady = true AND m.isExternalConfigReady = true
    'Handle any remote config updates here:
    'Let youbora be enabled by the remote config

    youboraEnabled = m._.get(m.constants, "externalConfig.info.youbora_enabled")
    if youboraEnabled = true
      m.constants.settings.youboraEnabled = youboraEnabled
    end if

    m.top.newBuildConstants = m.constants

    if m.constants.settings.useRemoteComponents = false
      m.top.useRemoteComponents = m.constants.settings.useRemoteComponents
    else

      ' if an experiment or remote config needs to update the remoteComponentsUrl, do it here.
      ' (experiment tracking should not happen here. It should happen when the user encounters the experiment!)
      '-------------------------------------------------------------------------------------'
      ' EXPERIMENT EXAMPLE
      ' experiments = TubiExperiments(m.constants)
      ' sideNavEnabled = m.experiments.getExperimentResource("RokuNamespace", "roku_side_nav").enabled
      ' if sideNavEnabled = true
      '   remoteComponentsUrl = "someUrl"
      ' else
      '   remoteComponentsUrl = "someOtherUrl"
      ' end if
      '
      ' sendExposureEvent("RokuNamespace", "roku_side_nav", experiments)
      '
      ' REMOTE/EXTERNAL CONFIG EXAMPLE:
      ' remoteComponentsUrl = m.constants.externalConfig.sideNavRemoteComponentsUrl
      '-------------------------------------------------------------------------------------'
      experiments = TubiExperiments(m.constants)
      remoteComponentsUrl = m.constants.settings.remoteComponentsUrl
      if experiments <> invalid then
        if m.constants.settings.mode <> "dev"
          if experiments.getExperimentResource("roku_new_cdn", "roku_new_cdn_v1").enabled = true
            remoteComponentsUrl = m.constants.settings.rcdnRemoteComponentsUrl
          end if
        end if

        if experiments.getExperimentResource("roku_async_stop", "roku_async_stop_v5").enabled = true then
          m.animationLogo.asyncStopSemantics = true
        end if
      end if
      '-------------------------------------------------------------------------------------'
      '-------------------------------------------------------------------------------------'

      ' This needs to be set before m.top.remoteComponentsUrl as we are getting m.top.remoteComponentLibProvided as part of that observer's additional fields
      m.top.remoteComponentLibProvided = m.constants.settings.remoteComponentLibProvided

      print "remoteComponentsUrl "; remoteComponentsUrl
      m.top.remoteComponentsUrl = remoteComponentsUrl
    end if
  end if
End Function


' Performs network request to get experiments and external config.
Function sendRequestForExperimentsAndConfig()
  constants = m.constants
  externalConfig = TubiExternalConfig(m.request, constants)
  experiments = TubiExperiments(constants)

  experimentsRequest = experiments.getNamespaceRequestInfo(constants)
  if experimentsRequest <> invalid
    experimentsRequest.successCallback = onExperimentsRequestSuccess
    experimentsRequest.errorCallback = onExperimentsRequestFailure
    experimentsRequest.timeoutInMilliSec = 5000
    m.makeRequest(experimentsRequest)
  else
    ' If there are no namespaces then skip the request.
    m.isExperimentConfigReady = true
  end if

  externalConfigRequestInfo = externalConfig.getConfigsRequestInfo(constants)
  externalConfigRequestInfo.successCallback = onExternalConfigRequestSuccess
  externalConfigRequestInfo.errorCallback = onExternalConfigRequestFailure
  externalConfigRequestInfo.timeoutInMilliSec = 5000
  m.makeRequest(externalConfigRequestInfo)
End Function


' Callback triggered once the experiments request is successful.
Function onExperimentsRequestSuccess(experimentInfo)
  m.constants.experiments.info = experimentInfo
  m.isExperimentConfigReady = true
  checkIfExperimentAndRemoteConfigReadyAndProceed()
End Function


' Callback triggered if the experiment request fails.
Function onExperimentsRequestFailure(_responses)
  ' Continue using the local defaults.
  m.isExperimentConfigReady = true
  checkIfExperimentAndRemoteConfigReadyAndProceed()
End Function


' Callback triggered once the config request is successful.
Function onExternalConfigRequestSuccess(config)
  if config <> invalid
    if config.country <> invalid AND config.country <> ""
      m.constants.deviceInfo.countryCode = UCase(config.country)
    end if

    if isAA(config.blocked_analytics_events) = true
      ' Storing the value of blocked analytics event to registry as a fallback in future if the external config call fails.
      RegWrite("blocked_analytics_events", FormatJson(config.blocked_analytics_events), m.constants.registrySectionIDs.fallbacks)
    end if

    m.constants.externalConfig.info = config
  end if

  m.isExternalConfigReady = true
  checkIfExperimentAndRemoteConfigReadyAndProceed()
End Function


' Callback triggered once the config request is fails.
Function onExternalConfigRequestFailure(_error)
  ' Reading the fallback data if present from the registry and setting it to constants.
  blockedEventsList = RegRead("blocked_analytics_events", m.constants.registrySectionIDs.fallbacks)
  if blockedEventsList <> invalid
    blockedEventsList = ParseJson(blockedEventsList)
    if isAA(blockedEventsList) = true
      m.constants.externalConfig.info = {
        "blocked_analytics_events": blockedEventsList
      }
    end if
  end if

  m.isExternalConfigReady = true
  checkIfExperimentAndRemoteConfigReadyAndProceed()
End Function


Function sendExposureEvent(namespaceName as string, experimentName as string, experimentsLib)
  exposureInfo = experimentsLib.getExperimentTracking(namespaceName, experimentName)

  if exposureInfo <> invalid
    Request = TubiRequest(m.constants.settings)
    Auth = TubiAuth(m.constants, Request)
    trackingLib = TubiTracking(m.constants, Request, Auth)
    exposureEvent = trackingLib.getClientEvent(exposureInfo.type, exposureInfo.values)
    reqInfo = trackingLib.createUserTrackingReqInfo(exposureEvent)
    m.makeRequest({
      url: reqInfo.url
      options: reqInfo.options
      requestType: m.constants.reqNames.postAnalytics
      silenceCallbackWarnings: true
    })
  end if
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

  videoContent.url = m.request.passThroughCharlesProxy(m.constants.urls.animationLogo)

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
