Function init()
  m.constants = m.global.constants

  m.leftPanelWidth = 420
  m.rightPanelWidth = 1034
  m.rightPaneloffset = [220,-199]

  m.PanelSet = m.top.findNode("PanelSet")
  m.Title = m.top.findNode("Title")
  m.NavSection = m.top.findNode("nav")

  ' Create the menu
  m.SettingsMenuPanel = CreateSettingsMenuPanel()
  m.SettingsMenuPanel.observeField("createNextPanelIndex", "onCreateNextPanelIndex")
  m.SettingsMenuPanel.observeField("itemSelected", "onMenuItemSelected")
  m.SettingsMenuPanel.observeField("itemFocused", "onMenuItemFocused")

  ' This must happen after the pane is all set up so that the createNextPanelIndex
  ' event fires for the default menu selection
  m.PanelSet.appendChild(m.SettingsMenuPanel)
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("parentalSettingUpdated", "onSignedInChange")
  m.top.observeField("enabled", "onEnableChange")
  m.top.observeFieldScoped("itemRequested", "onItemRequested")

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
  aboutPanel = CreateObject("roSGNode", "AboutPanel")
  aboutPanel.titleOne = "About Tubi"
  textOne = "Tubi is the leading free, premium, video streaming app. We have the largest library of content with over 15,000 movies and television shows with far fewer ads than cable TV."
  textOne += Chr(10)
  aboutPanel.textOne = textOne

  aboutPanel.titleTwo = "Need Help?"
  textTwo = "Visit http://help.tubitv.com" + Chr(10)
  textTwo += Chr(10)
  textTwo += "Email our Support team at support@tubi.tv" + Chr(10)
  textTwo += Chr(10)
  textTwo += "Reach us on Facebook, Instagram, Twitter, and on our website at:" + Chr(10)
  textTwo += "https://tubitv.com/support" + Chr(10)
  textTwo += Chr(10)
  textTwo += "Version " + m.global.constants.settings.version.Replace("_",".") + Chr(10)
  textTwo += "Device ID: " + Right(m.constants.deviceInfo.deviceId, 7) + Chr(10)
  textTwo += Chr(10)
  year = CreateObject("roDateTime").GetYear().toStr()
  textTwo += "© " + year + " Tubi, Inc. all rights reserved."
  aboutPanel.textTwo = textTwo
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