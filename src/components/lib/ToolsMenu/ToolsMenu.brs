Function init()
  m.top.observeField("signedIn", "onSignedInChange")
  m.Menu = m.top.findNode("Menu")
  m.Menu.observeField("itemSelected", "onItemSelected")
  m.Menu.observeField("itemFocused", "onItemFocused")
  content = m.top.findNode("SearchSignInContent")
  m.Menu.content = content
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.Description = m.top.findNode("Description")
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
End Function

Function onItemSelected()
  tubiLog("ToolsMenu.onItemSelected")
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

Function onSignedInChanged()
  tubiLog("ToolsMenu.onSignedInChanged")
  content = m.top.findNode("SignInOutMenuItem")
  if m.top.signedIn then
    content.title = "Sign Out"
    content.description = "Sign Out of Tubi TV"
  else
    content.title = "Sign In"
    content.description = "Sign In to Tubi TV. Access your Queue and View History across your devices"
  end if
End Function