Function init()
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  m._ = rodash()
  m.Info = m.top.findNode("Info")
  m.YmalGroup = m.top.findNode("YmalGroup")
  m.YmalRow = m.top.findNode("YmalRow")

  m.relatedContentContainer = m.top.findNode("relatedContentContainer")
  m.relatedContentContainer.observeFieldScoped("focusedContent", "onFocusedContent")

  m.top.observeFieldScoped("updateContent", "onContentChange")
  m.top.observeFieldScoped("focusedChild", "onComponentFocus")
  m.top.observeFieldScoped("showInfoPanel", "onShowInfoPanel")
  m.top.observeFieldScoped("show", "onShowRelated")
  m.top.observeFieldScoped("hide", "onHideRelated")
  m.top.observeFieldScoped("open", "onOpenRelated")
  m.top.observeFieldScoped("close", "onCloseRelated")
  m.top.observeFieldScoped("showInFullScreen", "onShowRelatedInFullScreen")

  m.YmalGroupShowAnimation = invalid

  m.ymalXYPositionWhenHidden = [0, 0]
  m.ymalXYPositionWhenOpen = [0, -365]
End Function


Function onComponentFocus()
  if m.top.hasFocus()
    m.relatedContentContainer.setFocus(true)
    if m.Info.opacity = 0
      fade(m.Info, "in", 0.4)
    end if
  else if m.top.isInFocusChain() <> true
    m.relatedContentContainer.setFocus(false)
  end if
End Function


Function updateTrackingInfo()
  content = m.top.content

  if content <> invalid AND content.id <> invalid
    m.relatedContentContainer.trackingPageInfo = {
      pageType: m.top.associatedPageName
      pageValues: {
        video_id: content.id.toInt()
      }
    }
  end if
End Function


Function onContentChange()
  content = m.top.content
  if content <> invalid
    updateTrackingInfo()
    m.relatedContentContainer.content = content
    m.relatedContentContainer.contentUpdated = true
  end if
End Function


Function onFocusedContent(msg)
  focusedContent = msg.getData()
  if focusedContent <> invalid
    updateInfoPanel(m.Info, focusedContent)
  end if
End Function


Function updateInfoPanel(infoNode, content)
  infoNode.title = content.title

  lineOneData = {}
  lineOneData.type = content.type
  lineOneData.releaseDate = content.releaseDate
  lineOneData.length = content.length
  lineOneData.hasCC = (content.hasSubtitles = true OR isNonEmptyArray(content.subtitleTracks) = true)
  lineOneData.hasAudioDescription = content.hasAudioDescription

  if content.highestRendition = m.constants.serverValues.tensorVideoRenditions.fourK
    lineOneData.has4k = true
  end if

  if content.availabilityEnds <> invalid
    lineOneData.availabilityEnds = content.availabilityEnds
  end if

  lineOneData.descriptorCode = content.descriptorCode
  lineOneData.rating = content.rating
  lineOneData.partnerLogoUri = content.inlineLogoUri

  lineTwoData = {
    genres: content.genres
  }

  sotInfo = content.sotInfo
  if isAA(sotInfo) = true
    infoNode.sotTopLabelSignals = sotInfo.sotMetaDataTopLabels
    lineTwoData.sotMetaData = sotInfo.sotMetaData
    infoNode.sotMarkers = sotInfo.sotMarkers
  else
    infoNode.sotTopLabelSignals = []
    lineTwoData.sotMetaData = []
    infoNode.sotMarkers = {}
  end if

  infoNode.lineOneData = lineOneData
  infoNode.lineTwoData = lineTwoData
  infoNode.description = content.description
  infoNode.needsLogin = (content.needsLogin = true)

  ' always have to do this
  infoNode.calculateHeight = true
End Function


Function showInfoPanel()
  if m.Info.opacity = 0
    fade(m.Info, "in", 0.4)
  end if
End Function


Function hideInfoPanel()
  if m.Info.opacity > 0
    fade(m.Info, "out", 0.2)
  end if
End Function


Function onShowRelated()
  if m.YmalGroup.opacity < 1.0
    m.YmalGroupShowAnimation = slideFade(m.YmalGroup, "below", "in", 0.6)
  end if
End Function


Function onHideRelated(msg)
  ' we need to stop YmalGroupShowAnimation which shows YmalGroup, because YmalGroupShowAnimation duration is set as 0.6 and
  ' ymalGroup may reappear even after we hide ymalGroup as the animation state is still be running
  if m.YmalGroupShowAnimation <> invalid AND m.YmalGroupShowAnimation.state = "running"
    m.YmalGroupShowAnimation.control = "stop"
  end if

  if m.YmalGroup.opacity > 0
    hideInfoPanel()
    fade(m.YmalRow, "out", 0.2, 0, 0.2)
    slideFade(m.YmalGroup, "below", "out", 0.6)
  end if
End Function


Function onOpenRelated()
  if m.YmalRow.opacity < 1.0
    fade(m.YmalRow, "in", 0.2, 0, 1.0)
  end if

  showInfoPanel()
  slideTo(m.YmalGroup, m.ymalXYPositionWhenOpen, 0.6)
End Function


Function onCloseRelated()
  if m.YmalRow.opacity = 1.0
    fade(m.YmalRow, "out", 0.2, 0, 0.2)
  end if

  hideInfoPanel()
  slideTo(m.YmalGroup, m.ymalXYPositionWhenHidden, 0.6)
End Function


Function onShowRelatedInFullScreen()
  m.YmalGroup.translation = m.ymalXYPositionWhenOpen
  fade(m.YmalGroup, "in", 0.6)
  fade(m.YmalRow, "in", 0.2, 0, 1.0)
  showInfoPanel()
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  ' When the YMAL row is focused during playback and the user presses "fastforward" or "rewind",
  ' close the YMAL and handle the key press action in playback.
  if key = "fastforward" OR key = "rewind"
    m.top.keyPress = key
    return true
  end if
  return false
End Function