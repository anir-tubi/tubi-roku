Function init()

  m.continueWatchingLayout = m.top.findNode("continueWatchingLayout")
  m.continueWatchingButton= m.top.findNode("ButtonGroup")
  m.title = m.top.findNode("Title")
  

  if getExperimentResource("roku_continue_watching_signed_out", "roku_continue_watching_signed_out_experiment", false).display_free = true
    sTitle = getTranslation("metadata_continueWatching_notSignedIn_container_description_experiment2")
    sButton = getTranslation("metadata_continueWatching_notSignedIn_container_button_experiment2")
  else 
    sTitle = getTranslation("metadata_continueWatching_notSignedIn_container_description_experiment1")
    sButton = getTranslation("metadata_continueWatching_notSignedIn_container_button_experiment1")
  end if
  m.title.text = sTitle

  m.button = m.top.findNode("button")
  contentNode = CreateObject("roSGNode", "DetailMenuItemContentNode")
  contentNode.title = sButton
  m.button.itemContent = contentNode


  m.buttonBG = m.top.findNode("buttonBg")
  m.buttonBG.blendColor = m.global.theme.focused

  setButtonWidthAndAlignment()
End Function

Function setButtonWidthAndAlignment()
  nTextWidth = m.button.calculatedTextWidth

  nButtonBGWidth = m.buttonBG.width
  nMinSpacing = 80
  if m.button.leftTextPadding > nMinSpacing
    nMinSpacing = m.button.leftTextPadding
  end if 

  '//1st ensure the width of the BG is greater than the label
  nEntireWidth = (nMinSpacing - m.button.leftTextPadding) + m.button.calculatedWidth + nMinSpacing
  m.buttonBG.width = nEntireWidth

  '//2nd ensure the BG and label are center aligned
  m.button.translation = [nMinSpacing - m.button.leftTextPadding, m.button.translation[1]]
  
End Function
