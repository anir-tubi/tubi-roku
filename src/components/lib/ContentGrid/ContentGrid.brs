Function init()
  m.top.observeField("width", "onDimensionChange")
  m.top.observeField("height", "onDimensionChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("itemSize", "onItemSizeChange")
  m.top.observeField("numRows", "onContentChange")
  m.top.observeField("numColumns", "onContentChange")
  m.top.observeField("fillDirection", "onContentChange")
  m.contents = m.top.findNode("Contents")
  m.mask = m.top.findNode("ContentsMask")
  m.scrollAnimation = m.top.findNode("ScrollAnimation")
  m.translationInterpolator = m.top.findNode("TranslationInterpolator")
  m.focusBoxInterpolator = m.top.findNode("FocusBoxInterpolator")
  m.focusBox = m.top.findNode("FocusBox")

  ' These are our own actual dimensions of the grid, based on fitting the
  ' supplied content to the numRows and numColumns values. We mostly
  ' use this for focus navigation.
  m.internalNumColumns = 0
  m.internalNumRows = 0

  ' focus handling
  m.internalItemFocused = [-1,-1]   ' this moves immediately, not after animation. This way we
                                  ' can keep track while animation is in process
  m.overlappedKeypress = invalid
  m.pressAndHold = invalid
End Function


''''''''''''''''''''''
' onItemSizeChange
'
' the 9-patch focus image is 13 pixels padding on each side, so we set focus image 
' translation and  width to account for that.
Function onItemSizeChange() As Void
  focusPoster = m.focusBox.findNode("FocusBoxPoster")
  focusPoster.width = m.top.itemSize[0] + 26
  focusPoster.height = m.top.itemSize[1] + 26
End Function


''''''''''''''''''''''
' onDimensionsChange
'
' Sets our scrolling extremeties. We could scroll current focused item
' here but I don't think this will change once it is set. 
Function onDimensionChange() As Void
  'TODO(Chris): The clipping is quite harsh. Use opacity or mask here
  m.mask.clippingRect = [0,0,m.top.width,m.top.height]
End Function


''''''''''''''''''''''
' onComponentFocusChange
'
' Called when the ContentGrid itself has gained/lost focus
'
Function onComponentFocusChange()
  tubiLog("ContentGrid.onComponentFocusChange")
  if m.top.content <> invalid and m.top.content.getChildCount() > 0 and m.top.isInFocusChain() then
    m.focusBox.visible = true
    focusedItem = getGridItemAt(m.internalItemFocused)
    if focusedItem <> invalid then m.top.itemFocused = focusedItem.contentGridIndex
  else
    m.focusBox.visible = false
  end if
End Function


''''''''''''''''''''''
' onContentChange
'
' Map the linear content list to a 2d grid based on numColumns and numRows
'
Function onContentChange() As Void
  tubiLog("ContentGrid.onContentChange")
  ' Remove all existing children except the focus box
  m.contents.removeChildrenIndex(m.contents.getChildCount(), 0)

  content = m.top.content
  if content = invalid or content.getChildCount() = 0 then 
    m.internalItemFocused = -1
    m.itemFocused = -1
    return
  end if
  numItems = content.getChildCount()

  ' Resolve the real grid size
  numRows = m.top.numRows
  numColumns = m.top.numColumns

  if m.top.fillDirection = "W" and numRows > 0
    ' if rows = 0, draw nothing. if rows > 0, expand columns, ignoring numColumns
    numColumns = numItems \ numRows
    if numItems MOD numRows > 0 then numColumns = numColumns + 1
  else if m.top.fillDirection = "Z" and numColumns > 0 then
    numRows = numItems \ numColumns
    if numItems MOD numColumns > 0 then numRows = numRows + 1
  end if

  ' Set dimensions and translation for each item
  x = 0
  y = 0
  rows = m.contents.createChildren(numRows, "Group")
  for i=0 to numItems - 1 
    item = CreateObject("roSGNode", m.top.itemComponentName)
    item.width = m.top.itemSize[0]
    item.height = m.top.itemSize[1]
    item.index = i
    item.visible = true
    item.itemContent = content.getChild(i)  ' may be invalid
    item.translation = [
      x * (m.top.itemSize[0] + m.top.itemSpacing[0])
      y * (m.top.itemSize[1] + m.top.itemSpacing[1])
    ]
    ' store the index into m.top.content to set itemFocus later
    item.addField("contentGridIndex", "integer", false)
    item.contentGridIndex = i
    rows[y].appendChild(item)

    if m.top.fillDirection = "W" then
      y = y + 1
      if y >= numRows then
        x = x + 1
        y = 0
      end if
    else if m.top.fillDirection = "Z" then
      x = x + 1
      if x >= numColumns then
        y = y + 1
        x = 0
      end if
    end if
  end for

  ' Save the real dimensions for focus navigation
  m.internalNumRows = numRows
  m.internalNumColumns = numColumns
  if m.top.isInFocusChain() then m.focusBox.visible = true
  startChangeFocus([0,0])
End Function


'''''''''''''''''
' startChangeFocus
'
' Shift the grid and move the focus box simultaneously
Function startChangeFocus(newFocusedIndex As Object) As Void
  tubiLog("ContentGrid.startChangeFocus")

  'TODO(Chris): This needs to safely fall back to [0,0] or not show focus at all
  focusedItem = getGridItemAt(newFocusedIndex)
  ' focusedItem may be invalid if content changed or we're at an empty spot in the bottom-right of the grid
  if focusedItem = invalid then return
  m.internalItemFocused = newFocusedIndex
  focusedRow = focusedItem.getParent()

  'find out if we need to scroll
  itemRect = focusedItem.boundingRect()    ' for testing X direction
  rowRect = focusedRow.boundingRect() ' for testing Y direction

  ' Vertical scrolling
  if (rowRect.y + rowRect.height + m.contents.translation[1]) > m.top.height then
    newY = m.top.height - rowRect.y - rowRect.height
  else if (rowRect.y + m.contents.translation[1]) < 0 then
    newY = -rowRect.y
  else
    newY = m.contents.translation[1]
  end if

  ' Horizontal scrolling
  if (itemRect.x + itemRect.width + m.contents.translation[0]) > m.top.width then
    newX = m.top.width - itemRect.x - itemRect.width
  else if (itemRect.x + m.contents.translation[0]) < 0 then
    newX = -itemRect.x
  else
    newX = m.contents.translation[0]
  end if

  ' Start scroll animation
  m.translationInterpolator.key=[ 0.0, 1.0 ]
  m.translationInterpolator.keyvalue=[ m.contents.translation, [newX,newY] ]
  m.focusBoxInterpolator.key=[0.0,1.0]
  m.focusBoxInterpolator.keyvalue=[ m.focusBox.translation, [itemRect.x + newX, itemRect.y + newY] ]
  m.scrollAnimation.observeField("state", "endChangeFocus")
  m.scrollAnimation.control = "start"
End Function


''''''''''''''''''''
' endChangeFocus
'
' Runs after focus animation has completed
'
Function endChangeFocus()
  tubiLog("ContentGrid.endChangeFocus")
  if m.scrollAnimation.state = "stopped" then
    m.scrollAnimation.unobserveField("state")

    ' emit event only if key events aren't happening, or they're being ignored
    ' because we're at the end of the list
    keyHandled = false
    if m.overlappedKeypress <> invalid then
      keyHandled = scrollGrid(m.overlappedKeypress)
      m.overlappedKeypress = invalid
    else if m.pressAndHold <> invalid then
      keyHandled = scrollGrid(m.pressAndHold)
    end if

    if not keyHandled then 
      focusedItem = getGridItemAt(m.internalItemFocused)
      if focusedItem <> invalid then m.top.itemFocused = focusedItem.contentGridIndex
    end if
  end if
End Function


''''''''''''''''''''
' onKeyEvent
'
' We want 2 behaviors. First is slow scrolling 
' and the second is "fast" scrolling.  Fast scrolling
' is triggered when a) the user is hitting the button
' repeatedly very quickly, and b) the user has pressed
' and held down the key.
Function onKeyEvent(key As Object, press As Boolean) As Boolean
  tubiLog("ContentGrid.onKeyEvent")

  if press then
    if m.scrollAnimation.state = "running" then 
      m.overlappedKeypress = key
      return true
    end if
    if scrollGrid(key) then
      ' we only do scrolling if its a key that affects the grid
      m.pressAndHold = key
      return true
    else if key = "OK" or key = "play" then
      focused = getGridItemAt(m.internalItemFocused)
      if focused <> invalid then m.top.itemSelected = focused.contentGridIndex
      return true
    end if
  else if m.pressAndHold <> invalid then
    ' only consume the release if we had also processed the press
    m.pressAndHold = invalid
    return true
  end if
  return false
End Function


'''''''''''''
' scrollGrid
'
' Scroll the grid in the direction intended.  This is for handling immediate as well as 
' overlapped key input
'
Function scrollGrid(direction As String) As Boolean
  if direction = "down" and m.internalItemFocused[1] < m.internalNumRows-1 then
    startChangeFocus([m.internalItemFocused[0], m.internalItemFocused[1] + 1])
    return true
  else if direction = "up" and m.internalItemFocused[1] > 0 then
    startChangeFocus([m.internalItemFocused[0], m.internalItemFocused[1] - 1])
    return true
  else if direction = "left" and m.internalItemFocused[0] > 0 then
    startChangeFocus([m.internalItemFocused[0] - 1, m.internalItemFocused[1]])
    return true
  else if direction = "right" and m.internalItemFocused[0] < m.internalNumColumns-1 then
    startChangeFocus([m.internalItemFocused[0] + 1, m.internalItemFocused[1]])
    return true
  else
    return false
  end if
End Function

''''''''''''''''''''
' getGridItemAt
' For a vector [x,y], safely get the item at that location in
' the 2d content grid.
'
Function getGridItemAt(itemIndex As Object)
  if m.contents.getChildCount() > 0 then
    row = m.contents.getChild(itemIndex[1]) 
    if row <> invalid then return row.getChild(itemIndex[0])
  end if
  return invalid  
End Function
