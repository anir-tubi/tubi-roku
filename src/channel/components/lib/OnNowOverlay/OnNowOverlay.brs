Function init()
  m.leftGrid = m.top.findNode("LeftGrid")
  m.rightGrid = m.top.findNode("RightGrid")
  m.info = m.top.findNode("Info")
  m.nextItemTitle = m.top.findNode("NextItemTitle")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("jumpToIndex", "onJumpToIndexChange")
  m.top.observeField("focusedChild", "onChildFocused")
  m.navigations = m.top.navigations
End Function


Function onChildFocused()
  if not m.top.isInFocusChain() or not m.top.hasFocus()
    m.navigations = 0
  end if
End Function


'currently expect this will only happen at app start up
Function onContentChange()
  tubiLog("OnNowOverlay.onContentChange")

  ' clone the content
  if m.top.content <> invalid
    internalContent = CreateObject("roSGNode", "ContentNode")
    row = internalContent.createChild("ContentNode")
    for i=0 to m.top.content.getChildCount()-1
      child = row.createChild("ContentNode")
      child.id = m.top.content.getChild(i).id
      child.title = m.top.content.getChild(i).title
      child.hdgridposterurl = m.top.content.getChild(i).landscape
    end for
    m.leftGrid.content = internalContent
    m.rightGrid.content = internalContent
  else
    m.leftGrid.content = invalid
    m.rightGrid.content = invalid
  end if
  showContent(0)
End Function

'Handles updating both content grids in the overlay when either a user has pressed left or right on the overlay
'or the player has advanced/retreated the content (event sent via OnNow.brs)
Function onJumpToIndexChange()
  tubiLog("OnNowOverlay.onJumpToIndexChange")
  showContent(m.top.jumpToIndex)
End Function

Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("OnNowOverlay.onKeyEvent key = " + key)
  if press
    if key = "left"
      showContent(m.top.contentFocused - 1)
      return true
    else if key = "right"
      showContent(m.top.contentFocused + 1)
      return true
    else if key = "OK"
      m.top.contentSelected = m.top.contentFocused
      m.navigations = 0
      return true
    end if
  end if
  return false
End Function


Function showContent(index) As Void
  currentContent = invalid
  if m.top.content <> invalid and m.top.content.getChildCount() > 0
    length = m.top.content.getChildCount()
    currentIndex = (index + length) MOD length    ' index can be -1 when the onKeyEvent is handling "left"
    nextIndex = (currentIndex + 1) MOD length
    currentContent = m.top.content.getChild(currentIndex)
    if currentContent <> invalid then 
      m.leftGrid.jumpToRowItem = [0,currentIndex]
      m.rightGrid.jumpToRowItem = [0,nextIndex]
      nextContent = m.top.content.getChild(nextIndex)
      if nextContent <> invalid then m.nextItemTitle.text = nextContent.title
      m.top.contentFocused = currentIndex
    end if
  end if
  m.info.content = currentContent
End Function


' Helper function to make trackEvent calls prettier
Function trackEvent(event As Object) As Void
  m.global.trackingLoggingTask.trackEvent = event
End Function