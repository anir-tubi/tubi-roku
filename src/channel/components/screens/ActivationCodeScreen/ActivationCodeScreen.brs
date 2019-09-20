Function init()
  m.trackingLoggingTask = m.global.trackingLoggingTask
  m.constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.Buttons = m.top.findNode("Buttons")
  m.Buttons.observeField("itemSelected", "onButtonSelected")
  m.RegistrationCode1 = m.top.findNode("RegistrationCode1")
  m.RegistrationCode2 = m.top.findNode("RegistrationCode2")
  m.RegistrationCode3 = m.top.findNode("RegistrationCode3")
  m.RegistrationCode4 = m.top.findNode("RegistrationCode4")
  m.RegistrationCode5 = m.top.findNode("RegistrationCode5")
  m.RegistrationCode6 = m.top.findNode("RegistrationCode6")
  setButtonContent()

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
' setButtonContent
'
Function setButtonContent()
  content = CreateObject("roSGNode", "ContentNode")
  refresh = content.createChild("ContentNode")
  refresh.id = "refresh"
  refresh.title = "Refresh Code"
  m.Buttons.translation= [720, m.Buttons.translation[1]]
  m.Buttons.itemSpacings = [0,0]
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
      regCodeButton.AUDIO_GUIDE_TEXT = "Activation Code: " + m.RegCodeTask.code.split("").join(". ") + ". Refresh Code"
      ' Automatically appended to the text above is "... button. Press OK to select."
      m.Buttons.jumpToItem = m.Buttons.itemFocused
    end if
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

  sSubtypeCode = ""

  sEventName = evt.getData()
  if sEventName = "expire"
    title = "Activation Code Expired"
    message = "We're sorry, but the activation code expired before your device was successfully linked."
    sSubtypeCode = m.constants.errors.subtypes.expireError
  else if sEventName = "poll"
    title = "Connection Error During Activation"
    message = "We're sorry, but we could not connect with the server to see if you registered your device."
    sSubtypeCode = m.constants.errors.subtypes.networkError
  else if sEventName = "code"
    title = "Connection Error During Code Fetch"
    message = "We're sorry, but there was an error while receiving the code from the server."
    sSubtypeCode = m.constants.errors.subtypes.fetchError
  else
    title = "Activation Code Error"
    message = "We're sorry, but an activation code error occurred."
  end if
  
  userErrorCode = getUserFacingErrorCode(m.constants.errors.context.activateScreen, sSubtypeCode)
  
  authPageValues = {
    auth_action:  "ACTIVATION"  'Action enum
  }
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "REGISTRATION"
      pageOneof: m.Tracking.getAnalyticsPage("auth_page", authPageValues)
      dialog_action: "SHOW"
      dialog_sub_type: userErrorCode
    }
  }

  modalInfo = {
    title: title
    message: getErrorMessage(message, userErrorCode)
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }

  showErrorModal(modalInfo, onErrorButtonTryAgainPress, invalid, onErrorButtonCancelPress, invalid, ["Try again", "Skip"])
End Function


'''''''''''''''''''''''''
' onErrorButtonTryAgainPress
'
' Respond the user selecting the try again button on the error modal
Function onErrorButtonTryAgainPress()
  getRegistrationCode()
End Function


'''''''''''''''''''''''''
' onErrorButtonCancelPress
'
' Respond the user selecting the cancel button on the error modal
Function onErrorButtonCancelPress()
  'leave the screen and go to homepage
  m.RegCodeTask.cancel = true
  m.top.skipButtonPressed = true
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


Function onKeyEvent(key As String, press As Boolean)
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
          current: "UNKNOWN"
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