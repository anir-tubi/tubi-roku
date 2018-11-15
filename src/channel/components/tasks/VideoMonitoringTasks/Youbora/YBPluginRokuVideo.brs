' ********** Copyright 2016 Nice People At Work.  All Rights Reserved. **********

Library "Roku_Ads.brs"

sub init()
    YouboraLog("YBPluginRokuVideo.brs - init")
end sub

sub startMonitoring()

    m.pluginName = "RokuVideo"
    m.pluginVersion = "6.0.4-" + m.pluginName

    m.top.videoplayer.ObserveField("state", m.port)
    m.top.videoplayer.ObserveField("bufferingStatus", m.port)
    m.top.ObserveField("taskState", "_taskListener")
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
                eventHandler("buffering")
            endif
        endif
    endif

end function

sub processPlayerState(newState as String)

    YouboraLog("Player state: " + newState)

    if newState = "buffering"
        if m.viewManager.isStartSent = false
            eventHandler("play")
        else
            eventHandler("seeking")
        endif
    else if newState = "playing"
        if m.viewManager.isStartSent = true
            if m.viewManager.isJoinSent = false
                eventHandler("join")
            else if m.viewManager.isPaused = true
                eventHandler("resume")
            endif

            if m.viewManager.isBuffering = true
                eventHandler("buffered")
            else if m.viewManager.isSeeking = true
                eventHandler("seeked")
            endif
        endif
    else if newState = "stopped"
        'Sometimes when playing an HLS Live stream, the Video player
        'enters the "stopped" state while buffering.
        '
        'Here we check for the control property of the video player
        'and close the view only if it is stop. This avoids sending
        'false stop events.
        if m.top.videoplayer.control = "stop" AND m.viewManager.isShowingAds = false
            'eventHandler("stop")
        else
            YouboraLog("Ignoring 'stopped' state; Video.control is not 'stop'")
        endif
    else if newState = "error"
        eventHandler("error", {"msg":m.top.videoplayer.errorMsg, "errorCode":m.top.videoplayer.errorCode.ToStr()})
    else if newState = "paused"
        eventHandler("pause")
    else if newState = "finished"
        m.viewManager.isFinished = true
        if m.top.videoplayer.control = "stop"
            eventHandler("stop")
        else
            YouboraLog("Ignoring 'stopped' state; Video.control is not 'stop'")
        endif
    endif
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
        endif
    endif

end sub

'Info methods
function getResource()

    'stop
    resource = "unknown"

    'This is only for segmented video transports (dash, hls)
    ssegment = m.top.videoplayer.streamingSegment
    if ssegment <> invalid
        resource = ssegment.segUrl
    else
        'This is only for roku >= 7.2
        info = m.top.videoplayer.streamInfo
        if info <> invalid
            resource = info.streamUrl
        else
            'Get it from the informed url by the client
            content = m.top.videoplayer.content
            if content <> invalid
                resource = content.URL
            endif
        endif
    endif

    return resource

end function

function getMediaDuration()
    duration = m.top.videoplayer.duration

    if duration = invalid
        duration = 0
    endif

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
    endif

    return title

end function

function getIsLive()
    'This always returns false
    content = m.top.videoplayer.content

    if content <> invalid
        live = content.Live
    else
        live = false
    endif

    return live
end function

function getThroughput()
    'This is only for roku >= 7.2
    info = m.top.videoplayer.streamInfo
    if info <> invalid
        throughput = info.measuredBitrate
    else
        throughput = invalid
    endif
    return throughput
end function

function getBitrate()
    'This is only for HLS and DASH
    ssegment = m.top.videoplayer.streamingSegment
    if ssegment <> invalid
        br = ssegment.segBitrateBps
    else
        br = -1
    endif
    return br
end function

function getRendition()
    'This is only for HLS and DASH
    ssegment = m.top.videoplayer.streamingSegment
    if ssegment <> invalid
        rendition = ssegment.segBitrateBps
        if rendition < 1000
            rendition = rendition.ToStr() + "bps"
        else if rendition < 1000000
            rendition = (rendition/1000).ToStr() + "Kbps"
        else
            rendAux = rendition / 1000000.0 'Divide by mega
            rendAux = Cint(rendAux * 100) / 100.0
            rendition = rendAux.ToStr() + "Mbps"
        endif
    else
        rendition = invalid
    endif
    return rendition
end function

function getPlayerVersion()
    return "Roku-Video"
end function

sub _taskListener()
    if m.top.taskState = "stop"
        m.top.videoplayer.unobserveFieldScoped("state")
        m.top.videoplayer.unobserveFieldScoped("bufferingStatus")
    end if
end sub
