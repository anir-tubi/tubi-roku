Function init()
  m.constants = getConstantsFromGlobal()
  m.tubiTrackingInfo = TubiTrackingInfo(m.constants)
  topRef = m.top

  topRef.observeFieldScoped("updateAndShowComingUpInfo", "onUpdateAndShowComingUpInfo")
  topRef.observeFieldScoped("showOverlay", "onShowOverlay")
  topRef.observeFieldScoped("hideOverlay", "onHideOverlay")
  topRef.observeFieldScoped("hideComingUpOverlay", "onHideComingUpOverlay")
  topRef.observeFieldScoped("hideClosedCaptionAudioTrackOverlay", "onHideClosedCaptionAudioTrackOverlay")
  topRef.observeFieldScoped("updateTimeGridContent", "onTimeContentChange")
  topRef.observeFieldScoped("timeGridContentLoading", "onTimeGridContentLoadingChange")

  topRef.observeFieldScoped("increaseChannel", "onIncreaseChannel")
  topRef.observeFieldScoped("decreaseChannel", "onDecreaseChannel")

  m.OverlayParent = topRef.findNode("OverlayParent")
  m.InfoPanelGroup = topRef.findNode("InfoPanelGroup")
  m.InfoPanel = topRef.findNode("InfoPanel")
  m.ChannelList = topRef.findNode("ChannelList")

  'channelIndexFocused holds integer value, default value is -1
  'It helps to find which channel has focus, using this the channel can be switched easily
  m.channelIndexFocused = -1

  'default state of Closed caption overlay
  m.isClosedCaptionAudioOverlayShowing = false

  'shouldShowComingUpOverlay holds boolean value, default value is false
  'It helps to decide whether to show comingUp overlay or not
  m.shouldShowComingUpOverlay = false

  'direction variable decides on which way the info panel animation should start
  'if user increase channel, animation starts towards up. If user decrease channel, animation starts towards down
  m.direction = "down"

  m.comingUpInsideInfoPanelDuration = m.constants.player.linear.comingUpInsideInfoPanelDuration
  m.comingUpOutsideInfoPanelDuration = m.constants.player.linear.comingUpOutsideInfoPanelDuration

  'Overriding value from <env>.yml file. This field is added for QA testing purpose
  if m.constants.settings.comingUpInsideInfoPanelDuration <> invalid
    m.comingUpInsideInfoPanelDuration = m.constants.settings.comingUpInsideInfoPanelDuration
  end if

  'Overriding value from <env>.yml file. This field is added for QA testing purpose
  if m.constants.settings.comingUpOutsideInfoPanelDuration <> invalid
    m.comingUpOutsideInfoPanelDuration = m.constants.settings.comingUpOutsideInfoPanelDuration
  end if

  m.ProgressBar = topRef.findNode("ProgressBar")
  isScaledUI = m.constants.deviceInfo.scaledUi
  if isScaledUI = true then
    m.ProgressBar.scaledUI = isScaledUI
  end if

  m.ButtonList = topRef.findNode("ButtonList")
  m.ButtonList.observeFieldScoped("itemFocused", "onButtonFocused")
  m.ButtonList.observeFieldScoped("itemSelected", "onButtonSelected")

  columnWidths = []
  tvGuideButtonItem = CreateObject("roSGNode", "ButtonWithIconAndLabel")
  tvGuideNode =  CreateObject("roSGNode", "ContentNode")
  tvGuideNode.id = "TvGuideButton"
  tvGuideNode.title = getTranslation("linearVideoPlayer_buttonTvGuide")
  tvGuideNode.HDPosterUrl = "pkg:/images/tvguide.png"
  tvGuideButtonItem.itemContent = tvGuideNode
  columnWidths.push(tvGuideButtonItem.calculatedWidth)

  languageButtonItem = CreateObject("roSGNode", "ButtonWithIconAndLabel")
  languageNode =  CreateObject("roSGNode", "ContentNode")
  languageNode.id = "LanguageButton"
  languageNode.title = getTranslation("linearVideoPlayer_buttonLanguage")
  languageNode.HDPosterUrl = "pkg:/images/transport/sgplayer/icon-subtitles.webp"
  languageButtonItem.itemContent = languageNode
  columnWidths.push(languageButtonItem.calculatedWidth)

  contentNode = CreateObject("roSGNode", "ContentNode")
  contentNode.appendChild(tvGuideNode)
  contentNode.appendChild(languageNode)
  m.ButtonList.columnWidths = columnWidths
  m.ButtonList.content = contentNode

  m.ComingUpGroupInInfoPanel = topRef.findNode("ComingUpGroupInInfoPanel")
  m.ComingUpTimeInInfoPanel = topRef.findNode("ComingUpTimeInInfoPanel")
  m.ComingUpTitleInInfoPanel = topRef.findNode("ComingUpTitleInInfoPanel")

  m.overlayComingUp = topRef.findNode("overlayComingUp")
  m.ComingUpTime = topRef.findNode("ComingUpTime")
  m.ComingUpTitle = topRef.findNode("ComingUpTitle")

  m.showComingUpTimer = topRef.findNode("showComingUpTimer")
  m.hideComingUpTimer = topRef.findNode("hideComingUpTimer")

  m.closedCaptionAndAudioSelectionOverlay = topRef.findNode("closedCaptionAndAudioSelectionOverlay")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("globalCaptionTurnedOn", "onGlobalCaptionTurnedOnChange")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("globalCaptionTurnedOff", "onGlobalCaptionTurnedOffChange")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("wasBackButtonSelected", "onWasBackButtonSelectedWhenCCHasFocus")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("trackingEventInfo", "onTrackingEventInfoChange")
  m.closedCaptionAndAudioSelectionOverlayGroup = topRef.findNode("closedCaptionAndAudioSelectionOverlayGroup")

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
    m.ProgressBar.focusColor = theme.focusedColor
    m.ProgressBar.trackColor = theme.neutralColor2
    m.closedCaptionAndAudioSelectionOverlayGroup.color = theme.shadeColor
  end if
End Function


Function onDecreaseChannel(msg)
  jumpChannelUiToCurrentPlayingVideo()
  decreaseChannel()
End Function


Function decreaseChannel()
  if m.channelIndexFocused > 0
    m.channelIndexFocused = m.channelIndexFocused - 1
  end if

  displayOverlay()
  changeChannelAndUiByIndex(m.channelIndexFocused)
  m.direction = "up"
  animateInfoPanel()
End Function


Function onIncreaseChannel(msg)
  jumpChannelUiToCurrentPlayingVideo()
  increaseChannel()
End Function


Function increaseChannel()
  content = m.ChannelList.content

  if content <> invalid AND m.channelIndexFocused < content.getchildCount() - 1
    m.channelIndexFocused = m.channelIndexFocused + 1
  end if

  displayOverlay()
  changeChannelAndUiByIndex(m.channelIndexFocused)
  m.direction = "down"
  animateInfoPanel()
End Function


Function onShowOverlay(msg)
  if m.OverlayParent.opacity < 1
    jumpChannelUiToCurrentPlayingVideo()
    changeChannelUiByIndex(m.channelIndexFocused)
    channelInfo = getChannelInfo(m.channelIndexFocused)
    updateInfoPanel(channelInfo)
    showInfoPanel()
    displayOverlay()
  end if
End Function


Function onUpdateAndShowComingUpInfo(msg)
  jumpChannelUiToCurrentPlayingVideo()
  channelInfo = getChannelInfo(m.channelIndexFocused)

  if channelInfo <> invalid
    updateComingUpInfo(channelInfo)
    updateChannelInfo(channelInfo)
  end if
End Function


Function onHideOverlay(msg)
  if m.OverlayParent.opacity > 0
    hideOverlay()
  end if
End Function


Function displayOverlay()
  m.ButtonList.animateToItem = 0 'setting default focus to TvGuide Button
  m.top.isDisplaying = true
  m.shouldShowComingUpOverlay = false
  hideComingUpOverlay()
  fade(m.OverlayParent, "in", 0.4)
  m.ChannelList.setFocus(true)
  m.ButtonList.setFocus(true)
  m.top.reactedToKeyPresss = true
End Function


'@channelIndexFocused: integer, the index of the channels maintained for increasing/decresing the channel
Function changeChannelAndUiByIndex(channelIndexFocused)
  channelInfo = getChannelInfo(channelIndexFocused)
  if channelInfo <> invalid
    m.ChannelList.animateToItem = channelIndexFocused
    changeChannelUi(channelInfo)
    changeChannel(channelInfo)
  end if
End Function


'@channelIndexFocused: integer, the index of the channels maintained for increasing/decresing the channel
Function changeChannelUiByIndex(channelIndexFocused)
  channelInfo = getChannelInfo(channelIndexFocused)
  if channelInfo <> invalid
    m.ChannelList.animateToItem = channelIndexFocused
    changeChannelUi(channelInfo)
  end if
End Function


Function hideOverlay()
  m.top.isDisplaying = false
  fade(m.OverlayParent, "out", 0.4)
  if m.shouldShowComingUpOverlay = true
    showComingUpOverlay()
  end if
End Function


Function onButtonFocused(msg)
  m.top.reactedToKeyPresss = true
End Function


Function onButtonSelected(msg)
  itemSelected = msg.getData()
  button = invalid
  buttonContent = m.ButtonList.content

  if buttonContent <> invalid
    button = buttonContent.getChild(itemSelected)
  end if

  if button <> invalid AND button.id = "TvGuideButton"
    m.shouldShowComingUpOverlay = false
    hideComingUpOverlay()
    hideOverlay()
    setComponentInteractionInfo("FULL_TV_GUIDE")
    m.top.trackingComponentInfo = {
      componentType : "button_component"
      componentValues : {
        button_type: "TEXT"
        button_value: "FULL_TV_GUIDE"
      }
    }
    m.top.navigateToEPGScreen = true
  else if button <> invalid AND button.id = "LanguageButton"
    setComponentInteractionInfo("LANGUAGE")
    showClosedCaptionAudioTrackOverlay()
  end if
End Function


'@buttonValue: String, value used in button_value attribute of analytic event
Function setComponentInteractionInfo(buttonValue)
  componentValues = {
    button_type: "TEXT"
    button_value: buttonValue
  }

  pageValues = {}
  currentLinearVideoContent = m.top.currentLinearVideoContent

  if currentLinearVideoContent <> invalid AND isNonEmptyString(currentLinearVideoContent.id) = true
    pageValues =  {video_id: currentLinearVideoContent.id.toInt()}
  end if

  if pageValues.video_id <> invalid
    pageOneof = m.tubiTrackingInfo.getAnalyticsPage("video_player_page", pageValues)
    componentOneof = m.tubiTrackingInfo.getAnalyticsComponent("button_component", componentValues)

    m.top.componentInteractionInfo = {
      pageOneof: pageOneof
      componentOneof: componentOneof
      user_interaction: "CONFIRM"
    }
  end if
End Function


' Displays the closed caption and audio track selection overlay.
Function showClosedCaptionAudioTrackOverlay()
  videoNode = m.top.videoNode
  m.closedCaptionAndAudioSelectionOverlay.closedCaptionTrack = videoNode.subtitleTrack
  m.closedCaptionAndAudioSelectionOverlay.globalCaptionMode = videoNode.globalCaptionMode
  m.closedCaptionAndAudioSelectionOverlay.availableClosedCaptionTracks = videoNode.availableSubtitleTracks
  m.closedCaptionAndAudioSelectionOverlay.availableAudioTracks = videoNode.availableAudioTracks
  m.closedCaptionAndAudioSelectionOverlay.setFocus(true)
  fade(m.closedCaptionAndAudioSelectionOverlayGroup, "in", 0.6)
  m.top.isClosedCaptionAudioOverlayShowing = true
  m.isClosedCaptionAudioOverlayShowing = true

  if m.top.currentLinearVideoContent <> invalid
    m.closedCaptionAndAudioSelectionOverlay.videoId = m.top.currentLinearVideoContent.id.toInt()
  end if
End Function


' Hides the closed caption and audio track selection overlay.
Function hideClosedCaptionAudioTrackOverlay()
  m.top.isClosedCaptionAudioOverlayShowing = false
  m.isClosedCaptionAudioOverlayShowing = false
  m.closedCaptionAndAudioSelectionOverlay.setFocus(false)
  fade(m.closedCaptionAndAudioSelectionOverlayGroup, "out", 0.6)
End Function


Function onWasBackButtonSelectedWhenCCHasFocus(msg)
  wasSelected = msg.getData()

  if wasSelected = true
    hideClosedCaptionAudioTrackOverlay()
    m.ButtonList.setFocus(true)
  end if
End Function


Function onGlobalCaptionTurnedOnChange(msg)
  if msg.getData() = true
    m.top.globalCaptionMode = "On"
  end if
End Function


Function onGlobalCaptionTurnedOffChange(msg)
  if msg.getData() = true
    m.top.globalCaptionMode = "Off"
  end if
End Function


Function onTimeContentChange()
  if m.top.updateTimeGridContent = true
    if m.top.timeGridContent <> invalid
      m.ChannelList.content = m.top.timeGridContent
    else
      hideOverlay()
    end if
  end if
End Function


Function onTimeGridContentLoadingChange()
  if m.top.timeGridContentLoading = true
    m.InfoPanel.visible = false
    m.top.timeGridContent = invalid
    m.ChannelList.content = invalid
  else
    if m.top.timeGridContent <> invalid
      m.InfoPanel.visible = true
    else
      m.InfoPanel.visible = false
    end if
  end if
End Function


Function jumpChannelUiToCurrentPlayingVideo()
  if m.top.currentLinearVideoContent <> invalid
    jumpToLinearChannelID = m.top.currentLinearVideoContent.id
    content = m.ChannelList.content

    if jumpToLinearChannelID <> invalid AND content <> invalid
      for i = 0 to content.getChildCount() - 1
        item = content.getchild(i)
        if item <> invalid AND item.id = jumpToLinearChannelID
          m.channelIndexFocused = i
          m.ChannelList.jumpToItem = m.channelIndexFocused
          exit for
        end if
      end for
    end if
  end if
End Function


'@channelInfo: TubiContentNode, node which holds the channel information
Function updateInfoPanel(channelInfo)
  programInfo = invalid

  if channelInfo <> invalid
    programInfo = channelInfo.getChild(0)
  end if

  if programInfo <> invalid
    m.InfoPanel.mode = m.constants.ui.infoPanelModes.simplifiedLinearPlayer
    m.InfoPanel.title = programInfo.title
    m.InfoPanel.episodeTitle = programInfo.epgProgramTitle
    m.InfoPanel.width = 894

    timeLeft = ""
    endTime = programInfo.endTime

    if endTime <> invalid AND endTime > 0
      localTime = getCurrentLocalTime()
      remainingTime = endTime - localTime
      timeLeft = getTranslation("linearVideoPlayer_timeLeft", {time: formatLengthSelectedLocale(remainingTime)})
    end if

    lineOneData = {}
    lineOneData.timeLeft = timeLeft
    lineOneData.hoursOfAiring = programInfo.hoursOfAiring
    lineOneData.rating = programInfo.rating
    lineOneData.hasCC = programInfo.hasSubtitles

    if programInfo.descriptors <> invalid AND programInfo.descriptors.Count() > 0
      lineOneData.descriptorCode = programInfo.descriptors.join(", ")
    end if

    m.InfoPanel.lineOneData = lineOneData
    m.InfoPanel.description = programInfo.description
    m.InfoPanel.descriptionMaxLines = 3
    m.InfoPanel.needsLogin = programInfo.needsLogin

    endTime = programInfo.endTime
    localTime = getCurrentLocalTime()

    if endTime <> invalid AND endTime > 0

      if isNonEmptyString(programInfo.hoursOfAiring) = true
        nextProgram = channelInfo.getChild(1)

        if nextProgram <> invalid
          nextProgramTitle = nextProgram.title
          nextProgramStartTime = programInfo.hoursOfAiring.split("-")[1]
          m.ComingUpTimeInInfoPanel.text = getTranslation("linearVideoPlayer_comingUpAt", {time: nextProgramStartTime})
          m.ComingUpTitleInInfoPanel.text = nextProgramTitle
          m.ComingUpTime.text = getTranslation("linearVideoPlayer_comingUp")
          m.ComingUpTitle.text = nextProgramTitle
        end if

      end if

      if endTime - localTime <= m.comingUpInsideInfoPanelDuration
        m.ComingUpGroupInInfoPanel.opacity = 1
      else
        m.ComingUpGroupInInfoPanel.opacity = 0
      end if
    else
      m.ComingUpGroupInInfoPanel.opacity = 0
    end if
  end if

  m.InfoPanel.calculateHeight = true
End Function


Function updateComingUpInfo(channelInfo)
  if channelInfo <> invalid
    nextProgram = channelInfo.getChild(1)

    if nextProgram <> invalid
      m.ComingUpTime.text = getTranslation("linearVideoPlayer_comingUp")
      m.ComingUpTitle.text = nextProgram.title
    end if
  end if
End Function


'@channelInfo: TubiContentNode, node which holds the channel information
Function updateProgressBar(channelInfo)
  dateTime = createObject("roDateTime")
  dateTime.ToLocalTime()
  progress = 100

  programInfo = channelInfo.getChild(0)
  if programInfo <> invalid AND programInfo.startTime <> invalid AND programInfo.startTime > 0 AND programInfo.endTime <> invalid AND programInfo.endTime > 0
    currentPosition = dateTime.asSeconds() - programInfo.startTime
    totalDuration = programInfo.endTime - programInfo.startTime
    progress = (currentPosition / totalDuration) *  100
  end if
  m.ProgressBar.progress = progress
End Function


'updateChannelInfo removes the past programs from channelInfo node
'also it starts/stops the comingUp timer for next program based on starttime of next program
'
'@channelInfo: TubiContentNode, node which holds the channel information
Function updateChannelInfo(channelInfo)
  if channelInfo <> invalid
    localTime = getCurrentLocalTime()

    for i = 0 to channelInfo.getChildCount()-1
      programInfo = channelInfo.getChild(i)
      endTime = programInfo.endTime

      if programInfo <> invalid AND endTime > 0 AND localTime >= endTime
        channelInfo.removeChildIndex(i)
        exit for
      end if
    end for
    nextProgram = channelInfo.getChild(1)

    if nextProgram <> invalid
      nextProgramStartTime = nextProgram.startTime

      if nextProgramStartTime <> invalid and nextProgramStartTime <> 0
        timeDiff = nextProgramStartTime - localTime
        timerStartTime = timeDiff - m.comingUpOutsideInfoPanelDuration

        if timeDiff >= 0
          stopShowComingUpTimer()

          'if the timerStartTime value is negative, show the comingup ovelay in 1 second
          if timerStartTime > 0
            m.showComingUpTimer.duration = timerStartTime
          else
            m.showComingUpTimer.duration = 1
          end if

          startShowComingUpTimer()
        else
          stopShowComingUpTimer()
          m.shouldShowComingUpOverlay = true
        end if
      end if
    end if

  end if
End Function


Function stopShowComingUpTimer()
  m.showComingUpTimer.unobserveFieldScoped("fire")
  m.showComingUpTimer.control = "stop"
End Function


Function startShowComingUpTimer()
  m.showComingUpTimer.unobserveFieldScoped("fire")
  m.showComingUpTimer.observeFieldScoped("fire", "onShowComingUpTimerFired")
  m.showComingUpTimer.control = "start"
End Function


Function onShowComingUpTimerFired()
  m.shouldShowComingUpOverlay = true
  localTime = getCurrentLocalTime()
  channelInfo = getChannelInfo(m.channelIndexFocused)

  if channelInfo <> invalid
    nextProgram = channelInfo.getChild(1)

    if nextProgram <> invalid AND nextProgram.startTime <> invalid
      timeDiff = nextProgram.startTime - localTime
      stopHideComingUpTimer()
      m.hideComingUpTimer.duration = timeDiff
      startHideComingUpTimer()
    end if
  end if

  if m.OverlayParent.opacity < 1.0
    showComingUpOverlay()
  end if
End Function


Function stopHideComingUpTimer()
  m.hideComingUpTimer.unobserveFieldScoped("fire")
  m.hideComingUpTimer.control = "stop"
End Function


Function startHideComingUpTimer()
  m.hideComingUpTimer.unobserveFieldScoped("fire")
  m.hideComingUpTimer.observeFieldScoped("fire", "onHideComingUpTimerFired")
  m.hideComingUpTimer.control = "start"
End Function


Function onHideComingUpTimerFired()
  m.shouldShowComingUpOverlay = false
  hideComingUpOverlay()
End Function


Function showComingUpOverlay()
  fade(m.overlayComingUp, "in", 0.4)
End Function


Function hideComingUpOverlay()
  fade(m.overlayComingUp, "out", 0.4)
End Function


Function onHideComingUpOverlay()
  hideComingUpOverlay()
End Function


Function onHideClosedCaptionAudioTrackOverlay()
  hideClosedCaptionAudioTrackOverlay()
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean

  if press then

    if key = "back"
      'This will move the focus back to VideoNode in LinearVideoPlayerScreen
      hideOverlay()

    else if key = "up" OR key = "down"

      if m.isClosedCaptionAudioOverlayShowing = false
        if key = "down"
          increaseChannel()
        else if key = "up"
          decreaseChannel()
        end if
      end if
    end if
  end if

  m.top.reactedToKeyPresss = true
  return true
End Function


'@channelInfo: TubiContentNode, which has channel information including programs
Function changeChannel(channelInfo)
  if channelInfo <> invalid
    m.top.linearChannelToPlay = channelInfo
    m.top.linearChannelToPlayUpdated = true
  end if
End Function


'@channelInfo: TubiContentNode, which has channel information including programs
Function changeChannelUi(channelInfo)
  if channelInfo <> invalid
    updateChannelInfo(channelInfo)
    updateProgressBar(channelInfo)
  end if
End Function


'@channelIndexFocused: integer, the index of the channels maintained for increasing/decresing the channel
'
'@returns: channelInfo - TubiContentNode which holds the channel information or invalid
Function getChannelInfo(channelIndexFocused)
  channelInfo = invalid
  content = m.ChannelList.content

  if content <> invalid AND content.getchildCount() > 0
    channelInfo = content.getchild(channelIndexFocused)
  end if
  return channelInfo
End Function


Function animateInfoPanel()
  infoPanelGroupAnimationGrp = hideInfoPanel()
  if infoPanelGroupAnimationGrp <> invalid
    infoPanelGroupAnimationGrp.observeFieldScoped("state", "onInfoPanelGroupChange")
  end if
End Function


'@returns: animationNode or invalid, infoPanelGroupAnimationGrp animation node which helps to show the information of other programs
'          returns animationNode when user presses "up" or "down"
'          returns invalid for any other time
Function hideInfoPanel()
  infoPanelGroupAnimationGrp = invalid

  if m.direction = "up"
    infoPanelGroupAnimationGrp = slideFade(m.InfoPanelGroup, "below", "out", 0.3, 0, 30)
  else if m.direction = "down"
    infoPanelGroupAnimationGrp = slideFade(m.InfoPanelGroup, "above", "out", 0.3, 0, 30)
  else
    'The block will not get triggered, but for safety we wrote a code to just hide info panel
    'we return infoPanelGroupAnimationGrp as invalid by default when the direction is not up or down
    'because, we don't need to observe the state of animation to show the info panel of previous/next program
    fade(m.InfoPanelGroup, "out", 0.3)
  end if

  return infoPanelGroupAnimationGrp
End Function


Function showInfoPanel()
  if m.direction = "up"
    slideFade(m.InfoPanelGroup, "above", "in", 0.3, 0, 30)
  else if m.direction = "down"
    slideFade(m.InfoPanelGroup, "below", "in", 0.3, 0, 30)
  else
    fade(m.InfoPanelGroup, "in", 0.3)
  end if
End Function


Function onInfoPanelGroupChange(msg)
  animationState = msg.getData()
  infoPanelGroup = msg.getRoSGNode()

  if animationState = "stopped"
    infoPanelGroup.unobserveField("state")
    channelInfo = getChannelInfo(m.channelIndexFocused)
    updateInfoPanel(channelInfo)
    showInfoPanel()
  end if
End Function