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

  if isNonEmptyArray(m.availableAudioTracks) = true
    for i = 0 to m.availableAudioTracks.Count()-1
      track = m.availableAudioTracks[i]
      
      if track.track = m.currentAudioTrack
        'It is possible user may update the Audio Track in Roku firmware UI when the CCOverlay is open, At this time we need to update the audio track selection on CCOverlay as well to make it same.
        m.audioTrackSelector.updateSelection = i
        exit for
      end if
    end for
  end if

End Function


' Callback triggered when the component receives focus.
Function onComponentFocus()
  if m.top.hasFocus() = true

    totalSubtitleCount = renderAvailableClosedCaptionTracks()
    totalAudioTrackCount = renderAudioTracks()
    numRows = getNumRowsForSubtitleAndAudioTrack(totalSubtitleCount, totalAudioTrackCount)
    m.closedCaptionSelector.numRows = numRows.subtitle
    m.audioTrackSelector.numRows = numRows.audioTrack

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
      localizedTitle = getLocalizedSubtitleLanguage(track.description)

      if localizedTitle <> invalid
        trackNodes.push({
          title: localizedTitle
          checked: checked
        })

        if checked = true
          defaultCheckedItemIndex = index
        end if
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

  trackNodeCount = trackNodes.Count()
  ' Hiding the closed caption section if there are no options available.
  ' Using scale so that layout adjust position accordingly.
  if trackNodeCount > 0
    m.closedCaptionSection.scale = [1, 1]
  else
    m.closedCaptionSection.scale = [0, 0]
  end if

  return trackNodeCount
End Function


Function sortAudioTracks(availableAudioTracks)

  hasAccessibilityDescription = false
  for each track in availableAudioTracks
    if isNonEmptyString(track.name) = true AND track.name.instr(m.constants.player.audioTrack.audioDescriptionTrackNamePrefix) > -1
      hasAccessibilityDescription = true
      exit for
    end if
  end for

  audioTracks = []

  for each track in availableAudioTracks
    languageCode = m.tubiTrackingInfo.getLanguageCode(track.language)

    if languageCode = "EN" 'ENGLISH
      if isNonEmptyString(track.name) = true AND track.name.instr(m.constants.player.audioTrack.audioDescriptionTrackNamePrefix) > -1
        index = 1
      else
        index = 0  
      end if
    else if languageCode = "ES" 'ESPANOL
      if hasAccessibilityDescription = true
        index = 2
      else
        index = 1
      end if
    else if languageCode = "FR" 'FRENCH
      if hasAccessibilityDescription = true
        index = 3
      else
        index = 2
      end if
    else
      index = availableAudioTracks.Count()
    end if

    audioTracks = insertItemIntoArray(audioTracks, track, index)
  end for

  return audioTracks
End Function


Function renderAudioTracks()
  currentAudioTrack = m.currentAudioTrack
  m.availableAudioTracks = m.top.availableAudioTracks
  trackNodeCount = 0
  trackNodes = []

  if m.availableAudioTracks.Count() > 1
    index = 0
    sortedAudioTracks = sortAudioTracks(m.availableAudioTracks)
    m.availableAudioTracks = sortedAudioTracks

    for each track in sortedAudioTracks

      if isNonEmptyString(track.name) then
        checked = (currentAudioTrack = track.track)
        localizedTitle = getLocalizedAudioTrackLanguage(track)

        trackNodes.push({
          title: localizedTitle
          checked: checked
        })

        if checked = true
          m.audioTrackSelector.defaultCheckedItemIndex = index
        end if

        index = index + 1
      end if
    end for

    trackNodeCount = trackNodes.Count()

    if trackNodeCount > 1
      node = CreateObject("roSGNode", "ContentNode")
      node.update(trackNodes, true)
      m.audioTrackSelector.content = node
    else
      ' Resetting the content to invalid
      m.audioTrackSelector.content = invalid
    end if
  end if

  ' Using scale so that layout adjust position accordingly.
  if trackNodeCount > 1
    m.audioTracksSection.scale = [1, 1]
  else
    m.audioTracksSection.scale = [0, 0]
  end if

  return trackNodeCount
End Function


' gets the numRows Count for Subtitle & AudioTrack
' Maximum 8 items can be displayed on ClosedCaptionAndAudioSelectionOverlay at a time.
' Few examples:
' If there are 8 subtitles & 3 audio tracks, it displays 5 subtitles & 3 audio tracks.
' If there are 5 subtitles & 5 audio tracks, it displays 4 subtitles & 4 audio tracks.
' If there are 8 subtitles & 0 audio tracks, it displays 8 subtitles & no audio tracks.
'
' returns assocarray which has subtitle & audiotrack display count
Function getNumRowsForSubtitleAndAudioTrack(totalSubtitleCount, totalAudioTrackCount)
  ' Maximum Subtitles & Audio Track can be displayed on Screen
  maxSubtitleAndAudioTrackOnScreen = 8
  ' Maximum Subtitles can be displayed on Screen if there are 4 of more Audio Tracks
  maxSubtitleOnScreen = 4
  ' Maximum Audio Track can be displayed on Screen if there are 4 of more Subtitles
  maxAudioTrackOnScreen = 4

  closedCaptionNumRows = totalSubtitleCount
  audioTrackNumRows = totalAudioTrackCount

  if (totalSubtitleCount + totalAudioTrackCount) > maxSubtitleAndAudioTrackOnScreen
    if (totalSubtitleCount > maxSubtitleOnScreen) AND (totalAudioTrackCount > maxAudioTrackOnScreen)
      closedCaptionNumRows = maxSubtitleOnScreen
      audioTrackNumRows = maxAudioTrackOnScreen
    else
      subtitleBalance = totalSubtitleCount - maxSubtitleOnScreen
      audioTrackBalance = totalAudioTrackCount - maxAudioTrackOnScreen

      if subtitleBalance > 0 AND audioTrackBalance > 0
        closedCaptionNumRows = maxSubtitleOnScreen
        audioTrackNumRows = maxAudioTrackOnScreen
      else if subtitleBalance > 0 AND audioTrackBalance < 0
        closedCaptionNumRows = maxSubtitleOnScreen - audioTrackBalance
        audioTrackNumRows = totalAudioTrackCount
      else if subtitleBalance < 0 AND audioTrackBalance > 0
        closedCaptionNumRows = totalSubtitleCount
        audioTrackNumRows = maxAudioTrackOnScreen - subtitleBalance
      end if
    end if
  end if

  numRows = {
    subtitle: closedCaptionNumRows
    audioTrack: audioTrackNumRows
  }
  return numRows

End Function


'getLocalizedSubtitleLanguage gets the localized subtitle language
'
'@subtitleLanguage: string, subtitle language returned from backend
'returns localized Subtitle language as string or invalid
Function getLocalizedSubtitleLanguage(subtitleLanguage)
  localizedSubtitleLanguage = invalid
  languageMap = m.constants.player.subtitle.languageMap

  for each language in languageMap

    if subtitleLanguage.instr(language) >= 0
      localizedSubtitleLanguage = m.constants.player.subtitle.localizedLanguage[language]
      exit for
    end if

  end for

  return localizedSubtitleLanguage
End Function


'getLocalizedAudioTrackLanguage gets the localized audio track language
'
'@track: assocarray, audio track object returned from backend
'returns (string) localized audio track name or audio track name as returned from backend
Function getLocalizedAudioTrackLanguage(track)
  localizedAudioTrackLanguage = track.name
  languageCode =  m.tubiTrackingInfo.getLanguageCode(track.language)
  audioDescriptionTrackNamePrefix = m.constants.player.audioTrack.audioDescriptionTrackNamePrefix

  if languageCode = "EN" AND isNonEmptyString(track.name) = true AND track.name.instr(audioDescriptionTrackNamePrefix) > -1 'English Audio Description
    localizedAudioTrackLanguage = m.constants.player.audioTrack.audioDescriptionTrackName
  else if languageCode <> "UNKNOWN"
    localizedAudioTrackLanguage = m.constants.player.audioTrack.localizedLanguage[languageCode]
  end if

  return localizedAudioTrackLanguage
End Function


' Callback triggered when the user changes the caption selection.
Function onClosedCaptionSelectorItemSelectedChange(msg)
  itemSelected = msg.getData()
  languageCode = "Off"

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
      languageCode = m.tubiTrackingInfo.getLanguageCode(selectedTrack.language)

      m.top.trackingEventInfo = {
        type: "subtitles_toggle"
        values: {
          video_id: m.top.videoId
          toggle_state: "ON"
          language_code: languageCode
        }
      }
      m.top.closedCaptionTrack = selectedTrack.TrackName
    end if
  end if

  m.top.subtitleTrackSettings = {
    language: languageCode
  }

End Function


Function onAudioTrackSelectorItemSelectedChange(msg)
  itemSelected = msg.getData()
  selectedTrack = m.availableAudioTracks[itemSelected]

  if selectedTrack <> invalid
    m.top.audioTrack = selectedTrack.track
    m.currentAudioTrack = selectedTrack.track

    hasAccessibilityDescription = false
    if selectedTrack.name.instr(m.constants.player.audioTrack.audioDescriptionTrackNamePrefix) > -1
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
