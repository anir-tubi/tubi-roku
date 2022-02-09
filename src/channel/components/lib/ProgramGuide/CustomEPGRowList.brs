Sub init()
  m.currentItemFocused = -1
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