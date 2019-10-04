Function init()
  ' wait for any children to be added to the scene
  m.top.observeField("change", "onChildrenChange")
End Function

Function onChildrenChange()
  m.top.unobserveField("change")
  ' can consider putting an animated logo video here
End Function