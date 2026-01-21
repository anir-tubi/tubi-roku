Function init()
  m.posterBackground = m.top.findNode("PosterBackground")
  m.posterText = m.top.findNode("PosterText")
  m.top.observeFieldScoped("textFont", "onSetTypography")
  m.top.observeFieldScoped("text", "onSetTypography")
  m.typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.posterText, m.typographyConstants.ids.displayMedium)

  centerText()
End Function


Function centerText()
  ' Center the text on the poster
  if m.posterText.text <> ""

    textSize = m.posterText.boundingRect()

    textX = m.posterBackground.translation[0] + ((m.posterBackground.width - textSize.width) / 2)
    textY = m.posterBackground.translation[1] + ((m.posterBackground.height - textSize.height) / 2)

    m.posterText.translation = [textX, textY]
  end if
End Function


Function onSetTypography()
  fontSize = m.top.textFont

  if isString(fontSize) = true AND m.typographyConstants.ids[fontSize] <> invalid
    fontSize = m.typographyConstants.ids[fontSize]
    setTypographyOfLabel(m.posterText, fontSize)
  else
    ' Default to medium strong if invalid font specified
    setTypographyOfLabel(m.posterText, m.typographyConstants.ids.bodyMediumStrong)
  end if

  m.posterText.text = m.top.text
  centerText()
End Function


