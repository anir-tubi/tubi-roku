Function init()
  tubiLog("ScrollingList.init")
  m.top.observeField("width", "onDimensionChange")
  m.top.observeField("height", "onDimensionChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("animateToItem", "onAnimateToItem")
  m.items = m.top.findNode("Items")
  m.focusImage = m.top.findNode("FocusImage")
  m.scrollAnimation = m.top.findNode("ScrollAnimation")
  m.translationInterpolator = m.top.findNode("TranslationInterpolator")
  m.focusInterpolator = m.top.findNode("FocusInterpolator")
  m.focusImageInterpolator = m.top.findNode("FocusImageInterpolator")
  m.focusImageWidthInterpolator = m.top.findNode("FocusImageWidthInterpolator")
  m.focusImageHeightInterpolator = m.top.findNode("FocusImageHeightInterpolator")
  m.unfocusInterpolator = m.top.findNode("UnfocusInterpolator")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.internalItemFocused = m.top.itemFocused  ' separate from event emitter
  m.overlappedKeypress = invalid 'track when a key is pressed during animation
  m.pressAndHold = invalid 'track when a key is being held down without release
  m.focusImage.visible = m.top.isInFocusChain()
End Function

''''''''''''''''''''''
' onAnimateToItem
'
' Callback for 'animateToItem' field
Function onAnimateToItem() As Void
  if m.top.animateToItem >= 0 and m.top.animateToItem < m.items.getChildCount() then
    startChangeFocus(m.top.animateToItem)
  end if
End Function


''''''''''''''''''''''
' onDimensionsChange
'
' Handle changes to 'width' or 'height' fields. Note that this
' does not immediate scroll if the focused item becomes invisible.
' Therefore the 'width' and 'height' should be set before 'content'.
Function onDimensionChange() As Void
  'TODO(Chris): The clipping is quite harsh. Use opacity or mask here
  m.top.clippingRect = [0,0,m.top.width,m.top.height]
End Function


''''''''''''''''''''''
' onContentChange
'
' When 'content' is set, interpret it into 'itemComponentName' items
' for inclusion in the list.
Function onContentChange() As Void
  tubiLog("ScrollingList.onContentChange")
  ' first clear the existing children
  for i=0 to m.items.getChildCount()-1
    m.items.removeChild(i)
  end for

  ' add new children for content
  if m.top.content = invalid then return
  for i=0 to m.top.content.getChildCount()-1
    newItem = CreateObject("roSGNode", m.top.itemComponentName)
    ' may be invalid if itemComponentName incorrectly set
    if newItem <> invalid then
      newItem.content = m.top.content.getChild(i)
      'TODO(Chris): does this id guarantee uniqueness for the animation?
      newItem.id = newItem.content.id
      m.items.appendChild(newItem)
    end if
  end for

  ' Default focus to first item
  startChangeFocus(0)
End Function

''''''''''''''''''''''
' onComponentFocusChange
'
' When focus is gained or lost on this component, notify the
' child items so they can draw or hide something.
Function onComponentFocusChange()
  tubiLog("ScrollingList.onComponentFocusChange")
  if m.top.content <> invalid and m.top.content.getChildCount() > 0 then
    for i=0 to m.items.getChildCount()-1
      m.items.getChild(i).listHasFocus = m.top.isInFocusChain() 
    end for
    ' provide a bump for listeners when focus comes back to this component
    if m.top.isInFocusChain() then
      m.top.itemFocused = m.internalItemFocused
    end if
  end if
  if m.top.isInFocusChain() then
    m.focusImage.visible = true
  else
    m.focusImage.visible = false
  end if
End Function

''''''''''''''''''''''
' onKeyEvent
'
' We want 2 behaviors. First is slow scrolling 
' and the second is "fast" scrolling.  Fast scrolling
' is triggered when a) the user is hitting the button
' repeatedly very quickly, and b) the user has pressed
' and held down the key.
Function onKeyEvent(key As Object, press As Boolean) As Boolean
  tubiLog("ScrollingList.onKeyEvent")

  if press and m.items.getChildCount() <> 0 then
    if m.scrollAnimation.state = "running" then 
      m.overlappedKeypress = key
      return true
    end if
    if key = "OK" and m.scrollAnimation.state = "stopped" then
      m.top.itemSelected = m.internalItemFocused
      return true
    end if
    if scrollList(key) then
      m.pressAndHold = key
      return true
    end if
  else if m.pressAndHold <> invalid then
    m.pressAndHold = invalid
    return true
  end if
  return false
End Function


''''''''''''''''''''''
' scrollList
'
' Process a key press, abstracted from onKeyPress
' so that we can also process delayed key presses
' without affecting the key handling logic
Function scrollList(direction As String)
  if m.top.layoutDirection = "vert" then
    forward = "down"
    backward = "up"
  else if m.top.layoutDirection = "horiz" then
    forward = "right"
    backward = "left"
  end if

  if direction = forward and m.internalItemFocused < (m.top.content.getChildCount() -1) then
    startChangeFocus(m.internalItemFocused + 1)
    return true
  else if direction = backward and m.internalItemFocused > 0 then
    startChangeFocus(m.internalItemFocused - 1)
    return true
  end if
  return false
End Function

''''''''''''''''''''''
' newPositionVertical
'
' Calculate where the content group will scroll to
' in order to make the new focus item visible
Function newPositionVertical(itemRect As Object)
  if (itemRect.y + itemRect.height + m.items.translation[1]) > m.top.height then
    ' scroll up just enough to show the next item
    newPosition = [
      m.items.translation[0]
      m.top.height - itemRect.y - itemRect.height
    ]
  else if (itemRect.y + m.items.translation[1]) < 0 then
    newPosition = [
      m.items.translation[0]
      -itemRect.y
    ]
  else
    newPosition = m.items.translation
  end if
  return newPosition
End Function

''''''''''''''''''''''
' newPositionHorizontal
'
' Calculate where the content group will scroll to
' in order to make the new focus item visible
Function newPositionHorizontal(itemRect As Object)
  if (itemRect.x + itemRect.width + m.items.translation[0]) > m.top.width then
    ' scroll up just enough to show the next item
    newPosition = [
      m.items.translation[1]
      m.top.width - itemRect.x - itemRect.width
    ]
  else if (itemRect.x + m.items.translation[0]) < 0 then
    newPosition = [
      m.items.translation[1]
      -itemRect.x
    ]
  else
    newPosition = m.items.translation
  end if
  return newPosition
End Function


''''''''''''''''''''''
' startChangeFocus
'
' Begin the animations to:
'   1) Unfocus the old item, incrementally
'   2) Focus the new item, incrementally
'   3) Scroll the list as necessary
Function startChangeFocus(newFocusedIndex As Integer) As Void
  unfocusedItem = m.items.getChild(m.internalItemFocused)

  focusedItem = m.items.getChild(newFocusedIndex)
  if focusedItem = invalid then return
  m.internalItemFocused = newFocusedIndex

  itemRect = focusedItem.boundingRect()

  if m.top.layoutDirection = "vert" then
    newPosition = newPositionVertical(itemRect)
  else
    newPosition = newPositionHorizontal(itemRect)
  end if

  ' Start scroll animation
  m.translationInterpolator.key = [ 0.0, 1.0 ]
  m.translationInterpolator.keyvalue = [ m.items.translation, newPosition ]
  m.focusInterpolator.fieldToInterp = + focusedItem.id + ".focusPercent"
  if unfocusedItem <> invalid then
    ' we may have just received content
    m.unfocusInterpolator.fieldToInterp= unfocusedItem.id + ".focusPercent"
  end if
  newFocusImagePosition = [ 
    itemRect.x + newPosition[0]
    itemRect.y + newPosition[1]
  ]
  m.focusImageInterpolator.keyvalue = [ m.focusImage.translation, newFocusImagePosition ]
  m.focusImageWidthInterpolator.keyvalue = [ m.focusImage.width, itemRect.width ]
  m.focusImageHeightInterpolator.keyvalue = [ m.focusImage.height, itemRect.height ]
  m.scrollAnimation.observeField("state", "endChangeFocus")
  m.scrollAnimation.control = "start"
End Function


''''''''''''''''''''''
' endChangeFocus
'
' Animation is done.  If we aren't repeating keys or
' press-and-hold, the send the itemFocused update.
Function endChangeFocus()
  'TODO(Chris): supress this event if another keypress has come in
  if m.scrollAnimation.state = "stopped" then
    m.scrollAnimation.unobserveField("state")
    focusedItem = m.items.getChild(m.internalItemFocused)
    focusedItem.focusPercent = 1.0  ' in case animation didn't set this, force it

    ' emit event only if key events aren't happening, or they're being ignored
    ' because we're at the end of the list
    keyHandled = false
    if m.overlappedKeypress <> invalid then
      keyHandled = scrollList(m.overlappedKeypress)
      m.overlappedKeypress = invalid
    else if m.pressAndHold <> invalid then
      keyHandled = onKeyEvent(m.pressAndHold, true)
    end if

    ' TODO(Chris): be careful here if content has changed
    if not keyHandled and m.internalItemFocused < m.items.getChildCount() then
      m.top.itemFocused = m.internalItemFocused
    end if
  end if
End Function
