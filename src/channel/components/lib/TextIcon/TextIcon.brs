Function init()
  m.textLabel = m.top.findNode("textLabel")
  m.textLabel.observeFieldScoped("text", "onTextChange")

  m.textBackground = m.top.findNode("textBackground")
  m.top.observeFieldScoped("uri", "onUriChange")
End Function

Function onTextChange()
  ' If we don't reset back to 0 before our boundRect our y position won't be correct
  m.textLabel.translation = [0, 0]
  textBoundingRect = m.textLabel.boundingRect()
  textWidth= textBoundingRect.width
  textHeight = textBoundingRect.height

  padding = m.top.padding
  xPadding = padding[0]
  yPadding = padding[1]
  m.textBackground.width = textWidth + xPadding * 2
  m.textBackground.height = textHeight + yPadding * 2

  ' The x translation assumes that m.textLabel.horizOrigin = "center"
  ' The y translation assumes that m.textLabel.vertOrigin = "center" and that an extra pixel is needed to take into account 
  '    that the roku firmware not doing a good job with text. The 1 pixel adjustment is found by trial and error.
  m.textLabel.translation = [m.textBackground.width/2, m.textBackground.height/2 + 1]
End Function


Function onUriChange(msg)
  uri = msg.getData()

  ' Allows not having to setup uri in brs just to be able to switch between hd and fhd or to have to use two uris
  m.textBackground.uri = setImageUriSize(uri)
End Function
