Function init()
  m.constants = getConstantsFromGlobal()

  m.textIcon = m.top.findNode("textIcon")
  m.layoutGroup = m.top.findNode("layoutGroup")

  m.top.observeFieldScoped("experienceId", "onExperienceIdChange")
  m.top.observeFieldScoped("width", "onWidthChange")
End Function

Function onWidthChange(msg)
  width = msg.getData()
  ' we have to center the layoutgroup because we're using horizAlignment="center"
  m.layoutGroup.translation = [width / 2, m.layoutGroup.translation[1]]
End Function

Function onExperienceIdChange(msg)
  id = msg.getData()

  text = ""
  blendColor = ""
  if id = m.constants.ui.contentExperienceModes.bestKnown
    text = getTranslation("screenInitialContent_bestKnown_menu_item_title")
    blendColor = "#D81A79"
  else if id = m.constants.ui.contentExperienceModes.nostalgia
    text = getTranslation("screenInitialContent_nostalgia_menu_item_title")
    blendColor = "#D7702C"
  else if id = m.constants.ui.contentExperienceModes.liveTV
    text = getTranslation("menu_livetv")
    blendColor = "#CC090B"
  else if id = m.constants.ui.contentExperienceModes.espanol
    text = "Español"
    blendColor = "#00964E"
  else if id = m.constants.ui.modes.kids
    text = getTranslation("menu_kids")
    blendColor = "#EB9C00"
  end if

  if text <> "" and blendColor <> ""
    m.textIcon.text = ucase(text)
    m.textIcon.blendColor = blendColor
  end if
End Function
