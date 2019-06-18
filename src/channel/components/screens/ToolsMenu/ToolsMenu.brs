Function init()
  m.constants = m.global.constants
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("itemSelected", "onItemSelected")
  m.top.observeField("itemFocused", "onItemFocused")
  content = m.top.findNode("SearchSignInContent")
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.Menu = m.top.findNode("Menu")
  m.Menu.content = content
  m.Menu.observeField("rowItemFocused", "onMenuItemFocused")
  m.SignInContent = content.findNode("SignInMenuItem")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.Description = m.top.findNode("Description")

  onSignedInChange()  ' initialize the sign in/out text

  if m.constants.deviceInfo.scaledUi = true
    m.Menu.focusBitmapUri = "pkg:/images/menu-focus-hd.9.png"
  end if

  m.top.trackingPageInfo = {
    pageType: "generic_page"
    pageValues: {
      generic_page_type: "OTT_MENU"
    }
  }

  m.top.screenLevel = m.constants.ui.screenLevels.toolsMenu
End Function

Function updateFocusedMenuItemDescription()
  rowItemFocused = m.Menu.rowItemFocused
  if rowItemFocused <> invalid and rowItemFocused.Count() > 0 and m.Menu.content <> invalid
    item = m.Menu.content.getChild(rowItemFocused[0]).getChild(rowItemFocused[1])
    m.Description.text = item.description
  end if
End Function

Function onComponentFocusChange()
  if m.top.isInFocusChain() and not m.Menu.hasFocus() then
    m.Menu.setFocus(true)
    m.top.backgroundUriList = [m.constants.ui.uris.defaultBackground]
  end if
End Function


'We don't use a straight alias of the m.Menu.rowItemFocused because that field is treated like alwaysNotify=true
'by the RowList component, so we inject our own field that we can treat like alwaysNotify=false
Function onMenuItemFocused(msg)
  itemFocused = msg.getData()
  m.top.itemFocused = itemFocused
End Function

Function onItemFocused() 
  tubiLog("ToolsMenu.onItemFocused")
  rowItemFocused = m.Menu.rowItemFocused
  if rowItemFocused<> invalid and rowItemFocused.Count() > 0
    updateFocusedMenuItemDescription()

    'Set the navigateWithinPageInfo value which will pass through to HomeScreen.brs and eventually trigger ContentController
    'to fire a navigate_within_page analytics event.
    if m.Menu.hasFocus()
      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage("generic_page", {generic_page_type: "OTT_MENU"})
        componentOneof: m.Tracking.getAnalyticsComponent("tools_component", {}) 'there is no "tools_component" in protos, so this is a place holder for now
        means_of_navigation: "BUTTON"  'MeansOfNavigation enum
        vertical_location: 1
        vertical_location_mode: "INDEX"  'LocationMode enum
        horizontal_location: rowItemFocused[1] + 1 '1 based index
        horizontal_location_mode: "INDEX"  'LocationMode enum
      }
    end if
  end if
End Function

Function onItemSelected()
  tubiLog("ToolsMenu.onItemSelected")
  if m.Menu.content <> invalid then
    rowItemSelected = m.Menu.rowItemSelected
    item = m.Menu.content.getChild(rowItemSelected[0]).getChild(rowItemSelected[1])
    m.top.trackingComponentInfo = {
      componentType: "tools_menu_component"    'doesn't actually exist in protos currently
      componentValues: {}
    }

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
  
  '//When the signed in state changes, ensure the selected menu item has the proper description showing
  updateFocusedMenuItemDescription()
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
