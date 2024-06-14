Function init()
  m.top.observeFieldScoped("fraction", "onFractionChanged")
  m.top.observeFieldScoped("key", "onKeyChanged")
  m.top.observeFieldScoped("vector4DKeyValue", "onVector4DKeyValueChanged")

  m.keys = []
  m.keyValues = []

  'the result of findNode on the passed in fieldToInterp
  m.interpolatedNode = invalid

  ' field part of the passed in fieldToInterp
  m.interpolatedField = ""
End Function


Function onFractionChanged(msg)
  fraction = msg.getData()

  if m.interpolatedNode = invalid then
    fieldToInterpParts = m.top.fieldToInterp.split(".")
    interpolatedField = fieldToInterpParts.pop()
    if interpolatedField <> invalid then
      m.interpolatedField = interpolatedField
    end if

    ' We have to go up a level to find the node to interpolate since the interpolator is a child of an Animation
    m.interpolatedNode = m.top.getParent().findNode(fieldToInterpParts.join("."))
    if m.interpolatedNode = invalid then
      tubiLog("Could not find node to interpolate on")
    end if
  end if

  if m.interpolatedNode <> invalid then
    for i = 0 to m.keys.count() - 1
      startKey = m.keys[i]
      endKey = m.keys[i + 1]

      if startKey <= fraction AND endKey <> invalid AND endKey >= fraction then
        ' Avoids us dividing by 0
        if startKey <> endKey then
          startKeyValue = m.keyValues[i]
          endKeyValue = m.keyValues[i + 1]
          if startKeyValue <> invalid AND endKeyValue <> invalid then
            stepPercent = (fraction - startKey) / (endKey - startKey)

            computedValue = []
            computedValue.push(startKeyValue[0] + (endKeyValue[0] - startKeyValue[0]) * stepPercent)
            computedValue.push(startKeyValue[1] + (endKeyValue[1] - startKeyValue[1]) * stepPercent)
            computedValue.push(startKeyValue[2] + (endKeyValue[2] - startKeyValue[2]) * stepPercent)
            computedValue.push(startKeyValue[3] + (endKeyValue[3] - startKeyValue[3]) * stepPercent)

            m.interpolatedNode.setField(m.interpolatedField, computedValue)
          end if
        end if
        exit for
      end if
    end for
  end if
End Function


Function onKeyChanged(msg)
  keys = msg.getData()

  if isArray(keys) = true then
    m.keys = keys
  end if
End Function


Function onVector4DKeyValueChanged(msg)
  keyValues = msg.getData()

  if isArray(keyValues) = true then
    isValidValue = true
    for each keyValue in keyValues
      if isArray(keyValue) = false OR keyValue.count() <> 4 then
        isValidValue = false
        tubiLog("Invalid key value provided should be a 4D vector")
        exit for
      end if
    end for

    if isValidValue = true then
      m.keyValues = keyValues
    else
      m.keyValues = []
    end if
  end if
End Function
