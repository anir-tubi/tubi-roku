Function init()
  m.constants = getConstantsFromGlobal()

  m.channelIcon = m.top.findNode("channelIcon")
  m.minutesLeft = m.top.findNode("minutesLeft")
  m.title1 = m.top.findNode("title1")
  m.title2 = m.top.findNode("title2")
  m.time = m.top.findNode("time")
  m.programProgressBar = m.top.findNode("programProgressBar")
  m.background = m.top.findNode("background")

  m.minutesLeft.color = m.constants.ui.colors.secondaryText
  m.title1.color = m.constants.ui.colors.primaryText
  m.title2.color = m.constants.ui.colors.secondaryText
  m.time.color = m.constants.ui.colors.secondaryText

  m.top.observeField("metadata", "onMetadataChanged")
End Function


Function onMetadataChanged()
  metadata = m.top.metadata 
  if metadata.channelURI <> invalid
    m.channelIcon.uri = metadata.channelURI
  else
    m.channelIcon.uri = ""
  end if

  if metadata.minutesLeft >= 0 and metadata.currentDuration > 0 and metadata.minutesLeft < metadata.currentDuration
    nPercentDone = (metadata.currentDuration - metadata.minutesLeft)/metadata.currentDuration
    m.programProgressBar.width = m.background.width * nPercentDone
    m.programProgressBar.visible = true
  else
    m.programProgressBar.width = 0
    m.programProgressBar.visible = false
  end if

  if metadata.minutesLeft <> invalid and metadata.minutesLeft >= 0
    m.minutesLeft.text = getTranslation("epg_minutes_left", {minutes: toStr(metadata.minutesLeft)})
  else
    m.minutesLeft.text = ""
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