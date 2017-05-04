Function init()
  m.contentGrid = m.top.findNode("ContentGrid")
  m.contentGrid.observeField("itemFocused", "onItemFocused")
  m.contentGrid.observeField("itemSelected", "onItemSelected")
  m.top.observeField("jumpToIndex", "onJumpToIndex")
  m.top.observeField("focusedChild", "onChildFocused")
End Function

Function onChildFocused()
  if m.top.isInFocusChain() and m.top.hasFocus()
    m.contentGrid.setFocus(true)
  end if
End Function

Function onItemFocused()
  tubiLog("VideoPicker.onItemFocused " + stri(m.contentGrid.cursorIndex))
  m.top.contentFocused = m.contentGrid.cursorIndex
End Function

Function onItemSelected()
  tubiLog("VideoPicker.onItemSelected " + stri(m.contentGrid.cursorIndex))
  m.top.contentSelected = m.contentGrid.cursorIndex
End Function

Function onJumpToIndex()
  m.contentGrid.animateToItem = [m.top.jumpToIndex, 0]
End Function