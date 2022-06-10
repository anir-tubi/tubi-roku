Function init()
  m.constants = getConstantsFromGlobal()
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("buttons", "onButtonList")
  m.top.instantResumeAction = m.constants.instantResumeActions.startChannel

  m.onBoardingBackground = m.top.findNode("onBoardingBackground")
  m.onBoardingBackground.uri = m.constants.urls.onBoardingBackground

  m.buttonList = m.top.findNode("buttonList")
  m.buttonList.observeFieldScoped("itemSelected", "onButtonSelected")

End Function


Function onButtonList()

  buttonList = m.top.buttons
  newContent = CreateObject("roSGNode", "ContentNode")
  for each b in buttonList
    button = newContent.createChild("ContentNode")
    button.id = b
    if b = "onBoarding_next_button"
      button.title = getTranslation("next_button")
    else if b = "onBoarding_skip_button"
      button.title = getTranslation("skip_button")
    else b = "onBoarding_getStarted_button"
      button.title = getTranslation("getStarted_button")
    end if
  end for
  m.buttonList.content = newContent

End Function


Function onScreenFocusChange()
  tubiLog("OnBoardingScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.buttonList.setFocus(true)
  end if
End Function


Function onButtonSelected()
  tubiLog("OnBoardingScreen.onButtonSelected")
  button = m.buttonList.content.getChild(m.buttonList.itemSelected)
  if button.id = "onBoarding_next_button"
    m.top.nextButtonPressed = true
  else if button.id = "onBoarding_skip_button"
    m.top.skipButtonPressed = true
  else if button.id = "onBoarding_getStarted_button"
    m.top.getStartedButtonPressed = true
  end if
End Function
