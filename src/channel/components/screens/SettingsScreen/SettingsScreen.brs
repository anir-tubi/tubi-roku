Function init()
  m.constants = m.global.constants

  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.leftPanelWidth = 420
  m.rightPanelWidth = 1034
  m.rightPaneloffset = [220,-197]

  m.PanelSet = m.top.findNode("PanelSet")
  m.Title = m.top.findNode("Title")

  ' Create the menu
  m.SettingsMenuPanel = CreateSettingsMenuPanel()
  m.SettingsMenuPanel.observeField("createNextPanelIndex", "onCreateNextPanelIndex")
  m.SettingsMenuPanel.observeField("itemSelected", "onMenuItemSelected")
  m.SettingsMenuPanel.observeField("itemFocused", "onMenuItemFocused")

  ' This must happen after the pane is all set up so that the createNextPanelIndex
  ' event fires for the default menu selection
  m.PanelSet.appendChild(m.SettingsMenuPanel)
  m.PanelSet.observeField("isGoingBack", "onReturnToMenu")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")

  ' used to compare if a newly focused item gained focus from a different item while scrolling,
  ' or gained focus from a different component/screen
  m.menuIsFocused = false
End Function

Function onSignedInChange()
  tubiLog("SettingsScreen.onSignedInChange")
  m.SettingsMenuPanel.signedIn = m.top.signedIn

  ' renew the parental controls panel if it is showing
  for i=0 to m.PanelSet.getChildCount()-1
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

  if m.menuIsFocused = true
    row = m.SettingsMenuPanel.itemFocused + 1
    col = 1
    m.top.navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent("settings_menu_component", {}) 'settings_menu_component doesn't exist in protos
      means_of_navigation: "SCROLL"  'MeansOfNavigation enum
      vertical_location: row
      vertical_location_mode: "COORDINATE"  'LocationMode enum
      horizontal_location: col
      horizontal_location_mode: "INDEX"  'LocationMode enum
    }
  end if
  m.menuIsFocused = true
End Function

Function onComponentFocusChange()
  tubiLog("SettingsScreen.onComponentFocusChange")

  menu = m.SettingsMenuPanel.findNode("SettingsMenu")
  if m.top.isInFocusChain()
    if m.top.hasFocus() = false
      m.Title.opacity = 0.3
    end if
  end if
End Function


Function onReturnToMenu(msg)
  isReturning = msg.getData()
  if isReturning = true
    m.menuIsFocused = false
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
      nextPanel = CreateLegalPanel("Privacy Policy", m.global.constants.urls.privacyUrl)
    else if buttonContent.id = "TermsOfServiceButton"
      nextPanel = CreateLegalPanel("Terms of Service", m.global.constants.urls.termsOfUseUrl)
    else if buttonContent.id = "SignInOutButton"
      if m.top.signedIn = true
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

Function CreateParentalControlsPanel(existingPanel=invalid)
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
  if m.top.signedIn = true
    pcPanel.isLoading = true
    requestTask = CreateObject("roSGNode", "AuthTask")
    requestTask.functionName = "execGetUserInfo"
    requestTask.observeField("userInfo", "onParentalSettingsReceived")
    requestTask.control = "RUN"
    pcPanel.appendChild(requestTask)
  else
    pcPanel.selectItem = 3  ' default if not signed in
  end if
  return pcPanel
End Function

Function onParentalSettingsReceived(msg)
  task = msg.getRoSGNode()
  if task <> invalid
    panel = task.getParent()
    if panel <> invalid and panel.isLoading <> invalid
      userInfo = msg.GetData()
      panel.isLoading = false
      panel.selectItem = userInfo.parentalrating
      m.top.remoteParentalSetting = userInfo.parentalrating
    end if
  end if
End Function


Function CreateAboutPanel()
  aboutPanel = CreateObject("roSGNode", "ScrollingTextPanel")
  aboutPanel.title = "About Tubi"
  text = "Version " + m.global.constants.settings.version.Replace("_",".") + Chr(10)
  text += Chr(10)
  year = CreateObject("roDateTime").GetYear().toStr()
  text += "© " + year + " Tubi, Inc. all rights reserved." + Chr(10)
  text += "The Tubi wordmark and all related logotypes are trademarks of Tubi, Inc."
  aboutPanel.text = text
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
  settingsMenuPanel.signedIn = m.top.signedIn
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
  panel.title = "Sign In"
  panel.text = "Sign in to Tubi. Access your Queue and Continue Watching lists across your devices."
  panel.focusable = false
  panel.offset = m.rightPanelOffset
  return panel
End Function

Function CreateSignOutPanel()
  panel = CreateObject("roSGNode", "SignOutPanel")
  panel.name = m.top.name
  panel.email = m.top.email
  panel.width = m.rightPanelWidth
  panel.focusable = false
  panel.hasNextPanel = false
  panel.leftOnly = false
  panel.createNextPanelOnItemFocus = false
  panel.selectButtonMovesPanelForward = false
  panel.offset = m.rightPanelOffset
  return panel
End Function

Function onMenuItemSelected()
  buttonContent = m.SettingsMenuPanel.content.getChild(m.SettingsMenuPanel.itemSelected)
  if buttonContent.id = "SignInOutButton"
    if m.top.signedIn = true
      m.top.signOutSelected = true
    else
      m.top.signInSelected = true
    end if
  end if
End Function

Function onParentalControlsItemSelected(msg)
  tubiLog("SettingsScreen.onParentalControlsItemSelected")
  m.top.parentalSettingSelected = msg.GetData()
End Function