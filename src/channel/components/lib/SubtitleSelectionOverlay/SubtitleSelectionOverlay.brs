' SubtitleSelectionOverlay component
' Displays a horizontal list of subtitle track buttons for quick selection during video playback.


Function init()
  m.constants = getConstantsFromGlobal()
  topRef = m.top

  m.contentGroup = topRef.findNode("contentGroup")
  m.buttonList = topRef.findNode("buttonList")
  m.autoHideTimer = topRef.findNode("autoHideTimer")

  m.buttonList.observeFieldScoped("buttonSelected", "onButtonSelected")
  m.autoHideTimer.observeFieldScoped("fire", "onAutoHideTimerFired")
  topRef.observeFieldScoped("show", "onShowChange")
  topRef.observeFieldScoped("hide", "onHideChange")
  topRef.observeFieldScoped("populate", "onPopulateChange")
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
    m.autoHideTimer.control = "start"
    m.buttonList.setFocus(true)
    m.top.isVisible = true
  end if
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
' Stops the auto-hide timer and notifies parent via wasHidden field.
Function hideOverlay() as Void
  if m.contentGroup.opacity > 0
    fade(m.contentGroup, "out", 0.6)
    m.autoHideTimer.control = "stop"
    m.top.isVisible = false
    m.top.wasHidden = true
  end if
End Function


' populateButtons creates buttons based on available subtitle tracks.
' Adds an "Off" button first, then a button for each available track.
' Note: Does not set focus - focus is handled by showOverlay().
Function populateButtons() as Void
  availableTracks = m.top.availableSubtitleTracks

  if availableTracks <> invalid AND availableTracks.Count() > 0
    buttons = []

    ' Add "Off" button first
    buttons.push({
      id: "Off"
      title: getTranslation("dialog_button_off")
      trackName: ""
      isPrimaryButton: true
      displayOnlyIconTileWhenNotFocused: true
    })

    ' Add a button for each available subtitle track
    for each track in availableTracks
      ' Use description if available, otherwise use language
      trackTitle = track.description
      if isNonEmptyString(trackTitle) = false
        trackTitle = track.Language
      end if

      localizedTitle = getLocalizedSubtitleLanguage(trackTitle)

      if isNonEmptyString(localizedTitle) = true
        buttons.push({
          id: track.trackName
          title: localizedTitle
          trackName: track.trackName
          language: track.Language
          isPrimaryButton: true
          displayOnlyIconTileWhenNotFocused: true
        })
      end if
    end for

    m.buttonList.buttons = buttons
  end if
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
' Hides the overlay automatically after the timeout.
Function onAutoHideTimerFired()
  hideOverlay()
End Function


' onShowChange is called when show field is set to true.
Function onShowChange(msg)
  if msg.getData() = true
    showOverlay()
  end if
End Function


' onHideChange is called when hide field is set to true.
Function onHideChange(msg)
  if msg.getData() = true
    hideOverlay()
  end if
End Function


' onPopulateChange is called when populate field is set to true.
Function onPopulateChange(msg)
  if msg.getData() = true
    populateButtons()
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
' Other keys hide overlay but propagate to parent for transport focus.
Function onKeyEvent(key as String, press as Boolean) as Boolean
  handled = false

  if press = true
    hideOverlay()

    if key = "left" OR key = "right" OR key = "back"
      handled = true
    end if
  end if

  return handled
End Function

