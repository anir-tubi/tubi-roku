Function init()
  m.top.observeField("signedIn", "onSignedInChange")
  m.Menu = m.top.findNode("Menu")
  m.Menu.observeField("itemSelected", "onItemSelected")
  m.Menu.observeField("itemFocused", "onItemFocused")
  content = m.top.findNode("SearchSignInContent")
  m.Menu.content = content
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("trackingUri", "onTrackingUriChange")
  m.Description = m.top.findNode("Description")

  onSignedInChange()  ' initialize the sign in/out text

  if m.global.constants.ui.onnow.on = true
    m.top.findNode("OnNowHint-Tools").visible = true
  end if
End Function

Function onComponentFocusChange()
  if m.top.isInFocusChain() and not m.Menu.hasFocus() then
    m.Menu.setFocus(true)
  end if
End Function

Function onItemFocused()
  tubiLog("ToolsMenu.onItemFocused")
  item = m.Menu.content.getChild(m.Menu.itemFocused)
  m.Description.text = item.description
  if m.top.isInFocusChain()
    m.top.trackingUri = "/home/1/cat/Tools/1/" + (m.Menu.itemFocused + 1).toStr()   'assumes Tools is at the top
  end if
End Function

Function onItemSelected()
  tubiLog("ToolsMenu.onItemSelected")
  m.top.trackingCount = 0
  if m.Menu.content <> invalid then
    item = m.Menu.content.getChild(m.Menu.itemSelected)
    if item.id = "SearchMenuItem" then
      m.top.searchSelected = true
    else if item.id = "SignInOutMenuItem" then
      if m.top.signedIn then
        m.top.signOutSelected = true
      else
        m.top.signInSelected = true
      end if
    else if item.id = "AboutMenuItem" then
      m.top.aboutSelected = true
    else if item.id = "PrivacyMenuItem" then
      m.top.privacySelected = true
    end if
  end if
End Function

Function onSignedInChange()
  tubiLog("ToolsMenu.onSignedInChanged")
  content = m.top.findNode("SignInOutMenuItem")
  if m.top.signedIn then
    content.title = "Sign Out"
    content.description = "Sign Out of Tubi TV"
  else
    content.title = "Sign in"
    content.description = "Sign in to Tubi TV. Access your Queue and View History across your devices"
  end if
End Function

Function onTrackingUriChange()
  tubiLog("ToolsMenu.onTrackingUriChange")
  if m.top.isInFocusChain() and m.top.trackingUri <> ""
    m.top.trackingCount = m.top.trackingCount + 1
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "navigateInPage"
      value: m.top.trackingCount
      ctx: m.top.trackingUri
    }
  end if
End Function