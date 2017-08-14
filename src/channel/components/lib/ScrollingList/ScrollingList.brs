Function init()
  tubiLog("ScrollingList.init")
  m.top.observeField("width", "onDimensionChange")
  m.top.observeField("height", "onDimensionChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("animateToItem", "onAnimateToItem")
  m.top.observeField("focusAbove", "onFocusAboveChange")
  m.items = m.top.findNode("Items")
  m.focusImage = m.top.findNode("FocusImage")
  m.scrollAnimation = m.top.findNode("ScrollAnimation")
  m.scrollAnimation.observeField("state", "endChangeFocus")
  m.translationInterpolator = m.top.findNode("TranslationInterpolator")
  m.focusInterpolator = m.top.findNode("FocusInterpolator")
  m.focusImageInterpolator = m.top.findNode("FocusImageInterpolator")
  m.focusImageWidthInterpolator = m.top.findNode("FocusImageWidthInterpolator")
  m.focusImageHeightInterpolator = m.top.findNode("FocusImageHeightInterpolator")
  m.unfocusInterpolator = m.top.findNode("UnfocusInterpolator")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.internalItemFocused = m.top.itemFocused  ' separate from event emitter
  m.pressAndHold = invalid 'track when a key is being held down without release
End Function

''''''''''''''''''''''
' onAnimateToItem
'
' Callback for 'animateToItem' field
Function onAnimateToItem() As Void
  tubiLog("ScrollingList.animateToItem " + stri(m.top.animateToItem))
  if m.top.animateToItem < m.items.getChildCount() then
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
' onFocusAboveChange
'
Function onFocusAboveChange()
  if m.top.focusAbove then
    m.top.appendChild(m.focusImage)  ' set z order to last
  else
    m.top.insertChild(0, m.focusImage)
  end if
End Function


''''''''''''''''''''''
' onContentChange
'
' When 'content' is set, interpret it into 'itemComponentName' items
' for inclusion in the list.
Function onContentChange() As Void
  tubiLog("ScrollingList.onContentChange")

  ' try to reuse existing children, or create new children in one call
  oldNumItems = m.items.getChildCount()
  if m.top.content = invalid
    newNumItems = 0
  else
    newNumItems = m.top.content.getChildCount()
  end if

  ' add or remove children as necessary
  if newNumItems > oldNumItems
    for i=0 to (newNumItems - oldNumItems)-1
      m.items.createChild(m.top.itemComponentName)
    end for
  else if newNumItems < oldNumItems
    for i=oldNumItems-1 to newNumItems step -1
      m.items.removeChildIndex(i)
    end for
  end if

  ' early out if there are no items.  This mimics the behavior of internal components, where
  ' itemFocused and other fields are left with the last value rather than reset to, e.g., -1
  if m.top.content = invalid or m.top.content.getChildCount() = 0 then 
    m.focusImage.visible = false
    return
  end if

  nextItemPosition = 0
  for i=0 to m.top.content.getChildCount()-1
    newItem = m.items.getChild(i)
    ' may be invalid if itemComponentName incorrectly set
    if newItem <> invalid then
      newItem.content = m.top.content.getChild(i)
      ' may be invalid if component doesn't have a 'content' field
      if (newItem.id = invalid or newItem.id = "") and newItem.content <> invalid then
        newItem.id = newItem.content.id
      end if

      ' listHasFocus should default to "false" for itemComponent types
      if m.top.isInFocusChain() then
        newItem.listHasFocus = true
      end if

      if m.top.itemSpacings.count() = 0 then
        spacing = 0
      else
        spacing = m.top.itemSpacings[i \ m.top.itemSpacings.count()]
      end if

      itemRect = newItem.boundingRect()
      if m.top.layoutDirection = "horiz" then
        x = nextItemPosition
        y = 0
          nextItemPosition = nextItemPosition + itemRect.width + m.top.itemSpacings[i MOD m.top.itemSpacings.count()]
      else
        x = 0
        y = nextItemPosition
        nextItemPosition = nextItemPosition + itemRect.height + m.top.itemSpacings[i MOD m.top.itemSpacings.count()]
      end if

      newItem.translation = [x,y]
    end if
  end for

  ' Default focus to first item
  if m.internalItemFocused = -1 then
    focus = 0
  else if m.internalItemFocused >= m.top.content.getChildCount() then
    focus = m.top.content.getChildCount()-1
  else
    ' content for the item may have changed, so go through the animations to get focusPercent set right
    focus = m.internalItemFocused
  end if
  itemRect = m.items.getChild(focus).boundingRect()
  m.focusImage.width = itemRect.width
  m.focusImage.height = itemRect.height
  startChangeFocus(focus)
End Function

''''''''''''''''''''''
' onComponentFocusChange
'
' When focus is gained or lost on this component, notify the
' child items so they can draw or hide something.
Function onComponentFocusChange()
 tubiLog("ScrollingList.onComponentFocusChange " + focusState(m.top))
  if m.top.content <> invalid and m.top.content.getChildCount() > 0 then
    ' inform all children of focus change, in case they need to respond to it
    for i=0 to m.items.getChildCount()-1
      m.items.getChild(i).listHasFocus = m.top.isInFocusChain() 
    end for
    ' provide a bump for listeners when focus comes back to this component. 
    ' DON'T do it if there is a focus change in progress.  The itemFocused
    ' event will emit on the end of the animation.
    if m.top.hasFocus() and m.scrollAnimation.state = "stopped" then
      m.top.itemFocused = m.internalItemFocused
    end if
  end if
  if m.top.isInFocusChain() and m.items.getChildCount() > 0 and m.scrollAnimation.state = "stopped" then
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
  else
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
  vertLimit = m.top.scrollHeight
  if vertLimit = 0 then vertLimit = m.top.height
  if (itemRect.y + itemRect.height + m.items.translation[1]) > vertLimit then
    ' scroll up just enough to show the next item
    newPosition = [
      m.items.translation[0]
      vertLimit - itemRect.y - itemRect.height
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
  horizLimit = m.top.scrollWidth
  if horizLimit = 0 then horizLimit = m.top.width
  if (itemRect.x + itemRect.width + m.items.translation[0]) > horizLimit then
    ' scroll up just enough to show the next item
    newPosition = [
      m.items.translation[1]
      horizLimit - itemRect.x - itemRect.width
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
  tubiLog("ScrollingList.startChangeFocus")

  ' Stop any currently running animations.  This affects target components immediately so their 
  ' animated field values can be used throughout the rest of this function.
  if m.scrollAnimation.state = "running" then m.scrollAnimation.control = "finish"

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
  if unfocusedItem <> invalid and unfocusedItem.focusPercent <> 0.0
    ' we may have just received content
    m.unfocusInterpolator.fieldToInterp = unfocusedItem.id + ".focusPercent"
  else
    m.unfocusInterpolator.fieldToInterp = ""
  end if
  newFocusImagePosition = [ 
    itemRect.x + newPosition[0]
    itemRect.y + newPosition[1]
  ]
  m.focusImageInterpolator.keyvalue = [ m.focusImage.translation, newFocusImagePosition ]
  m.focusImageWidthInterpolator.keyvalue = [ m.focusImage.width, itemRect.width ]
  m.focusImageHeightInterpolator.keyvalue = [ m.focusImage.height, itemRect.height ]
  ' 2-speed scroll here.  If the duration is fast, the user will have a hard time making single item focus changes because
  ' scrolling will kick in too quickly.  So we only use the custom focus duration value after at least one normal-speed focus
  ' change.
  if m.pressAndHold = invalid and m.top.focusChangeDuration < 0.25
    m.scrollAnimation.duration = 0.25
  else
    m.scrollAnimation.duration = m.top.focusChangeDuration
  end if
  m.scrollAnimation.control = "start"

  ' send out a pre-focus trigger in case observers want to react early to focus change
  m.top.preItemFocused = m.internalItemFocused
End Function


''''''''''''''''''''''
' endChangeFocus
'
' Animation is done.  If we aren't repeating keys or
' press-and-hold, the send the itemFocused update.
Function endChangeFocus()
  tubiLog("ScrollingList.endChangeFocus")
  if m.scrollAnimation.state = "stopped" then
    focusedItem = m.items.getChild(m.internalItemFocused)
    if focusedItem <> invalid then
      focusedItem.focusPercent = 1.0  ' in case animation didn't set this, force it
    end if

    ' may be invisible there was no content previously
    if m.top.isInFocusChain() then m.focusImage.visible = true

    ' emit event only if key events aren't happening, or they're being ignored
    ' because we're at the end of the list
    keyHandled = false
    if m.pressAndHold <> invalid then
      keyHandled = onKeyEvent(m.pressAndHold, true)
    end if

    ' TODO(Chris): be careful here if content has changed
    if not keyHandled and focusedItem <> invalid then
      m.top.itemFocused = m.internalItemFocused
    end if
  end if
End Function
