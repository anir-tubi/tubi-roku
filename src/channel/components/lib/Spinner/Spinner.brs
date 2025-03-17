Function init()
  m.limitedUi = true

  m.Shade = m.top.findNode("shade")
  m.spinnerBox = m.top.findNode("SpinnerBox")
  constants = getConstantsFromGlobal()
  if constants <> invalid
    m.limitedUi = constants.deviceInfo.limitedUi
  end if

  m.top.opacity = "0.8"
  m.top.observeField("width", "onDimensionsChange")
  m.top.observeField("height", "onDimensionsChange")
  m.top.observeField("horizAlign", "onDimensionsChange")
  m.top.observeField("vertAlign", "onDimensionsChange")

  ' Non-OpenGL slow devices look really poor with clunky spinner
  ' https://developer.roku.com/en-gb/docs/specs/hardware.md
  loadingMessage = m.top.findNode("LoadingMessage")
  loadingMessage.text = getTranslation("loadingIndicator")
  if m.limitedUi <> true
    m.Animation = m.top.findNode("SpinnerAnimation")
    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("opacity", "onOpacityChange")
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
  
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(loadingMessage, typographyConstants.ids.bodyMedium)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if
  
  if theme <> invalid
    m.Shade.color = theme.shadeColor
    m.spinnerBox.color = theme.neutralSolidColor
  end if
End Function


Function onVisibleChange(msg)
  visibility = msg.getData()
  if visibility = true and m.Animation.state <> "running" then
    m.Animation.control = "start"
  else if visibility = false then
    m.Animation.control = "stop"
  end if
End Function


Function onOpacityChange(msg)
  opacity = msg.getData()
  if opacity = 0 then
    m.top.visible = false
  end if
End Function


Function onDimensionsChange()
  ' shade always takes up full size of bounding rect
  shade = m.top.findNode("Shade")
  shade.width = m.top.width
  shade.height = m.top.height

  ' max size 200x200 for box
  rect = calculateRect(200, 200)
  m.spinnerBox.translation = [rect.x, rect.y]
  m.spinnerBox.width = rect.width
  m.spinnerBox.height = rect.height

  ' max size 66x66 for spinner graphic
  spinner = m.top.findNode("SpinnerPoster")
  message = m.top.findNode("LoadingMessage")
  message.horizAlign = m.top.horizAlign

  rectMessage = calculateRect(m.top.width * .6, 30)
  message.width = rectMessage.width

  '//center is the default value for the message
  nMessageX = (m.top.width - rectMessage.width) / 2 '//ensure the message is center - assuming the text of the message is centered aligned
  if m.top.horizAlign = "right"
    nMessageX = m.top.width - rectMessage.width
  else if m.top.horizAlign = "left"
    nMessageX = 0
  end if

  message.height = rectMessage.height
  if spinner.visible
    rect = calculateRect(66, 66)
    spinner.width = rect.width
    spinner.height = rect.height
    spinner.scaleRotateCenter=[rect.width / 2, rect.height / 2]
    if m.top.displayText = true
      '//vertically center both spinner and message
      nMessageSpacing = 37
      nAdditionalMessageHeight = message.height + nMessageSpacing
      nSpinnerY = rect.y - nAdditionalMessageHeight / 2
      spinner.translation = [rect.x, nSpinnerY]
      message.translation = [nMessageX, nSpinnerY + nMessageSpacing + spinner.height]
    else
      spinner.translation = [rect.x, rect.y]
    end if
  else
    '//center is the default value for the message
    nMessageY = rectMessage.y '//ensure the message is center - assumes the text of the message is centered aligned by default
    if m.top.vertAlign = "bottom"
      nMessageY = m.top.height - rectMessage.height
    else if m.top.vertAlign = "top"
      nMessageY = 0
    end if
    message.translation = [nMessageX, nMessageY]
  end if
  End Function


  ' Get a bounding rect of a square with boundary of max size 'max'. Alignment should be dictated by the vertAlign and horizAlign values.
  ' If the max is greater than the total size of this Spinner component, the component size is used
  Function calculateRect(maxWidth, maxHeight)
  if m.top.width < maxWidth
    x = 0
    width = m.top.width
  else
    x = (m.top.width - maxWidth) / 2  '//center is the default value
    if m.top.horizAlign = "right"
      x = m.top.width - maxWidth
    else if m.top.horizAlign = "left"
      x = 0
    end if
    width = maxWidth
  end if
  if m.top.height < maxHeight
    y = 0
    height = m.top.height
  else
    y = (m.top.height - maxHeight) / 2  '//center is the default value
    if m.top.vertAlign = "bottom"
      y = m.top.height - maxHeight
    else if m.top.vertAlign = "top"
      y = 0
    end if
    height = maxHeight
  end if
  return { x: x, y: y, width: width, height: height }
End Function

Function onKeyEvent(_key, _press) as Boolean
  return m.top.modal
End Function
