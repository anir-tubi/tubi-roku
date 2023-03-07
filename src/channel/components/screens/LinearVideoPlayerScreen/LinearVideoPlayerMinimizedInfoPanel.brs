Function init()
  m.constants = getConstantsFromGlobal()

  m.channelIcon = m.top.findNode("channelIcon")
  m.minutesLeft = m.top.findNode("minutesLeft")
  m.title1 = m.top.findNode("title1")
  m.title2 = m.top.findNode("title2")
  m.time = m.top.findNode("time")
  m.programProgressBar = m.top.findNode("programProgressBar")
  m.background = m.top.findNode("background")


  m.top.observeField("metadata", "onMetadataChanged")
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
    m.background.color = theme.backgroundColor
    m.programProgressBar.color = theme.neutralColor2
    m.minutesLeft.color = theme.secondaryTextColor
    m.title1.color = theme.primaryTextColor
    m.title2.color = theme.secondaryTextColor
    m.time.color = theme.secondaryTextColor
  end if
End Function


Function onMetadataChanged()
  metadata = m.top.metadata 
  if metadata.channelURI <> invalid
    m.channelIcon.uri = metadata.channelURI
  else
    m.channelIcon.uri = ""
  end if

  if metadata.minutesLeft >= 0 AND metadata.currentDuration > 0 AND metadata.minutesLeft < metadata.currentDuration
    nPercentDone = (metadata.currentDuration - metadata.minutesLeft)/metadata.currentDuration
    m.programProgressBar.width = m.background.width * nPercentDone
    m.programProgressBar.visible = true
  else
    m.programProgressBar.width = 0
    m.programProgressBar.visible = false
  end if

  if metadata.minutesLeft <> invalid AND metadata.minutesLeft >= 0
    m.minutesLeft.text = getTranslation("epg_minutes_left", {minutes: toStr(metadata.minutesLeft)})
    m.title1.translation = [m.title1.translation[0],60]
  else
    m.minutesLeft.text = ""
    m.title1.translation = [m.title1.translation[0],45] '//vertically center title if no minutesLeft
  end if

  if metadata.title1 <> invalid
    m.title1.text = metadata.title1
  else
    m.title1.text = ""
  end if

  if metadata.title2 <> invalid
    m.title2.text = metadata.title2
  else
    m.title2.text = ""
  end if

  if metadata.time <> invalid
    m.time.text = metadata.time
  else
    m.time.text = ""
  end if
End Function