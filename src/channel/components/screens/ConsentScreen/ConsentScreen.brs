Function init()
  topRef = m.top
  m.constants = getConstantsFromGlobal()
  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.heading = topRef.findNode("heading")
  m.subheading = topRef.findNode("subheading")
  m.description = topRef.findNode("description")
  m.buttonList = topRef.findNode("buttonList")
  m.buttonList.observeFieldScoped("itemSelected", "onItemSelectedChange")

  m.heading.text = getTranslation("consent_screen_heading")
  m.subheading.text = getTranslation("consent_screen_subheading")

  buttonList = CreateObject("roSGNode", "ContentNode")
  buttons = [
    {
      id: m.constants.ui.consentActionButtonIds.manage
      title: getTranslation("manage_preferences_button_label")
    },
    {
      id: m.constants.ui.consentActionButtonIds.accept
      title: getTranslation("accept_button_label")
    },
    {
      id: m.constants.ui.consentActionButtonIds.reject
      title: getTranslation("reject_button_label")
    }
  ]
  buttonList.update(buttons, true)

  m.buttonList.content = buttonList

  ' Setting background.
  background = topRef.findNode("background")
  background.uri = m.constants.ui.uris.marketingBackground

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  onThemeChange()
  topRef.id = m.constants.ui.screenIds.consentScreen
  topRef.screenLevel = m.constants.ui.screenLevels.consentScreen
  

  topRef.trackingPageInfo = {
    pageType: "your_privacy_page"
    pageValues: {}
  }
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.heading.color = theme.primaryTextColor
    m.subheading.color = theme.secondaryTextColor
    m.description.color = theme.primaryTextColor
  end if
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    m.buttonList.setFocus(true)
  end if
End Function


Function onItemSelectedChange(msg)
  itemSelected = msg.getData()
  m.top.buttonSelected = m.buttonList.content.getChild(itemSelected).id
End Function
