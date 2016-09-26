Function init()
  m.top.observeField("width", "onDimensionChange")
  m.top.observeField("height", "onDimensionChange")
  m.top.observeField("scrollWidth", "onDimensionChange")
  m.top.observeField("scrollHeight", "onDimensionChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("itemSize", "onItemSizeChange")
  m.top.observeField("numRows", "onContentChange")
  m.top.observeField("numColumns", "onContentChange")
  m.top.observeField("fillDirection", "onContentChange")
  m.mask = m.top.findNode("ContentsMask")
  m.scrollAnimation = m.top.findNode("ScrollAnimation")
  m.translationInterpolator = m.top.findNode("TranslationInterpolator")
  m.focusBoxInterpolator = m.top.findNode("FocusBoxInterpolator")
  m.focusBox = m.top.findNode("FocusBox")


  ' m.items is a FIFO cache of components of the type specified in 
  ' m.top.itemComponents.  The cache size is calculated by the visible
  ' window, set by (m.top.width*m.top.height), and accounting for an
  ' overhang set by m.overhang.  Newer entries are added via appendChild()
  ' and older entries are expunged by removeChildIndex(0).
  m.items = m.top.findNode("Items")

  ' These are our own actual dimensions of the grid, based on fitting the
  ' supplied content to the numRows and numColumns values. We mostly
  ' use this for focus navigation.
  m.internalNumColumns = 0
  m.internalNumRows = 0

  ' focus handling
  m.internalItemFocused = [-1,-1]   ' this moves immediately, not after animation. This way we
                                  ' can keep track while animation is in process

  ' If onKeyEvent is called while we are animating focus, overlappedKeypress will contain
  ' that single key value and be processed after the animation ends.  If a second keypress
  ' is encountered, it will be ignored
  m.overlappedKeypress = invalid

  ' Holds the state of a button press.  If a button is released this will be false.  if
  ' the user presses a button and keeps it held down, the focus animations will continue
  ' until the button is released.  The value of this is the key which is held.
  m.pressAndHold = invalid

  ' This is the number of content items outside of the visible window which we
  ' will render.  We want it large enough to 'preload' posters which will
  ' be scrolled into view, but small enough that we aren't taking a performance
  ' hit for rendering too many posters.  
  '
  ' Example: If visible window is 2x2 and overhang = 1, 4x4=16 posters will be rendered.
  m.overhang = 1

  ' For reporting timing to the console
  m.timer = CreateObject("roTimespan")
End Function


''''''''''''''''''''''
' onItemSizeChange
'
' the 9-patch focus image is 7 pixels padding on each side, so we set focus image 
' translation and  width to account for that.
Function onItemSizeChange() As Void
  focusPoster = m.focusBox.findNode("FocusBoxPoster")
  focusPoster.width = m.top.itemSize[0] + 14
  focusPoster.height = m.top.itemSize[1] + 14
End Function


''''''''''''''''''''''
' onDimensionsChange
'
' Sets our scrolling extremeties. We could scroll current focused item
' here but I don't think this will change once it is set. 
Function onDimensionChange() As Void
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
    m.top.itemFocused = gridIndexToItemIndex(m.internalItemFocused)
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

  m.timer.Mark()

  ' Remove all existing children except the focus box
  while m.items.getChildCount() > 0
    m.items.removeChildIndex(0)
  end while

  content = m.top.content
  if content = invalid or content.getChildCount() = 0 then 
    m.internalItemFocused = [-1, -1]
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
  m.internalNumRows = numRows
  m.internalNumColumns = numColumns

  ' preload the visible content, skipping a cache check
  ' for faster visibility of initial content
  loadVisiblePosters(false)

  if m.top.isInFocusChain() then m.focusBox.visible = true

  'print "First content loaded in " + stri(m.timer.TotalMilliseconds()) + " ms"
  startChangeFocus([0,0])
End Function


''''''''''''''''''''''''
' loadVisiblePosters
'
' Determine which content items are in the visible window, then render those in 
' the m.items cache
Function loadVisiblePosters(useCache=true As Boolean)
  m.timer.Mark()
  ' find the visible items by comparing the clipping window to the m.items offset
  ' these are all grid indices, not pixel coords
  x =  -m.items.translation[0] \ (m.top.itemSize[0] + m.top.itemSpacing[0])
  y =  -m.items.translation[1] \ (m.top.itemSize[1] + m.top.itemSpacing[1])
  width =  m.top.width \ (m.top.itemSize[0] + m.top.itemSpacing[0]) + 1 ' always add one so we show overhang
  height =  m.top.height \ (m.top.itemSize[1] + m.top.itemSpacing[1]) + 1

  ' expand to preload a few outside of the visible window
  x = x - m.overhang
  y = y - m.overhang
  width = width + m.overhang * 2
  height = height + m.overhang * 2

  ' cap at the extremeties
  if x < 0 then x = 0
  if y < 0 then y = 0
  if (x + width) > m.internalNumColumns then width = m.internalNumColumns - x
  if (y + height) > m.internalNumRows then height = m.internalNumRows - y

  tubiLog("ContentGrid loading " + stri(width * height) + " visible items")
  for i=x to x+width-1
    for j=y to y+height-1
      index = gridIndexToItemIndex([i,j])
      item = invalid
      if useCache then
        item = m.items.findNode(stri(index))
        if item <> invalid then
          'print "Found cached item " + stri(index)
          m.items.appendChild(item)  ' FIFO, push it to the end
        end if
      end if
      if item = invalid then
        item = createItemComponent(index)
        m.items.appendChild(item)
      end if
    end for
  end for

  ' keep cache size down
  for i=0 to (m.items.getChildCount() - (width * height) - 1)
    m.items.removeChildIndex(0)  ' for each one we add, remove one
  end for

  'print "Visible items resolved in " + stri(m.timer.TotalMilliseconds()) + " ms"
  'print "Item cache has " + stri(m.items.getChildCount()) + " children"
End Function


'''''''''''''''''''''''
' createItemComponent
'
' Create one m.items component for the corresponding m.top.content item, inserting
' it into the cache. If cache size has grown, remove the oldest cache entry.  If
' the item is alread in the cache, reset it's FIFO position and don't create it
' again.
Function createItemComponent(index) As Object
  item = CreateObject("roSGNode", m.top.itemComponentName)
  item.id = stri(index)
  item.width = m.top.itemSize[0]
  item.height = m.top.itemSize[1]
  item.index = index
  item.visible = true
  content = m.top.content
  if content = invalid then return invalid ' could be that content was just changed
  item.itemContent = m.top.content.getChild(index)
  gridIndex = itemIndexToGridIndex(index)
  itemRect = getGridItemRect(gridIndex)
  item.translation = [itemRect.x,itemRect.y]
  'print "Rendering item " + stri(index) + " at [" + str(itemRect.x) + "," + str(itemRect.y) + "]"
  'print "Item " + stri(index) + " has dimensions [" + str(item.width) + "," + str(item.height) + "]"
  'print "Item " + stri(index) + " has uri " + content.portrait
  'print "Item " + stri(index) + " has grid index [" + stri(gridIndex[0]) + "," + stri(gridIndex[1]) + "]"
  return item
End Function


'''''''''''''''''
' startChangeFocus
'
' Shift the grid and move the focus box simultaneously
Function startChangeFocus(newFocusedIndex As Object) As Void
  tubiLog("ContentGrid.startChangeFocus")

  itemIndex = gridIndexToItemIndex(newFocusedIndex)
  ' check out of bounds, avoids scrolling to a missing corner when content is not neatly divible by the row/column span
  if itemIndex >= m.top.content.getChildCount() then
    return 
  end if

  itemRect = getGridItemRect(newFocusedIndex)
  'print "Scrolling to item " +  "[" + str(newFocusedIndex[0]) + "," + str(newFocusedIndex[1]) + "] at [" + str(itemRect.x) + "," + str(itemRect.y) + "]"
  m.internalItemFocused = newFocusedIndex

  ' Vertical scrolling
  vertLimit = m.top.scrollHeight
  if vertLimit = 0 then vertLimit = m.top.height
  if (itemRect.y + itemRect.height + m.items.translation[1]) > vertLimit then
    newY = vertLimit - itemRect.y - itemRect.height
  else if (itemRect.y + m.items.translation[1]) < 0 then
    newY = -itemRect.y
  else
    newY = m.items.translation[1]
  end if

  ' Horizontal scrolling
  horizLimit = m.top.scrollWidth
  if horizLimit = 0 then horizLimit = m.top.width
  if (itemRect.x + itemRect.width + m.items.translation[0]) > horizLimit then
    newX = horizLimit - itemRect.x - itemRect.width
  else if (itemRect.x + m.items.translation[0]) < 0 then
    newX = -itemRect.x
  else
    newX = m.items.translation[0]
  end if

  'print "Scrolling items to [" + str(newX) + "," + str(newY) + "]"

  ' Start scroll animation
  m.translationInterpolator.key=[ 0.0, 1.0 ]
  m.translationInterpolator.keyvalue=[ m.items.translation, [newX,newY] ]
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
      m.top.itemFocused = gridIndexToItemIndex(m.internalItemFocused)
      ' TODO(Chris): This seems to work well enough to only refresh
      '              the poster cache when keypresses have settled. If
      '              we want to be more aggressive, we can move the
      '              loadVisiblePosters() call outside of this if statement.
      loadVisiblePosters()
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
      m.top.itemSelected = gridIndexToItemIndex(m.internalItemFocused)
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
' overlapped key input.
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
' getGridItemRect
'
' Calculate the pixel location of an item within the content grid.
' This is a calculated (theoretical) value, not derived from any existing component
Function getGridItemRect(itemIndex As Object)
  return {
    ' multiply by 1.0 to force a Float, being consistent with ifSGNodeBoundingRect return structures
    x: itemIndex[0] * (m.top.itemSize[0] + m.top.itemSpacing[0]) * 1.0
    y: itemIndex[1] * (m.top.itemSize[1] + m.top.itemSpacing[1]) * 1.0
    width: m.top.itemSize[0] * 1.0
    height: m.top.itemSize[1] * 1.0
  }
End Function


'''''''''''''''''''''''''
' itemIndexToGridIndex
'
' Convert a scalar m.top.content index to a 2d array 
' index into the content grid.
Function itemIndexToGridIndex(index As Integer) As Object
  if m.top.fillDirection = "W" then
    x = index \ m.internalNumRows
    y = index MOD m.internalNumRows
  else if m.top.fillDirection = "Z" then
    x = index MOD m.internalNumColumns
    y = index \ m.internalNumColumns
  end if
  return [x,y]
End Function


''''''''''''''''''''''''''
' gridIndexToItemIndex
'
' Convert a 2d array content grid index into a scalar
' index into m.top.content
Function gridIndexToItemIndex(itemIndex As Object) As Integer
  if m.top.fillDirection = "W" then
    return (itemIndex[0]*m.internalNumRows + itemIndex[1])
  else if m.top.fillDirection = "Z" then
    return (itemIndex[1]*m.internalNumColumns + itemIndex[0])
  end if
End Function
