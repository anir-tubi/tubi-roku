Function init()
  m.constants = getConstantsFromGlobal()
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.top.screenLevel = m.constants.ui.screenLevels.landingScreen
  m.top.instantResumeAction = m.constants.instantResumeActions.startChannel

  m.top.trackingPageInfo = {
    pageType: "landing_page"
    pageValues: {
      page_sequence: m.constants.ui.onBoarding.pageSequence.landingScreen
      name: "roku_rfi"
    }
  }

  m.pageHeading = m.top.findNode("pageHeading")
  m.pageDescription = m.top.findNode("pageDescription")

  m.addtoYourListLabel = m.top.findNode("addtoYourListLabel")
  m.addtoYourListLabel.text = getTranslation("onBoarding_landingScreen_addListLabel")

  m.addtoYourListBody = m.top.findNode("addtoYourListBody")
  m.addtoYourListBody.text = getTranslation("onBoarding_landingScreen_addListBody")

  m.saveYourProgressLabel = m.top.findNode("saveYourProgressLabel")
  m.saveYourProgressLabel.text = getTranslation("onBoarding_landingScreen_saveProgressLabel")

  m.saveYourProgressBody = m.top.findNode("saveYourProgressBody")
  m.saveYourProgressBody.text = getTranslation("onBoarding_landingScreen_saveProgressBody")
  
  m.madeForYouLabel = m.top.findNode("madeForYouLabel")
  m.madeForYouLabel.text = getTranslation("onBoarding_landingScreen_madeForYouLabel")
  
  m.madeForYouBody = m.top.findNode("madeForYouBody")
  m.madeForYouBody.text = getTranslation("onBoarding_landingScreen_madeForYouBody")
  
  m.buttons = [
    "onBoarding_registerOrSignIn_button"
    "onBoarding_continueAsGuest_button"
  ]
  m.buttonList = m.top.findNode("buttonList")
  m.buttonList.observeFieldScoped("itemSelected", "onButtonSelected")
  setButtonListContent()
  
  m.pageHeading.text = getTranslation("onBoarding_landingScreen_heading")
  m.pageDescription.text = getTranslation("onBoarding_landingScreen_description")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.pageHeading, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.pageDescription, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.addtoYourListLabel, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.addtoYourListBody, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.saveYourProgressLabel, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.saveYourProgressBody, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.madeForYouLabel, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.madeForYouBody, typographyConstants.ids.bodySmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if
  
  if theme <> invalid
    m.saveYourProgressBody.color = theme.secondaryTextColor
    m.madeForYouLabel.color = theme.primaryTextColor
    m.madeForYouBody.color = theme.secondaryTextColor
    
    m.addtoYourListLabel.color = theme.primaryTextColor
    m.addtoYourListBody.color = theme.secondaryTextColor
    m.saveYourProgressLabel.color = theme.primaryTextColor
    
    m.pageHeading.color = theme.primaryTextColor
    m.pageDescription.color = theme.cautionColor
  end if
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