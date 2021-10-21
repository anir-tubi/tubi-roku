Function init()
  m.buttonText = m.top.findNode("buttonText")
  m.top.observeField("itemContent", "onItemContentChange")
End Function

''''''''''''''''''''
' onItemContentChange
'
' Set the label text on receiving the category name
Function onItemContentChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid then
    m.buttonText.text = itemContent.title
    nBoundingTextWidth = m.buttonText.boundingRect().width
    m.buttonText.width = nBoundingTextWidth 
     ' Adjust the width of the menu if the text is too long for the default width
     ' Adding the left and right margin along with text width 
    m.top.calculatedWidth = nBoundingTextWidth + 2 * m.buttonText.translation[0]
  end if
End Function