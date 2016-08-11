Function init()
  m.top.observeField("content", "onContentChange")
  m.Icon = m.top.findNode("Icon")
  m.Text = m.top.findNode("Text")
  m.Progress = m.top.findNode("ResumeProgressBar")
  ' Force a static size, which ScrollingList will pick up since it internal uses LayoutGroup for spacing
  m.top.width = 465
  m.top.height = 80
  m.top.color = m.global.constants.ui.colors.transparent
End Function

Function onContentChange()
  if m.top.content <> invalid then
    m.Text.text = m.top.content.title
    m.Icon.uri = m.top.content.url
    if m.top.content.playstart <> invalid and m.top.content.playstart <> 0.0 and m.top.content.length <> invalid and m.top.content.length <> 0.0 then
      showProgressBar(m.top.content.playstart / m.top.content.length)
    else
      m.Progress.visible = false
    end if
  end if
End Function

Function showProgressBar(percentage As Double)
  if percentage > 1.0 then percentage = 1.0
  if percentage < 0.0 then percentage = 0.0
  ' width of menu item is 465, 4 pixel margin for progress bar
  m.Progress.width = 457.0 * percentage
  m.Progress.visible = true
End Function
