Function init()
  m.cursor = m.top.findNode("categoryListCursor")
  m.label = m.top.findNode("categoryText")
  m.top.observeField("focusPercent", "onFocusChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("listHasFocus", "onListFocusChange")
End Function


''''''''''''''''''''
' onListFocusChange
'
' Always hide cursor if list has lost focus
Function onListFocusChange()
  if m.top.listHasFocus
    m.cursor.opacity = m.top.focusPercent
  else
    m.cursor.opacity = 0.0
  end if
End Function


''''''''''''''''''''
' onFocusChange
'
' Item focus is changing, which can be an incremental value
' from 0.0 to 1.0 corresponding to the amount of focus during
' an animation.
Function onFocusChange()
  tubiLog("CategoryListItem.onFocusChange")
  m.cursor.opacity = m.top.focusPercent
  ' dynamically generate a gradient to transition color
  ' from "0xFF9933FF" to  "0xFFFFFFFF"
  newColor = &hFFFFFF - (&hFFFFFF - &hFF9933) * m.top.focusPercent
  m.label.color = "0x" + stri(newColor, 16) + "FF"
End Function


''''''''''''''''''''
' onContentChange
'
' Set the label text and cursor height on receiving the 
' category name
Function onContentChange()
  tubiLog("CategoryListItem.onContentChange")
  m.label.text = Ucase(m.top.content.title)
  rect = m.label.localBoundingRect()

  ' Gathered empirically. A single line Label of 31pt font
  ' will be 43 pixels tall, which looks good with 22px 
  ' cursor.  We'll just stretch the cursor to 
  ' (label.height-N), where N comes from
  '    43 - N = 22; N = 21
  m.cursor.height = rect.height - 21

End Function