Function init()
  m.contentGrid = m.top.findNode("ContentGrid")
  m.contentGrid.observeField("itemFocused", "onItemFocused")
  m.contentGrid.observeField("itemSelected", "onItemSelected")
  m.top.observeField("jumpToIndex", "onJumpToIndex")
  m.top.observeField("focusedChild", "onChildFocused")
  m.top.observeField("contentFocused", "onContentFocused")
End Function

Function onChildFocused()
  if m.top.isInFocusChain() and m.top.hasFocus()
    m.contentGrid.setFocus(true)
  else
    m.top.navigations = 0
  end if
End Function

Function onItemFocused()
  tubiLog("VideoPicker.onItemFocused " + stri(m.contentGrid.cursorIndex))
  ' NOTE: We only emit events if in focus, that way we don't create
  ' feedback loops when the video player advancing (either autoplay or another control)
  ' tells this component to jump to index, which then emits and event to
  ' the video player, and on and on...
  if m.top.isInFocusChain() then m.top.contentFocused = m.contentGrid.cursorIndex
End Function

Function onItemSelected()
  tubiLog("VideoPicker.onItemSelected " + stri(m.contentGrid.cursorIndex))
  m.top.contentSelected = m.contentGrid.cursorIndex
End Function

Function onJumpToIndex()
  tubiLog("VideoPicker.onJumpToIndex" + stri(m.top.jumpToIndex))
  m.contentGrid.animateToItem = [m.top.jumpToIndex, 0]
End Function
