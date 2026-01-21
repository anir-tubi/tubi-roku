Function Init()

  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.unobserveFieldScoped("isEmailValid")
  m.top.observeFieldScoped("accountTypeSelected", "onAccountTypeSelected")

  m.pageHeading = m.top.findNode("PageHeading")
  m.subHeading = m.top.findNode("SubHeading")
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.subHeading, typographyConstants.ids.bodyLargeStrong)
  m.subHeading.color = m.subHeaderColor

  m.keyboard.domain = "name"


  m.privacyDisclaimer.text = ""

  setNameScreenHeading()

  m.top.trackingPageInfo = {
    pageType: "register_page"
    pageValues: {
      auth_method: "EMAIL"
    }
  }

End Function

' onFirstNameChanged callback triggers when user changes the first name input
Function onContinueButtonSelected(evt)

  isButtonSelected = evt.getData()

  if isButtonSelected = true
    ' we must set voiceEnabled = false here because if we rely on isInFocusChain() in
    ' onScreenFocusChange(), voiceEnabled is not set to false until after voiceEnabled is set to true
    ' on the SignInScreen, which prevents voiceEnabled is getting to true
    ' on the SignInScreen.
    m.keyboard.textEditBox.voiceEnabled = false
    firstName = m.emailTextEditBox.text
    m.top.name = firstName
    signInInfo = {}

    if m.top.accountTypeSelected = "kids"
      signInInfo["firstName"] = firstName
      signInInfo["hasPin"] = m.top.hasPin
      signInInfo["parentProfileId"] = m.top.parentProfileId
    else

      signInInfo["email"] = m.top.email
      signInInfo["firstName"] = firstName
      signInInfo["lastName"] = ""

    end if
    m.top.signInInfo = signInInfo
    m.top.continueSelected = true
  end if
End Function


Function onAccountTypeSelected(msg)
  accountType = msg.getData()
  setNameScreenHeading(accountType)
End Function


Function setNameScreenHeading(accountType = "adults")

  if accountType = "kids"
    m.pageHeading.text = getTranslation("name_screen_heading_kids")
    m.subHeading.text = getTranslation("name_screen_subheading_kids")
  else if accountType = "adults"
    m.pageHeading.text = getTranslation("name_screen_heading")
    m.subHeading.text = ""
  end if

End Function