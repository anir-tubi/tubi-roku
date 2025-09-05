Function init()
  m.top.list = m.top.findNode("labelList")

  m.top.observeField("createNextPanelIndex", "onCreateNextPanelIndexChanged")

  m.top.panelSize = "narrow"
  m.top.leftOnly = true
  m.top.selectButtonMovesPanelForward = true
  m.top.overhangTitle = "Tubi Companion App"
End Function


Function onCreateNextPanelIndexChanged(msg)
  panelType = m.top.list.content.getChild(msg.getData()).subtype
  m.top.nextPanel = createObject("RoSGNode", panelType)
End Function
