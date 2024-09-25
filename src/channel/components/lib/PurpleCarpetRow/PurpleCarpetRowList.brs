Function onKeyEvent(key, press) as boolean
  if press
    m.top.keyPressed = key
    if key = "left"
      return true
    end if
  end if
  return false
End Function
