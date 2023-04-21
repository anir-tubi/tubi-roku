Function init()
  m.Text = m.top.findNode("Text")
  m.Check = m.top.findNode("Check")
  m.TextFocused = m.top.findNode("TextFocused")
  m.CheckFocused = m.top.findNode("CheckFocused")
  m.BtnLayout = m.top.findNode("BtnLayout")
  m.TextFocused.opacity = 0
  m.CheckFocused.opacity = 0
  m.top.observeFieldScoped("itemContent", "onContentChange")
  m.top.observeFieldScoped("content", "onContentChange")
  m.top.observeFieldScoped("width", "onWidthChange")
  m.top.observeFieldScoped("height", "onHeightChange")
  m.top.observeFieldScoped("focusPercent", "onFocusPercentChange")
  m.top.observeFieldScoped("listHasFocus", "onListHasFocusChange")
  
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
    m.TextFocused.color = theme.focusedTextColor
    m.CheckFocused.blendColor = theme.focusedTextColor
  end if
End Function


''''''''''''''''''
' onContentChange
Function onContentChange()
  nOriginalTextWidth = m.Text.width
  if m.top.itemContent <> invalid then
    m.Text.text = m.top.itemContent.title
    m.TextFocused.text = m.top.itemContent.title
    if m.top.itemContent.checked <> invalid
      m.Check.visible = m.top.itemContent.checked
      m.CheckFocused.visible = m.top.itemContent.checked
    else
      m.Check.visible = false
      m.CheckFocused.visible = false
    end if
  else
    m.Text.text = ""
    m.TextFocused.text = ""
    m.Check.visible = false
    m.CheckFocused.visible = false
  end if
  nBoundingTextWidth = m.Text.boundingRect().width
  m.Text.width = nOriginalTextWidth
  m.TextFocused.width = nOriginalTextWidth
  m.top.calculatedWidth = nBoundingTextWidth + getWidthMinusText()
End Function


''''''''''''''''''
' onWidthChange
Function onWidthChange()
  nTextWidth = m.top.width - getWidthMinusText()
  m.Text.width = nTextWidth
  m.TextFocused.width = nTextWidth
End Function


''''''''''''''''''
' onHeightChange
Function onHeightChange()
  m.Text.height = m.top.height
  m.TextFocused.height = m.top.height
  '//Move the layout halfway down so it fits within the button component focus area
  m.BtnLayout.translation = [m.BtnLayout.translation[0], m.top.height/2]
End Function


''''''''''''''''''
' getWidthMinusText
Function getWidthMinusText()
  '//The width include the checkbox, the space in between the checkbox and the label, and the space before the 1st and last elements of the checkbutton
  return m.Check.width + m.BtnLayout.itemSpacings[0] + m.BtnLayout.translation[0]*2
End Function


' When the menu gains or loses focus, then ensure the Focused UI elements are displayed with their proper opacity
Function onListHasFocusChange()
  if m.top.listHasFocus = true AND m.top.itemHasFocus = true
    m.TextFocused.opacity = 1
    m.CheckFocused.opacity = 1
  else
    m.TextFocused.opacity = 0
    m.CheckFocused.opacity = 0
  end if
End Function


Function onFocusPercentChange()
  focusPercent = m.top.focusPercent
  if m.top.listHasFocus = true
    m.TextFocused.opacity = focusPercent
    m.CheckFocused.opacity = focusPercent
  else
    m.TextFocused.opacity = 0
    m.CheckFocused.opacity = 0
  end if
End Function
