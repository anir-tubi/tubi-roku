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
  m.Menu = m.top.findNode("AutoplayPreviewMenu")
  m.Menu.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.Menu.focusBitmapBlendColor = theme.focusedColor
  end if
  ' Adding a transparent 1px image since leaving it empty causes roku to use it's default.
  ' We do not want to show unfocused background as per designs.
  m.Menu.focusFootprintBitmapUri = "pkg:/images/transparent.png"

  m.Menu.observeFieldScoped("itemFocused", "onItemFocusChanged")

  'm.instructionsText is used to store the title and description of autoplay previews  for screen reader when screen loaded.
  m.instructionsText = ""

  setAutoplayPreviewChoices()
  m.Spinner = m.top.findNode("Spinner")
  checkItemHelper(m.top.selectItem)
End Function


Function setAutoplayPreviewChoices()
  Title = m.top.findNode("Title")
  Title.text = getTranslation("screenSettings_menu_autoplayPreview")
  Instructions = m.top.findNode("Instructions")
  Instructions.text = getTranslation("screenSettings_autoplayPreview_instructions")

  m.instructionsText = Title.text + " " + Instructions.text

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

End Function


Function onComponentFocus()
  if m.top.isInFocusChain() = true AND m.top.hasFocus() = true
    m.Menu.setFocus(true)
    sendComponentInteractionEventForAutoplayPreview()
  end if
End Function


Function onSelectItem()
  tubiLog("AutoplayPreviewPanel.onSelectItem")
  checkItemHelper(m.top.selectItem)
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
Function checkItemHelper(newIndex)
  newContent = m.Menu.content.clone(true)

  for i=0 to newContent.getChildCount()-1
    child = newContent.getChild(i)
    if i = newIndex
      child.checked = true
    else
      child.checked = false
    end if
  end for
  m.Menu.content = newContent
  m.Menu.jumpToItem = newIndex
End Function


Function sendComponentInteractionEventForAutoplayPreview()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  Tracking = TubiTracking(m.constants, Request, Auth)

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
