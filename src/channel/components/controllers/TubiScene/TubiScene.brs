Function init()
  ' wait for any children to be added to the scene
  m.constants = m.global.constants

  m.spinner = m.top.findNode("TubiSceneSpinner")

  m.customSplashPoster = m.top.findNode("customSplashPoster")
  if m.constants.deviceInfo.scaledUi = true then
    m.customSplashPoster.uri = "pkg:/images/splash-hd.jpg"
  else
    m.customSplashPoster.uri = "pkg:/images/splash-fhd.jpg"
  end if  

  m.top.observeField("fadeOutCustomSplash", "onFadeOutCustomSplash")
  m.top.observeField("fadeOutSpinner", "onFadeOutSpinner")
  
  m.top.observeField("change", "onChildrenChange")
End Function


Function onChildrenChange()
  m.top.unobserveField("change")
  ' can consider putting an animated logo video here
End Function


' customSuspend is the callback for suspendhandler customization tag, 
' will be triggered when user presses Home/Labeled channel key
Function customSuspend(args)

  m.contentController = m.top.findNode("ContentController") 
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


Function onFadeOutCustomSplash()

  customSplashFade = customFadeOut(m.customSplashPoster, 1, 0)
  customSplashFade.observeField("state", "onCustomSplashFadeStateChange")

End Function


Function onCustomSplashFadeStateChange(msg)

  animationState = msg.getData()
  customSplashFade = msg.getRoSGNode()
  if animationState = "stopped"
    if m.spinner <> invalid and m.spinner.opacity = 0
      m.spinnerFade = customFadeIn(m.spinner, 1, 0)
    end if    
    customSplashFade.unobserveField("state")
  end if
  
End Function


Function onFadeOutSpinner()

  if m.spinnerFade <> invalid and m.spinnerFade.state = "running"
    m.spinnerFade.control = "stop"
  end if
  
  if m.spinner <> invalid and m.spinner.opacity > 0
    customFadeOut(m.spinner, 1, 0)
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