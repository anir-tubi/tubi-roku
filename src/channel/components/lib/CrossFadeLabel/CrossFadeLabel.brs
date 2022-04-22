Function init()
  m.constants = getConstantsFromGlobal()
  m.currentLabel = m.top.findNode("labelA")
  m.nextLabel = m.top.findNode("labelB")
  m.animation = m.top.findNode("animation")
  m.fadeOutInterpolator = m.top.findNode("fadeOutInterpolator")
  m.fadeInInterpolator = m.top.findNode("fadeInInterpolator")

  m.top.observeFieldScoped("text", "onTextChanged")
End Function


Function onTextChanged(msg)
  text = msg.getData()
  if m.constants.deviceInfo.limitedUi = true
    m.currentLabel.text = text
  else
    m.animation.control = "finish"
    m.nextLabel.text = text

    m.fadeOutInterpolator.fieldToInterp = m.currentLabel.id + ".opacity"
    m.fadeInInterpolator.fieldToInterp = m.nextLabel.id + ".opacity"
    m.animation.control = "start"
    ' Swap the labels for the next animation
    temp = m.nextLabel
    m.nextLabel = m.currentLabel
    m.currentLabel = temp
  end if
End Function
