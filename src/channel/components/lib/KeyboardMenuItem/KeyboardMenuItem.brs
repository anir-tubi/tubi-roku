Function init()
  tubiLog("KeyboardMenuItem.init")
  m.top.height = 80
  m.top.width = 124
  m.top.vertAlign = "center"
  m.top.horizAlign = "center"
  m.top.observeField("content", "onContentChange")
  m.top.color = m.global.constants.ui.colors.primaryText
End Function

''''''''''''''''''''
' onContentChange
'
' Set the label text
Function onContentChange()
  tubiLog("KeyboardMenuItem.onContentChange")
  if m.top.content <> invalid and m.top.content.title <> invalid then
    m.top.text = m.top.content.title
    m.top.id = m.top.content.id + "-text"
  else
    m.top.text = ""
  end if
End Function