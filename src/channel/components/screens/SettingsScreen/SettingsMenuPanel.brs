Function init()
  m.constants = getConstantsFromGlobal()
  m.nodeHelpers = TubiNodeHelpers()
  m.SettingsMenu = m.top.findNode("SettingsMenu")
  m.SettingsMenuGroup = m.top.findNode("SettingsMenuGroup")
  m.settingsMenuContent = m.top.findNode("SettingsMenuContent")

  m.top.list = m.SettingsMenu

  m.SettingsMenu.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"

  m.SettingsMenu.focusFootprintBitmapUri = "pkg:/images/menu-disabled-focus-$$RES$$.9.png"

  m.top.observeField("focusedChild", "onComponentFocus")

  m.top.observeFieldScoped("signInInfo", "onSignInInfoChange")
  m.top.observeFieldScoped("uiMode", "onUiModeChange")

  m.isUserInMultiAccount = isUserInMultiAccountFromRegistry()

  setSettingsSidePanelMenuItems()

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
    m.SettingsMenu.focusFootprintBlendColor = theme.neutralColor
  end if
End Function


Function setSettingsSidePanelMenuItems()

  autoPlayPreviewText = getTranslation("screenSettings_menu_autoplayControls")
  ' Adding a display order field since roku does not maintain order in an associative array.
  index = 1
  availablePanelItems = {}

  if m.isUserInMultiAccount = true
    availablePanelItems.append({
      "signInOut": {
        subType: "DetailMenuItemContentNode"
        id: "SignInOutButton"
        title: getTranslation("menu_signIn")
        iconUrl: "pkg:/images/icon-account.webp"
        displayOrder: index
    } })
    index = index + 1

    availablePanelItems.append({
      "parentalControls": {
        subType: "DetailMenuItemContentNode"
        id: "ParentalControlsButton"
        title: getTranslation("screenSettings_menu_contentSettings")
        iconUrl: "pkg:/images/icon-parental.webp"
        displayOrder: index
    } })

  else
    availablePanelItems.append({
      "parentalControls": {
        subType: "DetailMenuItemContentNode"
        id: "ParentalControlsButton"
        title: getTranslation("screenSettings_menu_parentalControls")
        iconUrl: "pkg:/images/icon-parental.webp"
        displayOrder: index
    } })
  end if

  index = index + 1

  availablePanelItems.append({

    "autoplayPreview": {
      subType: "DetailMenuItemContentNode"
      id: "AutoplayPreviewButton"
      title: autoPlayPreviewText
      iconUrl: "pkg:/images/icon-trailer.webp"
      displayOrder: index
  } })

  index = index + 1
  availablePanelItems.append({
    "about": {
      subType: "DetailMenuItemContentNode"
      id: "AboutButton"
      title: getTranslation("screenSettings_menu_about")
      iconUrl: "pkg:/images/icon-about.webp"
      displayOrder: index
  } })

  index = index + 1
  availablePanelItems.append({
    "privacyCenter": {
      subType: "DetailMenuItemContentNode"
      id: "PrivacyCenterButton"
      title: getTranslation("screenSettings_menu_PrivacyCenter")
      iconUrl: "pkg:/images/icon-privacy.webp"
      displayOrder: index
  } })

  if m.isUserInMultiAccount = false
    index = index + 1
    availablePanelItems.append({
      "signInOut": {
        subType: "DetailMenuItemContentNode"
        id: "SignInOutButton"
        title: getTranslation("menu_signIn")
        iconUrl: "pkg:/images/icon-account.webp"
        displayOrder: index
    } })
  end if

  index = index + 1
  availablePanelItems.append({
    "exit": {
      subType: "DetailMenuItemContentNode"
      id: "ExitButton"
      title: getTranslation("menu_exit")
      iconUrl: "pkg:/images/sideNavExit.webp"
      displayOrder: index
  } })
  index = index + 1
  availablePanelItems.append({
    "testAid": {
      subType: "DetailMenuItemContentNode"
      id: "TestingAidButton"
      title: "TestAid"
      displayOrder: index
    }
  })

  ' removing the parental controls if the config returns false.
  if getExternalConfigValueFromGlobal("enable_parental_control", false) = false then
    availablePanelItems.delete("parentalControls")
  end if

  ' Removing video preview button if device does not support the feature.
  if m.constants.deviceInfo.limitedUi = true then
    availablePanelItems.delete("autoplayPreview")
  end if

  if m.top.uiMode = m.constants.ui.modes.kidsAgeGate
    availablePanelItems.delete("signInOut")
  end if

  ' Deleting the test aid if non qa or dev mode.
  if m.constants.settings.mode = "production" 'this is for extra protection not to restart the app
    availablePanelItems.delete("testAid")
  end if

  menuItems = []

  for each id in availablePanelItems
    menuItems.push(availablePanelItems[id])
  end for

  menuItems.sortBy("displayOrder")
  m.settingsMenuContent.update(menuItems, true)
End Function


Function onSignInInfoChange()
  sText = getTranslation("menu_signIn")
  if m.isUserInMultiAccount = true
    sText = getTranslation("screenSettings_menu_Account")
  else
    signInInfo = m.top.signInInfo
    if signInInfo <> invalid AND signInInfo.signedIn = true
      sText = getTranslation("screenSettings_menu_signOut")
    end if
  end if


  signInButton = m.nodeHelpers.getChildById(m.settingsMenuContent, "SignInOutButton")
  if signInButton <> invalid
    signInButton.title = sText
  end if
End Function


' @id: string, id of the button that needs to be removed.
Function removeButton(id)
  button = m.nodeHelpers.getChildById(m.settingsMenuContent, id)
  if button <> invalid
    m.settingsMenuContent.removeChild(button)
  end if
End Function


Function onComponentFocus()
  if m.top.isInFocusChain() = true
    m.top.opacity = 1.0
    if m.top.hasFocus() = true
      m.SettingsMenu.setFocus(true)
    end if
  else
    m.top.opacity = 0.7
  end if
End Function


Function onUiModeChange(msg)
  uiMode = msg.getData()
  if uiMode = m.constants.ui.modes.kidsAgeGate
    removeButton("SignInOutButton")
    removeButton("ParentalControlsButton")
    resetSettingsMenuVerticalPosition()
  end if
End Function


Function resetSettingsMenuVerticalPosition()
  ' the default translation is [0, 0] and the default positioning on the page is due to the
  ' translation in SettingsScreen.PanelSet.translation, which assumes 6 items in the settings menu.
  ' We need to adjust the vertical translation if there are more than 6 items in the settings menu.
  numButtons = m.SettingsMenu.content.getChildCount()
  if numButtons > 6
    yTrans = (6 - numButtons) * (m.SettingsMenu.itemSize[1] + m.SettingsMenu.itemSpacing[1])
    m.SettingsMenuGroup.translation = [0, yTrans]
  end if
End Function
