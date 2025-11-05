Function init()
  topRef = m.top
  m.tileLayout = topRef.findNode("tileLayout")
  m.videoInGridGradient = topRef.findNode("videoInGridGradient")
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("height", "onHeightChange")

  experimentInfo = getStatsigExperimentResource("roku_video_tiles", "roku_video_tiles_1_7", false)
  if isAA(experimentInfo) = true
    m.variant = experimentInfo.variant
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()
  m.tileLayout.visible = itemContent <> invalid
End Function


Function onHeightChange(msg)
  height = msg.getData()
  if height > 0
    m.videoInGridGradient.height = height
  end if
End Function
