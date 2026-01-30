Function init()
  m.constants = getConstantsFromGlobal()
  m.emailGroup = m.top.findNode("EmailGroup")
  m.kidsGroup = m.top.findNode("KidsGroup")
  m.Tracking = TubiTrackingInfo(m.constants)

  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("isEmailValid", "onIsEmailValidChange")

  m.pageHeading = m.top.findNode("pageHeading")
  m.emailHeadingText = getTranslation("email_screen_heading")
  m.kidsHeadingText = getTranslation("kids_screen_heading")

  m.profileMenu = m.top.findNode("ProfileMenu")
  m.top.observeFieldScoped("profiles", "onProfileMenuContentChange")
  m.profileMenu.observeFieldScoped("itemSelected", "onProfileMenuItemSelected")
  m.bottomTextHeader = m.top.findNode("bottomTextHeader")
  m.bottomText = m.top.findNode("bottomText")
  m.bottomTextGroup = m.top.findNode("bottomTextGroup")


  m.emailTextEditBox = m.top.findNode("emailTextEditBox")
  m.emailTextEditBox.maxTextLength = 100

  m.emailValidationMsg = m.top.findNode("emailValidationMsg")
  m.emailValidationMsg.text = getTranslation("invalid_email_title")

  m.tabButtons = m.top.findNode("tabButtons")
  m.tabButtons.observeFieldScoped("itemSelected", "onTabButtonsItemSelected")
  m.tabButtons.observeFieldScoped("itemFocused", "onTabButtonsItemFocused")

  readAudioGuideText(m.pageHeading.text)

  m.keyboard = m.top.findNode("Keyboard")
  m.keyboard.textEditBox.opacity = 0.00001
  m.keyboard.textEditBox.maxTextLength = 100
  m.keyboard.domain = "email"

  'This will save the last focused key of the keyboard used to enable the roku default audioguide after screen components read.
  m.keyFocused = ""

  'This will disable the default roku screen reader for customKeyboard to read screen heading which are not read by roku default screen reader.
  m.keyboard.muteAudioGuide = true
  m.keyboard.observeFieldScoped("keyGrid", "onKeyGridChange")
  m.keyboard.textEditBox.observeFieldScoped("focusedChild", "onTextEditBoxFocused")

  m.keyboard.palette = handleKeyboardColors()

  m.back = m.top.findNode("back")
  m.back.text = getTranslation("linearVideoPlayer_buttonBack")

  m.continue = m.top.findNode("continue")
  m.continue.text = getTranslation("dialog_button_continue")
  m.continue.observeFieldScoped("selected", "onContinueButtonSelected")


  m.keyboard.textEditBox.observeFieldScoped("focusedChild", "onKeyboardTextEditBoxFocusedChildChange")

  m.keyboard.textEditBox.observeFieldScoped("cursorPosition", "onKeyboardTextEditBoxCursorPositionChange")

  m.top.instantResumeAction = m.constants.instantResumeActions.restartApp

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "register_page"
    pageValues: {
      auth_method: "EMAIL"
    }
  }

  m.top.isStackable = true
  m.top.screenLevel = m.constants.ui.screenLevels.emailInputScreen

  m.backgroundUriList = []

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.pageHeading, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.emailValidationMsg, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.bottomTextHeader, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.bottomText, typographyConstants.ids.bodySmall)

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
    m.back.color = theme.backgroundColorLight
    m.continue.color = theme.backgroundColorLight
    m.emailValidationMsg.color = theme.cautionColor
    m.pageHeading.color = theme.primaryTextColor

    paletteColors = m.keyboard.palette.colors
    paletteColors.FocusItemColor = theme.focusedTextColor
    paletteColors.FocusColor = theme.focusedColor
    m.keyboard.palette.colors = paletteColors
    m.profileMenu.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true then
    m.tabButtons.setFocus(true)
    m.emailTextEditBox.active = true
    m.keyboard.unobserveFieldScoped("text")
    m.keyboard.observeFieldScoped("text", "onKeyboardTextChanged")

    ' force a background update
    m.top.backgroundUriList = m.backgroundUriList

    m.Keyboard.textEditBox.voiceEnabled = true
  end if

  if m.top.isInFocusChain() = false
    m.emailTextEditBox.active = false
    m.keyboard.unobserveFieldScoped("text")
    m.Keyboard.textEditBox.voiceEnabled = false
  end if
End Function


'This function is to read the first focused keys in the keyboard as we disable the default screen reader for keyboard initially
'to read the screen components and later we enable roku default screen reader for keyboard.
'NOTE: hardcoded values are to match the default keyboard.
Function onKeyGridChange(msg)
  keyGrid = msg.getData()
  if isNonEmptyString(m.keyFocused) = true AND m.keyboard.muteAudioGuide = true

    if keyGrid.keyFocused = "a"
      audioGuideText = keyGrid.keyFocused + " " + "alpha"
    else
      audioGuideText = keyGrid.keyFocused + " " + m.constants.audioGuideHints.buttonHint
    end if

    readAudioGuideText(audioGuideText, false)

    'This is to read the screen text and suspend the kepboard default audio guide until focus moved to next key.
    if m.keyFocused <> keyGrid.keyFocused
      m.keyboard.muteAudioGuide = false
      m.keyboard.unObserveFieldScoped("keyGrid")
    end if
  end if

  m.keyFocused = keyGrid.keyFocused
End Function


Function onKeyboardTextEditBoxFocusedChildChange()
  ' Don't allow textEditBox to take focus since we're not showing it
  if m.keyboard.textEditBox.hasFocus()
    m.keyboard.keyGrid.setFocus(true)
  end if
End Function


Function onKeyboardTextEditBoxCursorPositionChange(msg)
  m.emailTextEditBox.cursorPosition = msg.getData()
End Function


Function onKeyboardTextChanged()
  m.emailTextEditBox.text = m.keyboard.text
End Function


'Handling when app is focusing on an invisible textbox that is built into the keyboard
Function onTextEditBoxFocused()
  if m.keyboard.textEditBox.hasFocus()
    m.tabButtons.setFocus(true)
  end if
End Function


' onContinueButtonSelected callback triggers when user selects continue button
Function onContinueButtonSelected(evt)

  isButtonSelected = evt.getData()
  if isButtonSelected = true
    m.top.email = m.emailTextEditBox.text
    ' we must set voiceEnabled = false here because if we rely on isInFocusChain() in
    ' onScreenFocusChange(), voiceEnabled is not set to false until after voiceEnabled is set to true
    ' on the SignInScreen, which prevents voiceEnabled is getting to true
    ' on the SignInScreen.
    m.keyboard.textEditBox.voiceEnabled = false
    m.top.continueSelected = true
  end if
End Function


Function onIsEmailValidChange(msg)
  isEmVal = msg.getData()

  if isEmVal = true
    fade(m.emailValidationMsg, "out", 0.3)
  else
    fade(m.emailValidationMsg, "in", 0.3)
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean

  handled = true
  if press = false then
    return false
  else
    if key = "OK"
      if m.emailGroup.visible = true
        m.emailTextEditBox.text = m.keyboard.text
      end if

    else if key = "back"
      m.top.backButtonSelected = true

    else if key = "down"
      if m.emailGroup.visible = true
        if m.tabButtons.isInFocusChain() = true
          m.keyboard.setFocus(true)
        else if m.keyboard.isInFocusChain() = true
          m.continue.setFocus(true)
          readAudioGuideText(m.continue.text)
        end if
      else if m.kidsGroup.visible = true
        if m.tabButtons.isInFocusChain() = true
          m.profileMenu.setFocus(true)
        end if

      end if

    else if key = "up"
      if m.emailGroup.visible = true
        if m.keyboard.isInFocusChain() = true
          m.tabButtons.setFocus(true)
        else if m.continue.hasFocus() = true
          m.keyboard.setFocus(true)
        else if m.back.hasFocus() = true
          m.keyboard.setFocus(true)
        end if
      else if m.kidsGroup.visible = true
        if m.profileMenu.isInFocusChain() = true
          m.tabButtons.setFocus(true)
        end if
      end if

    else if key = "right"
      if m.emailGroup.visible = true
        if m.back.hasFocus() = true
          m.continue.setFocus(true)
          readAudioGuideText(m.continue.text)
        end if
      end if

    else if key = "left"
      if m.emailGroup.visible = true
        if m.continue.hasFocus() = true
          m.back.setFocus(true)
          readAudioGuideText(m.back.text)
        end if
      end if

    end if
    return handled
  end if

End Function


Function onTabButtonsItemFocused(msg)
  itemFocused = msg.getData()
  if itemFocused = 0
    m.EmailGroup.visible = true
    m.KidsGroup.visible = false
    m.pageHeading.text = m.emailHeadingText
    m.top.accountTypeSelected = "adults"
  else if itemFocused = 1
    m.EmailGroup.visible = false
    m.KidsGroup.visible = true
    m.pageHeading.text = m.kidsHeadingText
    m.top.accountTypeSelected = "kids"
  end if

  if m.top.accountTypeSelected = "adults"
    componentValues = {
      top_nav_section: "ADULT"
    }
  else
    componentValues = {
      top_nav_section: "KIDS"
    }
  end if

  pageOneof = m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pagetype, m.top.trackingPageInfo.pageValues)
  componentOneof = m.Tracking.getAnalyticsComponent("top_nav_component", componentValues)

  componentInteractionEvent = {
    pageOneof: pageOneof
    componentOneof: componentOneof
    user_interaction: "TOGGLE_ON"
  }

  m.top.componentInteractionInfo = componentInteractionEvent
End Function


Function onProfileMenuContentChange(msg)
  profiles = msg.getData()
  m.profileMenu.content = profiles
  width = m.profileMenu.boundingRect().width + 100

  if profiles.count() > 2
    m.profileMenu.itemClippingRect = [0, 0, width, 301]
  end if

  m.bottomTextHeader.text = getTranslation("kids_screen_bottom_text_header")
  m.bottomText.text = getTranslation("kids_screen_bottom_text")
End Function


Function onProfileMenuItemSelected(msg)
  parentProfileId = msg.getData()
  profile = m.profileMenu.content.getChild(parentProfileId)
  m.top.hasPin = profile.hasPin
  m.top.parentProfileId = profile.id

  ' we must set voiceEnabled = false here because if we rely on isInFocusChain() in
  ' onScreenFocusChange(), voiceEnabled is not set to false until after voiceEnabled is set to true
  ' on the SignInScreen, which prevents voiceEnabled is getting to true
  ' on the SignInScreen.
  m.keyboard.textEditBox.voiceEnabled = false

  m.top.continueSelected = true
End Function



