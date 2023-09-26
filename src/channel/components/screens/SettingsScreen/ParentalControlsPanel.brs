Function init()
  m.top.width = 1034
  m.top.focusable = true
  m.top.hasNextPanel = false
  m.top.leftOnly = false
  m.top.selectButtonMovesPanelForward = true
  m.top.observeField("focusedChild", "onComponentFocus")
  m.top.observeField("selectItem", "onSelectItem")
  m.top.observeField("isLoading", "onIsLoading")
  m.ContentGroup = m.top.findNode("ContentGroup")
  m.Menu = m.top.findNode("ParentalControlsMenu")

  'hide Teens option for nz & uk region
  if isGDPR() = true
    removeTeensOption()
  end if

  m.Menu.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"
  m.Menu.observeFieldScoped("itemFocused", "onItemFocusChanged")

  'm.instructionsText is used to store the title and description of parental controls for screen reader when screen loaded.
  m.instructionsText = ""

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.Menu.focusBitmapBlendColor = theme.focusedColor
  end if
  ' Adding a transparent 1px image since leaving it empty causes roku to use it's default.
  ' We do not want to show unfocused background as per designs.
  m.Menu.focusFootprintBitmapUri = "pkg:/images/transparent.png"
  setParentalControlStrings()
  m.Spinner = m.top.findNode("Spinner")
  checkItemHelper(m.top.selectItem)
End Function


Function setParentalControlStrings()
  Title = m.top.findNode("Title")
  Title.text = getTranslation("screenSettings_menu_parentalControls")
  Instructions = m.top.findNode("Instructions")
  Instructions.text = getTranslation("screenSettings_parentalControls_instructions")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(Title, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(Instructions, typographyConstants.ids.bodyMedium)

  m.instructionsText = Title.text + " " + Instructions.text

  nWidestWidth = 0
  newContent = m.Menu.content.clone(true)
  for i=0 to newContent.getChildCount()-1
    child = newContent.getChild(i)
    sText = getTranslation("screenSettings_parentalControls_group_" + child.id)
    child.title = sText

    '//Temporarily create checkbuttons for each button text to find the largest width necessary for the set of buttons,
    '//   in order to determine how wide m.Menu should be.
    '//   Different languages may make the text wider than usual so we need to ensure the button displays the full text
    checkBtn = CreateObject("roSGNode", "CheckButton")
    btnContent =  CreateObject("roSGNode", "CheckButtonContentNode")
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
    m.ContentGroup.visible = false
  else
    m.Spinner.visible = false
    m.ContentGroup.visible = true
  end if
End Function


Function checkItemHelper(newIndex)
  newContent = m.Menu.content.clone(true)

  'default focus to Adult
  if newIndex >= newContent.getChildCount()
    newIndex = newContent.getChildCount()-1
  end if

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
