Function init()
  m.grid = m.top.findNode("Grid")
  m.grid.observeField("rowItemFocused", "onRowItemFocused")
  m.grid.observeField("rowItemSelected", "onRowItemSelected")
  m.top.observeField("jumpToIndex", "onJumpToRowIndex")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusedChild", "onChildFocused")
  m.top.observeField("contentFocused", "onContentFocused")

  ' internal content tree, so that we can wrap the content list in a tree for 
  ' RowList formatting
  m.internalContent = invalid

  if m.global.constants.deviceInfo.scaledUi = true then
    m.grid.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if
End Function

Function onChildFocused()
  if m.top.isInFocusChain() and m.top.hasFocus()
    m.grid.setFocus(true)
  else
    m.top.navigations = 0
  end if
End Function

Function onRowItemFocused()
  tubiLog("VideoPicker.onRowItemFocused " + stri(m.grid.rowItemFocused[1]))
  ' NOTE: We only emit events if in focus, that way we don't create
  ' feedback loops when the video player advancing (either autoplay or another control)
  ' tells this component to jump to index, which then emits and event to
  ' the video player, and on and on...
  if m.top.isInFocusChain() then m.top.contentFocused = m.grid.rowItemFocused[1]
End Function

Function onRowItemSelected()
  tubiLog("VideoPicker.onRowItemSelected " + stri(m.grid.rowItemSelected[1]))
  m.top.contentSelected = m.grid.rowItemSelected[1]
End Function

Function onJumpToRowIndex()
  tubiLog("VideoPicker.onJumpToRowIndex" + stri(m.top.jumpToIndex))
  m.grid.jumpToRowItem = [0, m.top.jumpToIndex]
End Function

Function onContentChange()
  tubiLog("VideoPicker.onContentChange")
  if m.top.content <> invalid then
    root = CreateObject("roSGNode", "ContentNode")
    root.appendChild(m.top.content.clone(true))
    m.internalContent = root
  else
    m.internalContent = invalid
  end if
  m.grid.content = m.internalContent
End Function