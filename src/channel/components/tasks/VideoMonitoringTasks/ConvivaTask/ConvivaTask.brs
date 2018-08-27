Function init()
  m.top.functionName = "execConvivaTask"
End Function

Function execConvivaTask()
  ' convivaIsLive is set to invalid for no events set (turned off), true for production, and false for testing
  convivaIsLive = m.global.constants.thirdParty.convivaIsLive
  deviceId = m.global.constants.deviceInfo.deviceId
  convivaSettings = invalid
  convivaLivePass = invalid

  if convivaIsLive = true
    convivaKey = "c35bb3e799927302a29d409cfb800607ecb2b0a4" 'production key
    convivaSettings = {
      gatewayUrl: "https://c35bb3e799927302a29d409cfb800607ecb2b0a4.cws.conviva.com"
    }
    convivaLivePass = ConvivaLivePassInitWithSettings(convivaKey, convivaSettings)
  else if convivaIsLive = false
    convivaKey = "1779288e2fe6824949fb15a315d461b583487a12" 'test key'
    convivaSettings = {
      gatewayUrl: "https://tubitv-test.testonly.conviva.com"
    }
    convivaLivePass = ConvivaLivePassInitWithSettings(convivaKey, convivaSettings)
  end if
  

  if convivaLivePass <> invalid
    convivaLivePass.toggleTraces(true)   'set debugging output
    
    m.Video = m.top.videoNode   'm.top.VideoNode must be set prior to calling "RUN" on the task
    convivaPort = createObject("roMessagePort")

    ' set observers needed to communicate from the video player to conviva
    m.top.observeField("beginPlayback", convivaPort)
    m.top.observeField("endPlayback", convivaPort)
    m.top.observeField("beginSeek", convivaPort)
    m.top.observeField("endSeek", convivaPort)
    m.top.observeField("beginAds", convivaPort)
    m.top.observeField("endAds", convivaPort)

    ' set observers needed to build conviva content
    m.Video.observeField("content", convivaPort)

    ' set observers needed by convivaWatch
    m.Video.observeField("streamInfo", convivaPort)
    m.Video.observeField("position", convivaPort)
    m.Video.observeField("state", convivaPort)
    m.Video.observeField("duration", convivaPort)
    m.Video.observeField("streamingSegment", convivaPort)
    m.Video.observeField("errorCode", convivaPort)
    m.Video.observeField("errorMsg", convivaPort)
    m.Video.observeField("downloadedSegment", convivaPort)

    m.activePreroll = false
    m.lastErrorMsg = ""

    while(true)
      msg = ConvivaWait(0, convivaPort, invalid)
      if type(msg) = "roSGNodeEvent"
        if msg.getNode() = "VideoNode"  'update convivaContent based on update to video content
          if msg.getField() = "content"
            content = msg.getData()
            if content <> invalid and content.id <> invalid
              contentIdentifier = content.id
              if content.title <> invalid
                 contentIdentifier += " - " + content.title
              end if
              convivaContent = ConvivaContentInfo(contentIdentifier)
              convivaContent.isLive = false
              convivaContent.playerName = "Tubi Roku"
              if content.url <> invalid then convivaContent.streamUrl = content.url
              if content.length <> invalid then convivaContent.contentLength = Int(content.length)
              if content.streamformat <> invalid then convivaContent.streamFormat = content.streamformat
              if deviceId <> invalid then convivaContent.viewerId = deviceid
            else
              convivaContent = invalid
            end if
          end if
        else if msg.getField() = "beginPlayback"
          if msg.getData() = "withAds"
            startWithMonitoring = false
          else
            startWithMonitoring = true
          end if
          convivaSession = convivaLivePass.createSession(startWithMonitoring, convivaContent, m.Video.notificationInterval, m.Video)
        else if msg.getField() = "endPlayback"
          ' Calling internal functions of the convivaLivePass is a HACK!!!
          ' However, Conviva internally listens for Video.errorMsg to identify errors. From experimentation, it seems that 
          ' the errorMsg field behaves like alwaysNotify = false. This means that if the same error happens multiple times in
          ' succession, only the first error is recorded. This hack uses the Video.state = error occurence to force Conviva
          ' to track all errors. The issue is, it records 2 errors the first time an error occurs, and then appropriately tracks
          ' a single error every subsequent occurrence.
          errorMsg = msg.getData()
          if errorMsg <> "noerror"
            if errorMsg = m.lastErrorMsg
              errData = {
                ft: true,
                err: errorMsg }
              convivaLivePass.session.cwsSessionOnError(errData)
            end if

            m.lastErrorMsg = errorMsg
          end if


          convivaLivePass.cleanupSession(convivaSession)
        else if msg.getField() = "beginSeek"
          seekTo = msg.getData() * 1000
          convivaLivePass.setPlayerSeekStart(convivaSession, seekTo)
        else if msg.getField() = "beginAds"   'we do not notify in the case of pre rolls
          if msg.getData() = "preroll"
            convivaLivePass.adStart()
            m.activePreroll = true
          else if msg.getData() = "midroll"
            convivaLivePass.detachStreamer()
          end if
        else if msg.getField() = "endAds"
          if m.activePreroll = true
            convivaLivePass.adEnd()
            m.activePreroll = false
          end if
          convivaLivePass.attachStreamer()
        end if
      end if
    end while
  end if
End Function