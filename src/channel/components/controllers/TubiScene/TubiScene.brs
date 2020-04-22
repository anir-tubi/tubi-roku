Function init()

  m.constants = m.global.constants

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
  
  ' videoPlayed helps to set animationLogoCompleted=true to ContentController
  m.videoPlayed = false
  
  m.spinner = m.top.findNode("TubiSceneSpinner")

  m.startupScreens = m.top.findNode("startupScreens")
  
  m.animationLogo = m.top.findNode("animationLogo")
  
  m.customSplashPoster = m.top.findNode("customSplashPoster")
  
  if m.constants.deviceInfo.scaledUi = true then
    m.customSplashPoster.uri = "pkg:/images/splash-hd.jpg"
  else
    m.customSplashPoster.uri = "pkg:/images/splash-fhd.jpg"
  end if
  
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
    focusContentControllerOrFadeInSpinner()
  end if

End Function


' onBufferingStatus callback triggered on every videoplayer buffering percent
Function onBufferingStatus(msg)

  buffering = msg.GetData()
  if buffering <> invalid and buffering.percentage >= 33
    m.animationLogo.unobserveField("bufferingStatus")
    m.bufferingCompleted = true
    playAnimationLogo()
  end if

End Function


Function playAnimationLogo()
  if m.bufferingCompleted = true and m.customSplashTimerCount >= m.splashScreenMin 
    customFadeOut(m.customSplashPoster, 1, 0)
    m.videoPlayed = true
    m.animationLogo.control = "play"
  end if
End Function


Function stopAnimationLogo()
  customFadeOut(m.customSplashPoster, 1, 0)
  m.videoPlayed = true
  m.animationLogo.control = "stop"
End Function


' onCustomSplashTimerFired fired on every second after customSplashTimer started
Function onCustomSplashTimerFired()
  m.customSplashTimerCount = m.customSplashTimerCount + 0.5
  if m.customSplashTimerCount >= m.splashScreenMax
    ' after reaching splashScreenMax time, manually stopping animationLogo if state is stopped or buffering
    if m.animationLogo.state <> "playing"
      stopAnimationLogo()
      focusContentControllerOrFadeInSpinner()
    end if
  else if m.videoPlayed = false
    ' will only play if video has pre buffered and m.splashScreenMin has been surpassed
    playAnimationLogo()
  end if
End Function


Function focusContentController(contentController, spinner, spinnerFade)
  if spinnerFade <> invalid and spinnerFade.state = "running"
    spinnerFade.control = "stop"
  end if

  if spinner <> invalid and spinner.opacity > 0
    customFadeOut(spinner, 1, 0)
  end if

  contentControllerBGGroup = contentController.findNode("contentControllerBGGroup")
  contentControllerFade = customFadeIn(contentControllerBGGroup, 2, 0.75)
  contentControllerFade.observeField("state", "onContentControllerFadeStateChange")

  contentController.animationLogoCompleted = true 'sets focus on content controller screen
End Function


Function onContentControllerFadeStateChange(msg)
  animationState = msg.getData()
  contentControllerFade = msg.getRoSGNode()
  if animationState = "stopped"
    removeAnimationLogoNode("onContentControllerFadeStateChange")
    contentControllerFade.unobserveField("state")
  end if
End Function


' onAnimationLogoChange callback triggered  when video state changes
Function onAnimationLogoChange(msg)

  state = msg.GetData()
  if (state = "finished" or state = "stopped") and m.videoPlayed = true
    focusContentControllerOrFadeInSpinner()
  end if

End Function


' removeAnimationLogoNode is used to remove animationLogo node
Function removeAnimationLogoNode(source)
  m.animationLogo.visible = false
  m.top.removeChild(m.animationLogo)
  m.animationLogo = invalid

  m.startupScreens.visible = false
  m.top.removeChild(m.startupScreens)
  m.startupScreens = invalid  
End Function


Function focusContentControllerOrFadeInSpinner()

  contentController = m.top.findNode("ContentController")
  if contentController <> invalid and contentController.animationLogoCompleted <> true
    m.customSplashTimer.unobserveField("fire")
    m.customSplashTimer.control = "stop"
    focusContentController(contentController, m.spinner, m.spinnerFade) 'will also fade content controller in
  else if m.spinner <> invalid and m.spinner.opacity = 0
    m.spinnerFade = customFadeIn(m.spinner, 2, 0.5)
  end if

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