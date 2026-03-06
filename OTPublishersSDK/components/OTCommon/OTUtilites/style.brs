Function setColor(list, color) as Object
  for each item in list
    item.color = color
  end for
End Function

Function setWidth(list, width) as Object
  for each item in list
    item.width = width
  end for
End Function

Function setFont(list, font) as Object
  for each item in list
    item.font = font
  end for
End Function

Function getNode()
  node = {
    font: Function(uri as String, size as Integer)
      label = CreateObject("roSGNode", "Label")
      if uri.Instr("font:") <> -1
        label.font = uri
      else
        label.font.uri = uri
      end if
      label.font.size = size
      return label.font
    End Function,
    label: Function(id = "label" as String, text = "" as String, font = "font:MediumSystemFont" as Dynamic, color = "0x000000" as Dynamic, width = 0 as Float) as Dynamic
      label = CreateObject("roSGNode", "Label")
      label.id = id
      label.text = text
      label.font = font
      label.color = color
      label.width = width
      label.wrap = true
      return label
    End Function,
    MultiStyleLabel: Function(id = "MultiStyleLabel" as String, text = "" as String, width = 0 as Float) as Dynamic
      label = CreateObject("roSGNode", "MultiStyleLabel")
      label.id = id
      label.text = text
      label.width = width
      label.wrap = true
      return label
    End Function,
    getMultiStyleLabel: Function(id = "MultiStyleLabel" as String, isMultiStyleLabel = false, label = invalid, text = "" as String, drawingStyles = {}, width = 0 as Float) as Dynamic
      if not isValid(label)
        label = CreateObject("roSGNode", "Label")
        if isvalid(isMultiStyleLabel) AND isMultiStyleLabel then label = CreateObject("roSGNode", "MultiStyleLabel")
        label.id = id
        label.text = text
        label.width = width
        label.wrap = true
      else
        if isValid(drawingStyles) AND isValid(drawingStyles.default)
          if isValid(label.font) then label.font = drawingStyles.default.fontUri
          label.color = drawingStyles.default.color
          if isvalid(isMultiStyleLabel) AND isMultiStyleLabel AND isValid(label.drawingStyles) then label.drawingStyles = drawingStyles
        end if
        label.text = text
        label.width = width
      end if
      return label
    End Function,
    layoutGroup: Function(id = "layoutGroup" as String, layoutDirection = "vert" as String, itemSpacings = [10] as Dynamic, vertAlignment = "top" as String, horizAlignment = "left" as String)
      layoutGroup = CreateObject("roSGNode", "LayoutGroup")
      layoutGroup.id = id
      layoutGroup.layoutDirection = layoutDirection
      layoutGroup.vertAlignment = vertAlignment
      layoutGroup.horizAlignment = horizAlignment
      layoutGroup.itemSpacings = itemSpacings
      return layoutGroup
    End Function,
    rectangle: Function(id = "rectangle" as String, color = "0x000000" as Dynamic, width = 0 as Float, height = 0 as Float)
      rectangle = CreateObject("roSGNode", "Rectangle")
      rectangle.id = id
      rectangle.color = color
      rectangle.width = width
      rectangle.height = height
      return rectangle
    End Function
    animation: Function(fieldToInterp as String, id = "rectangle" as String, duration = "0.5" as String, easeFunction = "linear" as String)
      animation = CreateObject("roSGNode", "Animation")
      animation.id = id
      animation.duration = duration
      animation.easeFunction = easeFunction
      animation.optional = true

      Vector2DFieldInterpolator = CreateObject("roSGNode", "Vector2DFieldInterpolator")
      Vector2DFieldInterpolator.id = id + "Interpolator"
      Vector2DFieldInterpolator.key = "[0.0, 1.0]"
      Vector2DFieldInterpolator.fieldToInterp = fieldToInterp

      animation.appendChild(Vector2DFieldInterpolator)
      return animation
    End Function
  }

  return node
End Function

