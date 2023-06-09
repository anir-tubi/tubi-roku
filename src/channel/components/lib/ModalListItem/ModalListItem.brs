Function init()
  m.buttonTextParent = m.top.findNode("buttonTextParent")
  m.buttonText = m.top.findNode("buttonText")
  m.buttonTextFocused = m.top.findNode("buttonTextFocused")
  m.buttonTextFocused.opacity = 0
  m.top.observeFieldScoped("itemContent", "onItemContentChange")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if
  
  if theme <> invalid
    m.buttonText.color = theme.primaryTextColor
    m.buttonTextFocused.color = theme.focusedTextColor
  end if
End Function


''''''''''''''''''''
' onItemContentChange
'
' Set the label text on receiving the category name
Function onItemContentChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid then
    m.buttonText.text = itemContent.title
    m.buttonTextFocused.text = itemContent.title
    nBoundingTextWidth = m.buttonText.boundingRect().width
    m.buttonText.width = nBoundingTextWidth 
    m.buttonTextFocused.width = nBoundingTextWidth 
     ' Adjust the width of the menu if the text is too long for the default width
     ' Adding the left and right margin along with text width 
    m.top.calculatedWidth = nBoundingTextWidth + (2 * m.buttonTextParent.translation[0])
  end if
End Function