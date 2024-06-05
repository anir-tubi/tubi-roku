Function init()
  m.constants = getConstantsFromGlobal()

  m.leftPanelWidth = 437
  m.rightPanelWidth = 1146
  '//The offset sets the right panel to be placed at a different position than the settings menu list
  m.rightPanelOffset = [36,-147]

  m.PageGroup = m.top.findNode("PageGroup")
  m.PageGroup.translation = [69, 0]
  m.PanelSet = m.top.findNode("PanelSet")
  m.Title = m.top.findNode("Title")
  m.Title.text = getTranslation("menu_settings")

  ' Create the menu
  m.SettingsMenuPanel = createSettingsMenuPanel()
  m.SettingsMenuPanel.observeField("createNextPanelIndex", "onCreateNextPanelIndex")
  m.SettingsMenuPanel.observeField("itemSelected", "onMenuItemSelected")
  m.SettingsMenuPanel.observeField("itemFocused", "onDetailScreenMenuItemFocused")

  ' This must happen after the pane is all set up so that the createNextPanelIndex
  ' event fires for the default menu selection
  m.PanelSet.appendChild(m.SettingsMenuPanel)
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("parentalSettingUpdated", "onSignInInfoChange")
  m.top.observeFieldScoped("itemRequested", "onItemRequested")

  m.top.observeFieldScoped("signInInfo", "onSignInInfoChange")
  m.top.observeFieldScoped("uiMode", "onUiModeChange")

  m.top.observeField("autoPreviewItemUpdated", "onSignInInfoChange")

  if m.constants.settings.mode <> "production"
    m.top.addField("appRestartRequested", "boolean", true)
  end if

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "account_page"
    pageValues: {
      account_page_type: "PARENTAL"
    }
  }

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.Title, typographyConstants.ids.headerSmall)

  m.top.backgroundUriList = []
  m.top.screenLevel = m.constants.ui.screenLevels.settingsScreen
  m.top.instantResumeAction = m.constants.instantResumeActions.startChannel

  request = TubiRequest(m.constants.settings)
  auth = TubiAuth(m.constants, request)
  m.Tracking = TubiTracking(m.constants, request, auth)

  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.Title.color = theme.primaryTextColor
  end if
End Function


Function onSignInInfoChange()
  m.SettingsMenuPanel.signInInfo = m.top.signInInfo
  ' renew the parental controls/autoplay preview panel if it is showing
  for i = 0 to m.PanelSet.getChildCount() - 1
    child = m.PanelSet.getChild(i)
    if child.subtype() = "ParentalControlsPanel"
      createParentalControlsPanel(child)
    else if child.subtype() = "AutoplayPreviewPanel"
      createOrUpdateAutoPlayPreviewPanel(child)
    end if
  end for
End Function


Function onUiModeChange(msg)
  tubiLog("SettingsScreen.onUiModeChange")
  uiMode = msg.getData()
  if m.SettingsMenuPanel <> invalid
    m.SettingsMenuPanel.uiMode = uiMode
  end if

  ' Changing the UI mode may have caused the top menu item to be removed, but still leaves the right
  ' panel associated with the menu item that is no longer there.
  ' Resetting the focus triggers another instance of onCreateNextPanelIndex() to be called which will
  ' reset the right panel in case the focused menu item is different after changing the uiMode.
  m.SettingsMenuPanel.setFocus(false)
  m.SettingsMenuPanel.setFocus(true)
End Function


' NOTE: The focus chain of PanelSet is very difficult to use to determine
'       which particular panel is focused, otherwise we could just set focus
'       in onComponentFocusChange.  Instead, this method, along with
'       onComponentFocusChange, are the only way I have been able to
'       achieve the desired opacity as focus moves left/right across panels
'       and in/out of the screen, such as when a sign in dialog shows.
Function onDetailScreenMenuItemFocused()
  tubiLog("SettingsScreen.onDetailScreenMenuItemFocused")
  m.Title.opacity = 1.0
  m.top.backgroundUriList = []
End Function


Function onComponentFocusChange()
  tubiLog("SettingsScreen.onComponentFocusChange")
  if m.top.isInFocusChain()
    if m.top.hasFocus() = true
      m.SettingsMenuPanel.setFocus(true)
    else
      m.Title.opacity = 0.7
    end if
  end if
End Function


Function onCreateNextPanelIndex()
  tubiLog("SettingsScreen.onCreateNextPanelIndex")
  nextIndex = m.SettingsMenuPanel.createNextPanelIndex
  nextPanel = invalid
  buttonContent = m.SettingsMenuPanel.content.getChild(nextIndex)
  nextPanel = createNextPanel(buttonContent)

  if nextPanel <> invalid
    m.SettingsMenuPanel.nextPanel = nextPanel
  end if
End Function


' @buttonContent: roSGnode, ContentNode used to create the items in the Settings menu. Should be one
'                 of the DetailMenuItemContentNodes in SettingsMenuPanel.SettingsMenu
Function createNextPanel(buttonContent)
  nextPanel = invalid

  if buttonContent <> invalid
    if buttonContent.id = "ParentalControlsButton"
      nextPanel = createParentalControlsPanel()
    else if buttonContent.id = "AutoplayPreviewButton"
      nextPanel = createOrUpdateAutoPlayPreviewPanel()
    else if buttonContent.id = "AboutButton"
      nextPanel = createAboutPanel()
    else if buttonContent.id = "PrivacyCenterButton"
      nextPanel = createPrivacyCenterPanel(buttonContent.title)
    else if buttonContent.id = "TestingAidButton"
      nextPanel = createTestingAidPanel()
    else if buttonContent.id = "YourPrivacyChoicesButton"
      nextPanel = createLegalPanel(buttonContent.title, m.constants.urls.yourPrivacyChoicesUrl)
    else if buttonContent.id = "SignInOutButton"
      if isSignedIn() = true
        nextPanel = createSignOutPanel()
      else
        nextPanel = createSignInPanel()
      end if
    end if
  end if

  return nextPanel
End Function


Function isSignedIn()
  bSignedIn = false
  if m.top.signInInfo <> invalid
    bSignedIn = (m.top.signInInfo.signedIn = true)
  end if
  return bSignedIn
End Function


Function createParentalControlsPanel(existingPanel = invalid)
  if existingPanel = invalid
    pcPanel = CreateObject("roSGNode", "ParentalControlsPanel")
    pcPanel.observeFieldScoped("audioGuideText", "onAudioGuideTextChanged")
    pcPanel.observeFieldScoped("itemSelected", "onParentalControlsItemSelected")
  else
    pcPanel = existingPanel
  end if

  pcPanel.width = m.rightPanelWidth
  pcPanel.focusable = true
  pcPanel.hasNextPanel = false
  pcPanel.leftOnly = false
  pcPanel.selectButtonMovesPanelForward = false
  pcPanel.offset = m.rightPanelOffset

  if isSignedIn() = true
    pcPanel.isLoading = true
    m.top.unobserveFieldScoped("userSettings")
    m.top.observeFieldScoped("userSettings", "onUserSettingsReceived")
    m.top.fetchUserSettings = true
  else
    pcPanel.selectItem = 3 ' default if not signed in
  end if
  return pcPanel
End Function


' @existingPanel: roSGnode, videoPreview panel if already been created.
' UI for panel consisting of autoplayPreview choices.
Function createOrUpdateAutoPlayPreviewPanel(existingPanel = invalid)
  if existingPanel = invalid
    videoPreviewPanel = createAutoPreviewPanel()
  else 'update the existing autoplayPreview Panel
    videoPreviewPanel = existingPanel
    if isSignedIn() = true
      videoPreviewPanel.selectItem = m.top.autoPreviewItemUpdated
    else
      videoPreviewPanel.selectItem = 0 ' default if not signed in
    end if
  end if

  return videoPreviewPanel
End Function


Function createAutoPreviewPanel()
  videoPreviewPanel = CreateObject("roSGNode", "AutoplayPreviewPanel")
  videoPreviewPanel.observeFieldScoped("itemSelected", "onAutoplayPreviewPanelItemSelected")
  videoPreviewPanel.observeFieldScoped("audioGuideText", "onAudioGuideTextChanged")
  videoPreviewPanel.observeFieldScoped("componentInteractionInfo", "onAutoPlayPreviewComponentInteractionInfo")
  videoPreviewPanel.width = m.rightPanelWidth
  videoPreviewPanel.focusable = true
  videoPreviewPanel.hasNextPanel = false
  videoPreviewPanel.leftOnly = false
  videoPreviewPanel.selectButtonMovesPanelForward = false
  videoPreviewPanel.offset = m.rightPanelOffset

  if m.top.isVideoPreviewOn = true
    videoPreviewPanel.selectItem = 0
  else
    videoPreviewPanel.selectItem = 1
  end if
  return videoPreviewPanel
End Function


Function onAutoPlayPreviewComponentInteractionInfo(msg)
  videoPreviewPanel = msg.getRoSGNode()
  m.top.componentInteractionInfo = videoPreviewPanel.componentInteractionInfo
End Function


Function onUserSettingsReceived(msg)
  parentalControlsPanel = getPanelBySubtype("ParentalControlsPanel")
  if parentalControlsPanel <> invalid then
    userSettings = msg.GetData()
    parentalControlsPanel.selectItem = userSettings.parentalRating
    parentalControlsPanel.isLoading = false
  end if
End Function


Function createAboutPanel()
  aboutPanel = CreateObject("roSGNode", "AboutPanel")
  aboutPanel.titleOne = getTranslation("screenSettings_about_title")
  aboutPanel.textOne = getTranslation("screenSettings_about_description")
  aboutPanel.titleTwo = getTranslation("screenSettings_about_title2")

  sVersion = m.constants.deviceInfo.clientVersion
  if m.constants.settings.mode <> "production"
    '//show the revision number and country code when not in production
    sVersion = sVersion + "." + m.constants.deviceInfo.revisionVersion
    sVersion += " : " + m.constants.deviceInfo.countryCode

    if m.constants.settings.stagingApis = true
      sVersion += " : Staging"
    else
      sVersion += " : Production"
    end if
  end if

  sShortDeviceID = Right(m.constants.deviceInfo.deviceId, 7)
  sYear = CreateObject("roDateTime").GetYear().toStr()
  dynamicText = {
    version: sVersion,
    id: sShortDeviceID,
    help_url: "http://help.tubitv.com",
    support_url: "https://tubitv.com/support",
    year: sYear
  }
  
  sSectionTwoText = getTranslation("screenSettings_about_description2", dynamicText)

  '//Go thru the sSectionTwoText and find the text within carriage returns and add it to the array
  aSectionTwoText = sSectionTwoText.split(chr(10) + chr(10))

  aboutPanel.textTwoArray = aSectionTwoText
  aboutPanel.focusable = false
  aboutPanel.offset = m.rightPanelOffset
  return aboutPanel
End Function


Function createSettingsMenuPanel()
  settingsMenuPanel = CreateObject("roSGNode", "SettingsMenuPanel")
  settingsMenuPanel.width = m.leftPanelWidth
  settingsMenuPanel.leftPosition = 0
  settingsMenuPanel.focusable = true
  settingsMenuPanel.leftOnly = true
  settingsMenuPanel.createNextPanelOnItemFocus = true
  settingsMenuPanel.selectButtonMovesPanelForward = true
  settingsMenuPanel.signInInfo = m.top.signInInfo
  settingsMenuPanel.uiMode = m.top.uiMode
  return settingsMenuPanel
End Function


Function createLegalPanel(title, uri)
  textPanel = CreateObject("roSGNode", "ScrollingTextPanel")
  textPanel.title = title
  textPanel.width = m.rightPanelWidth
  textPanel.focusable = true
  textPanel.hasNextPanel = false
  textPanel.leftOnly = false
  textPanel.selectButtonMovesPanelForward = false
  textPanel.offset = m.rightPanelOffset
  textPanel.isLoading = true
  requestTask = CreateObject("roSGNode", "SimpleRequestTask")
  requestTask.uri = uri
  requestTask.node = textPanel
  requestTask.field = "text"
  requestTask.control = "RUN"
  requestTask.observeField("state", "onLegalState")
  textPanel.appendChild(requestTask)
  return textPanel
End Function


Function createPrivacyCenterPanel(title)
  privacyCenterPanel = CreateObject("roSGNode", "PrivacyCenterPanel")
  privacyCenterPanel.id = "privacyCenterPanel"
  privacyCenterPanel.title = title
  privacyCenterPanel.isAllowedToManageConsent = m.top.isAllowedToManageConsent
  
  if isGDPR() = true
    privacyCenterPanel.observeFieldScoped("didUserSelectManagePrivacySettingsButton", "onDidUserSelectManagePrivacySettingsButton")
  else
    consentSettings = m.top.consentSettings
    focusable = false
    privacyCenterSettings = consentSettings.privacyCenterSettings
    privacyCenterPanel.consentSettings = consentSettings
    if privacyCenterSettings.showConsentPreferences = true AND consentSettings.consents.Count() > 0
      for i = 0 to consentSettings.consents.Count()-1
        if consentSettings.consents[i].value <> "required"
          focusable = true
          exit for
        end if
      end for
    end if

    if privacyCenterSettings.showTermsOfUse = true OR privacyCenterSettings.showPrivacyPolicy = true
      focusable = true
    end if

    privacyCenterPanel.focusable = focusable
    privacyCenterPanel.offset = [m.rightPanelOffset[0],-141]
    privacyCenterPanel.observeFieldScoped("newConsentPreferences", "onNewConsentPreferences")
    privacyCenterPanel.observeFieldScoped("selectedQrCodeSectionInfo", "onSelectedQrCodeSectionInfoChanged")
    privacyCenterPanel.observeFieldScoped("didUserSelectSaveAndRestart", "onDidUserSelectSaveAndRestart")
  end if


  pageValues = {
    account_page_type: "PRIVACY_PREFERENCES"
  }

  ' TODO: This is a temporary event and a more thorough approach to analytics on the Settings page will be implemented in the near future.
  m.top.navigateWithinPageInfo = {
    pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, pageValues)
    means_of_navigation: "SCROLL"
    vertical_location: m.SettingsMenuPanel.list.currFocusRow + 1 ' Since focused index starts from zero.
    horizontal_location: 1
  }

  return privacyCenterPanel
End Function


Function onNewConsentPreferences(msg)
  selectedConsent = msg.getData()
  keys = selectedConsent.Keys()
  ' we expect only single key/value pair in selectedConsent. so accessing the 0th item as it has only one item.
  key = keys[0]
  value = selectedConsent[key]

  if value <> "required"
    newConsentPreferences = m.top.newConsentPreferences
    if newConsentPreferences = invalid
      newConsentPreferences = {}
    end if

    newConsentPreferences.append(selectedConsent)
    m.top.newConsentPreferences = newConsentPreferences
  end if

  m.top.selectedConsent = selectedConsent
End Function


Function onSelectedQrCodeSectionInfoChanged(msg)
  data = msg.getData()
  m.top.selectedQrCodeSectionInfo = data
End Function


Function onLegalState(msg)
  tubiLog("onLegalState state = " + msg.GetData())
  if msg.GetData() = "stop" or msg.GetData() = "done"
    task = msg.getRoSGNode()
    if task <> invalid
      panel = task.getParent()
      if panel <> invalid AND panel.isLoading <> invalid
        panel.isLoading = false
      end if
    end if
  end if
End Function


Function createSignInPanel()
  panel = CreateObject("roSGNode", "ScrollingTextPanel")
  panel.title = getTranslation("screenSettings_signInPanel_title")
  panel.text = getTranslation("screenSettings_signIn_description")

  panel.focusable = false
  panel.offset = m.rightPanelOffset
  return panel
End Function


Function createSignOutPanel()
  panel = CreateObject("roSGNode", "SignOutPanel")
  panel.title = getTranslation("screenSettings_menu_signOut")

  sName = ""
  if m.top.signInInfo <> invalid
    sName = m.top.signInInfo.name
  end if
  if sName <> ""
    panel.description  = getTranslation("screenSettings_signOut_description", {name: sName})
  else
    panel.description  = ""
  end if

  sEmail = ""
  if m.top.signInInfo <> invalid
    sEmail = m.top.signInInfo.email
  end if
  if sEmail <> ""
    panel.description2  = getTranslation("screenSettings_signOut_description2", {email: sEmail})
  else
    panel.description2  = ""
  end if

  panel.width = m.rightPanelWidth
  panel.focusable = false
  panel.hasNextPanel = false
  panel.leftOnly = false
  panel.selectButtonMovesPanelForward = false
  panel.offset = m.rightPanelOffset
  return panel
End Function


Function createTestingAidPanel()

  TestingPanel = CreateObject("roSGNode", "TestingAidPanel")
  if TestingPanel <> invalid
    TestingPanel.observeFieldScoped("appRestartRequested", "onAppRestartRequested")
    TestingPanel.width = m.rightPanelWidth
    TestingPanel.focusable = true
    TestingPanel.hasNextPanel = false
    TestingPanel.leftOnly = false
    TestingPanel.selectButtonMovesPanelForward = false
    TestingPanel.offset = m.rightPanelOffset
  end if

  return TestingPanel
End Function


Function focusItemInList(list, sID)
  index = -1
  content = list.content
  index = -1
  for i = 0 to content.getChildCount() - 1
    item = content.getChild(i)
    if item.id = sID
      index = i
      exit for
    end if
  end for
  if index >= 0
    list.jumpToItem = index
  end if
  return index
End Function


Function onMenuItemSelected()
  buttonContent = m.SettingsMenuPanel.content.getChild(m.SettingsMenuPanel.itemSelected)
  if buttonContent.id = "SignInOutButton"
    if isSignedIn() = true
      m.top.signOutSelected = true
    else
      m.top.signInSelected = true
    end if
  else if buttonContent.id = "AboutButton"
    m.top.showDeviceModal = true
  else if buttonContent.id = "ExitButton"
    m.top.showExitModal = true

    ' TODO: This is a temporary event and a more thorough approach to analytics on the Settings page will be implemented in the near future.
    pageValues = {
      account_page_type: "ACCOUNT"
    }

    leftSideNavComponent = {
      left_nav_section: "EXIT"
    }

    pageOneof = m.Tracking.getAnalyticsPage("account_page", pageValues)
    componentOneof = m.Tracking.getAnalyticsComponent("left_side_nav_component", leftSideNavComponent)
    m.top.componentInteractionInfo = {
      pageOneof: pageOneof
      componentOneof: componentOneof
      user_interaction: "CONFIRM"
    }
  end if
End Function


Function onParentalControlsItemSelected(msg)
  tubiLog("SettingsScreen.onParentalControlsItemSelected")
  m.top.parentalSettingSelected = msg.GetData()
End Function


Function onAudioGuideTextChanged(msg)
  tubiLog("SettingsScreen.onAudioGuideTextChanged")
  focusedItemTitle = msg.getData()
  readAudioGuideText(focusedItemTitle)
End Function


Function onAutoplayPreviewPanelItemSelected(msg)
  tubiLog("SettingsScreen.onAutoplayPreviewItemSelected")
  itemSelected = msg.GetData()
  m.top.autoPreviewSettingSelected = itemSelected

End Function


Function onItemRequested()
  list = m.SettingsMenuPanel.list
  if list <> invalid
    if list.itemFocused <> invalid
      buttonContent = list.content.getChild(list.itemFocused)

      if m.top.itemRequested <> invalid AND m.top.itemRequested <> "" AND m.top.itemRequested <> buttonContent.id
        focusItemInList(list, m.top.itemRequested)
      end if
    end if
  end if
End Function


Function onKeyEvent(key, press) as Boolean
  if press = true
    if key = "back"
      m.top.backButtonPressed = true
      return true
    end if
  end if
  return false
End Function


Function onAppRestartRequested(msg)
  if m.top.appRestartRequested <> invalid
    m.top.appRestartRequested = msg.getData()
  end if
End Function


Function onDidUserSelectSaveAndRestart()
  ' since privacy center is dyanmically created we cannot use alias.
  m.top.didUserSelectSaveAndRestart = true
End Function


' Get a panel based on its node subtype
' @panelSubtype: string, subtype of the component we want to try to get for example "ParentalControlsPanel"
Function getPanelBySubtype(panelSubtype)
  for i = 0 to m.panelset.getChildCount() - 1
    node = m.panelset.getChild(i)
    if node.subtype() = panelSubtype then
      return node
    end if
  end for
  return invalid
End Function


Function onDidUserSelectManagePrivacySettingsButton()
  ' since privacy center is dyanmically created we cannot use alias.
  m.top.didUserSelectManagePrivacySettingsButton = true
End Function
