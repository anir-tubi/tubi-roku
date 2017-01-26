' TODO(Chris): These events and their triggers
'
'   Analytics tracking:
'
'      EVENT            TRIGGERS
'      ===============================
'      videoPlay        only on start of episode playback, or autoplay invoked playback
'
'      resumeAfterAds   after pre-roll and each mid-roll
'
'      playProgress     on start of scrubbing
'                       at regular intervals set by 'pingFrequency' in constants
'
'      seek             at end of scrubbing
'
'      pauseToggle      when paused using pause/play button
'                       when resumed using pause/play button
'
'      subtitle         when subtitles turned off
'                       when subtitles turned on
'
'
'
'   User History tracking:
'
'      - when user exits the ad or video by pressing 'back'
'      - right before a mid-roll
'      - every 60 seconds of watching (hard-coded in TubiPlayer.brs)
'


Function init()
  tubiLog("VideoPlayer.init")
  m.Transport = m.top.findNode("Transport")
  m.Video = m.top.findNode("VideoNode")  ' reference in case we change from extending Video to extending Group
  m.Video.observeField("state", "onVideoStateChange")
  m.Video.observeField("position", "onVideoPositionChange")
  m.top.observeField("content", "onContentChange")
  m.Video.observeField("globalCaptionMode", "onCaptionModeChange")

  m.lastPingTime = 0
  m.lastsavedPosition = 0

  m.analyticsInterval = m.global.constants.player.pingFrequency
  m.historyInterval = m.global.constants.player.historyFrequency
End Function


'''''''''''''''''''''''''
' onVideoPositionChange
'
' The notificationInterval and analyticsInterval are not necessarily equal or evenly divisible
' so we check the time passage before we send playProgress events
Function onVideoPositionChange()
  tubiLog("VideoPlayer.onVideoPositionChange")
  if m.Video.position >= m.lastPingTime + m.analyticsInterval then
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "playProgress"
      ctx: m.Video.content.id
      value: m.Video.position
      extraCtx: {
        interval: m.Video.position - m.lastPingTime
      }
    }
    m.lastPingTime = m.Video.position
    'TODO(Chris): When scrubbing shows up, lastPingTime should be reset once playback resumes
  end if

  if m.Video.position > m.lastsavedPosition + m.historyInterval or m.Video.position < m.lastsavedPosition - m.historyInterval
    m.top.historyPosition = m.Video.position
    m.lastSavedPosition = m.Video.position
  end if
End Function

Function onCaptionModeChange()
  tubiLog("VideoPlayer.onCaptionModeChange")
  if m.Video.content <> invalid then
    if m.Video.globalCaptionMode <> "Off" then
      value = "off"
    else
      value = "on"
    end if
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "subtitles"
      ctx: m.Video.content.id
      value: value
    }
  end if
End Function

Function onContentChange()
  tubiLog("VideoPlayer.onContentChange")
  if m.Video.content <> invalid and m.Video.state <> "playing" then
    if m.Video.content.nowPos <> invalid then
      m.Video.seek = m.Video.content.nowPos
    end if
    m.lastsavedPosition = m.Video.content.nowPos
    m.Video.control = "play"
    
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "videoPlay"
      value: m.Video.content.id
      ctx: m.Video.content.nowPos
      extraCtx: {
        subtitles: m.Video.content.showSubtitles
        livetv: false  ' TODO(Chris): remove this if unnecessary
      }
    }
  end if
End Function

Function onKeyEvent(key As String, press As Boolean)
  tubiLog("VideoPlayer.onKeyEvent key = " + key)
  if press 
    if key = "play" then
      if m.Video.state = "playing" then
        m.Video.control = "pause"
        m.global.trackingLoggingTask.trackEvent = {
          trackType: "pauseToggle"
          ctx: m.Video.content.id
          value: "paused"
        }
      else if m.Video.state = "paused" then
        m.Video.control = "resume"
        m.global.trackingLoggingTask.trackEvent = {
          trackType: "pauseToggle"
          ctx: m.Video.content.id
          value: "resumed"
        }
      end if
    else if key = "back" then 
      m.top.backButtonPressed = true
    end if
  end if
  ' Consume all key presses
  return true
End Function
