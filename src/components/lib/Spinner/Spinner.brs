Function init()
  m.top.opacity = "0.8"
  m.top.observeField("width", "onDimensionsChange")
  m.top.observeField("height", "onDimensionsChange")

  m.Animation = m.top.findNode("SpinnerAnimation")
  m.top.observeField("visible", "onVisibilityChange")
  if m.top.visible then
    m.Animation.control = "start"
  end if
End Function

Function onVisibilityChange()
  if m.top.visible = true and m.Animation.state <> "running" then
    m.Animation.control = "start"
  else if m.top.visible = false then
    m.Animation.control = "stop"
  endif
End Function

Function onDimensionsChange()
  shade = m.top.findNode("Shade")
  shade.width = m.top.width
  shade.height = m.top.height
  spinnerBox = m.top.findNode("SpinnerBox")
  newX = (m.top.width - 200) / 2
  newY = (m.top.height - 200) / 2
  spinnerBox.translation = [newX, newY]
  spinner = m.top.findNode("SpinnerPoster")
  newX = (m.top.width - 66) / 2
  newY = (m.top.height - 66) / 2
  spinner.translation = [newX, newY]  
End Function