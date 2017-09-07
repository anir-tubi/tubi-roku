Function init()
  tubiLog("KeyboardItem.init")
  m.top.height = 80
  m.top.width = 60
  m.top.color = m.global.constants.ui.colors.transparent
  m.top.observeField("content", "onContentChange")
  m.Text = m.top.findNode("Text")
End Function

''''''''''''''''''''
' onContentChange
'
' Set the label text
Function onContentChange()
  tubiLog("KeyboardItem.onContentChange")

  ' make this component reusable by resetting to its initial state
  m.top.width = 60
  'm.top.replaceChild(m.Text, 0)
  m.top.unobserveField("focusPercent")  ' by default, don't listen to this
  m.top.unobserveField("listHasFocus")  ' by default, don't listen to this

  if m.top.content <> invalid
    if m.top.content.title = " "
      createPosterNodes("pkg:/images/character-space.png", "pkg:/images/character-space-focused.png")
    else if m.top.content.title = Chr(&h7F)
      createPosterNodes("pkg:/images/character-delete.png", "pkg:/images/character-delete-focused.png")
    else
      m.top.removeChild(m.Image)
      m.top.removeChild(m.FocusImage)
      m.Image = invalid
      m.FocusImage = invalid
      m.top.appendChild(m.Text)
      m.Text.id = m.top.content.id + "-text"
      m.Text.text = m.top.content.title
    end if
  else
    m.top.removeChild(m.Image)
    m.top.removeChild(m.FocusImage)
    m.Image = invalid
    m.FocusImage = invalid
    m.top.appendChild(m.Text)
    m.Text.text = ""
  end if
End Function

Function onFocusChange()
  if m.FocusImage <> invalid then
    if m.top.listHasFocus
      m.FocusImage.opacity = m.top.focusPercent
    else
      m.FocusImage.opacity = 0.0
    end if
  end if
end Function

Function createPosterNodes(uri, focusedUri)
  m.Image = CreateObject("roSGNode", "Poster")
  m.Image.height = 40
  m.Image.width = 60
  m.Image.translation = [0,20]
  m.Image.uri = uri
  m.top.replaceChild(m.Image, 0)
  m.FocusImage = CreateObject("roSGNode", "Poster")
  m.FocusImage.height = 80
  m.FocusImage.width = 60
  m.FocusImage.uri = focusedUri
  m.FocusImage.translation = [0,0]
  m.top.appendChild(m.FocusImage)
  m.top.observeField("focusPercent", "onFocusChange")
  m.top.observeField("listHasFocus", "onFocusChange")
  onFocusChange() 'set initial opacity
End Function