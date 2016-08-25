Function init()
  m.Text = m.top.findNode("Text")
  m.top.observeField("hint", "formatTextBox")
  m.top.observeField("text", "formatTextBox")
  m.top.width = 480
  m.top.height = 80
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
  else
    m.Text.text = m.top.text
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