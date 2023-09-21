Function init()
  topRef = m.top
  m.constants = getConstantsFromGlobal()
  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.heading = topRef.findNode("heading")
  m.subheading = topRef.findNode("subheading")
  m.buttonList = topRef.findNode("buttonList")
  m.buttonList.observeFieldScoped("itemSelected", "onItemSelectedChange")

  m.heading.text = getTranslation("consent_screen_heading")
  m.subheading.text = getTranslation("consent_screen_subheading")

  m.focusableSection = topRef.findNode("focusableSection")
  m.description = topRef.findNode("description")
  topRef.observeFieldScoped("description", "onDescriptionChange")

  m.descriptionBackground = topRef.findNode("descriptionBackground")

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
    m.descriptionBackground.blendColor = theme.neutralColor2
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


Function onDescriptionChange(msg)
  text = msg.getData()

  ' Creating a virtual label to figure out the height.
  label = CreateObject("roSGNode", "Label")
  label.width = m.description.width
  label.text = text
  label.wrap = true

  height = label.boundingRect().height

  if height < m.description.height
    m.description.focusable = false
    m.description.translation = m.descriptionBackground.translation
    m.descriptionBackground.visible = false
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  if press = false
    return false
  end if

  if key = "right" AND m.buttonList.isInFocusChain() = true AND m.description.focusable = true
    m.description.scrollbarThumbBitmapUri = "pkg:/images/scrollbar-focused-$$RES$$.9.png"
    m.description.setFocus(true)
    return true
  else if key = "left" AND m.description.isInFocusChain() = true
    m.description.scrollbarThumbBitmapUri = "pkg:/images/scrollbar-unfocused-$$RES$$.9.png"
    m.buttonList.setFocus(true)
    return true
  end if

  return false
End Function
