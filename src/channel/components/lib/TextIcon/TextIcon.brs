Function init()
  m.textLabel = m.top.findNode("textLabel")
  m.textLabel.observeFieldScoped("text", "onTextChange")

  m.textBackground = m.top.findNode("textBackground")
  m.top.observeFieldScoped("uri", "onUriChange")
End Function

Function onTextChange()
  ' If we don't reset back to 0 before our boundRect our y position won't be correct
  m.textLabel.translation = [0, 0]
  boundingRect = m.textLabel.boundingRect()

  padding = m.top.padding
  xPadding = padding[0]
  yPadding = padding[1]
  m.textBackground.width = boundingRect.width + xPadding * 2
  m.textBackground.height = boundingRect.height + yPadding * 2

  ' boundingRect.y is negative because of us using baseline so we subtract to to add it on
  m.textLabel.translation = [xPadding, yPadding + boundingRect.height / 2 - boundingRect.y / 2]
End Function

Function onUriChange(msg)
  uri = msg.getData()

  ' Allows not having to setup uri in brs just to be able to switch between hd and fhd or to have to use two uris
  m.textBackground.uri = setImageUriSize(uri)
End Function
