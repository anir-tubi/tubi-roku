Function init()
  m.top.backgroundURI = "pkg:/images/black.png"
  m.top.overhang.showClock = false

  m.global.update({
    constants: getConstants()
  }, true)

  m.mainMenuPanel = m.top.panelSet.createChild("MainMenuPanel")
End Function
