Function init()
  ' wait for any children to be added to the scene
  m.constants = m.global.constants
  
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


Function onFadeOutCustomSplash()

  customFadeOut(m.customSplashPoster, 1, 0)

End Function


Function onFadeOutSpinner()

  customFadeOut(m.spinner, 1, 0)

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