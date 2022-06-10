' creates WelcomeScreen and pushes in screenstack
Function showOnBoardingWelcomeScreen()

  tubiLog("OnBoardingHelpers.showOnBoardingWelcomeScreen")
  welcomeScreen = CreateObject("roSGNode", "OnBoardingScreen")
  welcomeScreen.id = m.constants.ui.screenIds.welcomeScreen
  welcomeScreen.screenLevel = m.constants.ui.screenLevels.welcomeScreen
  welcomeScreen.title = getTranslation("onBoarding_welcomeScreen_heading")
  welcomeScreen.description = getTranslation("onBoarding_welcomeScreen_description")
  welcomeScreen.carouselIndex = 0
  welcomeScreen.buttons = [
    "onBoarding_next_button"
    "onBoarding_skip_button"
  ]
  welcomeScreen.trackingPageInfo = {
    pageType: "onboarding_page"
    pageValues: {
      page_sequence: m.constants.ui.onBoarding.pageSequence.welcomeScreen
    }
  }
  welcomeScreen.observeFieldScoped("nextButtonPressed", "onWelcomeScreenNextButtonPressed")
  welcomeScreen.observeFieldScoped("skipButtonPressed", "onWelcomeScreenSkipButtonPressed")
  pushScreen(welcomeScreen, true, true)

End Function


Function onWelcomeScreenNextButtonPressed()
  showOnBoardingFreeForeverScreen()
End Function


Function onWelcomeScreenSkipButtonPressed()
  showOnBoardingLandingScreen()
End Function


' creates FreeForeverScreen and pushes in screenstack
Function showOnBoardingFreeForeverScreen()

  tubiLog("OnBoardingHelpers.showOnBoardingFreeForeverScreen")
  freeForeverScreen = CreateObject("roSGNode", "OnBoardingScreen")
  freeForeverScreen.id = m.constants.ui.screenIds.freeForeverScreen
  freeForeverScreen.screenLevel = m.constants.ui.screenLevels.freeForeverScreen
  freeForeverScreen.title = getTranslation("onBoarding_freeForeverScreen_heading")
  freeForeverScreen.description = getTranslation("onBoarding_freeForeverScreen_description")
  freeForeverScreen.carouselIndex = 1
  freeForeverScreen.buttons = ["onBoarding_next_button"]
  freeForeverScreen.trackingPageInfo = {
    pageType: "onboarding_page"
    pageValues: {
      page_sequence: m.constants.ui.onBoarding.pageSequence.freeForeverScreen
    }
  }
  freeForeverScreen.observeFieldScoped("nextButtonPressed", "onFreeForeverScreenNextButtonPressed")
  pushScreen(freeForeverScreen, true, true)

End Function


Function onFreeForeverScreenNextButtonPressed()
  showOnBoardingAvailableDeviceScreen()
End Function


' creates AvailableDeviceScreen and pushes in screenstack
Function showOnBoardingAvailableDeviceScreen()

  tubiLog("OnBoardingHelpers.showOnBoardingAvailableDeviceScreen")
  availableDeviceScreen = CreateObject("roSGNode", "OnBoardingScreen")
  availableDeviceScreen.id = m.constants.ui.screenIds.availableDeviceScreen
  availableDeviceScreen.screenLevel = m.constants.ui.screenLevels.availableDeviceScreen
  availableDeviceScreen.title = getTranslation("onBoarding_availableDeviceScreen_heading")
  availableDeviceScreen.description = getTranslation("onBoarding_availableDeviceScreen_description")
  availableDeviceScreen.carouselIndex = 2
  availableDeviceScreen.buttons = ["onBoarding_getStarted_button"]
  availableDeviceScreen.trackingPageInfo = {
    pageType: "onboarding_page"
    pageValues: {
      page_sequence: m.constants.ui.onBoarding.pageSequence.availableDeviceScreen
    }
  }
  availableDeviceScreen.observeFieldScoped("getStartedButtonPressed", "onAvailableDeviceScreenGetStartedButtonPressed")
  pushScreen(availableDeviceScreen, true, true)

End Function


Function onAvailableDeviceScreenGetStartedButtonPressed()
  showOnBoardingLandingScreen()
End Function


' creates LandingScreen and pushes in screenstack
Function showOnBoardingLandingScreen()

  tubiLog("OnBoardingHelpers.showOnBoardingLandingScreen")
  landingScreen = CreateObject("roSGNode", "LandingScreen")
  landingScreen.id = m.constants.ui.screenIds.landingScreen
  landingScreen.observeFieldScoped("backgroundUriList", "onLandingScreenBackgroundChange")
  landingScreen.observeFieldScoped("registerOrSignInButtonPressed", "onLandingScreenRegisterOrSignInButtonPressed")
  landingScreen.observeFieldScoped("guestButtonPressed", "onLandingScreenGuestButtonPressed")
  pushScreen(landingScreen, true, true)

End Function


Function onLandingScreenRegisterOrSignInButtonPressed()
  startSignIn()
End Function


Function onLandingScreenGuestButtonPressed()
  restartChannel()
End Function
