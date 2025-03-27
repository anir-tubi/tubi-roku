Function init()
  m.proxyKB = m.top.findNode("proxyKB")
  keyGrid = m.proxyKB.keyGrid
  keyGrid.keyDefinitionUri = "pkg:/components/screens/SettingsScreen/TestAid/IpAddressKDF.json"

  theme = getThemeFromGlobal()
  if theme <> invalid
    palette = createObject("roSGNode", "RSGPalette")
    palette.colors = {
      "FocusColor": theme.focusedColor
      "FocusItemColor": theme.keyboardFocusedTextColor
    }
    keyGrid.palette = palette
  end if

  m.removeProxyBt = m.top.findNode("removeProxyBt")
  m.addProxyBt = m.top.findNode("addProxyBt")
  m.addProxyBt.observeFieldScoped("selected", "ipAddressInputChange")
  m.top.observeFieldScoped("focusedChild", "onFocusChange")
End Function

Function ipAddressInputChange(msg)
  if msg.getData() = true
    m.top.proxyAddress = m.proxyKB.text
  end if
End Function


Function onFocusChange()
  if m.top.hasFocus() = true
    m.proxyKB.setFocus(true)
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as boolean
  handled = false
  if press = true
    if key = "down" AND m.proxyKB.isInFocusChain() = true
      m.addProxyBt.setFocus(true)
      handled =true
    else if key = "up" AND m.addProxyBt.hasFocus() = true
      m.proxyKB.setFocus(true)
      handled = true
    else if key="right" AND m.addProxyBt.hasFocus() = true
      m.removeProxyBt.setFocus(true)
      handled = true
    else if key="left" AND m.removeProxyBt.hasFocus() = true
      m.addProxyBt.setFocus(true)
      handled = true
    end if
  end if

  return handled

End Function