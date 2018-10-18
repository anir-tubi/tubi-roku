Function init()
  m.top.observeField("signedIn", "onSignedInChange")
  m.Menu = m.top.findNode("Menu")
  m.Menu.observeField("rowItemSelected", "onItemSelected")
  m.Menu.observeField("rowItemFocused", "onItemFocused")
  content = m.top.findNode("SearchSignInContent")
  m.Menu.content = content
  m.SignInContent = content.findNode("SignInMenuItem")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.Description = m.top.findNode("Description")

  onSignedInChange()  ' initialize the sign in/out text

  m.constants = m.global.constants
  if m.constants.ui.onnow.on = true
    m.top.findNode("OnNowHint-Tools").visible = true
  end if

  if m.constants.deviceInfo.scaledUi = true
    m.Menu.focusBitmapUri = "pkg:/images/menu-focus-hd.9.png"
  end if
End Function

Function onComponentFocusChange()
  if m.top.isInFocusChain() and not m.Menu.hasFocus() then
    m.Menu.setFocus(true)
    m.top.backgroundUriList = [m.constants.ui.uris.defaultBackground]
  end if
End Function

Function onItemFocused()
  tubiLog("ToolsMenu.onItemFocused")
  rowItemFocused = m.Menu.rowItemFocused
  item = m.Menu.content.getChild(rowItemFocused[0]).getChild(rowItemFocused[1])
  m.Description.text = item.description
End Function

Function onItemSelected()
  tubiLog("ToolsMenu.onItemSelected")
  if m.Menu.content <> invalid then
    rowItemSelected = m.Menu.rowItemSelected
    item = m.Menu.content.getChild(rowItemSelected[0]).getChild(rowItemSelected[1])
    if item.id = "SearchMenuItem" then
      m.top.searchSelected = true
    else if item.id = "SignInMenuItem" then
      m.top.signInSelected = true
    else if item.id = "SettingsMenuItem" then
      m.top.settingsSelected = true
    else if item.id = "ExitMenuItem" then
      m.top.exitSelected = true
    end if
  end if
End Function

Function onSignedInChange()
  tubiLog("ToolsMenu.onSignedInChanged")
  if m.top.signedIn = true
    m.Menu.content.getChild(0).removeChild(m.SignInContent)
  else
    m.Menu.content.getChild(0).insertChild(m.SignInContent, 2)
  end if
  ' RowList doesn't automatically adjust the component width based on
  ' content like LayoutGroup does, so we manually adjust it here
  posterWidth = m.Menu.rowItemSize[0][0]
  posterSpacing = m.Menu.rowItemSpacing[0][0]
  numberButtons = m.Menu.content.getChild(0).getChildCount()
  menuWidth = (posterWidth + posterSpacing) * numberButtons
  m.Menu.itemSize = [menuWidth, 400]
End Function

Function onKeyEvent(key, press)
  if press = true and (key = "back" or key = "down")
    ' We want to suppress page navigation events specifically for tools menu
    ' to be consistent with old behavior. capture this event so screenstack 
    ' doesn't receive it
    m.top.backButtonPressed = true
    return true
  end if
  return false
End Function
