Function init()
  m.Text = m.top.findNode("Text")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("content", "onContentChange")
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.Text.color = theme.primaryTextColor
  end if
End Function


''''''''''''''''''
' onContentChange
Function onContentChange()
  if m.top.itemContent <> invalid then
    m.Text.text = m.top.itemContent.title
  else if m.top.content <> invalid then
    m.Text.text = m.top.content.title
  end if
End Function