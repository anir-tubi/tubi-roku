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
  else
    loadingMessage = m.top.findNode("LoadingMessage")
    loadingMessage.visible = true
    spinner = m.top.findNode("SpinnerPoster")
    spinner.visible = false
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
  rect = calculateRect(200, 200)
  spinnerBox.translation = [rect.x, rect.y]
  spinnerBox.width = rect.width
  spinnerBox.height = rect.height

  ' max size 66x66 for spinner graphic
  spinner = m.top.findNode("SpinnerPoster")
  if spinner.visible
    rect = calculateRect(66, 66)
    spinner.width = rect.width
    spinner.height = rect.height
    spinner.scaleRotateCenter=[rect.width / 2, rect.height / 2]
  else
    rect = calculateRect(180, 66)
    message = m.top.findNode("LoadingMessage")
    message.width = rect.width
    message.height = rect.height
  end if
  posterOrMessage = m.top.findNode("PosterOrMessage")
  posterOrMessage.translation = [rect.x, rect.y]
End Function


' Get a bounding rect of a centered square with boundary of max size 'max'. If the max is greater
' than the total size of this Spinner component, the component size is used
Function calculateRect(maxWidth, maxHeight)
  if m.top.width < maxWidth
    x = 0
    width = m.top.width
  else
    x = (m.top.width - maxWidth) / 2
    width = maxWidth
  end if
  if m.top.height < maxHeight
    y = 0
    height = m.top.height
  else
    y = (m.top.height - maxHeight) / 2
    height = maxHeight
  end if
  return { x: x, y: y, width: width, height: height }
End Function
