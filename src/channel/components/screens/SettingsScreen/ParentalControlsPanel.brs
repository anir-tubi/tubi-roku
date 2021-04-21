Function init()
  m.constants = m.global.constants
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
  m.Menu.focusBitmapUri = "pkg:/images/menu-focus-fhd.9.png"
  m.Menu.focusBitmapBlendColor = m.global.theme.focused
  m.Menu.focusFootprintBitmapUri = "pkg:/images/menu-footprint-fhd.9.png"
  if m.constants.deviceInfo.scaledUi = true
    m.Menu.focusBitmapUri = "pkg:/images/menu-focus-hd.9.png"
    m.Menu.focusFootprintBitmapUri = "pkg:/images/menu-footprint-hd.9.png"
  end if

  setParentalControlStrings()
  m.Spinner = m.top.findNode("Spinner")
  checkItemHelper(m.top.selectItem)
End Function



Function getRatingStrings(nRatingIndex)
  sRatingsReturn = ""
  countryCode = m.constants.deviceInfo.countryCode

  aRatings = m.constants.ui.ratings[countryCode]

  if aRatings = invalid
    aRatings = m.constants.ui.ratings["US"]
  end if

  if aRatings <> invalid and aRatings[nRatingIndex] <> invalid
    sRatingsReturn = aRatings[nRatingIndex]
  end if
  return sRatingsReturn 
End Function


Function setParentalControlStrings()
  Title = m.top.findNode("Title")
  Title.text = getTranslation("screenSettings_menu_parentalControls")
  Instructions = m.top.findNode("Instructions")
  Instructions.text = getTranslation("screenSettings_parentalControls_instructions")

  nWidestWidth = 0
  newContent = m.Menu.content.clone(true)
  for i=0 to newContent.getChildCount()-1
    child = newContent.getChild(i)
    sRatings = getRatingStrings(i)
    sText = getTranslation("screenSettings_parentalControls_group" + i.toStr(), {ratings: sRatings})
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
    checkBtn = invalid
  end for 
  m.Menu.itemSize = [nWidestWidth, m.Menu.itemSize[1]]

  m.Menu.content = newContent

End Function



Function onComponentFocus()
 if m.top.isInFocusChain() and m.top.hasFocus()
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
