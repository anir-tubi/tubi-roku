' callback for skip button for all OnBoarding screens
' it skips all onboarding screens and invokes startUserExperience
Function skipOnBoarding()

  startUserExperience()

End Function


' creates LandingScreen and pushes in screenstack  
Function showLandingScreen()

  landingScreen = CreateObject("roSGNode", "LandingScreen")
  landingScreen.id = m.constants.ui.screenIds.landingScreen
  landingScreen.observeField("registerButtonPressed", "onRegisterButtonPressed")
  landingScreen.observeField("guestButtonPressed", "onGuestButtonPressed")
  pushScreen(landingScreen, true, true)

End Function


' callback for Register for Tubi button on LandingScreen
Function onRegisterButtonPressed()

  if m.global.authInfo = invalid
    startSignIn(false)
  else
    skipOnBoarding()  
  end if

End Function


' callback for Continue as Guest button on LandingScreen
Function onGuestButtonPressed()
 
  showOnBoardingUnlimitedScreen()

End Function


' creates OnBoarding-UnlimitedScreen and pushes in screenstack  
Function showOnBoardingUnlimitedScreen()
 
  unlimitedScreen = CreateObject("roSGNode", "UnlimitedScreen")
  unlimitedScreen.id = m.constants.ui.screenIds.unlimitedScreen
  unlimitedScreen.observeField("nextButtonPressed", "onUnlimitedNextButtonPressed")
  unlimitedScreen.observeField("skipButtonPressed", "skipOnBoarding") 
  pushScreen(unlimitedScreen, true, true)

End Function


' callback for Next button in OnBoarding-UnlimitedScreen
Function onUnlimitedNextButtonPressed()

   showOnBoardingCostNothingScreen()

End Function


' creates OnBoarding-CostNothingScreen and pushes in screenstack 
Function showOnBoardingCostNothingScreen()

  costNothingScreen = CreateObject("roSGNode", "CostNothingScreen")
  costNothingScreen.id = m.constants.ui.screenIds.costNothingScreen
  costNothingScreen.observeField("nextButtonPressed", "onCostNothingNextButtonPressed")
  costNothingScreen.observeField("skipButtonPressed", "skipOnBoarding") 
  pushScreen(costNothingScreen, true, true)

End Function


' callback for Next button in OnBoarding-CostNothingScreen
Function onCostNothingNextButtonPressed()

   showOnBoardingAvailableDeviceScreen()

End Function


' creates OnBoarding-AvailableDeviceScreen and pushes in screenstack 
Function showOnBoardingAvailableDeviceScreen()

  availableDeviceScreen = CreateObject("roSGNode", "AvailableDeviceScreen")
  availableDeviceScreen.id = m.constants.ui.screenIds.availableDeviceScreen
  availableDeviceScreen.observeField("startWatchingButtonPressed", "onStartWatchingButtonPressed")
  pushScreen(availableDeviceScreen, true, true)

End Function


' callback for Start Watching button in OnBoarding-AvailableDeviceScreen
Function onStartWatchingButtonPressed()

   skipOnBoarding()

End Function