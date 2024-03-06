Function init()
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  m._ = rodash()
  m.Info = m.top.findNode("Info")
  m.YmalGroup = m.top.findNode("YmalGroup")
  m.YmalRow = m.top.findNode("YmalRow")
  m.RelatedGrid = m.top.findNode("RelatedGrid")
  m.RelatedGrid.observeFieldScoped("itemFocused", "onItemFocused")
  m.RelatedGrid.observeFieldScoped("itemSelected", "onItemSelected")
  m.RelatedGrid.observeFieldScoped("keyPress", "onKeyPress")
  m.top.observeFieldScoped("updateContent", "onContentChange")
  m.top.observeFieldScoped("focusedChild", "onComponentFocus")
  m.top.observeFieldScoped("showInfoPanel", "onShowInfoPanel")
  m.top.observeFieldScoped("unfocus", "onUnfocus")
  m.top.observeFieldScoped("show", "onShowRelated")
  m.top.observeFieldScoped("hide", "onHideRelated")
  m.top.observeFieldScoped("open", "onOpenRelated")
  m.top.observeFieldScoped("close", "onCloseRelated")
  m.top.observeFieldScoped("showInFullScreen", "onShowRelatedInFullScreen")
  RelatedRowLabelContent = m.top.findNode("RelatedRowLabelContent")
  RelatedRowLabelContent.title = getTranslation("screenDetails_relatedTitles")

  m.YmalGroupShowAnimation = invalid

  m.ymalXYPositionWhenHidden = [0,0]
  m.ymalXYPositionWhenOpen = [0,-235]

  ' Used to determine if navigate_within_page events should be sent. Only send when the Related content row already
  ' has focus, not when it gains focus.
  m.isRelatedFocused = false

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
    m.RelatedGrid.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function onComponentFocus()
  if m.top.hasFocus()
    m.RelatedGrid.setFocus(true)
    if m.Info.opacity = 0
      fade(m.Info, "in", 0.4)
    end if
  else if m.top.isInFocusChain() <> true
    m.isRelatedFocused = false
    m.RelatedGrid.setFocus(false)
  end if
End Function


Function onContentChange()
  content = m.top.content
  if content <> invalid
    m.RelatedGrid.content = content
    m.RelatedGrid.numColumns = content.getChildCount()
  end if
End Function


Function onItemFocused(msg)

  itemFocused = msg.getData()
  content = m.RelatedGrid.content.getChild(itemFocused)

  if content <> invalid
    updateInfoPanel(m.Info, content)
  end if

  col = itemFocused + 1
  row = 1
  pageName = m.top.associatedPageName

  if m.isRelatedFocused = true
    m.top.navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(pageName, {video_id: content.id.toInt()})
      componentOneof: m.Tracking.getAnalyticsComponent("related_component", m.oldYmalComponent)
      means_of_navigation: "BUTTON"
      vertical_location: row
      horizontal_location: col
    }

    contentTile = m.Tracking.getAnalyticsTile(content, col, row)
    m.oldYmalComponent = {content_tile: contentTile}
  else
    contentTile = m.Tracking.getAnalyticsTile(content, col, row)
    m.oldYmalComponent = {content_tile: contentTile}
  end if

  m.isRelatedFocused = true

  ' this field helps to update last key press time & pauseAd timer
  m.top.isRelatedContentFocused = true
End Function


Function onItemSelected(msg)
  itemSelected = msg.getData()
  m.top.selectedRelatedContentItem = m.RelatedGrid.content.getChild(itemSelected)
End Function


Function updateInfoPanel(infoNode, content)
  infoNode.title = content.title

  lineOneData = {}
  if content.type = m.constants.ui.contentTypes.series
    lineOneData.type = m.constants.ui.contentTypes.series
  end if
  lineOneData.releaseDate = content.releaseDate
  lineOneData.length = content.length
  lineOneData.hasCC = (content.hasSubtitles = true OR m._.empty(content.subtitleTracks) = false)

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

  infoNode.lineOneData = lineOneData
  infoNode.lineTwoData = lineTwoData
  infoNode.description = content.description
  infoNode.directors = content.directors
  infoNode.starring = content.actors
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


Function onShowRelated(msg)
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


Function onOpenRelated(msg)
  if m.YmalRow.opacity < 1.0
    fade(m.YmalRow, "in", 0.2, 0, 1.0)
  end if

  showInfoPanel()
  slideTo(m.YmalGroup, m.ymalXYPositionWhenOpen, 0.6)
End Function


Function onCloseRelated(msg)
  if m.YmalRow.opacity = 1.0
    fade(m.YmalRow, "out", 0.2, 0, 0.2)
  end if

  hideInfoPanel()
  slideTo(m.YmalGroup, m.ymalXYPositionWhenHidden, 0.6)
End Function


Function onShowRelatedInFullScreen(msg)
  m.YmalGroup.translation = m.ymalXYPositionWhenOpen
  fade(m.YmalGroup, "in", 0.6)
  fade(m.YmalRow, "in", 0.2, 0, 1.0)
  showInfoPanel()
End Function