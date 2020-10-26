Function init()
  m.constants = m.global.constants

  m.leftPanelWidth = 470
  m.rightPanelWidth = 1034
  '//The offset sets the right panel to be placed at a different position than the settings menu list
  m.rightPanelOffset = [36,-199]

  m.PanelSet = m.top.findNode("PanelSet")
  m.Title = m.top.findNode("Title")
  m.Title.text = getTranslation("menu_settings")
  m.NavSection = m.top.findNode("nav")
  BackLabel = m.top.findNode("callToAction")
  BackLabel.text = getTranslation("goBack_home")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment 
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if

  ' Create the menu
  m.SettingsMenuPanel = CreateSettingsMenuPanel()
  m.SettingsMenuPanel.observeField("createNextPanelIndex", "onCreateNextPanelIndex")
  m.SettingsMenuPanel.observeField("itemSelected", "onMenuItemSelected")
  m.SettingsMenuPanel.observeField("itemFocused", "onMenuItemFocused")

  ' This must happen after the pane is all set up so that the createNextPanelIndex
  ' event fires for the default menu selection
  m.PanelSet.appendChild(m.SettingsMenuPanel)
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("parentalSettingUpdated", "onSignInInfoChange")
  m.top.observeField("enabled", "onEnableChange")
  m.top.observeFieldScoped("itemRequested", "onItemRequested")

  m.top.observeFieldScoped("signInInfo", "onSignInInfoChange")

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "account_page"
    pageValues: {
      account_page_type: "PARENTAL"
    }
  }

  m.top.backgroundUriList = [m.constants.ui.uris.defaultBackground]
  m.top.screenLevel = m.constants.ui.screenLevels.settingsScreen

End Function


Function onSignInInfoChange()
  m.SettingsMenuPanel.signInInfo = m.top.signInInfo
  ' renew the parental controls panel if it is showing
  for i = 0 to m.PanelSet.getChildCount() - 1
    child = m.PanelSet.getChild(i)
    if child.subtype() = "ParentalControlsPanel"
      CreateParentalControlsPanel(child)
    end if
  end for
End Function


' NOTE: The focus chain of PanelSet is very difficult to use to determine
'       which particular panel is focused, otherwise we could just set focus
'       in onComponentFocusChange.  Instead, this method, along with
'       onComponentFocusChange, are the only way I have been able to
'       acheive the desired opacity as focus moves left/right across panels
'       and in/out of the screen, such as when a sign in dialog shows.
Function onMenuItemFocused()
  tubiLog("SettingsScreen.onMenuItemFocused")
  m.Title.opacity = 1.0
  m.top.backgroundUriList = [m.constants.ui.uris.defaultBackground]
End Function


Function onComponentFocusChange()
  tubiLog("SettingsScreen.onComponentFocusChange")
  if m.top.isInFocusChain()
    if m.top.hasFocus() = true
      m.SettingsMenuPanel.setFocus(true)
    else
      m.Title.opacity = 0.3
    end if
  end if
End Function


Function onEnableChange()
  if m.top.enabled = true
    fade(m.NavSection, "in", 0.3)
  else
    fade(m.NavSection, "out", 0.3)
  end if
End Function


Function onCreateNextPanelIndex()
  nextIndex = m.SettingsMenuPanel.createNextPanelIndex
  nextPanel = invalid
  buttonContent = m.SettingsMenuPanel.content.getChild(nextIndex)
  if buttonContent <> invalid
    if buttonContent.id = "ParentalControls"
      nextPanel = CreateParentalControlsPanel()
    else if buttonContent.id = "AboutButton"
      nextPanel = CreateAboutPanel()
    else if buttonContent.id = "PrivacyPolicyButton"
      nextPanel = CreateLegalPanel(buttonContent.title, m.constants.urls.privacyUrl)
    else if buttonContent.id = "TermsOfServiceButton"
      nextPanel = CreateLegalPanel(buttonContent.title, m.constants.urls.termsOfUseUrl)
    else if buttonContent.id = "DoNotSellPolicyButton"
      nextPanel = CreateLegalPanel(buttonContent.title, m.constants.urls.doNotSellUrl)
    else if buttonContent.id = "SignInOutButton"
      if isSignedIn() = true
        nextPanel = CreateSignOutPanel()
      else
        nextPanel = CreateSignInPanel()
      end if
    end if
  end if
  if nextPanel <> invalid
    m.SettingsMenuPanel.nextPanel = nextPanel
  else
    print "next panel is invalid"
  end if
End Function


Function isSignedIn()
  bSignedIn = false
  if m.top.signInInfo <> invalid 
    bSignedIn = (m.top.signInInfo.signedIn = true)
  end if
  return bSignedIn
End Function


Function CreateParentalControlsPanel(existingPanel = invalid)
  if existingPanel = invalid
    pcPanel = CreateObject("roSGNode", "ParentalControlsPanel")
    pcPanel.observeField("itemSelected", "onParentalControlsItemSelected")
  else
    pcPanel = existingPanel
  end if

  pcPanel.width = m.rightPanelWidth
  pcPanel.focusable = true
  pcPanel.hasNextPanel = false
  pcPanel.leftOnly = false
  pcPanel.createNextPanelOnItemFocus = false
  pcPanel.selectButtonMovesPanelForward = false
  pcPanel.offset = m.rightPanelOffset

  if isSignedIn() = true
    pcPanel.isLoading = true
    requestTask = CreateObject("roSGNode", "AuthTask")
    requestTask.functionName = "execGetUserInfo"
    requestTask.observeField("userInfo", "onParentalSettingsReceived")
    requestTask.control = "RUN"
    pcPanel.appendChild(requestTask)
  else
    pcPanel.selectItem = 3 ' default if not signed in
  end if
  return pcPanel
End Function


Function onParentalSettingsReceived(msg)
  task = msg.getRoSGNode()
  if task <> invalid
    panel = task.getParent()
    if panel <> invalid and panel.isLoading <> invalid
      panel.isLoading = false
      userInfo = msg.GetData()

      if userInfo <> invalid
        panel.selectItem = userInfo.parentalrating
      end if
    end if
  end if
End Function


Function CreateAboutPanel()
  aboutPanel = CreateObject("roSGNode", "AboutPanel")
  aboutPanel.titleOne = getTranslation("screenSettings_about_title")
  aboutPanel.textOne = getTranslation("screenSettings_about_description")
  aboutPanel.titleTwo = getTranslation("screenSettings_about_title2")

  sVersion = m.constants.settings.version.Replace("_", ".")
  sShortDeviceID = Right(m.constants.deviceInfo.deviceId, 7)
  sYear = CreateObject("roDateTime").GetYear().toStr()
  dynamicText = { 
    version: sVersion, 
    id: sShortDeviceID, 
    help_url: "http://help.tubitv.com", 
    support_url: "https://tubitv.com/support", 
    year: sYear
  }

  aboutPanel.textTwo = getTranslation("screenSettings_about_description2", dynamicText)

  aboutPanel.focusable = false
  aboutPanel.offset = m.rightPanelOffset
  return aboutPanel
End Function


Function CreateSettingsMenuPanel()
  settingsMenuPanel = CreateObject("roSGNode", "SettingsMenuPanel")
  settingsMenuPanel.width = m.leftPanelWidth
  settingsMenuPanel.leftPosition = 0
  settingsMenuPanel.focusable = true
  settingsMenuPanel.leftOnly = true
  settingsMenuPanel.createNextPanelOnItemFocus = true
  settingsMenuPanel.selectButtonMovesPanelForward = true
  settingsMenuPanel.signInInfo = m.top.signInInfo
  return settingsMenuPanel
End Function


Function CreateLegalPanel(title, uri)
  textPanel = CreateObject("roSGNode", "ScrollingTextPanel")
  textPanel.title = title
  textPanel.width = m.rightPanelWidth
  textPanel.focusable = true
  textPanel.hasNextPanel = false
  textPanel.leftOnly = false
  textPanel.createNextPanelOnItemFocus = false
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


Function onLegalState(msg)
  tubiLog("onLegalState state = " + msg.GetData())
  if msg.GetData() = "stop" or msg.GetData() = "done"
    task = msg.getRoSGNode()
    if task <> invalid
      panel = task.getParent()
      if panel <> invalid and panel.isLoading <> invalid
        panel.isLoading = false
      end if
    end if
  end if
End Function


Function CreateSignInPanel()
  panel = CreateObject("roSGNode", "ScrollingTextPanel")
  panel.title = getTranslation("screenSettings_signInPanel_title")
  panel.text = getTranslation("screenSettings_signIn_description")

  panel.focusable = false
  panel.offset = m.rightPanelOffset
  return panel
End Function


Function CreateSignOutPanel()
  panel = CreateObject("roSGNode", "SignOutPanel")
  panel.title = getTranslation("screenSettings_menu_signOut")
  sName = ""
  if m.top.signInInfo <> invalid and m.top.signInInfo.name <> invalid
    sName = m.top.signInInfo.name
  end if

  if sName <> ""
    panel.description  = getTranslation("screenSettings_signOut_description", {name: sName})
  else
    panel.description  = ""
  end if
  sEmail = ""
  if m.top.signInInfo <> invalid and m.top.signInInfo.email <> invalid
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
  panel.createNextPanelOnItemFocus = false
  panel.selectButtonMovesPanelForward = false
  panel.offset = m.rightPanelOffset
  return panel
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
  end if
End Function


Function onParentalControlsItemSelected(msg)
  tubiLog("SettingsScreen.onParentalControlsItemSelected")
  m.top.parentalSettingSelected = msg.GetData()
End Function


Function onItemRequested()
  sButtonID = ""
  list = m.SettingsMenuPanel.list
  if list <> invalid
    if list.itemFocused <> invalid
      buttonContent = list.content.getChild(list.itemFocused)
      sButtonID = buttonContent.id
    end if
    if m.top.itemRequested <> invalid and m.top.itemRequested <> "" and m.top.itemRequested <> buttonContent.id
      focusItemInList(list, m.top.itemRequested)
    end if
  end if
End Function


Function onKeyEvent(key, press)
  if press = true
    if key = "left"
      m.top.backButtonPressed = true
      return true
    end if

    return false
  end if
End Function
