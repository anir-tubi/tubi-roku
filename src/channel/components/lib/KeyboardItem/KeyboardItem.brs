Function init()
  tubiLog("KeyboardItem.init")
  m.top.height = 80
  m.top.width = 60
  m.top.color = m.global.constants.ui.colors.transparent
  m.top.observeField("content", "onContentChange")
  m.Text = m.top.findNode("Text")
  m.Image = m.top.findNode("Image")
End Function

''''''''''''''''''''
' onContentChange
'
' Set the label text
Function onContentChange()
  tubiLog("KeyboardItem.onContentChange")
  m.Text.visible = false
  m.Image.visible = false
  if m.top.content <> invalid and m.top.content.title <> invalid then
    if m.top.content.title = " "
      ' show space icon
      m.Image.uri = "pkg:/images/character-space.png"
      m.Image.visible = true
    else if m.top.content.title = Chr(&h7F) then
      ' show delete icon
      m.Image.uri = "pkg:/images/character-delete.png"
      m.Image.visible = true
    else
      m.Text.visible = true
      m.Text.id = m.top.content.id + "-text"
      m.Text.text = m.top.content.title
    end if
  else
    m.Text.visible = true
    m.Text.text = ""
  end if
End Function