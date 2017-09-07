Function init()
  tubiLog("SeasonContentGrid.init")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("listHasFocus", "onListHasFocus")
  m.SeasonName = m.top.findNode("SeasonName")
  m.FocusedSeasonName = m.top.findNode("FocusedSeasonName")
  m.UnfocusedSeasonName = m.top.findNode("UnfocusedSeasonName")
  m.ContentGrid = m.top.findNode("ContentGrid")

  ' initialize SeasonName visibility
  m.top.opacity = 0.2
End Function

Function onComponentFocusChange()
  tubiLog("SeasonContentGrid.onComponentFocusChange" + focusState(m.top))
  if m.top.hasFocus() and m.ContentGrid.visible then
    m.ContentGrid.setFocus(true)
  else if m.top.isInFocusChain() then
    m.top.itemFocused = m.top.content
  end if
End Function

Function onFocusPercentChange()
  tubiLog("SeasonContentGrid.onFocusPercentChange")
  if m.top.focusPercent > 0 and not m.top.listHasFocus then
    m.SeasonName.opacity = 1.0 - m.top.focusPercent
  else
    m.SeasonName.opacity = 1.0
  end if
  m.FocusedSeasonName.opacity = m.top.focusPercent
  m.UnfocusedSeasonName.opacity = 1.0 - m.top.focusPercent
  m.top.opacity = 0.20 + (0.80 * m.top.focusPercent)
End Function


Function onListHasFocus()
  tubiLog("SeasonContentGrid.onListHasFocus")
  if m.top.focusPercent = 1
    if m.top.listHasFocus = true
      fade(m.SeasonName, "in", 0.5)
    else
      fade(m.SeasonName, "out", 0.5)
    end if
  end if
End Function


Function onContentChange()
  tubiLog("SeasonContentGrid.onContentChange")
  if m.top.content <> invalid then
    m.FocusedSeasonName.text = m.top.content.title
    m.UnfocusedSeasonName.text = m.top.content.title
    m.ContentGrid.content = m.top.content
    if m.top.isInFocusChain() then m.ContentGrid.setFocus(true)  ' be careful when removing children that we don't remove a focused item
  end if
End Function
