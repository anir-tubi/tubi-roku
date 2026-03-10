' SubtitleSelectionOverlay component
' Displays a horizontal list of subtitle track buttons for quick selection during video playback.


Function init()
  m.constants = getConstantsFromGlobal()
  topRef = m.top

  m.contentGroup = topRef.findNode("contentGroup")
  m.buttonList = topRef.findNode("buttonList")
  m.autoHideTimer = topRef.findNode("autoHideTimer")

  m.iconSubtitleDefault = "pkg:/images/transport/sgplayer/icon-subtitles.webp"
  m.iconSubtitleEnabled = "pkg:/images/transport/sgplayer/icon-subtitles-enabled.webp"

  m.buttonList.observeFieldScoped("buttonSelected", "onButtonSelected")
  m.buttonList.observeFieldScoped("buttonFocused", "onButtonFocused")

  topRef.observeFieldScoped("show", "onShowChange")
  topRef.observeFieldScoped("hide", "onHideChange")
End Function


' showOverlay displays the subtitle selection overlay with a fade-in animation.
' Calculates and sets the focus index based on current subtitle track.
' Starts the auto-hide timer and sets focus to the button list.
Function showOverlay() as Void
  if m.contentGroup.opacity = 0.0
    ' Calculate focus index based on current subtitle track
    focusIndex = calculateFocusIndex()
    m.buttonList.jumpToIndex = focusIndex

    fade(m.contentGroup, "in", 0.6)
    startAutoHideTimer()
    m.buttonList.setFocus(true)
    updateSelectedButtonIcon()
  end if
End Function


Function startAutoHideTimer()
  m.autoHideTimer.observeFieldScoped("fire", "onAutoHideTimerFired")
  m.autoHideTimer.control = "start"
End Function


Function stopAutoHideTimer()
  m.autoHideTimer.unobserveFieldScoped("fire")
  m.autoHideTimer.control = "stop"
End Function


' calculateFocusIndex determines which button should be focused based on current subtitle track.
' Returns 0 (Off button) if captions are off, otherwise returns index of current track.
Function calculateFocusIndex() as Integer
  if m.top.globalCaptionMode = "Off"
    return 0
  end if

  buttons = m.buttonList.buttons
  currentTrack = m.top.currentSubtitleTrack

  if buttons = invalid OR buttons.Count() = 0
    return 0
  end if

  ' Find the index of the current subtitle track
  for i = 0 to buttons.Count() - 1
    if buttons[i].trackName = currentTrack
      return i
    end if
  end for

  return 0
End Function


' hideOverlay hides the subtitle selection overlay with a fade-out animation.
' Stops the auto-hide timer. Caller must set backPressed/selectedTrack/playPressed to notify parent.
Function hideOverlay() as Void
  if m.contentGroup.opacity > 0
    fade(m.contentGroup, "out", 0.6)
    stopAutoHideTimer()
  end if
End Function


' Returns the index of the currently selected subtitle button (Off = 0, or track matching currentSubtitleTrack).
Function getSelectedButtonIndex() as Integer
  if m.top.globalCaptionMode = "Off"
    return 0
  end if
  buttons = m.buttonList.buttons
  currentTrack = m.top.currentSubtitleTrack
  if buttons = invalid OR buttons.Count() = 0 then return 0
  for i = 0 to buttons.Count() - 1
    if buttons[i].trackName = currentTrack
      return i
    end if
  end for
  return 0
End Function


' Updates the selected button's iconUrl: enabled when it has focus, default when it does not.
Function updateSelectedButtonIcon() as Void
  selectedIndex = getSelectedButtonIndex()
  focusedIndex = m.buttonList.focusedIndex
  if focusedIndex = -1 then focusedIndex = 0
  selectedButton = m.buttonList.getChild(selectedIndex)
  if selectedButton = invalid OR selectedButton.itemContent = invalid then return
  if focusedIndex = selectedIndex
    selectedButton.itemContent.iconUrl = m.iconSubtitleEnabled
  else
    selectedButton.itemContent.iconUrl = m.iconSubtitleDefault
  end if
End Function


' populateButtons creates buttons based on available subtitle tracks.
' Adds an "Off" button first, then a button for each available track.
' Only the selected item gets iconUrl (default); others have no iconUrl.
' Note: Does not set focus - focus is handled by showOverlay().
Function populateButtons() as Void
  availableTracks = m.top.availableSubtitleTracks

  if availableTracks <> invalid AND availableTracks.Count() > 0
    buttons = []
    currentTrack = m.top.currentSubtitleTrack
    isOffSelected = (m.top.globalCaptionMode = "Off")
    defaultTitle = (getTranslation("cc_audio_overlay_subtitles") + Chr(32) + getTranslation("dialog_button_off"))

    ' Add "Off" button first; only set iconUrl when Off is selected
    offButton = {
      id: "Off"
      title: defaultTitle
      trackName: ""
      isPrimaryButton: true
      displayOnlyIconTileWhenNotFocused: true
    }
    if isOffSelected = true
      offButton.iconUrl = m.iconSubtitleDefault
    end if
    buttons.push(offButton)

    ' Add a button for each available subtitle track; only selected track gets iconUrl
    for each track in availableTracks
      trackTitle = track.description
      if isNonEmptyString(trackTitle) = false
        trackTitle = track.Language
      end if

      localizedTitle = getLocalizedSubtitleLanguage(trackTitle)

      if isNonEmptyString(localizedTitle) = true
        isTrackSelected = (isOffSelected = false AND track.trackName = currentTrack)
        trackButton = {
          id: track.trackName
          title: localizedTitle
          trackName: track.trackName
          language: track.Language
          isPrimaryButton: true
          displayOnlyIconTileWhenNotFocused: true
        }
        if isTrackSelected = true
          trackButton.iconUrl = m.iconSubtitleDefault
        end if
        buttons.push(trackButton)
      end if
    end for

    m.buttonList.buttons = buttons
  end if
End Function


' onButtonFocused updates the selected button's icon (enabled when focused, default when not).
Function onButtonFocused() as Void
  stopAutoHideTimer()
  startAutoHideTimer()
  updateSelectedButtonIcon()
End Function


' onButtonSelected handles when a subtitle button is selected.
' Outputs the selected track via selectedTrack field and hides the overlay.
Function onButtonSelected(msg)
  item = msg.getData()
  hideOverlay()

  if item <> invalid AND item.button <> invalid AND item.button.pressedKey = "play" then
    m.top.playPressed = true
  else
    m.top.selectedTrack = item
  end if
End Function


' onAutoHideTimerFired is called when the auto-hide timer fires.
' Hides the overlay and notifies parent via backPressed so focus is restored.
Function onAutoHideTimerFired()
  hideOverlay()
  m.top.backPressed = true
End Function


' onHideChange is called when hide field is set to true.
Function onHideChange(msg)
  if msg.getData() = true
    hideOverlay()
  end if
End Function


' onShowChange is called when show field is set to true.
Function onShowChange(msg)
  if msg.getData() = true
    populateButtons()
    showOverlay()
  end if
End Function


' getLocalizedSubtitleLanguage gets the localized subtitle language
' @subtitleLanguage: string, subtitle language returned from backend
' @return localized subtitle language as string or invalid
Function getLocalizedSubtitleLanguage(subtitleLanguage)
  if isNonEmptyString(subtitleLanguage) = false
    return invalid
  end if

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


' onKeyEvent handles remote control key presses.
' Hides overlay on any key press. Consumes left/right/back keys.
' Back key notifies parent via backPressed so focus can go to progress bar.
Function onKeyEvent(key as String, press as Boolean) as Boolean
  handled = false

  if press = true
    hideOverlay()

    if key = "back" OR key = "left" OR key = "right"
      m.top.backPressed = true
      handled = true
    end if

  end if

  return handled
End Function

