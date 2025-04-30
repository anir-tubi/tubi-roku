Function init()
  m.constants = getConstantsFromGlobal()
  m.top.width = 1034
  m.top.focusable = true
  m.top.hasNextPanel = false
  m.top.leftOnly = false
  m.top.selectButtonMovesPanelForward = true
  m.top.observeField("focusedChild", "onComponentFocus")
  m.top.observeField("selectItem", "onSelectItem")
  m.top.observeField("isLoading", "onIsLoading")
  m.ContentGroup = m.top.findNode("ContentGroup")
  m.Title = m.top.findNode("Title")
  m.Instructions = m.top.findNode("Instructions")
  m.Menu = m.top.findNode("AutoplayPreviewMenu")
  m.Menu.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"

  m.AutoPlayTimerContentGroup = m.top.findNode("AutoPlayTimerContentGroup")
  m.AutoPlayTimerTitle = m.top.findNode("AutoPlayTimerTitle")
  m.AutoPlayTimerInstructions = m.top.findNode("AutoPlayTimerInstructions")
  m.AutoPlayTimerMenu = m.top.findNode("AutoPlayTimerMenu")
  m.AutoPlayTimerMenuContent = m.top.findNode("AutoPlayTimerMenuContent")

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.Menu.focusBitmapBlendColor = theme.focusedColor
    m.Menu.focusFootprintBlendColor = theme.neutralColor
    m.Title.color = theme.primaryTextColor
    m.Instructions.color = theme.primaryTextColor

    m.AutoPlayTimerMenu.focusBitmapBlendColor = theme.focusedColor
    m.AutoPlayTimerTitle.color = theme.primaryTextColor
    m.AutoPlayTimerInstructions.color = theme.primaryTextColor
  end if

  ' Adding a transparent 1px image since leaving it empty causes roku to use it's default.
  ' We do not want to show unfocused background as per designs.
  m.Menu.focusFootprintBitmapUri = "pkg:/images/transparent.png"
  m.Menu.observeFieldScoped("itemFocused", "onItemFocusChanged")

  m.AutoPlayTimerMenu.observeFieldScoped("itemFocused", "onAutoPlayTimerItemFocusChanged")

  'm.instructionsText is used to store the title and description of autoplay previews for screen reader when screen loaded.
  m.instructionsText = ""

  'm.autoPlayTimerInstructionsText is used to store the title and description of autoplay timer for screen reader when screen loaded.
  m.autoPlayTimerInstructionsText = ""

  setAutoplayPreviewChoices()
  m.Spinner = m.top.findNode("Spinner")
  checkItemHelper(m.top.selectItem, m.Menu)

  if getExperimentResource("roku_autoplay_timer", "roku_autoplay_timer_v1", false).enabled = true
    m.top.observeFieldScoped("isUserSignedIn", "onUserSignedInfoChange")
    setAutoplayTimerChoices()
    checkItemHelper(m.top.autoPlayTimerSelectItem, m.AutoPlayTimerMenu)
    m.AutoPlayTimerContentGroup.visible = true
    m.top.observeField("autoPlayTimerSelectItem", "onAutoPlayTimerSelectItem")
  end if
End Function


Function setAutoplayPreviewChoices()
  m.Title.text = getTranslation("screenSettings_menu_autoplayPreview")

  if m.constants.deviceInfo.IsAutoplayEnabled = true
    m.Instructions.text = getTranslation("screenSettings_autoplayPreview_instructions")

    newContent = m.Menu.content.clone(true)

    for i = 0 to newContent.getChildCount() - 1
      child = newContent.getchild(i)
      if child.id = "On"
        child.title = getTranslation("dialog_button_on")
      else if child.id = "Off"
        child.title = getTranslation("dialog_button_off")
      end if
    end for

    m.Menu.content = newContent
    m.Menu.visible = true
  else
    m.Instructions.text = getTranslation("screenSettings_autoplayPreview_featureDisabledMessage")
    m.Menu.visible = false
  end if

  m.instructionsText = m.Title.text + " " + m.Instructions.text

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.Title, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.Instructions, typographyConstants.ids.bodyMedium)
End Function


Function setAutoplayTimerChoices()
  m.AutoPlayTimerTitle.text = getTranslation("screenSettings_menu_autoplayNextVideo")

  onUserSignedInfoChange()

  onContentNode = CreateObject("roSGNode", "CheckButtonContentNode")
  onContentNode.id = "On"
  onContentNode.title = getTranslation("dialog_button_on")

  offContentNode = CreateObject("roSGNode", "CheckButtonContentNode")
  offContentNode.id = "Off"
  offContentNode.title = getTranslation("dialog_button_off")

  m.AutoPlayTimerMenuContent.appendChildren([onContentNode, offContentNode])

  if m.constants.deviceInfo.IsAutoplayEnabled = true
    m.AutoPlayTimerTitle.translation = [0, 429]
    m.AutoPlayTimerInstructions.translation = [0, 572]
    m.AutoPlayTimerMenu.translation = [0, 681]
  else
    m.AutoPlayTimerTitle.translation = [0, 306]
    m.AutoPlayTimerInstructions.translation = [0, 450]
    m.AutoPlayTimerMenu.translation = [0, 583] 
  end if

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.AutoPlayTimerTitle, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.AutoPlayTimerInstructions, typographyConstants.ids.bodyMedium)
End Function


Function onUserSignedInfoChange()
  if m.top.isUserSignedIn = false
    m.AutoPlayTimerInstructions.text = getTranslation("screenSettings_autoplayTimer_instructions_guest_users")
  else
    m.AutoPlayTimerInstructions.text = getTranslation("screenSettings_autoplayTimer_instructions")
  end if
End Function


Function onComponentFocus()
  if m.top.isInFocusChain() = true AND m.top.hasFocus() = true
    if m.constants.deviceInfo.IsAutoplayEnabled = true
      m.Menu.setFocus(true)
    else
      m.AutoPlayTimerMenu.setFocus(true)
    end if
    sendComponentInteractionEventForAutoplayPreview()
  end if
End Function


Function onSelectItem()
  tubiLog("AutoplayPreviewPanel.onSelectItem")
  checkItemHelper(m.top.selectItem, m.Menu)
End Function


Function onAutoPlayTimerSelectItem()
  tubiLog("AutoplayPreviewPanel.onAutoPlayTimerSelectItem")
  checkItemHelper(m.top.autoPlayTimerSelectItem, m.AutoPlayTimerMenu)
End Function


Function onIsLoading()
  tubiLog("AutoplayPreviewPanel.onIsLoading")
  if m.top.isLoading = true
    m.Spinner.visible = true
    m.ContentGroup.visible = false
  else
    m.Spinner.visible = false
    m.ContentGroup.visible = true
  end if
End Function


'@newIndex : integer, selected index of videopreview choices 0 = On, 1 = Off.
Function checkItemHelper(newIndex, menuItem)
  newContent = menuItem.content.clone(true)

  for i=0 to newContent.getChildCount()-1
    child = newContent.getChild(i)
    if i = newIndex
      child.checked = true
    else
      child.checked = false
    end if
  end for
  menuItem.content = newContent
  menuItem.jumpToItem = newIndex
End Function


Function sendComponentInteractionEventForAutoplayPreview()
  Auth = TubiAuth(m.constants)
  Tracking = TubiTracking(m.constants, Auth)

  leftSideNavComponent = {
    left_nav_section: "ACCOUNT"
  }

  'set initial tracking values
  trackingPageInfo = {
    pageType: "account_page"
    pageValues: {
      account_page_type: "VIDEO_PREVIEW"
    }
  }
  componentInteractionInfo = {
    pageOneof: Tracking.getAnalyticsPage(trackingPageInfo.pagetype, trackingPageInfo.pageValues)
    componentOneof: Tracking.getAnalyticsComponent("left_side_nav_component", leftSideNavComponent)
    user_interaction: "CONFIRM"
  }

  m.top.componentInteractionInfo = componentInteractionInfo
End Function


Function onItemFocusChanged(msg)
  focusIndex = msg.getData()
  focusedContent = m.Menu.content.getChild(focusIndex)
  m.top.audioGuideText = m.instructionsText + " " + focusedContent.title

  'When Autoplay loaded, we are reading the title and description along with the focused menu item.
  'After setting the audio guide text, we are resetting instructionsText back to empty string as we don't need to read the title/description everytime.
  if isNonEmptyString(m.instructionsText) = true
    m.top.audioGuideText = m.instructionsText + " " + focusedContent.title
    m.instructionsText = ""
  else
    m.top.audioGuideText = focusedContent.title
  end if
End Function


Function onAutoPlayTimerItemFocusChanged(msg)
  focusIndex = msg.getData()
  focusedContent = m.AutoPlayTimerMenu.content.getChild(focusIndex)

  if focusedContent <> invalid
    'When Autoplay loaded, we are reading the title and description along with the focused menu item.
    'After setting the audio guide text, we are resetting instructionsText back to empty string as we don't need to read the title/description everytime.
    if isNonEmptyString(m.autoPlayTimerInstructionsText) = true
      m.top.audioGuideText = m.autoPlayTimerInstructionsText + " " + focusedContent.title
      m.autoPlayTimerInstructionsText = ""
    else
      m.top.audioGuideText = focusedContent.title
    end if
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  handled = false
  if press then
    if key = "up"
      if m.AutoPlayTimerMenu.isInFocusChain() = true
        handled = m.Menu.setFocus(true)
      end if
    else if key = "down"
      if m.AutoPlayTimerMenu.isInFocusChain() = false
        handled = m.AutoPlayTimerMenu.setFocus(true)
      end if
    end if
  end if

  return handled
End Function
