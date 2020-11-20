Function init()
  m.constants = m.global.constants
  m.top.observeField("focusedChild", "onScreenFocusChange")
  
  m.top.screenLevel = m.constants.ui.screenLevels.availableDeviceScreen
  m.top.trackingPageInfo = {
    pageType: "onboarding_page"
    pageValues: {
      page_sequence: m.constants.ui.pageSequence.availableDeviceScreen
    }
  }  
  
  m.backLabel = m.top.findNode("callToAction")
  m.pageHeading = m.top.findNode("pageHeading")
  m.pageDescription = m.top.findNode("pageDescription")

  m.buttonList = m.top.findNode("buttonList")
  m.buttonList.observeField("itemSelected", "onButtonSelected")
  setButtonListContent()

  '//Set strings
  m.backLabel.text = getTranslation("onBoarding_back_button")
  m.pageHeading.text = getTranslation("onBoarding_devices_heading")
  m.pageDescription.text = getTranslation("onBoarding_devices_description")
  
End Function


''''''''''''''''''''''''
' setButtonListContent
'
Function setButtonListContent()
  newContent = CreateObject("roSGNode", "ContentNode")
  
  button = newContent.createChild("ContentNode")      
  button.title = getTranslation("onBoarding_startWatching_button")
  button.id = "onBoarding_startWatching_button"
  
  m.buttonList.content = newContent
  
End Function


''''''''''''''''''''''''''
' onScreenFocusChange
'
' Set the focus on the button group
Function onScreenFocusChange()
  tubiLog("AvailableDevice.onScreenFocusChange")
  if m.top.hasFocus() then
    m.buttonList.setFocus(true)
  end if
End Function


'''''''''''''''''''''''''
' onButtonListSelected
'
Function onButtonSelected()
  tubiLog("AvailableDevice.onButtonSelected")
  button = m.buttonList.content.getChild(m.buttonList.itemSelected)
  if button.id = "onBoarding_startWatching_button"
    m.top.startWatchingButtonPressed = true
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  if press
    return false
  end if
End Function