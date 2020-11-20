Function init()
  m.constants = m.global.constants
  m.top.observeField("focusedChild", "onScreenFocusChange")
  
  m.top.screenLevel = m.constants.ui.screenLevels.landingScreen
  m.top.trackingPageInfo = {
    pageType: "landing_page"
    pageValues: {}
  }  
  
  m.landingBackground = m.top.findNode("landingBackground")
  m.landingBackground.uri = m.constants.urls.landingBackground
  
  m.pageHeading = m.top.findNode("pageHeading")
  m.pageDescription = m.top.findNode("pageDescription")

  m.buttons = ["onBoarding_register_button", "onBoarding_guest_button"]
  m.buttonList = m.top.findNode("buttonList")
  m.buttonList.observeField("itemSelected", "onButtonSelected")
  setButtonListContent()
  
  '//Set strings
  m.pageHeading.text = getTranslation("onBoarding_landingScreen_registration")
  m.pageDescription.text = getTranslation("onBoarding_onBoarding_landingScreen_info")

End Function


''''''''''''''''''''''''
' setButtonListContent
'
Function setButtonListContent()
  newContent = CreateObject("roSGNode", "ContentNode")
  
  for each b in m.buttons
      button = newContent.createChild("ContentNode")      
      button.title = getTranslation(b)
      button.id = b
  end for
  m.buttonList.content = newContent
  
End Function


''''''''''''''''''''''''''
' onScreenFocusChange
'
Function onScreenFocusChange()
  tubiLog("Landing.onScreenFocusChange")
  if m.top.hasFocus() then
    m.buttonList.setFocus(true)
  end if
End Function


'''''''''''''''''''''''''
' onButtonListSelected
'
Function onButtonSelected()
  tubiLog("Landing.onButtonSelected")
  button = m.buttonList.content.getChild(m.buttonList.itemSelected)
  if button.id = "onBoarding_register_button"
    m.top.registerButtonPressed = true
  else if button.id = "onBoarding_guest_button"  
    m.top.guestButtonPressed = true
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  if press
    return false
  end if
End Function