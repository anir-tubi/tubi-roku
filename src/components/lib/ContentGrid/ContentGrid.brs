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
  m.top.observeField("visible", "onVisibleChange")
  m.top.observeField("animateToItem", "onAnimateToItem")
  m.top.observeField("itemComponentName", "onItemComponentNameChange")
  m.mask = m.top.findNode("ContentsMask")
  m.scrollAnimation = m.top.findNode("ScrollAnimation")
  m.scrollAnimation.observeField("state", "endChangeFocus")
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
  m.numItems = 0  ' cached for performance

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

  constants = m.global.constants  ' minor performance improvement by not referencing m.global twice

  ' This is the number of content items outside of the visible window which we
  ' will render.  We want it large enough to 'preload' posters which will
  ' be scrolled into view, but small enough that we aren't taking a performance
  ' hit for rendering too many posters.  
  '
  ' Example: If visible window is 2x2 and overhang = 1, 4x4=16 posters will be rendered.
  m.overhang = constants.performance.contentGrid.overhang

  ' Send cursor events during scrolling or only when scrolling stops and item is focused
  m.continuousEvents = constants.performance.contentGrid.continuousEvents

  m.itemPool = createNodePool(m.top.itemComponentName, 0)
End Function

Function onItemComponentNameChange()
  m.itemPool = createNodePool(m.top.itemComponentName, 0)
  ' we have to recalculate all the internal dimensions and recreate all children
  onContentChange()
End Function

' Remove an item from its parent and return it to the free pool
' TODO(Chris): Should the NodePool mixin remove from parent?
Function removeAndRelease(item As Object)
  m.items.removeChild(item)
  ' clear out references to content or cached poster images
  if item.hasField("content") then item.content = invalid
  if item.hasField("itemContent") then item.itemContent = invalid
  if item.hasField("uri") then item.uri = ""
  m.itemPool.release(item)
End Function

Function onVisibleChange()
  tubiLog("ContentGrid.onVisibleChange")
  if m.top.visible = false then
    'remove children, freeing posters and associated HTTP and VRAM resources
    for i=0 to m.items.getChildCount()-1
      removeAndRelease(m.items.getChild(0))
    end for
  else if m.items.getChildCount() = 0 then
    loadVisiblePosters()
  end if
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
  tubiLog("ContentGrid.onComponentFocusChange " + focusState(m.top))
  if m.top.content <> invalid and m.numItems > 0 and m.top.isInFocusChain() then
    m.focusBox.visible = true

    if m.focusBox.opacity <> 1.0
      fade(m.focusBox, "in", 0.3)
    end if

    m.top.itemFocused = getContent(gridIndexToItemIndex(m.internalItemFocused))
    m.top.cursorPosition = [m.internalItemFocused[0], m.internalItemFocused[1]]
    m.top.cursorIndex = gridIndexToItemIndex(m.internalItemFocused)
  else
    fade(m.focusBox, "out", 0.3)
    ' If we don't have focus, clear out any keypresses.  This fixes an
    ' issue where we get a press but focus changes before we get the
    ' release, which causes an unfocused grid to continue scrolling.
    m.overlappedKeypress = invalid
    m.pressAndHold = invalid
  end if
End Function


''''''''''''''''''''''
' onContentChange
'
' Map the linear content list to a 2d grid based on numColumns and numRows
'
Function onContentChange() As Void
  tubiLog("ContentGrid.onContentChange")

  content = m.top.content
  if content = invalid or content.getChildCount() = 0 then
    m.internalItemFocused = [-1, -1]
    m.top.itemSelected = invalid
    m.top.itemFocused = invalid
    m.top.cursorPosition = [-1, -1]
    m.top.cursorIndex = -1
    ' Remove all existing itemComponents, returning them to the pool
    for i=0 to m.items.getChildCount()-1
      removeAndRelease(m.items.getChild(0))
    end for
    return
  end if
  m.numItems = getContentCount()

  ' Resolve the real grid size
  numRows = m.top.numRows
  numColumns = m.top.numColumns
  if m.top.fillDirection = "W" and numRows > 0
    ' if rows = 0, draw nothing. if rows > 0, expand columns, ignoring numColumns
    numColumns = m.numItems \ numRows
    if m.numItems MOD numRows > 0 then numColumns = numColumns + 1
  else if m.top.fillDirection = "Z" and numColumns > 0 then
    numRows = m.numItems \ numColumns
    if m.numItems MOD numColumns > 0 then numRows = numRows + 1
  end if
  m.internalNumRows = numRows
  m.internalNumColumns = numColumns

  ' preload the visible content
  loadVisiblePosters(false)

  if m.top.isInFocusChain()
    m.focusBox.visible = true
    m.focusBox.opacity = 1.0
  end if

  if m.internalItemFocused[0] = -1 and m.internalItemFocused[1] = -1 then
    ' zoom to beginning only if this was the first content
    startChangeFocus([0,0])
  else if m.numItems <= gridIndexToItemIndex(m.internalItemFocused) then
    'if numItems is less than location of focus box, move focus box to the end
    startChangeFocus(itemIndexToGridIndex(m.numItems-1))
  end if
End Function


''''''''''''''''''''''''
' loadVisiblePosters
'
' Determine which content items are in the visible window, then render those in 
' the m.items cache
Function loadVisiblePosters(useCache=true As Boolean) As Void
  ' quick out if the component is not visible, they'll be loaded once visibility changes
  if not m.top.visible then 
    print "Delaying item creation because invisible"
    return
  end if

  ' find the visible items by comparing the clipping window to the m.items offset
  ' these are all grid indices, not pixel coords
  visibleItems = getVisibleItemWindow()
  x = visibleItems.x
  y = visibleItems.y
  width = visibleItems.width
  height = visibleItems.height

  ' expand to preload a few outside of the visible window
  x = x - m.overhang
  y = y - m.overhang
  width = width + m.overhang * 2
  height = height + m.overhang * 2

  ' cap at the extremeties
  ' TODO(Chris): Wraparound would be accounted for here if we want to add that
  if x < 0 then x = 0
  if y < 0 then y = 0
  if (x + width) > m.internalNumColumns then width = m.internalNumColumns - x
  if (y + height) > m.internalNumRows then height = m.internalNumRows - y

  tubiLog("ContentGrid loading " + stri(width * height) + " visible items")

  ' Primarily for a complete reset of the content, such as initial loading
  if not useCache
    for i=0 to m.items.getChildCount()-1
      removeAndRelease(m.items.getChild(0))
    end for
  end if

  for i=x to x+width-1
    for j=y to y+height-1
      index = gridIndexToItemIndex([i,j])
      content = getContent(index)
      ' If we're beyond the end of the total items, don't create more components
      if index < m.numItems and content <> invalid then

        item = invalid
        if useCache then
          ' First see if we already have the item rendered, reset its cache position
          item = m.items.findNode(stri(index))
        end if

        if item = invalid then
          item = createItemComponent(index, content, m.itemPool.get())
        end if
        m.items.appendChild(item)  ' push to end of the FIFO
      end if
    end for
  end for

  ' keep cache size down
  for i=0 to (m.items.getChildCount() - (width * height) - 1)
    removeAndRelease(m.items.getChild(0))
  end for

  'print "Item cache has " + stri(m.items.getChildCount()) + " children"
End Function


'''''''''''''''''''''''
' createItemComponent
'
' Create one m.items component for the corresponding m.top.content item, inserting
' it into the cache. If cache size has grown, remove the oldest cache entry.  If
' the item is alread in the cache, reset it's FIFO position and don't create it
' again.
Function createItemComponent(index As Integer, content As Object, item As Object) As Object

  gridIndex = itemIndexToGridIndex(index)
  itemRect = getGridItemRect(gridIndex)

  if item.hasField("itemContent") then 
    fields = {
      id: stri(index)  
      width: m.top.itemSize[0]
      height: m.top.itemSize[1]
      itemContent: content
      translation: [itemRect.x,itemRect.y]
    }
    item.setFields(fields)
  else if item.hasField("uri") then 
    ' Special case here.  If we use Poster node type directly, it has a 'uri' field instead of
    ' an 'itemContent' field.
    fields = {
      id: stri(index)  
      width: m.top.itemSize[0]
      height: m.top.itemSize[1]
      loadDisplayMode: "scaleToZoom"
      loadingBitmapUri: "pkg:/images/placeholder.jpg"
      uri: content.hdgridposterurl
      translation: [itemRect.x,itemRect.y]
    }
    item.setFields(fields)
  end if

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
  if itemIndex >= m.numItems then return

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
  m.translationInterpolator.keyvalue=[ m.items.translation, [newX,newY] ]
  m.focusBoxInterpolator.keyvalue=[ m.focusBox.translation, [itemRect.x + newX, itemRect.y + newY] ]
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
    ' emit event only if key events aren't happening, or they're being ignored
    ' because we're at the end of the list
    keyHandled = false
    if m.overlappedKeypress <> invalid then
      keyHandled = scrollGrid(m.overlappedKeypress)
      m.overlappedKeypress = invalid
    else if m.pressAndHold <> invalid then
      keyHandled = scrollGrid(m.pressAndHold)
    end if

    ' If we're using a reasonably high-powered device, send messages while scrolling,
    ' otherwise send messages only when settled.
    if m.continuousEvents then
      m.top.cursorPosition = [m.internalItemFocused[0], m.internalItemFocused[1]]
      m.top.cursorIndex = gridIndexToItemIndex(m.internalItemFocused)
      loadVisiblePosters()
    end if

    ' Once things have settled, set itemFocused
    if not keyHandled then 
      if not m.continuousEvents then
        m.top.cursorPosition = [m.internalItemFocused[0], m.internalItemFocused[1]]
        m.top.cursorIndex = gridIndexToItemIndex(m.internalItemFocused)
        loadVisiblePosters()
      end if
      m.top.itemFocused = getContent(m.top.cursorIndex)
    end if
  end if

End Function



''''''''''''''''''''
' onAnimateToItem
'
' expect m.top.animateToItem to equal a 2d array like [x, y]
' in a single row, horizontal grid, to jump to the 5th item in the grid, set m.top.animateToItem = [4, 0]
Function onAnimateToItem()
  tubiLog("ContentGrid.onAnimateToItem")
  m.internalItemFocused = m.top.animateToItem
  startChangeFocus(m.top.animateToItem)
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

  ' Don't process any keypresses if there aren't any items
  if m.top.cursorIndex = -1 then return false

  if press then
    if m.scrollAnimation.state = "running" then 
      m.overlappedKeypress = key
      return true
    end if
    if scrollGrid(key) then
      ' we only do repeat if its a key that affects the grid, and also don't repeat ff and rew hops
      if key <> "fastforward" and key <> "rewind" then m.pressAndHold = key
      return true
    else if key = "OK" or key = "play" then
      m.top.itemSelected = getContent(gridIndexToItemIndex(m.internalItemFocused))
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
  else if direction = "fastforward" and m.internalItemFocused[0] < m.internalNumColumns-1 then
    visibleItems = getVisibleItemWindow()
    newX = m.internalItemFocused[0] + (visibleItems.width - 2)  ' subtract 2 since there may be overscan
    if newX > m.internalNumColumns-1 then newX = m.internalNumColumns-1
    startChangeFocus([newX, m.internalItemFocused[1]])
    return true
  else if direction = "rewind" and m.internalItemFocused[0] > 0 then
    visibleItems = getVisibleItemWindow()
    newX = m.internalItemFocused[0] - (visibleItems.width - 2)  ' subtract 2 since there may be overscan
    if newX < 0 then newX = 0
    startChangeFocus([newX, m.internalItemFocused[1]])
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
' Convert a scalar content index to a 2d grid index
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
' Convert a 2d grid index into a scalar content index
Function gridIndexToItemIndex(itemIndex As Object) As Integer
  if m.top.fillDirection = "W" then
    return (itemIndex[0]*m.internalNumRows + itemIndex[1])
  else if m.top.fillDirection = "Z" then
    return (itemIndex[1]*m.internalNumColumns + itemIndex[0])
  end if
End Function

'''''''''''''''''''''''''
' getContentCount
'
' Support for windowing the content
Function getContentCount()
  if m.top.content <> invalid then
    numItems = m.top.content.getChildCount()
    if m.top.content.totalCount <> invalid then
      numItems = m.top.content.totalCount
    end if
    if m.top.content.offset <> invalid then
      n = m.top.content.offset + m.top.content.getChildCount()
      if n > numItems then
        numItems = n
      end if
    end if
  else
    numItems = 0
  end if
  return numItems
End Function

''''''''''''''''
' getContent()
Function getContent(index)
  if m.top.content <> invalid then
    if m.top.content.offset <> invalid
      adjustedIndex = index - m.top.content.offset
    else
      adjustedIndex = index
    end if
    item = m.top.content.getChild(adjustedIndex)
  else
    item = invalid
  end if
  return item
End Function


'''''''''''''''
' getVisibleItemWindow
'
' Return grid index for visible items.  This is in item coordinates, not screen coordinates.
' NOTE: This will always have a valid x and y, though the width and height may be more than
'       the number of items available so the caller should clamp or account for item wrapping.
Function getVisibleItemWindow()
  x =  -m.items.translation[0] \ (m.top.itemSize[0] + m.top.itemSpacing[0])
  y =  -m.items.translation[1] \ (m.top.itemSize[1] + m.top.itemSpacing[1])
  width =  m.top.width \ (m.top.itemSize[0] + m.top.itemSpacing[0]) + 1 ' always add one so we show overhang
  height =  m.top.height \ (m.top.itemSize[1] + m.top.itemSpacing[1]) + 1

  return {
    x: x
    y: y
    width: width
    height: height
  }
End Function