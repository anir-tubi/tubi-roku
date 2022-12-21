Function init()
  m.constants = getConstantsFromGlobal()
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.top.screenLevel = m.constants.ui.screenLevels.landingScreen
  m.top.instantResumeAction = m.constants.instantResumeActions.startChannel

  m.top.trackingPageInfo = {
    pageType: "landing_page"
    pageValues: {
      page_sequence: m.constants.ui.onBoarding.pageSequence.landingScreen
    }
  }

  m.pageHeading = m.top.findNode("pageHeading")
  m.pageDescription = m.top.findNode("pageDescription")

  addtoYourListLabel = m.top.findNode("addtoYourListLabel")
  addtoYourListLabel.text = getTranslation("onBoarding_landingScreen_addListLabel")
  addtoYourListLabel.color = m.constants.ui.colors.primaryText

  addtoYourListBody = m.top.findNode("addtoYourListBody")
  addtoYourListBody.text = getTranslation("onBoarding_landingScreen_addListBody")
  addtoYourListBody.color = m.constants.ui.colors.secondaryText

  saveYourProgressLabel = m.top.findNode("saveYourProgressLabel")
  saveYourProgressLabel.text = getTranslation("onBoarding_landingScreen_saveProgressLabel")
  saveYourProgressLabel.color = m.constants.ui.colors.primaryText

  saveYourProgressBody = m.top.findNode("saveYourProgressBody")
  saveYourProgressBody.text = getTranslation("onBoarding_landingScreen_saveProgressBody")
  saveYourProgressBody.color = m.constants.ui.colors.secondaryText
  
  madeForYouLabel = m.top.findNode("madeForYouLabel")
  madeForYouLabel.text = getTranslation("onBoarding_landingScreen_madeForYouLabel")
  madeForYouLabel.color = m.constants.ui.colors.primaryText
  
  madeForYouBody = m.top.findNode("madeForYouBody")
  madeForYouBody.text = getTranslation("onBoarding_landingScreen_madeForYouBody")
  madeForYouBody.color = m.constants.ui.colors.secondaryText
  
  m.buttons = [
    "onBoarding_registerOrSignIn_button"
    "onBoarding_continueAsGuest_button"
  ]
  m.buttonList = m.top.findNode("buttonList")
  m.buttonList.observeFieldScoped("itemSelected", "onButtonSelected")
  setButtonListContent()
  
  m.pageHeading.text = getTranslation("onBoarding_landingScreen_heading")
  m.pageHeading.color = m.constants.ui.colors.primaryText
  m.pageDescription.text = getTranslation("onBoarding_landingScreen_description")
  m.pageDescription.color = m.constants.ui.colors.caution

End Function


Function setButtonListContent()
  newContent = CreateObject("roSGNode", "ContentNode")

  for each b in m.buttons
    button = newContent.createChild("ContentNode")
    button.id = b
    if b = "onBoarding_registerOrSignIn_button"
      button.title = getTranslation("registerOrSignIn_button")
    else if b = "onBoarding_continueAsGuest_button"
      button.title = getTranslation("continueAsGuest_button")
    end if
  end for
  m.buttonList.content = newContent

End Function


Function onScreenFocusChange()
  tubiLog("LandingScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.top.backgroundUriList = m.constants.urls.landingBackgroundUriList
    m.buttonList.setFocus(true)
  end if
End Function


Function onButtonSelected()
  tubiLog("LandingScreen.onButtonSelected")
  button = m.buttonList.content.getChild(m.buttonList.itemSelected)
  if button.id = "onBoarding_registerOrSignIn_button"
    m.top.registerOrSignInButtonPressed = true
  else if button.id = "onBoarding_continueAsGuest_button"
    m.top.guestButtonPressed = true
  end if
End Function
