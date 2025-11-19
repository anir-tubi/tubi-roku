''''''''
' TubiSGPreloadedAdShim - Connect to the Scene Graph ad player and listen for ad request events
'
'''''''
Function TubiSGPreloadedAdShim(constants, ads)
  return {
    ' dependencies
    constants_: constants
    ads: ads

    ' private
    adsList: invalid
    playAds: tubiSGPreloadedAdShim_playAds
    reset: tubiSGPreloadedAdShim_reset

    ' public
    run: tubiSGPreloadedAdShim_run
    handleControlMessage: tubiSGPreloadedAdShim_handleControlMessage
  }
End Function


''''''''''''''''
' run
'
' Attach to the scene graph VideoPlayer node and listen for events
' This is a blocking call
'@adPlayerNode: node, AdPlayerScreen node
Function tubiSGPreloadedAdShim_run(adPlayerNode) as Boolean
  tubiLog("TubiSGPreloadedAdShim.Run")
  m.adPlayerNode = adPlayerNode

  if type(m.adPlayerNode) <> "roSGNode" OR m.adPlayerNode.subtype() <> "AdPlayerScreen"
    tubiLog("TubiSGPreloadedAdShim.Run: adPlayerNode is not of component type AdPlayerScreen")
    return false
  end if

  ' Re-using the port so that we can listen to ad tracking requests too in the same while loop.
  port = m.ads.adMessagePort
  m.adPlayerNode.observeField("adControl", port)

  ' Let SceneGraph know that ad shim is ready
  m.adPlayerNode.adState = "ready"

  while(true)
    msg = wait(0, port)
    msgType = type(msg)
    if msgType = "roSGNodeEvent"
      tubiLog("TubiSGPreloadedAdShim got roSGNodeEvent for " + msg.GetField())
      if msg.GetField() = "exitApp"
        if msg.GetData() = true
          return true
        end if
      else if msg.GetField() = "adControl"
        value = msg.GetData()
        if m.adPlayerNode.content <> invalid
          content = m.adPlayerNode.content.getFields() ' clone the content node into a local AA to avoid messing with it

          tubiLog("TubiSGPreloadedAdShim: adControl = " + value + " ad state " + m.adPlayerNode.adState)
          m.ads.appMode = m.adPlayerNode.appMode
          m.handleControlMessage(m.adPlayerNode.adState, value, content)
        else
          m.adPlayerNode.adState = "noAds" ' if Ad player content was changed before we got here, return no ads
        end if
      end if
    else if msgType = "roUrlEvent" then
      m.ads.requestQueue.handleEvent(msg)
    end if
  end while
  return false
End Function


'''''''''''''''''''''''''''
' handleControlMessage
'
'@state: string, state of the Ad, possible values are init, adsReady, noAds, adsPlaying, adsClosed, adsCompleted
'@control: string, possible values are play, stop
'@content: assocarray, content fields from ad player
Function tubiSGPreloadedAdShim_handleControlMessage(state, control, content)

  stateMachine = {
    "init": {
      play: ""
      stop: ""
    }
    "adsReady": {
      play: "playAds"
      stop: "reset"
    }
    "adsPlaying": {
      play: ""
      stop: "reset"
    }
    "adsClosed": {
      play: "playAds"
      stop: "reset"
    }
    "adsCompleted": {
      '
      play: "playAds"
      stop: "reset"
    }
  }

  functionName = stateMachine[state][control]
  tubiLog("TubiSGPreloadedAdShim: state=" + state + " control=" + control + " function=" + functionName)
  if functionName <> "" then
    m[functionName](content)
  end if
End Function


''''''''''''''''''''
' playAds
'@content: roAssociativeArray, content details
Function tubiSGPreloadedAdShim_playAds(content)
  m.ads.getAdsListViaTubi(content)

  if m.ads.hasAds(m.ads.allAdUnitsList) = true
    m.adPlayerNode.adState = "adsPlaying"
    adContainer = m.adPlayerNode.findNode("RAFAdContainer")
    status = m.ads.showCommercialBreakViaRoku(adContainer, m.adPlayerNode)
    if status = m.constants_.player.playerResults.closed
      m.adPlayerNode.adState = "adsClosed"
    else if status = m.constants_.player.playerResults.completed
      m.adPlayerNode.adState = "adsCompleted"
    else
      m.adPlayerNode.adState = "noAds"
    end if
  else
    m.adPlayerNode.adState = "noAds"
  end if

End Function


''''''''''''''''''
' reset
'@content: roAssociativeArray, content details
Function tubiSGPreloadedAdShim_reset(content)
  m.ads.reset()
  m.adPlayerNode.adState = "init"
End Function
