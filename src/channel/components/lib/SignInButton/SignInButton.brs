Function init()
  m.Text = m.top.findNode("Text")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("content", "onContentChange")
  m.Text.color = m.global.constants.ui.colors.primaryText
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