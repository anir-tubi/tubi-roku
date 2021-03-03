Function init()
  m.trackingLoggingTask = m.global.trackingLoggingTask
  m.constants = m.global.constants
  Request = TubiRequest(m.constants.settings.mode)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("getActivationCode", "onGetActivationCode")
  m.pageHeading = m.top.findNode("pageHeading")
  m.pageSubheading = m.top.findNode("pageSubheading")

  m.Buttons = m.top.findNode("Buttons")
  m.Buttons.observeField("itemSelected", "onButtonSelected")
  m.RegistrationCode1 = m.top.findNode("RegistrationCode1")
  m.RegistrationCode2 = m.top.findNode("RegistrationCode2")
  m.RegistrationCode3 = m.top.findNode("RegistrationCode3")
  m.RegistrationCode4 = m.top.findNode("RegistrationCode4")
  m.RegistrationCode5 = m.top.findNode("RegistrationCode5")
  m.RegistrationCode6 = m.top.findNode("RegistrationCode6")
  setButtonContent()

  '//Set strings
  m.pageHeading.text = getTranslation("screenActivationCode_heading")
  m.pageSubheading.text = getTranslation("screenActivationCode_subheading")
  m.refreshBtnContent.title = getTranslation("screenActivationCode_button_refresh")

  if m.global.constants.deviceInfo.scaledUi = true then
    m.top.findNode("RegistrationPoster1").uri = "pkg:/images/hd/menu-button.9.png"
    m.top.findNode("RegistrationPoster2").uri = "pkg:/images/hd/menu-button.9.png"
    m.top.findNode("RegistrationPoster3").uri = "pkg:/images/hd/menu-button.9.png"
    m.top.findNode("RegistrationPoster4").uri = "pkg:/images/hd/menu-button.9.png"
    m.top.findNode("RegistrationPoster5").uri = "pkg:/images/hd/menu-button.9.png"
    m.top.findNode("RegistrationPoster6").uri = "pkg:/images/hd/menu-button.9.png"
  end if

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "auth_page"
    pageValues: {
      auth_action: "ACTIVATION"
    }
  }
  
  m.top.screenLevel = m.constants.ui.screenLevels.activationCodeScreen
  ' in the current design, navigating away from the activation page destroys the page
  ' so it is ok to only get the registration code when the page is created.
  getRegistrationCode()
End Function


''''''''''''''''''''''''
' onGetActivationCode
'
Function onGetActivationCode()
  if m.top.getActivationCode = true
    getRegistrationCode()
  else if m.RegCodeTask <> invalid
    m.RegCodeTask.cancel = true
  end if
End Function


''''''''''''''''''''''''
' setButtonContent
'
Function setButtonContent()
  content = CreateObject("roSGNode", "ContentNode")
  m.refreshBtnContent = content.createChild("ContentNode")
  m.refreshBtnContent.id = "refresh"
  m.Buttons.translation = [720, m.Buttons.translation[1]]
  m.Buttons.itemSpacing = [0,0]
  m.Buttons.content = content
End Function

''''''''''''''''''''''''''
' onScreenFocusChange
'
' Set the focus on the button group
Function onScreenFocusChange()
  tubiLog("ActivationCodeScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.Buttons.setFocus(true)
  end if
End Function


'''''''''''''''''''''''''
' onButtonSelected
'
' Handle Refresh button selected
Function onButtonSelected()
  tubiLog("ActivationCodeScreen.onButtonSelected")
  button = m.Buttons.content.getChild(m.Buttons.itemSelected)
  if button.id = "refresh" then
    getRegistrationCode()
  end if
End Function


'''''''''''''''''''''
' onCodeChange
'
' Display the new registration code
Function onCodeChange()
  m.RegistrationCode1.text = m.RegCodeTask.code.Mid(0,1)
  m.RegistrationCode2.text = m.RegCodeTask.code.Mid(1,1)
  m.RegistrationCode3.text = m.RegCodeTask.code.Mid(2,1)
  m.RegistrationCode4.text = m.RegCodeTask.code.Mid(3,1)
  m.RegistrationCode5.text = m.RegCodeTask.code.Mid(4,1)
  m.RegistrationCode6.text = m.RegCodeTask.code.Mid(5,1)

  ' Set the audio guide fields
  if m.Buttons.content <> invalid
    regCodeButton = m.Buttons.content.getChild(0)
    if regCodeButton <> invalid
      regCodeButton.AUDIO_GUIDE_TEXT = getTranslation("screenActivationCode_audioGuide", {code: m.RegCodeTask.code.split("").join(". ")})
      
      ' Automatically appended to the text above is "... button. Press OK to select."
      m.Buttons.jumpToItem = m.Buttons.itemFocused
    end if
  end if
  
  suitest = m.constants.settings.suitest
  automaticActivation = m.constants.settings.automaticActivation
  stagingApis = m.constants.settings.stagingApis
  
  if suitest = true and automaticActivation = true and stagingApis = true
    activateAutomatically()
  end if  
  
End Function


'''''''''''''''''''''''''
' onRegistrationResponse
'
' Registration polling received a response, watch for it to be successful
Function onRegistrationResponse()
  if m.RegCodeTask.response <> invalid and m.RegCodeTask.response.status = "registered" then
    m.top.activationSuccess = true
  end if
End Function


'''''''''''''''''''''''''
' onRegTaskError
'
' An error was recorded by the registrationCodeTask so let the user know
Function onRegTaskError(evt)
  m.top.errorType = evt.getData()
End Function


'''''''''''''''''''''''
' getRegistrationCode
'
Function getRegistrationCode()
  tubiLog("ActivationCodeScreen.getRegistrationCode")
  m.RegistrationCode1.text = "-"
  m.RegistrationCode2.text = "-"
  m.RegistrationCode3.text = "-"
  m.RegistrationCode4.text = "-"
  m.RegistrationCode5.text = "-"
  m.RegistrationCode6.text = "-"
  if m.RegCodeTask <> invalid then
    m.RegCodeTask.unobserveField("code")
    m.RegCodeTask.unobserveField("response")
    m.RegCodeTask.unobserveField("error")
    m.RegCodeTask.cancel = true  ' tell the thread to exit
  end if
  m.RegCodeTask = CreateObject("roSGNode", "RegistrationCodeTask")
  m.RegCodeTask.observeField("code", "onCodeChange")
  m.RegCodeTask.observeField("response", "onRegistrationResponse")
  m.RegCodeTask.observeField("error", "onRegTaskError")
  m.RegCodeTask.control = "RUN"
  
End Function


' This function is used only in suitest to activate automatically
Function activateAutomatically()

  if m.signUpTask <> invalid then
    m.signUpTask.unobserveField("error")
  end if

  m.signUpTask = CreateObject("roSGNode", "SignUpTask")
  ' delay field helps to show activation screen for 10 seconds during automatic activation
  m.signUpTask.delay = 10000
  m.signUpTask.requestParams = constructCodeRegisterReqParams()
  m.signUpTask.observeField("error", "onSignUpError")
  m.signUpTask.control = "RUN" 

End Function


' constructCodeRegisterReqParams is used to construct request params for code register
Function constructCodeRegisterReqParams()

  dateTime = CreateObject("roDateTime")
  secondsFromEpoch = dateTime.AsSeconds()

  requestParams = {}
  requestParams.email = "build_roku_" + secondsFromEpoch.ToStr() + "@tubi.tv"
  requestParams.password = "111111"
  requestParams.gender = "Male"
  requestParams.first_name = "Automation"
  requestParams.last_name = "Suitest"
  requestParams.birthday = "2000-01-01"
  
  requestParams.activationCode = m.RegCodeTask.code
  
  return requestParams

End Function


Function onSignUpError(evt)
  m.top.errorType = evt.getData()
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  if press
    if key = "back"
      if m.RegCodeTask <> invalid
        'leaving page so stop polling
        m.RegCodeTask.cancel = true
      end if

      m.trackingLoggingTask.trackEvent = {
        type: "account"
        values: {
          manip: "REGISTER_DEVICE"
          current: ""
          user_type: "UNKNOWN_USER_TYPE"
          status: "FAIL"
          message: "user-cancel"
          linked: ""
        }
      }
      return false
    end if
  end if
End Function