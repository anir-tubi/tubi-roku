Function init()
  m.top.width = 1034
  m.top.focusable = true
  m.top.hasNextPanel = false
  m.top.leftOnly = false
  m.top.selectButtonMovesPanelForward = true
  m.top.observeField("focusedChild", "onComponentFocus")
  m.top.observeField("selectItem", "onSelectItem")
  m.top.observeField("isLoading", "onIsLoading")
  m.top.observeField("isUserInMultiAccount", "onIsUserInMultiAccount")
  m.top.observeField("hideDescription", "onHideDescription")
  m.top.observeField("showPCForKids", "onShowPCForKids")
  m.top.observeField("hasPin", "updatePinButtonText")
  m.top.observeField("showPinLayout", "onShowPinLayout")

  m.Title = m.top.findNode("Title")
  m.Instructions = m.top.findNode("Instructions")
  m.contentGroup = m.top.findNode("ContentGroup")
  m.Menu = m.top.findNode("ParentalControlsMenu")
  m.constants = getConstantsFromGlobal()
  m.pinLabel = m.top.findNode("PinLabel")
  m.pinDescription = m.top.findNode("PinDescription")
  m.pinButton = m.top.findNode("PinButton")
  m.pinLayout = m.top.findNode("PinLayout")

  m.pinLabel.text = getTranslation("screenSettings_parentalControls_pinLabel")
  m.pinDescription.text = getTranslation("screenSettings_parentalControls_pinDescription")



  'hide Teens option for nz & uk region
  if isOneTrustConsentEnabled() = true
    removeTeensOption()
  end if

  m.Menu.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"
  m.Menu.observeFieldScoped("itemFocused", "onItemFocusChanged")
  m.Menu.observeFieldScoped("itemSelected", "onItemSelectedChanged")

  'm.instructionsText is used to store the title and description of parental controls for screen reader when screen loaded.
  m.instructionsText = ""

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.Menu.focusBitmapBlendColor = theme.focusedColor
    m.Menu.focusFootprintBlendColor = theme.neutralColor
    m.Title.color = theme.primaryTextColor
    m.Instructions.color = theme.primaryTextColor
  end if

  ' Adding a transparent 1px image since leaving it empty causes roku to use it's default.
  ' We do not want to show unfocused background as per designs.
  m.Menu.focusFootprintBitmapUri = "pkg:/images/transparent.png"

  if isUserInMultiAccount() = true
    m.isUserInMultiAccount = true
    m.isPinLayoutPresent = true
  else
    m.isUserInMultiAccount = false
    'remove pin layout if not in multi account
    m.contentGroup.removeChild(m.pinLayout)
    m.isPinLayoutPresent = false
  end if
  setMenuItemComponent()

  m.Spinner = m.top.findNode("Spinner")
  checkItemHelper(m.top.selectItem)
End Function


Function setParentalControlStringsForMultiUser(kidsMode = false)

  m.Title.text = getTranslation("screenSettings_menu_contentSettings")
  if kidsMode = true
    m.Instructions.text = getTranslation("screenSettings_parentalControls_kids_instructions")
  else
    m.Instructions.text = getTranslation("screenSettings_parentalControls_instructions")
  end if

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.Title, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.Instructions, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.PinLabel, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.PinDescription, typographyConstants.ids.bodyMedium)

  m.instructionsText = m.Title.text + " " + m.Instructions.text

  nWidestWidth = 0
  newContent = createObject("roSGNode", "ContentNode")
  pcValues = m.constants.serverValues.parentalControls
  if kidsMode = true
    m.pcDisplayOrder = [pcValues[4], pcValues[0], pcValues[1], pcValues[5]]
    addOrRemovePinLayout(false)
  else
    m.pcDisplayOrder = [pcValues[4], pcValues[0], pcValues[1], pcValues[5], pcValues[2], pcValues[3]]
    addOrRemovePinLayout(true)
  end if

  for each item in m.pcDisplayOrder
    child = createObject("roSGNode", "CheckButtonContentNode")
    sText = getTranslation("screenSettings_contentSetting_" + item)
    child.addField("contentRatings", "array", false)
    child.contentRatings = m.constants.ui.ratings[item]
    child.title = sText
    child.id = item

    checkBtn = CreateObject("roSGNode", "ContentSettingCheckButton")
    btnContent = CreateObject("roSGNode", "CheckButtonContentNode")
    btnContent.addField("contentRatings", "array", false)
    btnContent.contentRatings = m.constants.ui.ratings[item]
    btnContent.title = sText
    checkBtn.itemContent = btnContent

    if checkBtn.calculatedWidth > nWidestWidth
      nWidestWidth = checkBtn.calculatedWidth
    end if

    newContent.appendChild(child)
  end for
  m.Menu.itemSize = [nWidestWidth, m.Menu.itemSize[1]]
  m.Menu.content = invalid
  m.Menu.content = newContent

End Function


Function setParentalControlStrings()
  m.Title.text = getTranslation("screenSettings_menu_parentalControls")
  m.Instructions.text = getTranslation("screenSettings_parentalControls_instructions")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.Title, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.Instructions, typographyConstants.ids.bodyMedium)

  m.instructionsText = m.Title.text + " " + m.Instructions.text

  nWidestWidth = 0
  newContent = m.Menu.content.clone(true)
  for i = 0 to newContent.getChildCount() - 1
    child = newContent.getChild(i)
    sText = getTranslation("screenSettings_parentalControls_group_" + child.id)
    child.title = sText

    '//Temporarily create checkbuttons for each button text to find the largest width necessary for the set of buttons,
    '//   in order to determine how wide m.Menu should be.
    '//   Different languages may make the text wider than usual so we need to ensure the button displays the full text
    checkBtn = CreateObject("roSGNode", "CheckButton")
    btnContent = CreateObject("roSGNode", "CheckButtonContentNode")
    btnContent.title = sText
    checkBtn.itemContent = btnContent
    if checkBtn.calculatedWidth > nWidestWidth
      nWidestWidth = checkBtn.calculatedWidth
    end if
  end for
  m.Menu.itemSize = [nWidestWidth, m.Menu.itemSize[1]]

  m.Menu.content = newContent
End Function


Function removeTeensOption()
  teensGroup = m.top.findNode("Teens")
  m.Menu.content.removeChild(teensGroup)
End Function


Function onComponentFocus()
  if m.top.isInFocusChain() AND m.top.hasFocus()
    m.Menu.setFocus(true)
  end if
End Function

Function onSelectItem()
  tubiLog("ParentalControlsPanel.onSelectItem")
  checkItemHelper(m.top.selectItem)
End Function


Function onIsLoading()
  tubiLog("ParentalControlsPanel.onIsLoading")
  if m.top.isLoading = true
    m.Spinner.visible = true
    m.contentGroup.visible = false
  else
    m.Spinner.visible = false
    m.contentGroup.visible = true
  end if
End Function


Function checkItemHelper(newIndex)
  newContent = m.Menu.content.clone(true)



  if m.isUserInMultiAccount = true
    pcValue = m.constants.serverValues.parentalControls[newIndex]
    lastIndex = newContent.getChildCount() - 1
    jumpToIndex = lastIndex
    for i = 0 to lastIndex
      child = newContent.getChild(i)
      if child.id = pcValue
        jumpToIndex = i
        child.checked = true
      else
        child.checked = false
      end if
    end for
    m.Menu.content = newContent
    m.Menu.jumpToItem = jumpToIndex
  else 'single user old mode
    'default focus to Adult
    if newIndex >= newContent.getChildCount()
      newIndex = newContent.getChildCount() - 1
    end if
    for i = 0 to newContent.getChildCount() - 1
      child = newContent.getChild(i)
      if i = newIndex
        child.checked = true
      else
        child.checked = false
      end if
    end for
    m.Menu.content = newContent
    m.Menu.jumpToItem = newIndex
  end if

End Function


Function onItemFocusChanged(msg)
  focusIndex = msg.getData()
  focusedContent = m.Menu.content.getChild(focusIndex)
  m.top.audioGuideText = m.instructionsText + " " + focusedContent.title

  'When parental controls loaded, we are reading the title and description along with the focused menu item.
  'After setting the audio guide text, we are resetting back to empty string as we don't need to read the title/description everytime.
  if isNonEmptyString(m.instructionsText) = true
    m.top.audioGuideText = m.instructionsText + " " + focusedContent.title
    m.instructionsText = ""
  else
    m.top.audioGuideText = focusedContent.title
  end if
End Function


Function onItemSelectedChanged(msg)
  selectedIndex = msg.getData()
  selectedContent = m.Menu.content.getChild(selectedIndex)

  if m.isUserInMultiAccount = true
    index = 0
    if selectedContent <> invalid
      for each item in m.constants.serverValues.parentalControls
        if item = selectedContent.id
          m.top.itemSelected = index
          exit for
        end if
        index++
      end for
    end if
  else
    ' Creating a mapping for parental rating id has key.
    parentalRatingMapping = {
      LittleKids: 0
      OlderKids: 1
      Teens: 2
      Adults: 3
    }

    if selectedContent <> invalid
      m.top.itemSelected = parentalRatingMapping[selectedContent.id]
    end if
  end if

End Function


Function onIsUserInMultiAccount(msg = invalid)
  if msg <> invalid AND msg.getData() <> m.isUserInMultiAccount
    m.isUserInMultiAccount = msg.getData()

    setMenuItemComponent()
  end if
End Function


Function setMenuItemComponent()
  if m.isUserInMultiAccount = true
    m.Menu.itemComponentName = "ContentSettingCheckButton"
    setParentalControlStringsForMultiUser()
  else
    m.Menu.itemComponentName = "CheckButton"
    setParentalControlStrings()
  end if
End Function


Function onHideDescription(msg)
  hideDescription = msg.getData()
  if hideDescription = true
    m.contentGroup.removeChild(m.Instructions)
  else
    if m.Instructions.getParent() = invalid
      m.contentGroup.appendChild(m.Instructions)
    end if
  end if
End Function


Function onShowPCForKids(msg)
  setKidsMode = msg.getData()
  if setKidsMode = true
    setParentalControlStringsForMultiUser(true)
  else
    setParentalControlStringsForMultiUser(false)
  end if
End Function


Function onShowPinLayout(msg)
  showPinLayout = msg.getData()
  if showPinLayout = true
    addOrRemovePinLayout(true)
  else
    addOrRemovePinLayout(false)
  end if
End Function


Function addOrRemovePinLayout(addPinLayout = true)

  if addPinLayout = true
    updatePinButtonText()

    if m.pinLayout.getParent() = invalid
      m.contentGroup.appendChild(m.pinLayout)
      m.isPinLayoutPresent = true
    end if
  else
    m.contentGroup.removeChild(m.pinLayout)
    m.isPinLayoutPresent = false
  end if
End Function


Function onKeyEvent(key, press) as Boolean
  if press = true
    if key = "up"
      if m.isPinLayoutPresent = true AND m.pinButton.isInFocusChain() = true
        m.Menu.setFocus(true)

        return true
      end if
    else if key = "down"
      if m.isPinLayoutPresent = true AND m.Menu.isInFocusChain() = true
        m.pinButton.setFocus(true)

        return true
      end if
    end if
  end if
  return false
End Function


Function updatePinButtonText()
  if m.pinButton <> invalid
    if m.top.hasPin = false
      m.pinButton.text = getTranslation("screenSettings_contentSettings_create_pinLabel")
    else
      m.pinButton.text = getTranslation("screenSettings_contentSettings_edit_pinLabel")
    end if
  end if
End Function