Function init()
  m.Text = m.top.findNode("Text")
  m.top.observeField("content", "onContentChange")
  m.top.width = 480
  m.top.height = 80
  m.top.color = m.global.constants.ui.colors.transparent
End Function

''''''''''''''''''
' onContentChange
Function onContentChange()
  if m.top.content <> invalid then
    m.Text.text = m.top.content.title
  end if
End Function