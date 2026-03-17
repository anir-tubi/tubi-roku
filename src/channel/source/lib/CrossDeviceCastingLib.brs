' CrossDeviceCastingLib.brs
' Helper library for Voyager cross-device communication.
' Provides utilities for parsing Voyager messages and extracting command data.


' Parse the inner payload from a Voyager message
' Voyager messages have nested payloads: message.payload.payload contains the actual command data
' @param message: assocarray - The parsed Voyager message
' @return: assocarray or invalid - The extracted command data
Function extractCastingCommandPayload(message) as Object
  ' The actual command data is nested in payload.payload
  if message <> invalid AND message.payload <> invalid AND message.payload.payload <> invalid
    return message.payload.payload
  end if

  return invalid
End Function


' Check if a payload matches a specific casting command type
' @param payload: assocarray - The extracted command payload
' @param commandType: string - The expected command type to match against
' @return: boolean
Function isCastingCommandType(payload, commandType as String) as Boolean
  if payload = invalid
    return false
  end if

  return (payload.type = commandType)
End Function


' Attach observers to the video player screen for casting metadata
' @param videoPlayerScreen: roSGNode - The video player screen to attach observers to
Function attachCastingVideoPlayerObservers(videoPlayerScreen as Object)
  m.castingVideoPlayerObserversActive = true
  videoPlayerScreen.observeFieldScoped("state", "onCastingPlayerStateChanged")
  videoPlayerScreen.observeFieldScoped("position", "onCastingPlayerPositionChanged")
  videoPlayerScreen.observeFieldScoped("globalCaptionMode", "onCastingGlobalCaptionModeChanged")
  if videoPlayerScreen.id <> m.constants.ui.screenIds.linearVideoPlayerScreen
    videoPlayerScreen.observeFieldScoped("adPlaybackPosition", "onCastingAdPlaybackPositionChanged")
    videoPlayerScreen.observeFieldScoped("exitPlayer", "onCastingExitPlayerChanged")
  else
    videoPlayerScreen.observeFieldScoped("backButtonPressed", "onCastingExitPlayerChanged")
  end if
End Function


' Release casting-specific observers from the video player screen.
' Uses a flag for "state" to avoid removing the shared onVideoPlayerState observer
' registered by setupVideoPlayer, since unobserveFieldScoped removes ALL scoped
' observers for a field.
' @param videoPlayerScreen: roSGNode - The video player screen to release observers from
Function releaseCastingVideoPlayerObservers(videoPlayerScreen as Object)
  m.castingVideoPlayerObserversActive = false
  videoPlayerScreen.unobserveFieldScoped("position")
  videoPlayerScreen.unobserveFieldScoped("globalCaptionMode")
  if videoPlayerScreen.id <> m.constants.ui.screenIds.linearVideoPlayerScreen
    videoPlayerScreen.unobserveFieldScoped("adPlaybackPosition")
    videoPlayerScreen.unobserveFieldScoped("exitPlayer")
  else
    videoPlayerScreen.unobserveFieldScoped("backButtonPressed")
  end if
End Function


' Returns the active subtitle language code for casting metadata.
' @param videoPlayerScreen: roSGNode - The current video player screen
' @return string - Two-character language code (e.g. "en"), or "" if captions are off
Function getCastingSubtitleLanguage(videoPlayerScreen as Object) as String
  if videoPlayerScreen.globalCaptionMode <> "On"
    return ""
  end if

  subtitleTrackSettings = videoPlayerScreen.subtitleTrackSettings
  if subtitleTrackSettings <> invalid AND subtitleTrackSettings.language <> invalid
    return LCase(subtitleTrackSettings.language)
  end if

  return ""
End Function


' Returns ad playback information for casting metadata, or invalid when no ad is playing.
' Uses adPlaybackPosition (updated every second by RAF) for the current position, and
' adTrackingObject (updated on discrete RAF events) for ad metadata.
' @param videoPlayerScreen: roSGNode - The current video player screen
' @return assocarray or invalid - Ad info with position, duration, sequence, and podCount
Function getCastingAdInfo(videoPlayerScreen as Object) as Object
  if videoPlayerScreen.adState <> "adsPlaying"
    return invalid
  end if

  trackingObj = videoPlayerScreen.adTrackingObject
  if trackingObj = invalid
    return invalid
  end if

  return {
    "position": videoPlayerScreen.adPlaybackPosition
    "duration": getNumber(trackingObj.duration)
    "sequence": getNumber(trackingObj.adIndex)
    "podCount": getNumber(trackingObj.adCount)
  }
End Function
