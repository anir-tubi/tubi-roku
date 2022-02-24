Function init()
  m.constants = getConstantsFromGlobal()
  m.top.observeFieldScoped("display", "onOverlayDisplayChange")
  m.top.observeFieldScoped("closedCaptioningItems", "onClosedCaptionListUpdated")
  
  m.OverlayParent = m.top.findNode("OverlayParent")
  m.OverlayContentArea = m.top.findNode("overlayContentArea")
  m.clock = m.top.findNode("clock")

  m.EPG = m.top.findNode("EPG")
  m.EPG.EPGChannelPlayMode = m.constants.EPGChannelPlayMode.playItemOnFocus
  m.EPG.observeField("linearChannelFocusedUpdated", "onChannelFocused")
  m.EPG.observeField("linearChannelToPlayUpdated", "onLinearChannelToPlayChanged")
  m.EPGHorizontalSlide = m.top.findNode("EPGHorizontalSlide")
  m.EPGSpinner = m.top.findNode("EPGSpinner")
  m.infoPanel = m.top.findNode("infoPanel")
  m.EPGError = m.top.findNode("EPGError")
  m.EPGError.text = getTranslation("error_noGetChannelGuide_description") 
  m.sideNav = m.top.findNode("sideNav")
  m.sideNav.observeFieldScoped("focusedButtonID", "onSideNavFocusChange")
  m.sideNav.observeFieldScoped("selectedButtonID", "onSideNavSelectChange")
  m.top.observeField("updateTimeGridContent", "onTimeContentChange")
  m.top.observeField("timeGridContentLoading", "onTimeGridContentLoadingChange")
   
  '//Closed Captioning Nodes
  m.closedCaptioningGroup = m.top.findNode("closedCaptioningGroup")
  m.closedCaptioningButtonList = m.top.findNode("closedCaptioningButtonList")
  m.closedCaptioningButtonListBackground = m.top.findNode("closedCaptioningButtonListBackground")
  m.closedCaptioningButtonListBackground.observeFieldScoped("rowItemSelected", "onCCContentSelected")
  m.closedCaptioningButtonListBackground.observeFieldScoped("rowItemFocused", "onCCContentFocused")
  m.closedCaptioningButtonListBackground.focusBitmapBlendColor = m.global.theme.focused
  m.closedCaptioningButtonListBackground.focusFootprintBlendColor = "0xFFFFFF33"

  if m.constants.deviceInfo.scaledUi = true
    m.closedCaptioningButtonListBackground.focusBitmapUri = "pkg://images/menu-focus-hd.9.png"
    m.closedCaptioningButtonListBackground.focusFootprintBitmapUri = "pkg://images/menu-focus-hd.9.png"
  end if

  '//It is best not to check the visible state of a UI element as it may be in a transitionary state. So m.bEPGVisible is used to know what is the intention of the EPG visble state.
  '//if the EPG is visible, then bEPGVisible is true. If the closed captioning is visible (and the EPG is not), then bEPGVisible is false. If there are more than 2 states, then this boolean will need to be changed to a different kind of variable
  m.bEPGVisible = true
  m.nDelaySeconds = .5
  m.originalEPGTranslation = m.EPGHorizontalSlide.translation
  m.slideOutEPGTranslation = [390, m.EPGHorizontalSlide.translation[1]]
  resetUI(false)
  m.firstTimeEPGLaunched = true 'm.firstTimeEPGLaunched is a flag to avoid jumping to the content 'currently playing' causing epg to trigger stop video and refetch the channel. 
End Function


Function onChannelFocused()
  tubiLog("LinearVideoPlayerNewScreenOverlay.onChannelFocused")
  m.top.reactedToKeyPresss = true
  populateInfoPanel(m.EPG.linearChannelFocused)
End Function


'@contentNode: program content node
Function populateInfoPanel(contentNode)
  tubiLog("LinearVideoPlayerNewScreenOverlay. populateInfoPanel")
  if contentNode <> invalid
    m.InfoPanel.mode = m.constants.ui.infoPanelModes.epg
    m.InfoPanel.title = contentNode.title
    m.InfoPanel.description = contentNode.description
    m.InfoPanel.width = 650
    m.InfoPanel.headerImageUri = contentNode.FHDPosterUrl
    lineOneData = {}
    lineOneData.rating = contentNode.rating
    lineOneData.hasCC = contentNode.hasSubtitles
    if contentNode.descriptors <> invalid and contentNode.descriptors.Count() > 0
      lineOneData.descriptorCode = contentNode.descriptors.join(", ") ' ::TODO:: When when we get real values into TAGS
    end if
    lineOneData.releaseDate = contentNode.ReleaseDate
    lineOneData.hoursOfAiring = contentNode.hoursOfAiring
    m.InfoPanel.lineOneData = lineOneData
    m.InfoPanel.genres = [contentNode.genre]
  end if
  m.InfoPanel.calculateHeight = true
End Function


Function onLinearChannelToPlayChanged(msg)
  tubiLog("LinearVideoPlayerNewScreenOverlay.onLinearChannelToPlayChanged")

  selectedChannelUpdated = msg.getData()
  if selectedChannelUpdated = true
    selectedChannel = m.EPG.linearChannelToPlay
    if selectedChannel <> invalid and m.firstTimeEPGLaunched <> true
      m.top.linearChannelToPlay = selectedChannel
      m.top.linearChannelToPlayUpdated = true
    end if
  
    if m.firstTimeEPGLaunched = true
      m.firstTimeEPGLaunched = false
    end if
  end if
End Function

 
Function onSideNavFocusChange()
  tubiLog("LinearVideoPlayerNewScreenOverlay.onSideNavFocusChange")
  m.top.reactedToKeyPresss = true
End Function


Function onSideNavSelectChange()
  tubilog("LinearVideoPlayerNewScreenOverlay.onSideNavSelectChange")
  if m.sideNav.selectedButtonID = m.constants.ui.linearSideNavIds.cc
    displayClosedCaptioningMenu()
  else if m.sideNav.selectedButtonID = m.constants.ui.linearSideNavIds.epg
    goBackToEPGFromSideNav()
  end if
  m.top.reactedToKeyPresss = true
End Function


Function onOverlayDisplayChange()
  tubiLog("LinearVideoPlayerNewScreenOverlay.onOverlayDisplayChange")
  if m.top.isDisplaying = false and m.top.display = true
    displayOverlay(m.top.displayWithDelay)
  else if m.firstTimeEPGLaunched = true
      'EPG is still loading, so keep the overlay with spinning  wheel
  else if m.top.isDisplaying = true and m.top.display = false
    hideOverlay()
  end if
End Function



Function onCCContentFocused(msg)
  tubiLog("LinearVideoPlayerNewScreenOverlay.onCCContentFocused")
  '//When the closed captioning layer is focused, make sure to update reactedToKeyPresss so the transport overlay does not automatically hide 
  m.top.reactedToKeyPresss = true
End Function



Function onCCContentSelected(msg)
  tubiLog("LinearVideoPlayerNewScreenOverlay.onCCContentSelected") 
  list = msg.getRoSGNode()
  item = msg.getData()

  hideOverlay()
  ccItemContent = list.content.getChild(item[0]).getChild(item[1])
  if ccItemContent.trackname <> invalid and ccItemContent.trackname <> ""
    if ccItemContent.trackname = "off"
      m.top.closedCaptioningSelectedLanguage = ""
    else
      m.top.closedCaptioningSelectedLanguage = ccItemContent.trackname
    end if
  end if
End Function


Function onClosedCaptionListUpdated()
  root = m.top.closedCaptioningItems
  if root <> invalid
    '//Display the side nav in case it had been previously hidden
    m.sideNav.visible = true

    m.closedCaptioningButtonList.content = root
    '//clone the Closed captioning so any changes made for the m.closedCaptioningButtonListBackground is not reflected in the original cc content
    backgroundCaptionsContent = root.clone(true)
    for i=0 to backgroundCaptionsContent.getChild(0).getChildCount()-1
      clonedCaptionNode = backgroundCaptionsContent.getChild(0).getChild(i)
      clonedCaptionNode.isForeground = false
    end for

    m.closedCaptioningButtonListBackground.content = backgroundCaptionsContent
    centerClosedCaptioning()

  else
    '//Hide the side nav since there are no close captions
    m.sideNav.visible = false
  end if

End Function


Function centerClosedCaptioning()
  nSpacing = m.closedCaptioningButtonList.rowItemSpacing[0][0]
  nItemWidth = m.closedCaptioningButtonList.rowItemSize[0][0]
  nItems = m.closedCaptioningButtonList.content.getChild(0).getChildCount()
  nListWidth = (nItems * nItemWidth) + ((nItems-1) * nSpacing) 

  nCenterPointX = (1920-nListWidth)/2
  m.closedCaptioningButtonList.translation = [nCenterPointX, m.closedCaptioningButtonList.translation[1]]
  m.closedCaptioningButtonListBackground.translation = [nCenterPointX, m.closedCaptioningButtonList.translation[1]]
End Function


Function displayOverlay(bDelay = false)
  tubiLog("LinearVideoPlayerNewScreenOverlay.displayOverlay")
  '//open the the overlay
  if m.animationHide <> invalid
    m.animationHide.unobserveField("state")
    m.animationHide.control = "stop"
  end if
  m.clock.control = "start"
  m.top.isDisplaying = true
  jumpEPGToCurrentPlayingVideo(true)
  m.EPG.setFocus(true)
  nDelaySeconds = 0
  if bDelay = true
    nDelaySeconds = m.nDelaySeconds
  end if

  fade(m.OverlayParent, "in", m.top.animationDuration, nDelaySeconds)
  m.animationDisplay = slideFade(m.OverlayContentArea, "below", "in", m.top.animationDuration, nDelaySeconds)
  if m.animationDisplay <> invalid
    m.animationDisplay.observeField("state", "onDisplayAnimationStopped")
  end if
End Function


Function hideOverlay()
  tubiLog("LinearVideoPlayerNewScreenOverlay.hideOverlay")
  '//close the the overlay
  if m.animationDisplay <> invalid
    m.animationDisplay.unobserveField("state")
    m.animationDisplay.control = "stop"
  end if
  m.top.isDisplaying = false

  m.clock.control = "stop"
  fade(m.OverlayParent, "out", m.top.animationDuration)
  m.animationHide = slideFade(m.OverlayContentArea, "below", "out", m.top.animationDuration)
  if m.animationHide <> invalid
    m.animationHide.observeField("state", "onHideAnimationStopped")
  end if
End Function


Function onDisplayAnimationStopped(msg)
  if m.animationDisplay.state = "stopped"
    m.animationDisplay.unobserveField("state")
    m.animationDisplay = invalid
  end if 
End Function


Function onHideAnimationStopped(msg)
  tubiLog("LinearVideoPlayerNewScreenOverlay.hideAnimationStopeed")
  if m.animationHide.state = "stopped"
    m.animationHide.unobserveField("state")
    m.animationHide = invalid
    resetUI(false) 
  end if 
End Function


Function onTimeContentChange()
  tubiLog("LinearVideoPlayerNewScreenOverlay.onTimeContentChanged")
  if m.top.updateTimeGridContent = true
    if m.top.timeGridContent <> invalid
      m.EPG.content = m.top.timeGridContent
      m.EPG.contentUpdated = true 
      m.EPGError.visible = false
      jumpEPGToCurrentPlayingVideo()
    else
      '//display inline error message
      m.EPGError.visible = true
      hideOverlay()
    end if
  end if
End Function


Function onTimeGridContentLoadingChange()
  tubiLog("LinearVideoPlayerNewScreenOverlay.onTimeGridContentLoadingChange")
  if m.top.timeGridContentLoading = true
    '//indicate that the EPG is loading
    m.EPGSpinner.visible = true
    m.EPGError.visible = false
    m.InfoPanel.visible = false
    m.EPG.visible = false
    m.top.timeGridContent = invalid
    m.EPG.content = m.top.timeGridContent
  else
    m.EPGSpinner.visible = false
    m.InfoPanel.visible = true
    m.EPG.visible = true
  end if
End Function




' Update the EPG so the focused item is that of the playing video.
Function jumpEPGToCurrentPlayingVideo(shouldSendComponentInteractionEvent = false)
  tubiLog("LinearVideoPlayerNewScreenOverlay.jumpEPGToCurrentPlayingVideo")
  if m.top.currentLinearVideoContent <> invalid and m.EPG.contentUpdated = true
    ' second element of the array is not used in case of EPG. So, hardcoded to empty string.

    m.EPG.trackingPageInfo = {
      pageType: "video_player_page"
      pageValues: {video_id: m.top.currentLinearVideoContent.id.toInt()}
    }
    if shouldSendComponentInteractionEvent = true
      m.EPG.shouldSendComponentInteractionEventOnJumpToLinearChannelId = true
    end if
    m.EPG.jumpToLinearChannelID = [m.top.currentLinearVideoContent.id, ""]
  end if
End Function


' reset the overlay back to the original state
Function resetUI(bAnimated = true)
  tubiLog("LinearVideoPlayerNewScreenOverlay.resetUI")
  m.sideNav.setOpenState = "closed"
  if m.bEPGVisible = true
    if bAnimated = true
      slideTo(m.EPGHorizontalSlide, m.originalEPGTranslation, m.top.animationDuration)
    else
      m.EPGHorizontalSlide.translation = m.originalEPGTranslation
    end if
  else
    hideClosedCaptioningMenu(bAnimated)
    m.EPGHorizontalSlide.translation = m.originalEPGTranslation
  end if
End Function


Function displayClosedCaptioningMenu()
  m.closedCaptioningButtonListBackground.setFocus(true)
  m.closedCaptioningButtonListBackground.setFocus(false) ' workaround for roku focus indicator bug
  m.closedCaptioningButtonListBackground.setFocus(true)  ' workaround for roku focus indicator bug
  m.sideNav.setOpenState = "openedAndNotInFocus"

  if m.bEPGVisible = true
    m.bEPGVisible = false

    ' preselect the caption option that the user currently has enabled
    nJumpTo = 0
    if m.closedCaptioningButtonListBackground.content <> invalid and m.closedCaptioningButtonListBackground.content.getChildCount() > 0
      captions = m.closedCaptioningButtonListBackground.content.getChild(0)
      for i = 0 to captions.getChildCount()-1
        caption = captions.getChild(i)
        if caption.enabled = true
          nJumpTo = i
        end if
      end for
      m.closedCaptioningButtonListBackground.jumpToRowItem = [0, nJumpTo]
    end if

    slideFade(m.EPG, "below", "out", m.top.animationDuration)
    slideFade(m.closedCaptioningGroup, "below", "in", m.top.animationDuration)
  end if
End Function


Function hideClosedCaptioningMenu(bAnimated = true)
  m.bEPGVisible = true
  nAnimationDuration = 0
  if bAnimated = true
    nAnimationDuration = m.top.animationDuration
  end if

  slideFade(m.closedCaptioningGroup, "below", "out", m.top.animationDuration)
  slideFade(m.EPG, "below", "in", nAnimationDuration)
End Function


Function goBackToEPGFromSideNav()
  m.EPG.setFocus(true)
  resetUI()
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  bKeyReacted = false

  if m.top.isDisplaying = true and press = true then
    tubiLog("LinearVideoPlayerNewScreenOverlay.onKeyEvent" + key)
    if key = "left"
      if m.EPG.isInFocusChain() = true and m.sideNav.visible = true
        '//if the EPG has focus and the side nav is visible, then move the focus to the subtitles button
        slideTo(m.EPGHorizontalSlide, m.slideOutEPGTranslation, m.top.animationDuration)
        m.sideNav.setOpenState = "openedAndInFocus"
        m.sideNav.buttonToFocusID = m.constants.ui.linearSideNavIds.epg
        bKeyReacted = true
      else if m.closedCaptioningGroup.isInFocusChain() = true
        m.sideNav.setOpenState = "openedAndInFocus"
        m.sideNav.buttonToFocusID = m.constants.ui.linearSideNavIds.cc
        hideClosedCaptioningMenu() '//Hide the CC menu and display EPG again
        slideTo(m.EPGHorizontalSlide, m.slideOutEPGTranslation, m.top.animationDuration)
        bKeyReacted = true
      end if
    else if key = "right" 
      if m.bEPGVisible = true and m.EPG.isInFocusChain() = false
        goBackToEPGFromSideNav()
        bKeyReacted = true
      else if m.bEPGVisible = false and m.closedCaptioningGroup.isInFocusChain() = false
        displayClosedCaptioningMenu()
        slideTo(m.EPGHorizontalSlide, m.slideOutEPGTranslation, m.top.animationDuration)
        bKeyReacted = true
      end if
    else if key = "back"
      if m.closedCaptioningGroup.isInFocusChain() = true
        m.sideNav.setOpenState = "openedAndInFocus"
        m.sideNav.buttonToFocusID = m.constants.ui.linearSideNavIds.cc
        hideClosedCaptioningMenu() '//Hide the CC menu and display EPG again
        bKeyReacted = true
      else if m.EPG.isInFocusChain() = false
        goBackToEPGFromSideNav()
      else
        hideOverlay()
      end if
      bKeyReacted = true
    end if
  end if

  if bKeyReacted = true
    m.top.reactedToKeyPresss = true
  end if

  return bKeyReacted
End Function