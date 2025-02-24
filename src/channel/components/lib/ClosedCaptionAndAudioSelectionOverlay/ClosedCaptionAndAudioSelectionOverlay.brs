Function init()
  topRef = m.top

  deviceInfo = CreateObject("roDeviceInfo")
  modelType = deviceInfo.GetModelType()
  m.captionModes = ["On", "Off", "Instant replay"]

  if modelType = "TV"
    m.captionModes.push("When mute")
  end if

  m.playerSideOverlay = invalid
  m.closedCaptionAndAudioSettings = []

  topRef.observeFieldScoped("focusedChild", "onComponentFocus")
  topRef.observeFieldScoped("globalCaptionMode", "onGlobalCaptionModeChange")

  m.constants = getConstantsFromGlobal()
  m.globalCaptionMode = "Off"

  'The isCCOrAudioSelectedFromFirmware variable is a boolean flag used to identify the source of updates to Closed Captions (CC) or audio tracks.
  'Source can be from Roku firmware overlay or our application's CC overlay. If the update happened via roku firmware overlay, then we need to hide our CCOverlay. 
  m.isCCOrAudioSelectedFromFirmware = true

  m.tubiTrackingInfo = TubiTrackingInfo(m.constants)

  m.currentSubtitleTrack = ""
  topRef.observeFieldScoped("currentSubtitleTrack", "onCurrentSubtitleTrackChanged")

  m.currentAudioTrack = ""
  topRef.observeFieldScoped("currentAudioTrack", "onCurrentAudioTrackChange")
End Function


Function onCurrentSubtitleTrackChanged(msg)
  m.currentSubtitleTrack = msg.getData()

  if m.isCCOrAudioSelectedFromFirmware = true
    m.top.wasBackButtonSelected = true
  else
    updateSubtitleModeAndSubtitleTrackUI()
  end if
End Function


Function onCurrentAudioTrackChange(msg)
  m.currentAudioTrack = msg.getData()

  if m.isCCOrAudioSelectedFromFirmware = true
    m.top.wasBackButtonSelected = true
  else
    updateAudioTrackUI()
  end if
End Function


Function showClosedCaptionAndAudioSettings()
  m.top.removeChild(m.playerSideOverlay)
  m.playerSideOverlay = invalid
  m.closedCaptionAndAudioSettings = []

  subtitleModeAA = {}
  subtitleModeAA.id = "subtitleModes"
  subtitleModeAA.title = getTranslation("cc_audio_overlay_subtitles_mode")
  subtitleModeAA.subtitle = invalid
  subtitleModeAA.hasSubmenu = true

  defaultCheckedItemIndex = 0
  subtitleModeArray = []
  captionModes = m.captionModes

  for i = 0 to captionModes.Count()-1
    captionMode = captionModes[i]

    if captionMode = m.globalCaptionMode
      defaultCheckedItemIndex = i
      subtitleModeArray.push({
        id: "subtitleMode"
        title: getLocalizedSubtitleMode(captionMode)
        checked: true
        hasSubmenu: true
      })
    end if
    
  end for

  subtitleModeContentNode = CreateObject("roSGNode", "ContentNode")
  subtitleModeContentNode.update(subtitleModeArray, true)
  subtitleModeAA.content = subtitleModeContentNode
  subtitleModeAA.defaultCheckedItemIndex = defaultCheckedItemIndex
  m.closedCaptionAndAudioSettings.push(subtitleModeAA)

  'Subtitle
  subtitleAA = {}
  subtitleAA.title = getTranslation("cc_audio_overlay_subtitles")
  subtitleAA.id = "subtitleTracks"
  subtitleAA.subtitle = invalid
  subtitleAA.hasSubmenu = false
  tracks = renderAvailableClosedCaptionTracks()
  subtitleNode = tracks.content
  subtitleAA.content = subtitleNode
  subtitleAA.defaultCheckedItemIndex = tracks.defaultCheckedItemIndex
  subtitleCount = subtitleNode.getChildCount()

  'Audio
  audioTrackAA = {}
  audioTrackAA.title = getTranslation("cc_audio_overlay_audio")
  audioTrackAA.id = "audioTracks"
  audioTrackAA.subtitle = invalid
  audioTrackAA.hasSubmenu = false
  tracks = renderAudioTracks()
  audioTrackNode = tracks.content
  audioTrackAA.content = audioTrackNode
  audioTrackAA.defaultCheckedItemIndex = tracks.defaultCheckedItemIndex
  audioTrackCount = audioTrackNode.getChildCount()

  numRows = getNumRowsForSubtitleAndAudioTrack(subtitleCount, audioTrackCount)
  subtitleAA.numRows = numRows.subtitle
  audioTrackAA.numRows = numRows.audioTrack

  if subtitleCount > 0 
    m.closedCaptionAndAudioSettings.push(subtitleAA)
  end if

  if audioTrackCount > 0
    m.closedCaptionAndAudioSettings.push(audioTrackAA)
  end if

  m.playerSideOverlay = CreateObject("roSGNode", "PlayerSideOverlay")
  m.playerSideOverlay.observeFieldScoped("itemUpdated", "onCCAndAudioOptionItemSelected")
  m.playerSideOverlay.observeFieldScoped("backOrLeftKeyPress", "onCCAndAudioOptionBackKeyPressed")
  m.top.appendChild(m.playerSideOverlay)

  m.playerSideOverlay.itemList = m.closedCaptionAndAudioSettings
  m.playerSideOverlay.setFocus(true)
End Function


' This function returns the localized subtitle modes. Eg. If we pass "Instant replay" to this, it will return "On Replay"
'
'mode: string, subtitle modes, possible values are "On", "Off", "Instant replay", "When mute"
'returns (string) localized subtitle modes
Function getLocalizedSubtitleMode(mode)
  translatedMode = mode

  if mode = "Instant replay"
    translatedMode = "On Replay"
  else if mode = "When mute"
    translatedMode = "On Mute"
  end if  

  return translatedMode
End Function


Function onCCAndAudioOptionBackKeyPressed()
  m.top.wasBackButtonSelected = true
End Function


Function onCCAndAudioOptionItemSelected(msg)
  screen = msg.getRoSGNode()

  if screen <> invalid
    item = screen.content
    
    if item <> invalid AND item.checked = true
      
      if item.id = "subtitleMode"
        showSubtitleModeSubMenu()
      else if item.id = "subtitleTrack"
        m.isCCOrAudioSelectedFromFirmware = false
  
        if item.title = "Off"
  
          m.globalCaptionMode = "Off"
          m.top.globalCaptionChanged = m.globalCaptionMode
  
          m.top.trackingEventInfo = {
            type: "subtitles_toggle"
            values: {
              video_id: m.top.videoId
              toggle_state: "OFF"
            }
          }
        else
          if m.globalCaptionMode = "Off"
            m.globalCaptionMode = "On"
          end if
  
          languageCode = m.tubiTrackingInfo.getLanguageCode(item.language)
  
          m.top.trackingEventInfo = {
            type: "subtitles_toggle"
            values: {
              video_id: m.top.videoId
              toggle_state: "ON"
              language_code: languageCode
            }
          }
  
          m.top.subtitleTrack = item.trackName
          m.currentSubtitleTrack = item.trackName
          m.top.globalCaptionChanged = m.globalCaptionMode
  
        end if  
      else if item.id = "audioTrack"
        m.isCCOrAudioSelectedFromFirmware = false
        m.top.audioTrack = item.track
        m.currentAudioTrack = item.track
  
        hasAccessibilityDescription = false
        if item.name.instr(m.constants.player.audioTrack.audioDescriptionTrackNamePrefix) > -1
          hasAccessibilityDescription = true
        end if
  
        m.top.trackingEventInfo = {
          type: "audio_selection"
          values: {
            video_id: m.top.videoId
            language_code: m.tubiTrackingInfo.getLanguageCode(item.language)
            descriptions_enabled: (hasAccessibilityDescription = true)
          }
        }
      end if

    end if
  end if

  'resetting isCCOrAudioSelectedFromFirmware
  m.isCCOrAudioSelectedFromFirmware = true
End Function


' Callback triggered when the component receives focus.
Function onComponentFocus()
  if m.top.hasFocus() = true
    showClosedCaptionAndAudioSettings()
  end if
End Function


Function renderAvailableClosedCaptionTracks()
  availableClosedCaptionTracks = m.top.availableClosedCaptionTracks
  subtitleTrack = m.currentSubtitleTrack

  trackArray = []
  content = CreateObject("roSGNode", "ContentNode")
  defaultCheckedItemIndex = 0

  if availableClosedCaptionTracks.Count() > 0
    globalCaptionMode = m.globalCaptionMode
    ' Creating a item to disable closed captioning.
    trackArray = [{
      id: "subtitleTrack"
      title: "Off"
      checked: (globalCaptionMode = "Off")
    }]

    index = 0
    ' Looping through the available tracks exposed by video node.
    for each track in availableClosedCaptionTracks
      ' Incrementing the value since off is the first element.
      index = index + 1

      ' Checking if the caption is turned on or in instant replay mode and selected track matches the item.
      checked = (globalCaptionMode <> "Off" AND subtitleTrack = track.trackName)
      localizedTitle = getLocalizedSubtitleLanguage(track.description)

      if localizedTitle <> invalid
        trackArray.push({
          id: "subtitleTrack"
          title: localizedTitle
          checked: checked
          trackName: track.trackName
          language: track.Language
        })

        if checked = true
          defaultCheckedItemIndex = index
        end if
      end if

    end for

    content.update(trackArray, true)
  end if

  tracks = {
    content: content
    defaultCheckedItemIndex: defaultCheckedItemIndex
  }

  return tracks
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

  trackArray = []
  content = CreateObject("roSGNode", "ContentNode")
  defaultCheckedItemIndex = 0

  if m.availableAudioTracks.Count() > 1
    index = 0
    sortedAudioTracks = sortAudioTracks(m.availableAudioTracks)
    m.availableAudioTracks = sortedAudioTracks

    for each track in sortedAudioTracks

      if isNonEmptyString(track.name) then
        checked = (currentAudioTrack = track.track)
        localizedTitle = getLocalizedAudioTrackLanguage(track)

        trackArray.push({
          id: "audioTrack"
          title: localizedTitle
          checked: checked
          track: track.Track
          name: track.Name
          language: track.Language
        })

        if checked = true
          defaultCheckedItemIndex = index
        end if
        index = index + 1
      end if
    end for

    content.update(trackArray, true)
  end if

  content = CreateObject("roSGNode", "ContentNode")
  content.update(trackArray, true)

  tracks = {
    content: content
    defaultCheckedItemIndex: defaultCheckedItemIndex
  }

  return tracks
End Function


' gets the numRows Count for Subtitle & AudioTrack
' Maximum 7 items can be displayed on ClosedCaptionAndAudioSelectionOverlay at a time. In that, 1 item is dedicated for SubtitleMode
' Few examples:
' If there are 7 subtitles & 2 audio tracks, it displays 4 subtitles & 2 audio tracks.
' If there are 7 subtitles & 3 audio tracks, it displays 3 subtitles & 3 audio tracks.
' If there are 5 subtitles & 5 audio tracks, it displays 3 subtitles & 3 audio tracks.
' If there are 6 subtitles & 0 audio tracks, it displays 6 subtitles & no audio tracks.
'
' returns assocarray which has subtitle & audiotrack display count
Function getNumRowsForSubtitleAndAudioTrack(totalSubtitleCount, totalAudioTrackCount)
  ' Maximum Subtitles & Audio Track can be displayed on Screen
  maxSubtitleAndAudioTrackOnScreen = 6
  ' Maximum Subtitles can be displayed on Screen if there are 3 or more Audio Tracks
  maxSubtitleOnScreen = 3
  ' Maximum Audio Track can be displayed on Screen if there are 3 or more Subtitles
  maxAudioTrackOnScreen = 3

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


Function updateSubtitleModeAndSubtitleTrackUI()
  closedCaptionAndAudioSettings = m.closedCaptionAndAudioSettings
  closedCaptionAndAudioSettingsCount = closedCaptionAndAudioSettings.Count()

  for i = 0 to closedCaptionAndAudioSettingsCount - 1

    if closedCaptionAndAudioSettings[i].id = "subtitleModes"
      closedCaptionAndAudioSettings[i].content.getChild(0).title = getLocalizedSubtitleMode(m.globalCaptionMode)
    end if

    if closedCaptionAndAudioSettings[i].id = "subtitleTracks"
      content = closedCaptionAndAudioSettings[i].content

      if m.globalCaptionMode = "Off"

        for j = 0 to content.getChildCount()-1
          if content.getChild(j).title = "Off"
            content.getChild(0).checked = true
          else
            content.getChild(j).checked = false
          end if
        end for

      else

        for j = 0 to content.getChildCount()-1
          trackName = content.getChild(j).trackName

          if m.currentSubtitleTrack = trackName
            content.getChild(j).checked = true
          else
            content.getChild(j).checked = false
          end if
        end for

      end if
    end if

  end for
End Function


Function updateAudioTrackUI()
  closedCaptionAndAudioSettings = m.closedCaptionAndAudioSettings
  closedCaptionAndAudioSettingsCount = closedCaptionAndAudioSettings.Count()

  for i = 0 to closedCaptionAndAudioSettingsCount - 1

    if closedCaptionAndAudioSettings[i].id = "audioTracks"
      content = closedCaptionAndAudioSettings[i].content

      for j = 0 to content.getChildCount()-1
        track = content.getChild(j).track

        if m.currentAudioTrack = track
          content.getChild(j).checked = true
        else
          content.getChild(j).checked = false
        end if
      end for

    end if

  end for
End Function


Function onGlobalCaptionModeChange(msg)
  m.globalCaptionMode = msg.getData()

  if m.isCCOrAudioSelectedFromFirmware = true
    m.top.wasBackButtonSelected = true
  else
    updateSubtitleModeAndSubtitleTrackUI()
  end if

End Function


Function showSubtitleModeSubMenu()
  m.top.removeChild(m.playerSideOverlay)
  m.playerSideOverlay = invalid
  subtitleModeArray = []
  captionModes = m.captionModes

  subtitleModeSubMenuAA = {}
  subtitleModeSubMenuAA.id = "subtitleModeSubMenu"
  subtitleModeSubMenuAA.title = getTranslation("cc_audio_overlay_subtitles_mode")
  subtitleModeSubMenuAA.subtitle = invalid
  subtitleModeSubMenuAA.hasSubmenu = false
  defaultCheckedItemIndex = 0

  for i = 0 to captionModes.Count()-1
    
    if captionModes[i] = m.globalCaptionMode
      checked = true
      defaultCheckedItemIndex = i
    else
      checked = false  
    end if

    subtitleModeArray.push({
      id: captionModes[i].trim()
      title: getLocalizedSubtitleMode(captionModes[i])
      checked: checked
    })

  end for

  content = CreateObject("roSGNode", "ContentNode")
  content.id = "subtitleMode"
  content.update(subtitleModeArray, true)
  
  subtitleModeSubMenuAA.content = content
  subtitleModeSubMenuAA.defaultCheckedItemIndex = defaultCheckedItemIndex
  subtitleModeSubMenuAA.numRows = content.getChildCount()

  m.closedCaptionAndAudioSettings = []
  m.closedCaptionAndAudioSettings.push(subtitleModeSubMenuAA)

  m.playerSideOverlay = CreateObject("roSGNode", "PlayerSideOverlay")
  m.playerSideOverlay.observeFieldScoped("itemUpdated", "onSubtitleModeSubMenuItemSelected")
  m.playerSideOverlay.observeFieldScoped("backOrLeftKeyPress", "onSubtitleModeBackKeyPressed")
  m.top.appendChild(m.playerSideOverlay)

  m.playerSideOverlay.itemList = m.closedCaptionAndAudioSettings
  m.playerSideOverlay.setFocus(true)
  
End Function


Function onSubtitleModeBackKeyPressed(msg)
  showClosedCaptionAndAudioSettings()
End Function


Function onSubtitleModeSubMenuItemSelected(msg)
  screen = msg.getRoSGNode()

  if screen <> invalid
    item = screen.content

    if item <> invalid AND item.checked = true
      m.isCCOrAudioSelectedFromFirmware = false
      m.top.globalCaptionChanged = item.id
      m.globalCaptionMode = item.id
    end if

  end if
End Function