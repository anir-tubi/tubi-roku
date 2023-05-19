Function init()
  constants = getConstantsFromGlobal()
  pauseAdBackLabel = m.top.findNode("PauseAdBackLabel")
  pauseAdBackLabel.text = getTranslation("goBack_videoPlayer_ad")
  rectangleGradient = m.top.findNode("RectangleGradient")
  rectangleGradient.color = constants.ui.themes.default.shadeColor
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  tubiLog("PauseAdGroup.onKeyEvent key = " + key + " press: " + press.toStr())
  handled = false

  if press
    if key = "back"
      fade(m.top, "out", 0.1)
      m.top.close = true
      handled = true
    else if key = "fastforward" OR key = "rewind" OR key = "play" OR key = "replay" OR key = "options"
      fade(m.top, "out", 0.1)
      m.top.close = true
      handled = false
    else if key = "OK" OR key = "up" OR key = "down" OR key = "left" OR key = "right"
      handled = true
    end if
  end if

  return handled
End Function
