Function init()
  topRef = m.top
  m.tileLayout = topRef.findNode("tileLayout")
  m.videoInGridGradient = topRef.findNode("videoInGridGradient")
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("height", "onHeightChange")

  experimentInfo = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v_1_6", false)
  if isAA(experimentInfo) = true
    m.variant = experimentInfo.variant
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()
  m.tileLayout.visible = itemContent <> invalid

  isBillboardRow = m.variant = "billboard" AND m.top.containerIndex = m.top.billboardContainerIndex
  if isBillboardRow = false
    m.videoInGridGradient.uri = "pkg:/images/video_in_grid_gradient_$$RES$$.9.png"
  else
    m.videoInGridGradient.uri = "pkg:/images/billboard-gradient-$$RES$$.webp"
  end if
End Function


Function onHeightChange(msg)
  height = msg.getData()
  if height > 0
    m.videoInGridGradient.height = height
  end if
End Function
