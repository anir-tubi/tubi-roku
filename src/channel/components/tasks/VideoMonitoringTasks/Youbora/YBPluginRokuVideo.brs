' ********** Copyright 2023 Nice People At Work.  All Rights Reserved. **********

Library "Roku_Ads.brs"

sub init()
    YouboraLog("YBPluginRokuVideo.brs - init")
end sub

sub startMonitoring()

    m.pluginName = "RokuVideo"
    m.pluginVersion = "6.5.31-" + m.pluginName

    ' Let's cache the segment used on the bitrate to access less to it
    m.bitrateSegment = invalid
    ' Cache the streamInfo too, to use with throughtput and resource
    m.streamInfo = invalid
    ' Summ of all downloaded chunks
    m.totalBytes = 0
    ' Last chunk's position, mainly to avoid adding a repeated chunk
    m.lastChunkSeqNum = -1
    if m.top.videoplayer <> invalid
        m.top.videoplayer.observeFieldScoped("state", m.port)
        m.top.videoplayer.observeFieldScoped("bufferingStatus", m.port)
        m.top.videoplayer.observeFieldScoped("downloadedSegment", m.port)
    else
        m.top.observeFieldScoped("videoplayer", m.port)
    end if

    m.top.observeFieldScoped("taskState", m.port)
    'm.top.ObserveField("taskState", "_taskListener")

    ' Notify monitoring startup
    m.top.monitoring = true
    m.needsPlayer = true
end sub

function getParamsVideoError()
  params = { "msg": m.top.videoplayer.errorMsg, "errorCode": m.top.videoplayer.errorCode.ToStr() }
  if m.top.videoplayer.errorStr <> invalid
  	errormd = m.top.videoplayer.errorStr
    if m.top.videoplayer.errorinfo <> invalid
    	if m.top.videoplayer.errorInfo.clipid <> invalid then errormd += ",clip_id:" + m.top.videoplayer.errorInfo.clipid.ToStr()
        if m.top.videoplayer.errorInfo.ignored <> invalid then errormd += ",ignored:" + m.top.videoplayer.errorInfo.ignored.ToStr()
        if m.top.videoplayer.errorInfo.source <> invalid then errormd += ",source:" + m.top.videoplayer.errorInfo.source
        if m.top.videoplayer.errorInfo.category <> invalid then errormd += ",category:" + m.top.videoplayer.errorInfo.category
    end if
    params["metadata"] = errormd
  end if
  return params
end function

'This method can be overwritten to control retry scenarios, to keep them in one view
'so its important to keep it unmodified calling only 'error' to avoid side effects
sub onVideoError()
  print "ERROR: "; m.top.videoplayer.error.code.toStr() + ": " + m.top.videoplayer.error.message
  eventHandler("error", getParamsVideoError())
end sub

'This method can be overwritten to control retry scenarios, to keep them in one view
'so its important to keep it unmodified calling only 'stop' to avoid side effects
sub onStopVideo()
  eventHandler("stop")
end sub

function onBufferingStatusChanged(bufferStatus) as void

    if bufferStatus <> invalid
        isBuffer = bufferStatus["isUnderrun"]
        if isBuffer = true
            if m.viewManager.isSeeking = true

                YouboraLog("Converting seek to buffer...")

                m.viewManager.isSeeking = false
                m.viewManager.isBuffering = true

                m.viewManager.chronoBuffer.startTime = m.viewManager.chronoSeek.startTime
                m.viewManager.chronoBuffer.stopTime = invalid

                m.viewManager.chronoSeek.stop()

            else
                eventHandler("resume")
                eventHandler("buffering")
            end if
        end if
    end if

end function

sub processPlayerState(newState as string)

    YouboraLog("Player state: " + newState)

    if newState = "buffering"
        if m.viewManager.isStartSent = false
            eventHandler("play")
        else
            if m.viewManager.isPaused = true
                eventHandler("resume")
                eventHandler("seeking")
            else
                eventHandler("buffering")
            end if
        end if
    else if newState = "playing"
        'if m.viewManager.isStartSent = true
        if m.viewManager.isJoinSent = false
            eventHandler("join")
        else if m.viewManager.isPaused = true
            eventHandler("resume")
        end if

        if m.viewManager.isBuffering = true
            eventHandler("buffered")
        else if m.viewManager.isSeeking = true
            eventHandler("seeked")
        end if
        'endif
    else if newState = "stopped"
        'Sometimes when playing an HLS Live stream, the Video player
        'enters the "stopped" state while buffering.
        '
        'Here we check for the control property of the video player
        'and close the view only if it is stop. This avoids sending
        'false stop events.
        ' if m.top.videoplayer.control = "stop" AND m.viewManager.isShowingAds = false
        '     'eventHandler("stop")
        ' else
        '     YouboraLog("Ignoring 'stopped' state; Video.control is not 'stop'")
        ' endif
    else if newState = "error"
        onVideoError()
    else if newState = "paused"
        eventHandler("pause")
    else if newState = "finished"
        m.viewManager.isFinished = true
        if m.top.videoplayer.control = "stop"
            onStopVideo()
        else
            YouboraLog("Ignoring 'stopped' state; Video.control is not 'stop'")
        end if
    end if
end sub

'Overriden parent method
sub processMessage(msg, port)

    mt = type(msg)
    if mt = "roSGNodeEvent"
        if msg.getField() = "state" 'Player state
            state = msg.getData()
            processPlayerState(state)
        else if msg.getField() = "bufferingStatus"
            bufferStatus = msg.getData()
            onBufferingStatusChanged(bufferStatus)
        else if msg.getField() = "videoplayer" AND m.needsPlayer = true
            m.needsPlayer = false
            m.top.unobserveFieldScoped("videoplayer")
            setNewPlayer(["state", "bufferingStatus"])
        else if msg.getField() = "downloadedSegment"
            if m.viewManager.isJoinSent = false and m.viewManager.isshowingads = false and m.top.videoplayer.state = "playing"
                eventHandler("join")
            end if
            downloadedSegment = msg.getData()
            if downloadedSegment <> invalid
                if downloadedSegment.Status = 0 AND (downloadedSegment.SegType = 0 OR downloadedSegment.SegType = 1 OR downloadedSegment.SegType = 2) AND m.lastChunkSeqNum <> downloadedSegment.Sequence
                    m.totalBytes =  m.totalBytes + downloadedSegment.SegSize
                endif
            endif
        else if msg.getField() = "taskState"
            _taskListener(msg.getData())
        end if
    end if

end sub

sub setNewPlayer(taskFields)
    m.top.videoplayer.observeFieldScoped("state", m.port)
    m.top.videoplayer.observeFieldScoped("bufferingStatus", m.port)
    m.top.videoplayer.observeFieldScoped("downloadedSegment", m.port)
    ' for each field in taskFields
    '     m.top.videoplayer.observeFieldScoped(field, m.port)
    ' end for
end sub

'Info methods
function getResource()

    resource = "unknown"

    if m.contentUrl = invalid
        'Get it from the informed url by the client
        content = m.top.videoplayer.content
        if content <> invalid
            resource = content.URL
            m.contentUrl = resource
        end if
    else
        resource = m.contentUrl
    end if

    return resource

end function

function getParsedResource()

    resource = invalid

    'This is only for segmented video transports (dash, hls)
    ssegment = m.top.videoplayer.streamingSegment
    if ssegment <> invalid
        resource = ssegment.segUrl
    endif

    return resource

end function

function getMediaDuration()
    duration = m.top.videoplayer.duration

    if duration = invalid
        duration = 0
    end if

    return duration
end function

function getPlayhead()
    if m.viewManager.isJoinSent = true
        return m.top.videoplayer.position
    else
        return 0
    end if
end function

function getTitle()
    content = m.top.videoplayer.content

    if content <> invalid
        title = content.TITLE
    else
        title = invalid
    end if

    return title

end function

function getIsLive()
    'This always returns false, so get rid of one call to a node
    return false
    ' content = m.top.videoplayer.content

    ' if content <> invalid
    '     live = content.Live
    ' else
    '     live = false
    ' endif

    ' return live
end function

function getThroughput()
    'This is only for roku >= 7.2
    m.streamInfo = m.top.videoplayer.streamInfo
    if m.streamInfo <> invalid
        throughput = m.streamInfo.measuredBitrate
    else
        throughput = invalid
    end if
    return throughput
end function

function getBitrate()
    'This is only for HLS and DASH
    m.bitrateSegment = m.top.videoplayer.streamingSegment
    if m.bitrateSegment <> invalid and m.bitrateSegment.segType <> 1 and m.bitrateSegment.segType <> 3 'not audio or captions
        br = m.bitrateSegment.segBitrateBps
    else
        br = -1
    end if
    return br
end function

function getRendition()
    'This is only for HLS and DASH
    m.bitrateSegment = m.top.videoplayer.streamingSegment
    if m.bitrateSegment <> invalid AND m.bitrateSegment.segType <> 1 'not audio
        rendition = m.bitrateSegment.segBitrateBps
        if rendition < 1000
            rendition = rendition.ToStr() + "bps"
        else if rendition < 1000000
            rendition = (rendition / 1000).ToStr() + "Kbps"
        else
            rendAux = rendition / 1000000.0 'Divide by mega
            rendAux = Cint(rendAux * 100) / 100.0
            rendition = rendAux.ToStr() + "Mbps"
        end if
        width = m.bitrateSegment.width
        height = m.bitrateSegment.height
        if width <> invalid AND height <> invalid AND width <> 0 AND height <> 0
            rendition = width.ToStr() + "x" + height.ToStr() + "@" + rendition
        endif
    else
        rendition = invalid
    end if
    return rendition
end function

function getTotalBytes()
    ' downloadedSegment = m.top.videoplayer.downloadedSegment
    ' if downloadedSegment <> invalid
    '     ?"download segment";downloadedSegment
    '     if downloadedSegment.Status = 0 AND (downloadedSegment.SegType = 1 OR downloadedSegment.SegType = 2) AND lastChunkSeqNum <> downloadedSegment.Sequence
    '         totalBytes = totalBytes + downloadedSegment.SegSize
    '     endif
    ' endif
    return m.totalBytes
end function

function getPlayrate()
    ret = m.top.videoplayer.playbackSpeed
    if m.viewManager.isPaused
        ret = 0
    end if
    return ret
end function

function getPlayerVersion()
    return "Roku-Video"
end function

sub _taskListener(taskState)
    if taskState = "stop"
        m.top.videoplayer.unobserveFieldScoped("state")
        m.top.videoplayer.unobserveFieldScoped("bufferingStatus")
        m.top.videoplayer.unobserveFieldScoped("downloadedSegment")
        'm.top.videoplayer = invalid
        m.needsPlayer = true
        m.top.observeFieldScoped("videoplayer", m.port)
        m.contentUrl = invalid
        m.top.monitoring = false
        m.viewManager.isFinished = false
        m.top.taskState = "" 'This is necessary since if the last reported state has been stop and is reported again it won't get notified, since the value hasn't changed
    end if
end sub
