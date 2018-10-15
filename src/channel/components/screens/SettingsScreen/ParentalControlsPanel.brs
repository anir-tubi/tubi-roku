Function init()
  m.top.width = 1034
  m.top.focusable = true
  m.top.hasNextPanel = false
  m.top.leftOnly = false
  m.top.createNextPanelOnItemFocus = false
  m.top.selectButtonMovesPanelForward = true
  m.top.observeField("focusedChild", "onComponentFocus")
  m.top.observeField("selectItem", "onSelectItem")
  m.top.observeField("isLoading", "onIsLoading")
  m.ContentGroup = m.top.findNode("ContentGroup")
  m.Instructions = m.top.findNode("Instructions")
  text =  "Please select the appropriate viewing age for Tubi TV. Your "
  text += "selection will determine which movie and show ratings you can view "
  text += "in the app. If this selection is changed, you will be required to "
  text += "enter your account password."
  m.Instructions.text = text
  m.Menu = m.top.findNode("ParentalControlsMenu")
  m.Menu.focusBitmapUri = "pkg:/images/menu-focus-fhd.9.png"
  m.Menu.focusFootprintBitmapUri = "pkg:/images/menu-footprint-fhd.9.png"
  if m.global.constants.deviceInfo.scaledUi = true
    m.Menu.focusBitmapUri = "pkg:/images/menu-focus-hd.9.png"
    m.Menu.focusFootprintBitmapUri = "pkg:/images/menu-footprint-hd.9.png"
  end if
  m.Spinner = m.top.findNode("Spinner")
  checkItemHelper(m.top.selectItem)
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
