''''''''
' TubiSGAdShim - Connect to the Scene Graph video player and listen for ad request events
'
'''''''
Function TubiSGAdShim(constants, ads)
  return {
    ' dependencies
    constants_: constants
    ads: ads

    ' private
    videoAdsList: invalid
    resumePlayAdsList: invalid
    preroll: tubiSGAdShim_preroll
    playAds: tubiSGAdShim_playAds
    reset: tubiSGAdShim_reset
    midroll: tubiSGAdShim_midroll
    resume: tubiSGAdShim_resume

    ' public
    run: tubiSGAdShim_run
    handleControlMessage: tubiSGAdShim_handleControlMessage
  }
End Function


''''''''''''''''
' run
'
' Attach to the scene graph VideoPlayer node and listen for events
' This is a blocking call
Function tubiSGAdShim_run(videoPlayerNode As Object) As boolean
  tubiLog("TubSGAdShim.Run")
  m.videoPlayerNode = videoPlayerNode

  if type(m.videoPlayerNode) <> "roSGNode" or m.videoPlayerNode.subtype() <> "VideoPlayerScreen"
    tubiLog("TubSGAdShim.Run: videoPlayerNode is not component type VideoPlayer")
    return false
  end if
  port = CreateObject("roMessagePort")
  m.videoPlayerNode.observeField("adControl", port)

  ' Let SceneGraph know that ad shim is ready
  m.videoPlayerNode.adState = "ready"

  while(true)
    msg = wait(0, port)
    msgType = type(msg)
    
    if msgType = "roSGNodeEvent"
      tubiLog("TubiSGAdShim got roSGNodeEvent for " + msg.GetField())
      if msg.GetField() = "exitApp"
        if msg.GetData() = true
          return true
        end if
      else if msg.GetField() = "adControl"
        value = msg.GetData()        
        if m.videoPlayerNode.content <> invalid
          episode = m.videoPlayerNode.content.getFields()  ' clone the content node into a local AA to avoid messing with it
          '//Place the tracking info into the episode AA variable
          episode.videoSponsorExposureId = m.videoPlayerNode.videoSponsorExposureId

          position = m.videoPlayerNode.adPosition
          tubiLog("TubiSGAdShim: adControl = " + value + " position = " + stri(position))
          print "ad state "; m.videoPlayerNode.adState
          m.ads.appMode = m.videoPlayerNode.appMode
          m.handleControlMessage(m.videoPlayerNode.adState, value, episode, position)
        else
          m.videoPlayerNode.adState = "noads"  ' if video player content was changed before we got here, return no ads
        end if
      end if
    end if
  end while
End Function


'''''''''''''''''''''''''''
' handleControlMessage
'
Function tubiSGAdShim_handleControlMessage(state As String, control As String, episode As Object, position As Integer)

  stateMachine = {
    init: {
      preroll: "preroll"
      midroll: "preroll"
      seek: "preroll"
      play: ""
      stop: ""
    }
    fetching: {
      preroll: "preroll"
      midroll: ""
      seek: "midroll"
      play: ""
      stop: "reset"
    }
    noads: {
      preroll: "preroll"
      midroll: "midroll"
      seek: "resume"
      play: ""
      stop: "reset"
    }
    adspending: {
      preroll: "preroll"
      midroll: "midroll"
      seek: "resume"
      play: "playAds"
      stop: "reset"
    }
    adsplaying: {
      preroll: "preroll"
      midroll: ""
      seek: ""
      play: ""
      stop: "reset"
    }
    adsclosed: {
      preroll: "preroll"
      midroll: ""
      seek: ""
      play: ""
      stop: "reset"
    }
  }

  ' normalize the position since TubiAds expects the breakPos to align with one of
  ' the midroll times exactly and there is a possibility of the video node 'position'
  ' field to be slightly off due to delays in thread synchronization.
  normalizedPosition = position
  if episode.cuepoints <> invalid and type(episode.cuepoints) = "roArray" then
    for each cuepoint in episode.cuepoints
      ' We'll give an allowance of 15 seconds here.  I don't expect any cuepoints to be
      ' within 15 seconds of each other so this should be safe
      if Abs(position - cuepoint) < 20 then
        normalizedPosition = cuepoint
        exit for
      end if
    end for
  end if

  functionName = stateMachine[state][control]
  tubiLog("TubiSGAdShim: state=" + state + " control=" + control + " function=" + functionName)
  if functionName <> "" then
    newState = m[functionName](episode, normalizedPosition)
  end if
End Function


''''''''''''''''''
' preroll
'
'
Function tubiSGAdShim_preroll(episode As Object, cuepoint As Integer)
  m.videoplayernode.adstate = "fetching"
  m.ads.reset()

  'if the user is starting from beginning or resuming on a cue point, show ads
  'attempt to get list of ads and play them for preroll
  m.ads.getAdsListViaRoku(episode, cuepoint)
  if m.ads.hasAds(m.ads.allAdUnitsList) = true
    m.videoPlayerNode.adState = "adspending"
  else
    m.videoPlayerNode.adState = "noads"
  end if
End Function


''''''''''''''''''''
' playAds
'
' TODO(Chris): The relevant ads here may be:
'      a) resume ads set on m.resumePlayAdsList
'      b) cached ads for non-RAF midrolls in m.videoAdsList
'      c) cached ads in RAF which it stored internally
Function tubiSGAdShim_playAds(episode As Object, cuepoint As Integer)
  m.videoPlayerNode.adState = "adsplaying"

  adContainer = m.videoPlayerNode.findNode("RAFAdContainer")
  status = m.ads.showCommercialBreakViaRoku(adContainer, m.videoPlayerNode)
  if status = m.constants_.player.playerResults.closed
    m.videoPlayerNode.adState = "adsclosed"
  else
    m.videoPlayerNode.adState = "noads"
  end if
End Function


''''''''''''''''''
' reset
Function tubiSGAdShim_reset(episode As Object, cuepoint As Integer)
  m.ads.reset()
  m.videoPlayerNode.adState = "init"
End Function


''''''''''''''''''
' midroll
Function tubiSGAdShim_midroll(episode As Object, cuepoint As Integer)
  m.videoplayernode.adstate = "fetching"
  m.ads.cacheAdsList(episode, cuepoint)
  if m.ads.getCachedAdsList(episode, cuepoint) <> invalid then
    m.videoPlayerNode.adState = "adspending"
  else
    m.videoPlayerNode.adState = "noads"
  end if
End Function


'''''''''''''''''
' resume
Function tubiSGAdShim_resume(episode As Object, cuepoint As Integer)
  m.videoplayernode.adstate = "fetching"
  'NOTE: TubiAds sets resumePlayAdsList on 'm' here
  if m.ads.getResumingPlayAds(episode, cuepoint) then
    tubiLog("Setting adState to adspending")
    m.videoPlayerNode.adState = "adspending"
  else
    tubiLog("Setting adState to noads")
    m.videoPlayerNode.adState = "noads"
  end if
End Function

