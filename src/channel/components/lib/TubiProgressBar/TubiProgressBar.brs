Function init()
  m.background = m.top.findNode("ProgressBarBackground")
  m.background.observeField("bitmapWidth", "drawProgressBar")
  m.foreground = m.top.findNode("ProgressBarForeground")

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.top.focusColor = theme.primaryTextColor
    m.top.unfocusColor = theme.primaryTextColor
  end if

  m.foreground.observeField("bitmapWidth", "drawProgressBar")
  m.top.observeField("width", "drawProgressBar")
  m.top.observeField("progress", "drawProgressBar")
  m.top.observeField("focusedChild", "drawProgressBar")
  m.top.observeField("scaledUI", "drawProgressBar")
  m.top.observeField("focusColor", "drawProgressBar")
  m.top.observeField("unfocusColor", "drawProgressBar")
  drawProgressBar()
End Function

Function drawProgressBar()
  ' ProgressBarBackground and ProgressBarForeground use 9-patch images which have
  ' special undocumented handling (bugs?).  For manifest with ui_resolution=fhd, we
  ' need to provide 2 resolutions: fhd and hd, where hd 0.75 the intended resolution.  For instance,
  ' we expect the FHD height to be 16 pixels so the hd source image height has to be 12 pixels.  Roku
  ' wrongly applies a 1.5x scaling when ui_resolution=fhd and the screen is 720p.  SD resolutions are
  ' not needed since 720p ui resolution is used and scaled down properly.
  '
  ' NOTE2: 9-patch images can't have width/height set below their native resolution (bitmapWidth/bitmapHeight)
  '        else the 9-patch logic does not get applied and you will just see stretched images.  Because of
  '        scaling wackiness, bitmapWidth or bitmapHeight may report half-pixel values.  It's best to not
  '        set a height explicitly.
  if m.top.scaledUI = true then
    m.background.uri = "pkg:/images/transport/sgplayer/hd/white-progress-foreground.9.png"
    m.foreground.uri = "pkg:/images/transport/sgplayer/hd/white-progress-foreground.9.png"
  else
    m.background.uri = "pkg:/images/transport/sgplayer/fhd/white-progress-foreground.9.png"
    m.foreground.uri = "pkg:/images/transport/sgplayer/fhd/white-progress-foreground.9.png"
  end if

  maxWidth = m.top.width
  ' Because a 9-patch will have artifacts less than the width of the bitmap, we
  ' force it to be at least bitmapWidth
  if maxWidth < m.background.bitmapWidth
    m.background.width = m.background.bitmapWidth
  else
    m.background.width = maxWidth
  end if
  minWidth = m.foreground.bitmapWidth

  percentComplete = m.top.progress
  if percentComplete > 100
    percentComplete = 100
  end if
  if percentComplete < 0
    percentComplete = 0
  end if

  if percentComplete = 0
    m.foreground.visible = false
  else
    m.foreground.visible = true
    m.foreground.width = minWidth + (percentComplete / 100.0) * (maxWidth - minWidth)
  end if

  if m.top.isInFocusChain() then
    m.foreground.blendColor = m.top.focusColor
  else
    m.foreground.blendColor = m.top.unfocusColor
  end if
End Function