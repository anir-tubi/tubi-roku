Function init()
  m.SettingsMenu = m.top.findNode("SettingsMenu")
  m.SettingsMenuGroup = m.top.findNode("SettingsMenuGroup")
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
    if UCase(m.global.constants.deviceInfo.countryCode) = "US"
      '//We only show the DO Not Sell Policy in the US. It is only applicable to CA residents but we show it to all of US in case CA residents are traveling within the US.
      DoNotSellPolicyButton = CreateObject("roSGNode", "DetailMenuItemContentNode")
      DoNotSellPolicyButton.title = getTranslation("screenSettings_menu_doNotSellPolicy")
      DoNotSellPolicyButton.id = "DoNotSellPolicyButton"
      DoNotSellPolicyButton.iconUrl ="pkg:/images/icon-dns.png" 

      '//Offet the vertical placement of the list when adding a new list item
      nYOffset = -1 * (m.SettingsMenu.itemSize[1] + m.SettingsMenu.itemSpacing[1]) 
      m.SettingsMenuGroup.translation = [0, nYOffset]
      
      SettingsMenuContent =  m.top.findNode("SettingsMenuContent")
      '//::HARDCODE:: hardcode the location of the new many item at the 4th index spot
      SettingsMenuContent.insertChild(DoNotSellPolicyButton, 4)
      
    end if
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
