Function init()
  ' set up the specifics to make this markupGrid a number pad
  m.Foreground = m.top.findNode("NumberPadForegroundRowlist")
  m.Background = m.top.findNode("NumberPadBackgroundRowlist")
  m.Foreground.itemComponentName = "NumberPadGridItem"
  m.Background.itemComponentName = "NumberPadGridItem"
  m.Foreground.itemSize = [483, 96]
  m.Background.itemSize = [483, 96]
  m.Foreground.rowItemSize = [
    [159, 96]
    [159, 96]
    [159, 96]
    [240, 96]
  ]
  m.Background.rowItemSize = [
    [159, 96]
    [159, 96]
    [159, 96]
    [240, 96]
  ]
  m.Foreground.numRows = 4
  m.Background.numRows = 4
  m.Foreground.rowSpacings = [3]
  m.Background.rowSpacings = [3]
  m.Foreground.itemSpacing = [0, 3]
  m.Background.itemSpacing = [0, 3]
  m.Foreground.rowItemSpacing = [[3, 3]]
  m.Background.rowItemSpacing = [[3, 3]]

  m.Foreground.vertFocusAnimationStyle = "floatingFocus"

  if m.global.constants.deviceInfo.scaledUi = true
    m.Foreground.focusBitmapUri = "pkg://images/menu-focus-hd.9.png"
  else
    m.Foreground.focusBitmapUri = "pkg://images/menu-focus-hd.9.png"
  end if
  m.Foreground.focusBitmapBlendColor = m.global.theme.focused
  m.Foreground.drawFocusFeedbackOnTop = false

  m.Background.drawFocusFeedback = false

  m.Foreground.observeField("rowItemSelected", "onRowItemSelected")
  m.top.observeField("focusedChild", "onComponentFocusedChange")

  m.top.observeField("moveFocusToDelete", "onMoveFocusToDelete")

  foregroundButtons = createForegroundButtons()
  backgroundButtons = createBackgroundButtons()
  m.Foreground.content = foregroundButtons
  m.Background.content = backgroundButtons
End Function


Function onComponentFocusedChange()

  if m.top.hasFocus() = true
    m.Foreground.setFocus(true)
  end if

End Function


Function onMoveFocusToDelete()

  if m.top.moveFocusToDelete = true
    m.Foreground.jumpToRowItem = [3,1] ' sets the focus to "back/delete" button on numberpad
    m.Foreground.setFocus(true)
  end if

End Function


Function createForegroundButtons()
  return createButtons(true)
End Function

Function createBackgroundButtons()
  return createButtons(false)
End Function


Function createButtons(isForeground = true)
  parent = CreateObject("roSGNode", "ContentNode")

  for i=0 to 8
    if i MOD 3 = 0
      row = parent.createChild("ContentNode")
    end if
    
    child = row.createChild("ContentNode")
    child.id = (i + 1).toStr()

    if isForeground = true
      child.title = (i + 1).toStr()
    end if
  end for

  row = parent.createChild("ContentNode")

  zero = row.createChild("ContentNode")
  zero.id = "0"
  back = row.createChild("ContentNode")
  back.id = "back"

  if isForeground = true
    zero.title = "0"
    back.title = "back"
  end if

  return parent
End Function


Function onRowItemSelected(msg)
  pad = msg.getRoSGNode()
  itemIndex = msg.getData()
  itemRowIndex = itemIndex[0]
  itemColIndex = itemIndex[1]

  row = pad.content.getChild(itemRowIndex)
  item = row.getChild(itemColIndex)

  if item <> invalid
    m.top.buttonSelected = item.title
  end if
End Function


