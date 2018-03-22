Function init()
  m.lastFocused = 0
  m.top.observeField("itemUnfocused", "onItemUnfocused")
  m.top.observeField("currFocusRow", "onCurrFocusRowChange")
End Function


Function onItemUnfocused()
  m.lastFocused = m.top.itemUnfocused
End Function


Function onCurrFocusRowChange(msg)
  if m.top.hasFocus()
    focusPos = msg.getData()

    newFocus = Int(focusPos)
    if focusPos > m.lastFocused
      if newFocus < focusPos
        newFocus += 1
      end if
      print newFocus
    end if

    m.top.rowScrollFocused = newFocus
  end if
End Function

