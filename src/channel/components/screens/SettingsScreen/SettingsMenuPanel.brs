Function init()
  m.SettingsMenu = m.top.findNode("SettingsMenu")
  m.top.list = m.SettingsMenu

  m.SettingsMenu.focusBitmapUri = "pkg:/images/menu-focus-fhd.9.png"
  m.SettingsMenu.focusBitmapBlendColor = m.global.theme.focused
  m.SettingsMenu.focusFootprintBitmapUri = "pkg:/images/menu-disabled-focus-fhd.9.png"
  if m.global.constants.deviceInfo.scaledUi = true
    m.SettingsMenu.focusBitmapUri = "pkg:/images/menu-focus-hd.9.png"
    m.SettingsMenu.focusFootprintBitmapUri = "pkg:/images/menu-disabled-focus-hd.9.png"
  end if
  m.SignInOutButtonContent = m.top.findNode("SignInOutButton")
  m.top.observeField("focusedChild", "onComponentFocus")

  m.top.observeFieldScoped("signInInfo", "onSignInInfoChange")

  setSettingsMenuStrings()
End Function


Function setSettingsMenuStrings()
    ParentalControls =  m.top.findNode("ParentalControls")
    ParentalControls.title = getTranslation("screenSettings_menu_parentalControls")
    AboutButton =  m.top.findNode("AboutButton")
    AboutButton.title = getTranslation("screenSettings_menu_about")
    PrivacyPolicyButton =  m.top.findNode("PrivacyPolicyButton")
    PrivacyPolicyButton.title = getTranslation("screenSettings_menu_privacyPolicy")
    TermsOfServiceButton =  m.top.findNode("TermsOfServiceButton")
    TermsOfServiceButton.title = getTranslation("screenSettings_menu_tos")
End Function


Function onSignInInfoChange()
  signInButton = m.top.findNode("SignInOutButton")
  sText = getTranslation("menu_signIn")
  if m.top.signInInfo <> invalid
    if m.top.signInInfo.signedIn = true
      sText = getTranslation("screenSettings_menu_signOut")
    end if
  end if
  signInButton.title = sText
End Function


Function onComponentFocus()
  if m.top.isInFocusChain() = true
    m.top.opacity = 1.0
    if m.top.hasFocus() = true
      m.SettingsMenu.setFocus(true)
    end if
  else
    m.top.opacity = 0.3
  end if
End Function
