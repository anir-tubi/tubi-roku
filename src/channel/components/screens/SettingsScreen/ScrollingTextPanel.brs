Function init()
  m.top.observeField("focusedChild", "onComponentFocus")
  m.top.observeField("isLoading", "onIsLoading")
  m.ContentGroup = m.top.findNode("ContentGroup")
  m.Spinner = m.top.findNode("Spinner")
  m.Text = m.top.findNode("Text")
  if getExperimentResource("roku_safe_zone", "roku_safe_zone_v2", false).enabled = true
    m.Text.height = 615
  end if
  m.theme = m.global.theme

  m.Text.scrollbarTrackBitmapUri = "pkg:/does-not-exist.png" ' Setting this to an empty string or invalid will cause
                                                             ' the default track image to show.  We hide it by
                                                             ' setting a garbage value here
  if m.global.constants.deviceInfo.scaledUi = true
    m.focusBitmapUri = m.theme.scrollbarThumbBitmapUri_hd
    m.focusFootprintUri = "pkg:/images/transport/sgplayer/hd/unfocused-progress-foreground.9.png"
  else
    m.focusBitmapUri = m.theme.scrollbarThumbBitmapUri_fhd
    m.focusFootprintUri = "pkg:/images/transport/sgplayer/fhd/unfocused-progress-foreground.9.png"
  end if
   m.Text.scrollbarThumbBitmapUri = m.focusFootprintUri
End Function

Function onComponentFocus()
 tubiLog("ScrollingTextPanel.onComponentFocus")
 if m.top.isInFocusChain() 
   if m.top.hasFocus()
     m.Text.setFocus(true)
   end if
   m.Text.scrollbarThumbBitmapUri = m.focusBitmapUri
 else
   m.Text.scrollbarThumbBitmapUri = m.focusFootprintUri
 end if
End Function

Function onIsLoading()
  tubiLog("ScrollingTextPanel.onIsLoading")
  if m.top.isLoading = true
    m.Spinner.visible = true
    m.ContentGroup.visible = false
  else
    m.Spinner.visible = false
    m.ContentGroup.visible = true
  end if
End Function
