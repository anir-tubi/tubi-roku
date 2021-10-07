Function init()

  m.border = m.top.findNode("border")
  m.border.color = m.global.theme.focused

  m.rectBG = m.top.findNode("rectBG")
  m.rectBG.color = "0x9699A3"
  m.rectBG.opacity = 0.17

  m.Text = m.top.findNode("Text")
  m.Text.text = m.top.hint
  
  m.Text.color = "0x585B66"
  m.Text.opacity = 0.7
  
  m.top.observeField("boxWidth", "onBoxWidth")
  m.top.observeField("boxHeight", "onBoxHeight")
  
  m.top.observeField("hint", "formatTextBox")
  m.top.observeField("text", "formatTextBox")

  m.passwordPlaceholder = "*"
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("highlight", "onHighlight")
  m.top.observeField("passwordMode", "onPasswordModeChange")
  
End Function


Function onBoxWidth()

  m.rectBG.width = m.top.boxWidth
  m.border.width = m.top.boxWidth + 8

End Function


Function onBoxHeight()

  m.rectBG.height = m.top.boxHeight
  m.border.height = m.top.boxHeight + 8

End Function


Function onHighlight()

  if m.top.highlight = true
    
    m.rectBG.color = "0xFFFFFF"
    m.rectBG.opacity = 0.8
    m.Text.color = "0x1C1F29"
    
    if m.top.text = invalid or m.top.text = "" then
      m.Text.text = m.top.hint
      m.Text.opacity = 0.7
    else
      m.Text.opacity = 1.0
    end if  
  else
    
    m.rectBG.color = "0x9699A3"
    m.rectBG.opacity = 0.17
    
    if m.top.text = invalid or m.top.text = "" then
      m.Text.color = "0x585B66"
      m.Text.opacity = 0.7
    else
      m.Text.color = "0xFFFFFF"
      m.Text.opacity = 1.0    
    end if  
  end if

End Function


Function onScreenFocusChange()
  tubiLog("TextEntryBox.onScreenFocusChange")
  
  if m.top.hasFocus() then
    m.border.visible = true
    if m.top.text <> invalid and m.top.text <> "" then
      onPasswordModeChange()
    end if  
    m.top.highlight = true 
  else  
    m.border.visible = false
    m.top.highlight = false 
  end if
  
End Function


''''''''''''''''
' formatTextBox
'
' NOTE: There seems to be a bug in the calculation of text width which
'       causes us not to be able to rely on the numbers here for
'       the boundingRect.  To account for this, we use a smaller
'       number than the real text box width in order to apply the
'       shortening algorithm.
Function formatTextBox()
  tubiLog("TextEntryBox.formatTextBox")

  if m.top.text = invalid or m.top.text = "" then
    m.Text.text = m.top.hint
    m.Text.opacity = 0.7
  else
    m.Text.opacity = 1.0
    m.Text.color = "0xFFFFFF"
    onPasswordModeChange()
  end if
  
  textRect = m.Text.localBoundingRect()
  safetyWidth = 400   'Arbitrarily chosen, smaller than 428 max width
  if textRect.width > safetyWidth then
    while true
      m.Text.text = Right(m.Text.text, m.Text.text.len() - 1)
      textRect = m.Text.boundingRect()
      if textRect.width < safetyWidth then
        exit while
      end if
    end while
  end if
End Function


Function onPasswordModeChange()
  if m.top.passwordMode = true then
    passwordText = ""
    for i=0 to m.top.text.len()-1
      passwordText = passwordText + m.passwordPlaceholder
    end for
    if passwordText = ""
      m.Text.text = m.top.hint
    else
      m.Text.text = passwordText
    end if
  else
    if m.top.text = ""
      m.Text.text = m.top.hint
    else
      m.Text.text = m.top.text
    end if
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean

  tubiLog("TextEntryBox.onKeyEvent key = " + key)
  if press then
    if key = "OK"
      m.top.selected = true
      return true
    end if
  end if

  return false
End Function