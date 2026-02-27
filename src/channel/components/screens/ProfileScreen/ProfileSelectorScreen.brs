Function init()
  m.profileMenu = m.top.findNode("ProfileMenu")
  m.profileScreenTitle = m.top.findNode("ProfileScreenTitle")

  m.top.observeFieldScoped("content", "onCreateProfilesMenu")
  m.top.observeFieldScoped("focusedChild", "onFocusedChildChange")
  m.profileMenu.observeFieldScoped("itemSelected", "onItemSelectedChange")
  m.profileScreenTitle.text = getTranslation("profile_selector_screen_title")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.profileScreenTitle, typographyConstants.ids.headerLarge)

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.profileMenu.focusBitmapBlendColor = theme.focusedColor
    m.profileScreenTitle.color = theme.primaryTextColor
  end if

  m.top.trackingPageInfo = {
    pageType: "account_selection_page"
    pageValues: {}
  }

End Function


Function onCreateProfilesMenu(msg)
  profiles = msg.getData()
  m.profileMenu.content = profiles

  'set profile menu centered
  width = m.profileMenu.boundingRect().width
  height = m.profileMenu.boundingRect().height

  translationX = (1920 - width) / 2
  if translationX < 260
    translationX = 260
  end if
  m.profileMenu.translation = [translationX, 426]

  w = width + 580
  m.profileMenu.itemClippingRect = [-340, 0, w, height]
  m.top.contentReady = true
End Function


Function onFocusedChildChange(msg)
  if m.top.isInFocusChain() = true
    m.profileMenu.setFocus(true)
  end if
End Function


Function onItemSelectedChange(msg)
  itemSelected = msg.getData()
  if itemSelected <> invalid AND m.profileMenu.content <> invalid
    profileSelected = m.profileMenu.content.getChild(itemSelected).id
    m.top.profileSelected = profileSelected
  end if

End Function


Function onKeyEvent(key, press) as Boolean
  if press = true
    if key = "back" AND m.top.disableBack = true
      return true
    end if
  end if

  return false
End Function