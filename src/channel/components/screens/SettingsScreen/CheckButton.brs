Function init()
  m.Text = m.top.findNode("Text")
  m.Check = m.top.findNode("Check")
  m.BtnLayout = m.top.findNode("BtnLayout")
  m.top.observeFieldScoped("itemContent", "onContentChange")
  m.top.observeFieldScoped("content", "onContentChange")
  m.top.observeFieldScoped("width", "onWidthChange")
  m.top.observeFieldScoped("height", "onHeightChange")
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
    m.Text.color = theme.primaryTextColor
    m.Check.blendColor = theme.primaryTextColor
  end if
End Function


''''''''''''''''''
' onContentChange
Function onContentChange()
  nOriginalTextWidth = m.Text.width
  if m.top.itemContent <> invalid then
    m.Text.text = m.top.itemContent.title
    if m.top.itemContent.checked <> invalid
      m.Check.visible = m.top.itemContent.checked
    else
      m.Check.visible = false
    end if
  else
    m.Text.text = ""
    m.Check.visible = false
  end if
  nBoundingTextWidth = m.Text.boundingRect().width
  m.Text.width = nOriginalTextWidth
  m.top.calculatedWidth = nBoundingTextWidth + getWidthMinusText()
End Function


''''''''''''''''''
' onWidthChange
Function onWidthChange()
  nTextWidth = m.top.width - getWidthMinusText()
  m.Text.width = nTextWidth
End Function


''''''''''''''''''
' onHeightChange
Function onHeightChange()
  m.Text.height = m.top.height
  '//Move the layout halfway down so it fits within the button component focus area
  m.BtnLayout.translation = [m.BtnLayout.translation[0], m.top.height/2]
End Function


''''''''''''''''''
' getWidthMinusText
Function getWidthMinusText()
  '//The width include the checkbox, the space in between the checkbox and the label, and the space before the 1st and last elements of the checkbutton
  return m.Check.width + m.BtnLayout.itemSpacings[0] + m.BtnLayout.translation[0]*2
End Function


Function onItemHasFocus()
  theme = getThemeFromGlobal()
  if theme <> invalid
    if m.top.itemHasFocus = true
      m.Text.color = theme.focusedTextColor
      m.Check.blendColor = theme.focusedTextColor
    else
      m.Text.color = theme.primaryTextColor
      m.Check.blendColor = theme.primaryTextColor
    end if
  end if
End Function