Function init()
  m.constants = getConstantsFromGlobal()
  m.parentGroup = m.top.findNode("parentGroup")
  m.experienceLogo = m.top.findNode("experienceLogo")
  m.unfocusedBackgroundPoster = m.top.findNode("unfocusedBackgroundPoster")
  m.focusedBackgroundPoster = m.top.findNode("focusedBackgroundPoster")

  uri = "pkg:/images/icts_item_unfocused_fhd.9.png"
  if m.constants.deviceInfo.scaledUi = true
    uri = "pkg:/images/icts_item_unfocused_hd.9.png"
  end if
  m.unfocusedBackgroundPoster.uri = uri

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
End Function


Function onItemContentChange(msg)
  content = msg.getData()

  m.experienceLogo.experienceId = content.experienceId
  m.focusedBackgroundPoster.blendColor = content.backgroundColor
  m.parentGroup.opacity = 0

  rowContent = content.getParent()
  rowContent.unobserveFieldScoped("animate")
  rowContent.observeFieldScoped("animate", "onAnimateChange")

  ' ArrayGrid might not have created the node until after we set animate so have to check if it's already set
  if rowContent.animate = true
    onAnimateChange()
  end if
End Function

Function onAnimateChange()
  delay = .2*m.top.index
  m.parentGroup.opacity = 0
  slideFade(m.parentGroup, "above", "in", .5, delay, 60)
End Function
