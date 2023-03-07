Function init()
  ' Typically for content items in a grid, we do not want to access global, as it will rendezvous
  ' for each of the items created. However, only one instance of a ContinueWatchingCategoryGridPoster
  ' is ever expected in the home screen, so we can accept the single rendezvous.
  ' constants is added to m here because there are several calls to get getTranslation() below.
  ' Since getTranslation() will fetch constants from global if there is no m.constants, fetching
  ' constant from global once here, requires less rendezvous than fetching constants from global
  ' each time getTranslation() is called.
  m.constants = getConstantsFromGlobal()
  m.continueWatchingLayout = m.top.findNode("continueWatchingLayout")
  m.continueWatchingButton= m.top.findNode("ButtonGroup")
  m.title = m.top.findNode("Title")

  sTitle = getTranslation("metadata_continueWatching_notSignedIn_container_description")
  sButton = getTranslation("metadata_continueWatching_notSignedIn_container_button")
  m.title.text = sTitle

  m.button = m.top.findNode("button")
  contentNode = CreateObject("roSGNode", "DetailMenuItemContentNode")
  contentNode.title = sButton
  m.button.itemContent = contentNode


  m.buttonBG = m.top.findNode("buttonBg")
  setButtonWidthAndAlignment()

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if
  
  if theme <> invalid
    m.buttonBG.blendColor = theme.focusedColor
    m.Title.color = theme.primaryTextColor
  end if
End Function


Function setButtonWidthAndAlignment()
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
