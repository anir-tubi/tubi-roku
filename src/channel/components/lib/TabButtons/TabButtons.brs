Function init()
  m.backgroundRail = m.top.findNode("backgroundRail")
  m.tabsList = m.top.findNode("tabsList")
  m.tabsContent = m.top.findNode("tabsContent")
  m.top.observeFieldScoped("focusedChild", "onFocusedChildChange")

  m.tabsList.observeFieldScoped("itemSelected", "onItemSelected")
  m.tabsList.observeFieldScoped("itemFocused", "onItemFocused")

  menuItems = [
    {
      id: "adultsTab",
      title: getTranslation("kids_screen_tab_buttons_adults")
    },
    {
      id: "kidsTab",
      title: getTranslation("kids_screen_tab_buttons_kids")
    }
  ]
  m.tabsContent.update(menuItems, true)

  ' Set up theme
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
    m.tabsList.focusBitmapBlendColor = theme.focusedColor
    m.backgroundRail.blendColor = theme.neutralSolidColor2
    m.tabsList.focusFootprintBlendColor = theme.neutralColor
  end if
End Function


Function onFocusedChildChange()
  if m.top.isInFocusChain() = true AND m.tabsList.hasFocus() = false
    m.tabsList.setFocus(true)
  end if
End Function


Function onItemFocused(msg)

End Function

Function onItemSelected(msg)
End Function
