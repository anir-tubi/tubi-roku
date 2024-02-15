Function init()
  topRef = m.top
  m.overlayBackground = topRef.findNode("overlayBackground")
  m.closedCaptionSection = topRef.findNode("closedCaptionSection")
  m.closedCaptionSelector = topRef.findNode("closedCaptionSelector")
  m.audioTrackSelector = topRef.findNode("audioTrackSelector")
  m.audioTracksSection = topRef.findNode("audioTracksSection")

  topRef.observeFieldScoped("focusedChild", "onComponentFocus")
  topRef.observeFieldScoped("globalCaptionMode", "onGlobalCaptionModeChange")
  m.closedCaptionSelector.observeFieldScoped("itemSelected", "onClosedCaptionSelectorItemSelectedChange")
  m.audioTrackSelector.observeFieldScoped("itemSelected", "onAudioTrackSelectorItemSelectedChange")

  closedCaptionSectionHeaderLabel = topRef.findNode("closedCaptionSectionHeaderLabel")
  closedCaptionSectionHeaderLabel.text = getTranslation("cc_audio_overlay_subtitles")

  audioTracksSectionHeaderLabel = topRef.findNode("audioTracksSectionHeaderLabel")
  audioTracksSectionHeaderLabel.text = getTranslation("cc_audio_overlay_audio")

  m.constants = getConstantsFromGlobal()
  m.globalCaptionMode = "Off"

  m.tubiTrackingInfo = TubiTrackingInfo(m.constants)

  m.currentAudioTrack = ""
  m.top.observeFieldScoped("currentAudioTrack", "onCurrentAudioTrackChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(closedCaptionSectionHeaderLabel, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(audioTracksSectionHeaderLabel, typographyConstants.ids.subheaderMedium)


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
    m.closedCaptionSelector.focusBitmapBlendColor = theme.focusedColor
    m.audioTrackSelector.focusBitmapBlendColor = theme.focusedColor
    m.overlayBackground.blendColor = theme.neutralSolidColor
  end if
End Function


Function onCurrentAudioTrackChange(msg)
  m.currentAudioTrack = msg.getData()
End Function


' Callback triggered when the component receives focus.
Function onComponentFocus()
  if m.top.hasFocus() = true
    renderAvailableClosedCaptionTracks()
    renderAudioTracks()
    ' Checking to make sure we have items in closed caption selector before setting focus.
    if m.closedCaptionSelector.content <> invalid
      m.closedCaptionSelector.setFocus(true)
    else
      ' We will never have a use case where both are empty since we do not show the overlay itself if both are empty.
      m.audioTrackSelector.setFocus(true)
    end if
  end if
End Function


Function renderAvailableClosedCaptionTracks()
  availableClosedCaptionTracks = m.top.availableClosedCaptionTracks
  closedCaptionTrack = m.top.closedCaptionTrack
  trackNodes = []
  if availableClosedCaptionTracks.Count() > 0
    globalCaptionMode = m.globalCaptionMode
    ' Creating a item to disable closed captioning.
    trackNodes = [{
      title: "Off"
      checked: (globalCaptionMode = "Off")
    }]

    defaultCheckedItemIndex = 0
    index = 0
    ' Looping through the available tracks exposed by video node.
    for each track in availableClosedCaptionTracks
      ' Incrementing the value since off is the first element.
      index = index + 1
      ' Checking if the caption is turned on or in instant replay mode and selected track matches the item.
      checked = (globalCaptionMode <> "Off" AND closedCaptionTrack = track.trackName)
      trackNodes.push({
        title: track.description
        checked: checked
      })

      if checked = true
        defaultCheckedItemIndex = index
      end if
    end for

    ' Setting the initial default checked item index.
    m.closedCaptionSelector.defaultCheckedItemIndex = defaultCheckedItemIndex

    node = CreateObject("roSGNode", "ContentNode")
    node.update(trackNodes, true)

    m.closedCaptionSelector.content = node
  else
    ' Resetting the content.
    m.closedCaptionSelector.content = invalid
  end if

  ' Hiding the closed caption section if there are no options available.
  ' Using scale so that layout adjust position accordingly.
  if trackNodes.Count() > 0
    m.closedCaptionSection.scale = [1, 1]
  else
    m.closedCaptionSection.scale = [0, 0]
  end if
End Function


Function renderAudioTracks()
  currentAudioTrack = m.currentAudioTrack
  availableAudioTracks = m.top.availableAudioTracks

  ' Sorting the audio tracks since the sort order is not assured from backend.
  ' Below approach of sorting will make sure even when we have multiple languages they are grouped together.
  ' And always as the same position.
  availableAudioTracks.sortBy("Name")

  ' Storing in availableAudioTracks in m scope since we sorting the array obtained from roku video node.
  m.availableAudioTracks = availableAudioTracks

  trackNodes = []
  if availableAudioTracks.Count() > 1
    index = 0

    for each track in availableAudioTracks
      if isNonEmptyString(track.name) then
        checked = (currentAudioTrack = track.track)
        trackNodes.push({
          title: track.name
          checked: checked
        })

        if checked = true
          m.audioTrackSelector.defaultCheckedItemIndex = index
        end if
        index = index + 1
      end if
    end for

    if trackNodes.Count() > 1
      node = CreateObject("roSGNode", "ContentNode")
      node.update(trackNodes, true)
      m.audioTrackSelector.content = node
    else
      ' Resetting the content to invalid
      m.audioTrackSelector.content = invalid
    end if
  end if

  ' Using scale so that layout adjust position accordingly.
  if trackNodes.Count() > 1
    m.audioTracksSection.scale = [1, 1]
  else
    m.audioTracksSection.scale = [0, 0]
  end if
End Function


' Callback triggered when the user changes the caption selection.
Function onClosedCaptionSelectorItemSelectedChange(msg)
  itemSelected = msg.getData()

  ' If the selected item is index position zero than turning off the captions.
  if itemSelected = 0
    m.top.globalCaptionTurnedOff = true
    m.globalCaptionMode = "Off"
    m.top.trackingEventInfo = {
      type: "subtitles_toggle"
      values: {
        video_id: m.top.videoId
        toggle_state: "OFF"
      }
    }
  else
    m.top.globalCaptionTurnedOn = true
    m.globalCaptionMode = "On"
    selectedTrack = m.top.availableClosedCaptionTracks[itemSelected - 1]

    if selectedTrack <> invalid
      m.top.trackingEventInfo = {
        type: "subtitles_toggle"
        values: {
          video_id: m.top.videoId
          toggle_state: "ON"
          language_code: m.tubiTrackingInfo.getLanguageCode(selectedTrack.language)
        }
      }
      m.top.closedCaptionTrack = selectedTrack.TrackName
    end if
  end if
End Function


Function onAudioTrackSelectorItemSelectedChange(msg)
  itemSelected = msg.getData()
  selectedTrack = m.availableAudioTracks[itemSelected]

  if selectedTrack <> invalid
    m.top.audioTrack = selectedTrack.track
    m.currentAudioTrack = selectedTrack.track

    hasAccessibilityDescription = false
    if selectedTrack.name.instr(m.constants.player.audioDescriptionTrackNamePrefix) > -1
      hasAccessibilityDescription = true
    end if

    m.top.trackingEventInfo = {
      type: "audio_selection"
      values: {
        video_id: m.top.videoId
        language_code: m.tubiTrackingInfo.getLanguageCode(selectedTrack.language)
        descriptions_enabled: (hasAccessibilityDescription = true)
      }
    }

    ' Setting the preferred audio track so that it can saved to user/device settings.
    role = m.constants.player.audioTrackRoles.main
    if hasAccessibilityDescription = true
      role = m.constants.player.audioTrackRoles.description
    end if

    m.top.audioTrackSettings = {
      language: selectedTrack.language,
      role: role
    }
  end if
End Function


Function onGlobalCaptionModeChange(msg)
  m.globalCaptionMode = msg.getData()
End Function


Function onKeyEvent(key as string, press as boolean) as boolean
  if press = false
    return false
  end if

  if key = "down" AND m.closedCaptionSelector.isInFocusChain() = true AND m.audioTrackSelector.content <> invalid
    return m.audioTrackSelector.setFocus(true)
  else if key = "up" AND m.audioTrackSelector.isInFocusChain() = true AND m.closedCaptionSelector.content <> invalid
    return m.closedCaptionSelector.setFocus(true)
  else if key = "back"
    m.top.wasBackButtonSelected = true
    return true
  end if

  return false
End Function
