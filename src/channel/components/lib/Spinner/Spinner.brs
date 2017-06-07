Function init()
  m.top.opacity = "0.8"
  m.top.observeField("width", "onDimensionsChange")
  m.top.observeField("height", "onDimensionsChange")

  ' Non-OpenGL slow devices look really poor with clunky spinner
  if m.global.constants.deviceInfo.limitedNewUi = false
    m.Animation = m.top.findNode("SpinnerAnimation")
    m.top.observeField("visible", "onVisibilityChange")
    if m.top.visible then
      m.Animation.control = "start"
    end if
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
  ' shade always takes up full size of bounding rect
  shade = m.top.findNode("Shade")
  shade.width = m.top.width
  shade.height = m.top.height

  ' max size 200x200 for box
  spinnerBox = m.top.findNode("SpinnerBox")
  rect = calculateRect(200)
  spinnerBox.translation = [rect.x, rect.y]
  spinnerBox.width = rect.width
  spinnerBox.height = rect.height

  ' max size 66x66 for spinner graphic
  spinner = m.top.findNode("SpinnerPoster")
  rect = calculateRect(66)
  spinner.translation = [rect.x, rect.y]
  spinner.width = rect.width
  spinner.height = rect.height
  spinner.scaleRotateCenter=[rect.width / 2, rect.height / 2]
End Function


' Get a bounding rect of a centered square with boundary of max size 'max'. If the max is greater
' than the total size of this Spinner component, the component size is used
Function calculateRect(max As Integer)
  if m.top.width < max
    x = 0
    y = 0
    width = m.top.width
    height = m.top.height
  else
    x = (m.top.width - max) / 2
    y = (m.top.height - max) / 2
    width = max
    height = max
  end if
  return { x: x, y: y, width: width, height: height }
End Function
