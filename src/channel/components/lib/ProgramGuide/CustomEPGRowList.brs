Sub init()
  m.currentItemFocused = -1
  m.lastFocused = 0
  m.top.observeField("itemUnfocused", "onItemUnfocused")
  m.top.observeField("currFocusRow", "onCurrFocusRowChange")
End Sub


Function onKeyEvent(key, press) as boolean
  if press
    m.top.kepPressed = key
    if key = "down"
      if m.currentItemFocused <> m.top.itemFocused
        m.currentItemFocused = m.top.itemFocused
        m.top.jumpToRowItem = [m.currentItemFocused, 0]
      end if
    else if key = "up"
      if m.currentItemFocused <> m.top.itemFocused
        m.currentItemFocused = m.top.itemFocused
        m.top.jumpToRowItem = [m.currentItemFocused, 0]
      end if
    else if key = "OK"
      m.top.okPressed = true
    end if
  end if
  return false
End Function

Function onItemUnfocused()
  m.lastFocused = m.top.itemUnfocused
End Function


' observer for 'current focused row'  will trigger multiple times ( for example moveing focus from second row to third row it can be something like 1.2, 1.5, 1.6, ..2.0)
' causing execution of on-Observer function unnecessarily and mostly unwanted results. To avoid that situation, we set up observer to rowScrollFocused which will get updated only when
' int(currentRowFocus) resolves to be different than last focused row.
' rowScrollFocused interface will be updated if focus has changed the row successfully.
' We observe currFocusRow instead of itemFocused so that we can continually update the grid if a user presses and holds the up or down remote buttons.
Function onCurrFocusRowChange(msg)
  if m.top.hasFocus()
    focusPos = msg.getData()

    newFocus = Int(focusPos)

    if focusPos > m.lastFocused
      if newFocus < focusPos
        newFocus += 1
      end if
    end if

    m.top.rowScrollFocused = newFocus
  end if

End Function