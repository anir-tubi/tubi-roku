Function init()
  m.Text = m.top.findNode("Text")
  m.Check = m.top.findNode("Check")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("content", "onContentChange")
  m.Text.color = m.global.constants.ui.colors.primaryText
End Function

''''''''''''''''''
' onContentChange
Function onContentChange()
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
End Function
