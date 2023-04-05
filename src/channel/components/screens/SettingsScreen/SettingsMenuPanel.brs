Function init()
  m.constants = m.global.constants
  m.SettingsMenu = m.top.findNode("SettingsMenu")
  m.SettingsMenuGroup = m.top.findNode("SettingsMenuGroup")
  m.top.list = m.SettingsMenu

  m.SettingsMenu.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"

  m.SettingsMenu.focusFootprintBitmapUri = "pkg:/images/menu-disabled-focus-$$RES$$.9.png"

  m.SignInOutButtonContent = m.top.findNode("SignInOutButton")
  m.top.observeField("focusedChild", "onComponentFocus")

  m.top.observeFieldScoped("signInInfo", "onSignInInfoChange")
  m.top.observeFieldScoped("uiMode", "onUiModeChange")

  setSettingsMenuStringsAndIcons()

  if UCase(m.constants.deviceInfo.countryCode) <> "US"
    removeYourPrivacyChoicesButton()
  end if

  resetSettingsMenuVerticalPosition()

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
    m.SettingsMenu.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function setSettingsMenuStringsAndIcons()
    ParentalControlsButton =  m.top.findNode("ParentalControlsButton")
    ParentalControlsButton.title = getTranslation("screenSettings_menu_parentalControls")
    AboutButton =  m.top.findNode("AboutButton")
    AboutButton.title = getTranslation("screenSettings_menu_about")
    PrivacyPolicyButton =  m.top.findNode("PrivacyPolicyButton")
    PrivacyPolicyButton.title = getTranslation("screenSettings_menu_privacyPolicy")
    TermsOfServiceButton =  m.top.findNode("TermsOfServiceButton")
    TermsOfServiceButton.title = getTranslation("screenSettings_menu_tos")
    YourPrivacyChoicesButton = m.top.findNode("YourPrivacyChoicesButton")
    YourPrivacyChoicesButton.title = getTranslation("screenSettings_menu_yourPrivacyChoices")

    if isVideoPreviewEnabled() = true then
      AutoplayPreviewButton = CreateObject("roSGNode", "DetailMenuItemContentNode")
      AutoplayPreviewButton.title = getTranslation("screenSettings_menu_autoplayPreview")
      AutoplayPreviewButton.id="AutoplayPreviewButton"
      AutoplayPreviewButton.iconUrl="pkg:/images/icon-trailer.webp"
      settingContentNode = m.top.findNode("SettingsMenuContent")
      settingContentNode.insertChild(AutoplayPreviewButton, 1)
    end if

    if m.constants.settings.mode = "qa" OR  m.constants.settings.mode = "dev" 'this is for extra protection not to restart the app
      testingAidButton = createObject("roSGNode","DetailMenuItemContentNode" )
      testingAidButton.title = "TestAid"
      testingAidButton.id = "TestingAidButton"
      m.SettingsMenu.content.appendChild(testingAidButton)
    end if

End Function


Function onSignInInfoChange()
  signInOutButton = m.top.findNode("SignInOutButton")
  sText = getTranslation("menu_signIn")
  if m.top.signInInfo <> invalid
    if m.top.signInInfo.signedIn = true
      sText = getTranslation("screenSettings_menu_signOut")
    end if
  end if
  signInOutButton.title = sText
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


Function onUiModeChange(msg)
  uiMode = msg.getData()
  if uiMode = m.constants.ui.modes.kidsAgeGate
    removeParentalButton()
    removeSignInButton()
    resetSettingsMenuVerticalPosition()
  end if
End Function


Function removeParentalButton()
  parentalControlsButton = m.top.findNode("ParentalControlsButton")
  removeButton(parentalControlsButton)
End Function


Function removeSignInButton()
  signInOutButton = m.top.findNode("SignInOutButton")
  removeButton(signInOutButton)
End Function


Function removeYourPrivacyChoicesButton()
  yourPrivacyChoicesButton = m.top.findNode("YourPrivacyChoicesButton")
  removeButton(yourPrivacyChoicesButton)
End Function


' @button: roSGNode, a DetailMenuItemContentNode used to create the buttons in the settings menu
Function removeButton(button)
  m.SettingsMenu.content.removeChild(button)
End Function


Function resetSettingsMenuVerticalPosition()
  ' the default translation is [0, 0] and the default positioning on the page is due to the
  ' translation in SettingsScreen.PanelSet.translation, which assumes 6 items in the settings menu.
  ' We need to adjust the vertical translation if there are more or less than 6 items in the settings menu.
  numButtons = m.SettingsMenu.content.getChildCount()
  yTrans = (6 - numButtons) * (m.SettingsMenu.itemSize[1] + m.SettingsMenu.itemSpacing[1])
  m.SettingsMenuGroup.translation = [0, yTrans]

End Function
