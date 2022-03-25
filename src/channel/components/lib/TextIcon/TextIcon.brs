Function init()
  m.textLabel = m.top.findNode("textLabel")
  m.textLabel.observeFieldScoped("text", "onTextChange")
End Function


Function onTextChange(msg)
  text = msg.getData()
  textBackground = m.top.findNode("textBackground")
  nRatingBoundingBoxIncrease = m.textLabel.boundingRect().width + 24
  textBackground.width = nRatingBoundingBoxIncrease
  m.textLabel.width = nRatingBoundingBoxIncrease
End Function