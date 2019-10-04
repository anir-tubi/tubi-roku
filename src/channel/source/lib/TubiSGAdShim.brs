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
    removeMidroll: tubiSGAdShim_removeMidroll

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

  ' There is the chance for a race condition where m.videoPlayerNode.isCoppaEnabled is set before the adShim has
  ' a chance to start observing the field, so we grab the initial value here just in case. It can be updated later
  ' by the observer if necessary.
  m.ads.isCoppaEnabled = m.videoPlayerNode.isCoppaEnabled

  if type(m.videoPlayerNode) <> "roSGNode" or m.videoPlayerNode.subtype() <> "VideoPlayer"
    tubiLog("TubSGAdShim.Run: videoPlayerNode is not component type VideoPlayer")
    return false
  end if
  port = CreateObject("roMessagePort")
  m.videoPlayerNode.observeField("adControl", port)
  m.videoplayernode.observeField("isCoppaEnabled", port)

  ' Let SceneGraph know that ad shim is ready
  m.videoPlayerNode.adState = "init"

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
          position = m.videoPlayerNode.adPosition
          tubiLog("TubiSGAdShim: adControl = " + value + " position = " + stri(position))
          print "ad state "; m.videoPlayerNode.adState
          m.handleControlMessage(m.videoPlayerNode.adState, value, episode, position)
        else
          m.videoPlayerNode.adState = "noads"  ' if video player content was changed before we got here, return no ads
        end if
      else if msg.GetField() = "isCoppaEnabled"
        m.ads.isCoppaEnabled = msg.GetData()
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
  if m.ads.midrolls <> invalid and type(m.ads.midrolls) = "roArray" then
    for each cuepoint in m.ads.midrolls
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
    'always update midroll list since TubiAds can
    'make modifications to it throughout playback
    m.videoPlayerNode.midrolls = m.ads.midrolls
    for each time in m.ads.midrolls
      print "MIDROLL: " + time.toStr()
    end for
  end if
End Function


''''''''''''''''''
' preroll
'
'
Function tubiSGAdShim_preroll(episode As Object, cuepoint As Integer)
  m.videoplayernode.adstate = "fetching"
  m.ads.reset()

  'make a synchrynous call to get cuepoints, if any
  port = CreateObject("roMessagePort")
  timer = CreateObject("roTimespan")
  cuepointsReq = m.ads.getCuepointsReq(episode)
  cuepointsReq.start(port)

  'otherwise if the user is starting from beginning or resuming on a cue point, show ads
  'attempt to get list of ads and play them for preroll
  m.ads.getAdsListViaRoku(episode)

  ' wait ONLY 5 seconds for cuepoints to come back
  while timer.TotalMilliseconds() < 5000
    msg = wait(5000 - timer.TotalMilliseconds(), port)
    if type(msg) = "roUrlEvent" and cuepointsReq.handleEvent(msg) <> invalid
      m.ads.parseCuepoints(cuepointsReq)  'sets midrolls times on m.ads.midrolls
      exit while
    end if
  end while

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
    ' Mark the midroll as seen so we don't hit it again if scrubbing
    m.removeMidroll(cuepoint)
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
  if m.ads.getResumingPlayAds(episode, m) then
    tubiLog("Setting adState to adspending")
    m.videoPlayerNode.adState = "adspending"
  else
    tubiLog("Setting adState to noads")
    m.videoPlayerNode.adState = "noads"
  end if
End Function


'''''''''''
' removeMidroll
'
' Mark a midroll as seen using logic from TubiAds.checkForCommercialBreak
Function tubiSGAdShim_removeMidroll(cuepoint As Integer)
  if m.ads.midrolls <> invalid and type(m.ads.midrolls) = "roArray" then
    for i=0 to m.ads.midrolls.Count() - 1
      if cuepoint = m.ads.midrolls[i] then
        m.ads.midrolls[i] = -1000
      end if
    end for
  end if
End Function
