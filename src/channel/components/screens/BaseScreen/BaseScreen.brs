Function init()
End Function


Function determineBackgroundImage(content)
  if isNode(content) = true AND isNonEmptyArray(content.backgrounds) = true then
    return content.backgrounds
  else
    return [m.defaultBackgroundUri]
  end if
End Function
