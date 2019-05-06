Function init()
  m.limitedUi = m.global.constants.deviceInfo.limitedUi
  m.top.opacity = "0.8"
  m.top.observeField("width", "onDimensionsChange")
  m.top.observeField("height", "onDimensionsChange")
  m.top.observeField("isDisabled", "onIsDisabled")
  m.top.observeField("displayText", "onIsDisabled")
End Function


'Previously in init()
Function onIsDisabled()
  ' Non-OpenGL slow devices look really poor with clunky spinner
  loadingMessage = m.top.findNode("LoadingMessage")
  ' While we are using the SKD1 version of RAF, the search screen does not repopulate poster images if
  ' the following spinners are in effect. This should be temporary and full spinner usage should be ok 
  ' once we move to the SG version of RAF.
  if m.limitedUi <> true and m.top.isDisabled <> true
    m.Animation = m.top.findNode("SpinnerAnimation")
    m.top.observeField("visible", "onVisibilityChange")
    if m.top.visible then
      m.Animation.control = "start"
    end if
    if m.top.displayText = true
      loadingMessage.visible = true
    end if
  else
    loadingMessage.visible = true
    spinner = m.top.findNode("SpinnerPoster")
    spinner.visible = false
  end if
  onDimensionsChange() '//update the placement of spinners
End Function

Function onVisibilityChange()
  if m.top.visible = true and m.Animation.state <> "running" then
    m.Animation.control = "start"
  else if m.top.visible = false then
    m.Animation.control = "stop"
  end if
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
  message = m.top.findNode("LoadingMessage")
  
  rectMessage = calculateRect(m.top.width * .6, 66)
  message.width = rectMessage.width
  nMessageX = (m.top.width - rectMessage.width) / 2 '//ensure the message is center - assuming the text of the message is centered aligned
  message.height = rectMessage.height
  if spinner.visible
    rect = calculateRect(66, 66)
    spinner.width = rect.width
    spinner.height = rect.height
    spinner.scaleRotateCenter=[rect.width / 2, rect.height / 2]
    if m.top.displayText = true
      '//vertically center both sprinner and message
      nMessageSpacing = 37
      nAdditionalMessageHeight = message.height + nMessageSpacing
      nSpinnerY = rect.y - nAdditionalMessageHeight / 2
      spinner.translation = [rect.x, nSpinnerY]
      message.translation = [nMessageX, nSpinnerY + nMessageSpacing + spinner.height]
    else 
      spinner.translation = [rect.x, rect.y]
    end if
  else
    message.translation = [nMessageX, rectMessage.y]
  end if
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


Function onKeyEvent(key, press)
  return m.top.modal
End Function