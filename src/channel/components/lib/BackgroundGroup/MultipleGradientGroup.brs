Function init()

  m.gradientGroup = m.top.findNode("gradientGroup")

  m.lastAnimationName = m.top.findNode("lastAnimationName")
  m.uris = m.top.findNode("uris")
  m.fadeInControl = m.top.findNode("fadeInControl")
  m.fadeOutControl = m.top.findNode("fadeOutControl")
  m.gradientOpacity = m.top.findNode("gradientOpacity")

  m.top.observeField("lastAnimationName", "onLastAnimationName")
  m.top.observeField("uriList", "onUriListReceived")
  m.top.observeField("fadeInControl", "onFadeInControl")
  m.top.observeField("fadeOutControl", "onFadeOutControl")
  m.top.observeField("gradientOpacity", "OnGradientOpacity")

  m.gradientGroupCount = 0

End Function


Function onLastAnimationName()

  for i = 0 to m.gradientGroupCount-1
    gradient = m.gradientGroup.getChild(i)
    gradient.lastAnimationName = m.top.lastAnimationName
  end for

End Function


Function onUriListReceived()

  uriList = m.top.uriList
  if uriList <> invalid

    index = 0
    for each uri in uriList

      gradient = m.gradientGroup.CreateChild("BackgroundGradientGroup")
      gradient.id = "gradient_" + index.tostr()
      gradient.uri = uri
      gradient.gradientOpacity = 0.0
      index += 1

    end for

  end if

  m.gradientGroupCount = m.gradientGroup.getChildCount()

End Function


Function onFadeInControl()

  for i = 0 to m.gradientGroupCount-1
    gradient = m.gradientGroup.getChild(i)
    gradient.fadeInControl = m.top.fadeInControl
  end for

End Function



Function onFadeOutControl()

  for i = 0 to m.gradientGroupCount-1
    gradient = m.gradientGroup.getChild(i)
    gradient.fadeOutControl = m.top.fadeOutControl
  end for

End Function


Function OnGradientOpacity()

  for i = 0 to m.gradientGroupCount-1
    gradient = m.gradientGroup.getChild(i)
    gradient.gradientOpacity = m.top.gradientOpacity
  end for

End Function