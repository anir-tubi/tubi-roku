Function init()
  m.buttonText = m.top.findNode("buttonText")
  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocus")

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
    nBoundingTextWidth = m.buttonText.boundingRect().width
    m.buttonText.width = nBoundingTextWidth 
     ' Adjust the width of the menu if the text is too long for the default width
     ' Adding the left and right margin along with text width 
    m.top.calculatedWidth = nBoundingTextWidth + 2 * m.buttonText.translation[0]
  end if
End Function


Function onItemHasFocus()
  theme = getThemeFromGlobal()
  if theme <> invalid
    if m.top.itemHasFocus = true
      m.buttonText.color = theme.focusedTextColor
    else
      m.buttonText.color = theme.primaryTextColor
    end if
  end if
End Function