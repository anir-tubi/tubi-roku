Function onKeyEvent(key, press) as Boolean
  if press = true
    if key = "fastforward" OR key = "rewind"
      m.top.keyPress = key
      return true
    end if
  end if
  return false
End Function