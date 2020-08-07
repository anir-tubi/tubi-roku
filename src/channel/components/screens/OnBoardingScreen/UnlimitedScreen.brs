Function init()
  m.constants = m.global.constants
  m.top.observeField("focusedChild", "onScreenFocusChange")
  
  m.top.screenLevel = m.constants.ui.screenLevels.unlimitedScreen
  m.top.trackingPageInfo = {
    pageType: "onboarding_page"
    pageValues: {
      page_sequence: m.constants.ui.pageSequence.unlimitedScreen
    }
  }  
  
  m.backLabel = m.top.findNode("callToAction")
  m.pageHeading = m.top.findNode("pageHeading")
  m.pageDescription = m.top.findNode("pageDescription")

  m.buttons = ["onBoarding_next_button", "onBoarding_skip_button"]
  m.buttonList = m.top.findNode("buttonList")
  m.buttonList.observeField("itemSelected", "onButtonSelected")
  setButtonListContent()

  '//Set strings
  m.backLabel.text = getTranslation("onBoarding_back_button")
  m.pageHeading.text = getTranslation("onBoarding_unlimitedScreen_heading")
  m.pageDescription.text = getTranslation("onBoarding_unlimitedScreen_description")
  
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
' Set the focus on the button group
Function onScreenFocusChange()
  tubiLog("Unlimited.onScreenFocusChange")
  if m.top.hasFocus() then
    m.buttonList.setFocus(true)
  end if
End Function


'''''''''''''''''''''''''
' onButtonListSelected
'
Function onButtonSelected()
  tubiLog("Unlimited.onButtonSelected")
  button = m.buttonList.content.getChild(m.buttonList.itemSelected)
  if button.id = "onBoarding_next_button"
    m.top.nextButtonPressed = true
  else if button.id = "onBoarding_skip_button"  
    m.top.skipButtonPressed = true
  end if
End Function


Function onKeyEvent(key As String, press As Boolean)
  if press
    return false
  end if
End Function