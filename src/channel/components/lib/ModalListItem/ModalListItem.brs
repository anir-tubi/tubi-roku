Function init()
  m.buttonText = m.top.findNode("buttonText")
  m.top.observeField("itemContent", "onItemContentChange")
End Function

''''''''''''''''''''
' onItemContentChange
'
' Set the label text on receiving the category name
Function onItemContentChange()
  if m.top.itemContent <> invalid then
    m.buttonText.text = m.top.itemContent.title
  end if
End Function