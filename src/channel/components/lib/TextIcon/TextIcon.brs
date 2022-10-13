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

  ' The y translation is calculated based on the following info
  ' 1) we are using m.textLabel.vertOrigin = "baseline" which means the top of the text is higer than the origin
  '    so we need to add the textHeight to the y translation to bring the top of the text even with the origin
  ' 2) drop the text by the yPadding amount so there is space between the top of the background and the top of
  '    the text
  ' 3) drop an extra pixel to account for roku firmware not doing a good job with text... in this case the actual
  '    amount of vertical pixel space that text characters occupy on the screen is less than the boundingRect().height
  '    is reported as. The 1 pixel adjustment is found by trial and error.
  m.textLabel.translation = [xPadding, textHeight + yPadding - 1]
End Function

Function onUriChange(msg)
  uri = msg.getData()

  ' Allows not having to setup uri in brs just to be able to switch between hd and fhd or to have to use two uris
  m.textBackground.uri = setImageUriSize(uri)
End Function
