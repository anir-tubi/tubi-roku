Function init()
  topRef = m.top

  m.tooltipBackground = topRef.findNode("TooltipBackground")
  m.tooltipText = topRef.findNode("TooltipText")
  m.tooltipArrow = topRef.findNode("TooltipArrow")

  topRef.observeFieldScoped("text", "onTextChanged")
  topRef.observeFieldScoped("typography", "onTypographyChanged")
  topRef.observeFieldScoped("arrowPlacement", "onArrowPlacementChanged")
  topRef.observeFieldScoped("showArrow", "onShowArrowChanged")

  m.typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.tooltipText, m.typographyConstants.ids.bodyExtraSmallStrong)

  ' Initialize arrow visibility
  m.tooltipArrow.visible = topRef.showArrow
End Function


Function onTextChanged(msg)
  text = msg.getData()
  m.tooltipText.text = text
  adjustTooltipSize()
End Function


Function onTypographyChanged(msg)
  typography = msg.getData()

  if isString(typography) = true AND m.typographyConstants.ids[typography] <> invalid
    typographyId = m.typographyConstants.ids[typography]
    setTypographyOfLabel(m.tooltipText, typographyId)
    adjustTooltipSize()
  end if
End Function


Function onArrowPlacementChanged(msg)
  adjustTooltipSize()
End Function


Function onShowArrowChanged(msg)
  showArrow = msg.getData()
  m.tooltipArrow.visible = showArrow
  adjustTooltipSize()
End Function


Function adjustTooltipSize()
  topRef = m.top

  if topRef.autoSize = true
    textWidth = m.tooltipText.boundingRect().width
    textHeight = m.tooltipText.boundingRect().height
    horizontalPadding = topRef.horizontalPadding
    backgroundHeight = topRef.height

    ' Calculate the background width based on text width plus padding
    targetWidth = textWidth + horizontalPadding

    m.tooltipBackground.width = targetWidth

    ' Center the text within the background
    xOffset = (targetWidth - textWidth) / 2
    yOffset = (backgroundHeight - textHeight) / 2

    m.tooltipText.translation = [xOffset, yOffset]
  else
    ' If autoSize is false, use the fixed width and center the text
    backgroundWidth = topRef.width
    backgroundHeight = topRef.height
    textWidth = m.tooltipText.boundingRect().width
    textHeight = m.tooltipText.boundingRect().height

    xOffset = (backgroundWidth - textWidth) / 2
    yOffset = (backgroundHeight - textHeight) / 2

    m.tooltipText.translation = [xOffset, yOffset]
  end if

  ' Position the arrow based on placement
  positionArrow()
End Function


' Positions and rotates the arrow based on the arrowPlacement field
' Placements:
'   - left: no rotation, attached to left edge, centered vertically
'   - right: 180° rotation, attached to right edge, centered vertically
'   - up: 90° clockwise rotation, attached to top edge, centered horizontally
'   - bottom: 90° counter-clockwise rotation, attached to bottom edge, centered horizontally
Function positionArrow() as Void
  topRef = m.top

  if topRef.showArrow = false
    return
  end if

  ' PI constant for rotation calculations
  pi = 3.14159265359

  arrowPlacement = topRef.arrowPlacement
  backgroundWidth = m.tooltipBackground.width
  backgroundHeight = topRef.height
  size = m.tooltipArrow.boundingRect()

  arrowWidth = size.width
  arrowHeight = size.height

  ' Set the rotation center to the center of the arrow image
  m.tooltipArrow.scaleRotateCenter = [arrowWidth / 2, arrowHeight / 2]

  if arrowPlacement = "left"
    ' No rotation, attach to left edge, centered vertically
    m.tooltipArrow.rotation = 0
    arrowX = -arrowWidth
    arrowY = (backgroundHeight - arrowHeight) / 2
    m.tooltipArrow.translation = [arrowX, arrowY]

  else if arrowPlacement = "right"
    ' 180° rotation, attach to right edge, centered vertically
    m.tooltipArrow.rotation = pi
    arrowX = backgroundWidth
    arrowY = (backgroundHeight - arrowHeight) / 2
    m.tooltipArrow.translation = [arrowX, arrowY]

  else if arrowPlacement = "top"
    ' 90° clockwise rotation (PI/2), attach to top edge, centered horizontally
    m.tooltipArrow.rotation = -pi / 2
    arrowX = (backgroundWidth - arrowHeight) / 2
    arrowY = -arrowWidth
    m.tooltipArrow.translation = [arrowX, arrowY]

  else if arrowPlacement = "bottom"
    ' 90° counter-clockwise rotation (-PI/2), attach to bottom edge, centered horizontally
    m.tooltipArrow.rotation = pi / 2
    arrowX = (backgroundWidth - arrowHeight) / 2
    arrowY = backgroundHeight
    m.tooltipArrow.translation = [arrowX, arrowY]

  end if
End Function
