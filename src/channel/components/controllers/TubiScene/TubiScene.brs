Function init()
  m.timer = m.top.findNode("LoadingTimer")
  m.timer.observeField("fire", "onLoadingTimer")
  m.timer.control = "start"

  ' wait for any children to be added to the scene
  m.top.observeField("change", "onChildrenChange")
End Function

Function onLoadingTimer()
  m.top.findNode("LoadingSpinner").visible = true
End Function

Function onChildrenChange()
  m.top.unobserveField("change")
  m.timer.unobserveField("fire")
End Function