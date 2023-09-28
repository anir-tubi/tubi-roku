' ********** Copyright 2023 Nice People At Work.  All Rights Reserved. **********

sub init()

    YouboraLog("YBPluginGeneric.brs - init", "YBPluginGeneric")
    m.top.functionName = "_run"

    m.port = createObject("roMessagePort")
    m.top.observeField("event", m.port)
    m.top.ObserveField("adevent", m.port)
    m.top.ObserveField("imaadevent", m.port)
    m.top.observeField("options", m.port)
    m.top.observeField("session", m.port)
    m.top.observeField("updateplayer", m.port)

    'Public methods
    m._requestData = requestData
    m._startPingTimer = startPingTimer
    m._stopPingTimer = stopPingTimer
    m._startBeatTimer = startBeatTimer
    m._stopBeatTimer = stopBeatTimer

    m.getResource = getResource
    m.getParsedResource = getParsedResource
    m.getPlayhead = getPlayhead
    m.updateLastPlayhead = updateLastPlayhead
    m.getMediaDuration = getMediaDuration
    m.getTitle = getTitle
    m.getIsLive = getIsLive
    m.getPlayrate = getPlayrate
    m.getRendition = getRendition
    m.getThroughput = getThroughput
    m.getTotalBytes = getTotalBytes
    m.getBitrate = getBitrate
    m.getPluginName = getPluginName
    m.getPluginVersion = getPluginVersion
    m.getPlayerVersion = getPlayerVersion
    m.getIsStarted = getIsStarted
    m.isExtraMetadataReady = isExtraMetadataReady

    'Ads
    m.getAdPosition = getAdPosition
    m.getAdNumber = getAdNumber
    m.getAdNumberInBreak = getAdNumberInBreak
    m.getAdPlayhead = getAdPlayhead
    m.getAdDuration = getAdDuration

    'Sessions
    m.sessionStarted = false

    m.lastAdPlayhead = 0

    m.isStarted = false
    m.isAdStarted = false
    m.isAdBreakStarted = false

    m.adNumber = 0
    m.adLastPosition = invalid
    m.adNumberInBreak = 0
    m.adPosition = "unknown"
    m.adTitle = invalid
    m.adBreakNumber = 0
    m.adBreakLastPosition = invalid

    m.eventHandler = eventHandler

    'Extra to trick beat timer with ping timer
    m.totalPingTimer = 0

end sub

sub _run()

    YouboraLog("YBPluginGeneric.brs - run", "YBPluginGeneric")

    m.pluginName = "Generic"
    m.pluginVersion = "6.6.10-" + m.pluginName

    m.infoManager = InfoManager(m)
    setOptions(m.top.options)

    'The ViewManager sends the /data call through the _requestData() method
    m.viewManager = ViewManager(m.infoManager, m)
    startMonitoring()

    'Create timer for pings
    m.pingTimer = CreateObject("roSGNode", "Timer")
    pingTimerFields = {}
    pingTimerFields["duration"] = 5
    pingTimerFields["repeat"] = true
    m.pingTimer.setFields(pingTimerFields)
    m.pingTimer.ObserveField("fire", m.port)

    m.beatTimer = CreateObject("roSGNode", "Timer")
    beatTimerFields = { "duration" : 30, "repeat" : true }
    m.beatTimer.setFields(beatTimerFields)
    m.beatTimer.ObserveField("fire", m.port)

    m.isStarted = false
    m.isAdStarted = false

    'Endless loop to listen for events
    while true

        try
            msg = wait(0, m.port)

            'Delegate call to the specific plugin.
            'The plugin will have to override this method in order
            'to get the events from the player.
            processMessage(msg, m.port)

            mt = type(msg)

            if mt = "roSGNodeEvent"
                if msg.getField() = "event" 'Process event from outside
                    data = msg.getData()
                    if data.handler = "close"
                        m.viewManager.com.close = true
                        exit while
                    else
                        invokeHandler(msg.getData())
                    end if
                else if msg.getField() = "fire" 'Timer callback
                    'm.viewManager.pingCallback()
                    if m.pingTimer.control = "stop" or m.pingTimer.control = "none"
                        m.viewManager.beatCallback()
                    else
                        m.viewManager.pingCallback()
                        if (m.totalPingTimer = 30 or m.totalPingTimer > 25)
                            m.viewManager.beatCallback()
                            m.totalPingTimer = 0
                        else
                            m.totalPingTimer = m.totalPingTimer + 5
                        end if
                    end if
                else if msg.getField() = "options"
                    opt = msg.getData()
                    setOptions(opt)
                else if msg.getField() = "logging"
                    logEnabled = msg.getData()
                    GetGlobalAA().YouboraLogActive = logEnabled
                else if msg.getField() = "adevent"
                    invokeAdHandler(msg.getData())
                else if msg.getField() = "imaadevent"
                    invokeImaAdHandler(msg.getData())
                else if msg.getField() = "session"
                    onSessionEvent(msg.getData())
                end if
            else if (mt = "roUrlEvent") '/data response
                code = msg.GetResponseCode()
                if (code = 200)
                    response = msg.GetString()
                    receiveData(response)
                    m.dataRequest = invalid
                else
                    YouboraLog("Invalid data response, code: " + code.ToStr() + ", reason: " + msg.GetFailureReason(), "YBPluginGeneric")
                    'Communicate to Communication an invalid FastData response
                    m.viewManager.com.invalidFastDataResponse = true
                end if
            end if
        catch e
            YouboraLog("Exception listening event: " + e.message, "YBPluginGeneric")
        end try

    end while

end sub

sub _stop()

    'stopMonitoring()

end sub

sub setNewPlayer()

end sub

sub _taskListener(state)

end sub

'This method should be overriden in the specific plugin in order to process
'the player events
sub processMessage(msg, port)
    YouboraLog("Youbora.brs -  processMessage", "YBPluginGeneric")
end sub

'Info methods
function getResource()
    return "unknown"
end function

function getParsedResource()
    return invalid
end function

function getMediaDuration()
    return 0
end function

function getPlayhead()
    return 0
end function

sub updateLastPlayhead()
end sub

function getTitle()
    return invalid
end function

function getIsLive()
    return false
end function

function getRendition()
    return invalid
end function

function getThroughput()
    return invalid
end function

function getBitrate()
    return -1
end function

function getPlayrate()
    return invalid
end function

function getTotalBytes()
    return 0
end function

function getAdPosition()
    return invalid
end function

function getAdPlayhead()
    return m.lastAdPlayhead
end function

function getAdNumber()
    return invalid
end function

function getAdNumberInBreak()
    return m.adNumberInBreak
end function

function getAdDuration()
    return invalid
end function

function getPluginVersion()
    return m.pluginVersion
end function

function getPluginName()
    return m.pluginName
end function

function getPlayerVersion()
    return "GENERIC"
end function

sub startPingTimer()
    'm.beatTimer.control = "stop"
    m.pingTimer.control = "start"
end sub

sub stopPingTimer()
    m.pingTimer.control = "stop"
end sub

sub startBeatTimer()
    m.beatTimer.control = "start"
end sub

sub stopBeatTimer()
    m.beatTimer.control = "stop"
end sub

sub startMonitoring()

end sub

sub stoptMonitoring()
    eventHandler("stop")
end sub

function getIsStarted()
    return m.isStarted
end function

sub eventHandler(event as string, params = invalid)
    if event = "init"
        m.viewManager.sendRequest("init", params)
    else if event = "play"
        if (m.infoManager.getTitle() <> invalid and m.infoManager.getTitle() <> "") and (m.infoManager.getResource() <> invalid and m.infoManager.getResource() <> "Unknown") and (m.infoManager.getIsLive() = true or m.infoManager.getMediaDuration() <> 0) and m.isStarted = false and m.isExtraMetadataReady() = true or (m.isExtraMetadataReady() = true and m.viewManager.isJoinSent = true)
            m.viewManager.sendRequest("start", params)
            m.isStarted = true
        else if m.viewManager.isInitiated = false and m.isStarted = false
            m.viewManager.sendRequest("init", params)
            m.viewManager.isInitiated = true
        end if
    else if event = "join"
        if m.viewManager.isInitiated = true and m.isStarted = false and m.isExtraMetadataReady()
            m.viewManager.sendRequest("start", params) ' No need to check if it has been sent or not, ViewManager will take care of that
            m.isStarted = true
        end if
        m.viewManager.sendRequest("join", params)
    else if event = "pause"
        m.viewManager.sendRequest("pause", params)
    else if event = "resume"
        m.viewManager.sendRequest("resume", params)
    else if event = "stop"
        m.isStarted = false
        m.isAdStarted = false
        m.adBreakNumber = 0
        m.viewManager.sendRequest("stop", params)
    else if event = "error"
        'Brightscript transforms the keys of params to lowercase
        'This is bad for the error, as the code should be sent as errorCode
        if params = invalid or type(params) <> "roAssociativeArray"
            params = {}
        end if

        params2 = {}
        if params.DoesExist("msg")
            params2["msg"] = params["msg"]
        end if

        if params.DoesExist("errorCode")
            params2["errorCode"] = params["errorCode"]
        end if

        if params.DoesExist("metadata")
            params2["errorMetadata"] = params["metadata"]
        end if

        m.viewManager.sendRequest("error", params2)
    else if event = "buffering"
        m.viewManager.sendRequest("bufferStart", params)
    else if event = "buffered"
        m.viewManager.sendRequest("bufferEnd", params)
    else if event = "seeking"
        m.viewManager.sendRequest("seekStart", params)
    else if event = "seeked"
        m.viewManager.sendRequest("seekEnd", params)
    else if event = "event"
        if m.viewManager.isStartSent = true
            m.viewManager.sendRequest("videoEvent", params)
        end if
    else if event = "adPlay"
        if m.viewManager.isInitiated = false and m.isStarted = false
            m.viewManager.sendRequest("init", params)
        end if

        if (m.infoManager.getAdDuration() <> 0 or params["adDuration"] <> 0) and (m.infoManager.getAdTitle() <> invalid or params["adTitle"] <> invalid) and (m.infoManager.getAdResource() <> invalid or params["adResource"] <> invalid) and m.viewManager.isAdInitiated = false
            m.viewManager.sendRequest("adStart", params)
            m.isAdStarted = true
        else if m.viewManager.isAdInitiated = false
            m.viewManager.sendRequest("adInit", params)
            m.viewManager.isAdInitiated = true
        end if
    else if event = "adJoin"
        if m.viewManager.isAdInitiated = true or m.isAdStarted = true
            if m.isAdStarted = false
                m.viewManager.sendRequest("adStart", params)
            end if
            m.viewManager.sendRequest("adJoin", params)
        end if
    else if event = "adPlayJoin"
        if m.viewManager.isInitiated = false and m.isStarted = false
            m.viewManager.sendRequest("init", params)
        end if

        if m.infoManager.getAdDuration() <> 0 and m.viewManager.isAdInitiated = false
            m.viewManager.sendRequest("adStart", params)
            m.isAdStarted = true
            m.viewManager.sendRequest("adJoin", params)
        else if m.viewManager.isAdInitiated = false
            m.viewManager.sendRequest("adInit", params)
            m.viewManager.isAdInitiated = true
        end if
    else if event = "adQuartile"
        if m.viewManager.isAdJoinSent = true
            m.viewManager.sendRequest("adQuartile", params)
        end if
    else if event = "adStop"
        m.viewManager.sendRequest("adStop", params)
        m.isAdStarted = false
        m.isAdInitiated = false
    else if event = "adError"
        m.viewManager.sendRequest("adError", params)
        if m.viewManager.isShowingAds = true
            m.viewManager.sendRequest("adStop", params)
        end if
    else if event = "adPause"
        m.viewManager.sendRequest("adPause", params)
    else if event = "adResume"
        m.viewManager.sendRequest("adResume", params)
    else if event = "adBreakStart"
        m.viewManager.sendRequest("adBreakStart", params)
    else if event = "adBreakStop"
        m.viewManager.sendRequest("adBreakStop", params)
    else if event = "adManifest"
        m.viewManager.sendRequest("adManifest", params)
    else if event = "sessionStart"
        if m.sessionStarted = true
            m.viewManager.sendRequest("sessionNav", params)
        else
            m.viewManager.sendRequest("sessionStart", params)
            m.sessionStarted = true
        end if
    else if event = "sessionStop" and m.sessionStarted = true
        m.viewManager.sendRequest("sessionStop", params)
        m.sessionStarted = false
    else if event = "sessionEvent" and m.sessionStarted = true
        m.viewManager.sendRequest("sessionEvent", params)
    else if event = "sessionError" and m.sessionStarted = true
        m.viewManager.sendRequest("sessionError", params)
    else if event = "videoEvent"
        m.viewManager.sendRequest("videoEvent", params)
    end if

end sub

sub invokeHandler(data as object)
    try
        if type(data) = "roAssociativeArray"
            handler = data.handler
            params = data.params
            if type(handler) = "roString"
                m.eventHandler(handler, params)
            end if
        end if
    catch e
        YouboraLog("Exception on invokeHandler: " + e.message, "YBPluginGeneric")
    end try
end sub

sub invokeImaAdHandler(data as object)
    if type(data) = "roAssociativeArray"
        invokeAdHandler(convertToRokuAdsEvent(data))
    end if
end sub

function convertToRokuAdsEvent(adInfo as object) as object
    rokuAd = {}
    ad = adInfo.ad

    if (adInfo.event = "PodStart" or adInfo.event = "PodComplete")
        m.adNumberInBreak = 0
        rokuAd.type = adInfo.event
        rokuAd.rendersequence = "midroll"
        if ad.timeoffset = 0 then rokuAd.rendersequence = "preroll"
        if ad.timeoffset >= (m.infoManager.getMediaDuration() - ad.duration - 1) then rokuAd.rendersequence = "postroll"
        rokuAd.adcount = ad.totalads
    else
        rokuAd.index = ad.adbreakinfo.adposition
        rokuAd.time = ad.currenttime
        rokuAd.rendersequence = "midroll"
        if ad.adbreakinfo.timeoffset = 0 then rokuAd.rendersequence = "preroll"
        if ad.adbreakinfo.timeoffset >= (m.infoManager.getMediaDuration() - ad.duration - 1) then rokuAd.rendersequence = "postroll"
    end if

    if (adInfo.event = "start")
        m.adNumber = m.adNumber + 1
        m.adNumberInBreak = m.adNumberInBreak + 1
        rokuAd.type = "Impression"
        rokuAd.duration = ad.duration
        rokuAd.adtitle = ad.adtitle
        rokuAd.adindex = m.adNumber
        m.top.imaadevent = { "event": "loaded", "ad": ad } 'completly dummy event that we trigger since there is none
    else if (adInfo.event = "loaded")
        rokuAd.type = "Start"
        rokuAd.duration = ad.duration
        rokuAd.adtitle = ad.adtitle
        rokuAd.adindex = m.adNumber
    else if (adInfo.event = "firstQuartile")
        rokuAd.type = "FirstQuartile"
    else if (adInfo.event = "midpoint")
        rokuAd.type = "Midpoint"
    else if (adInfo.event = "thirdQuartile")
        rokuAd.type = "ThirdQuartile"
    else if (adInfo.event = "complete")
        rokuAd.type = "Complete"
    end if
    return rokuAd
end function

sub invokeAdHandler(data as object)

    adParams = { "breakNumber": m.adBreakNumber }
    adBreakParams = {}
    adPositions = { "preroll": "pre", "midroll": "mid", "postroll": "post" }

    if data.type = "PodStart" or data.type = "PodComplete"
        if data.rendersequence <> invalid then adBreakParams["position"] = adPositions[data.rendersequence]
        if data.adcount <> invalid then adBreakParams["givenAds"] = data.adcount
        try
            if data.type = "PodStart" and adBreakParams["position"] <> invalid and adBreakParams["position"] <> "" and adBreakParams["position"] <> "unknown"
                m.adPosition = adBreakParams["position"]
            else if data.type = "PodComplete"
                m.adPosition = "unknown"
            end if
        catch e
            YouboraLog("Exception storing PodStart position: " + e.message, "YBPluginGeneric")
        end try
    else
        adParams["adNumber"] = m.adNumber
        if data.ad <> invalid = true and data.ad.adtitle <> invalid = true
            adParams["adTitle"] = data.ad.adtitle
        end if

        if data.ad <> invalid = true and data.ad.creativeid <> invalid = true
            adParams["adCreativeId"] = data.ad.creativeid
        end if

        if data.time <> invalid
            m.lastAdPlayhead = data.time
        end if

        if data.duration <> invalid
            adParams["adDuration"] = data.duration
        end if

        if data.rendersequence = invalid
            try
                if m.adPosition <> invalid and m.adPosition <> "unknown" and m.adPosition <> ""
                    adParams["position"] = m.adPosition
                else
                    if (m.viewManager.isStartSent = true or m.viewManager.isInitiated = true) and m.viewManager.isJoinSent = false
                        adParams["position"] = "pre"
                    else if m.viewManager.isJoinSent = true
                        if m.viewManager.isFinished = true
                            adParams["position"] = "post"
                        else
                            adParams["position"] = "mid"
                        end if
                    end if
                end if
            catch e
                YouboraLog("Exception getting adPosition: " + e.message, "YBPluginGeneric")
            end try
        else
            adParams["position"] = adPositions[data.rendersequence]
        end if
    end if

    if data.type = "Close"
        if data.rendersequence <> invalid then adBreakParams["position"] = adPositions[data.rendersequence]
        if data.adcount <> invalid then adBreakParams["givenAds"] = data.adcount
    end if

    if type(data) = "roAssociativeArray"
        if data.type = "PodStart"
            m.adNumberInBreak = 0
            try
                if m.adBreakLastPosition = invalid or m.adBreakLastPosition <> adBreakParams["position"]
                    m.adBreakLastPosition = adBreakParams["position"]
                    m.adBreakNumber = 0
                end if
            catch e
                YouboraLog("Exception checking adBreakNumber: " + e.message, "YBPluginGeneric")
            end try
            m.adBreakNumber = m.adBreakNumber + 1
            adBreakParams["breakNumber"] = m.adBreakNumber
            if m.viewManager.isStartSent = false
                invokeHandler({ handler: "play" })
            end if
            if m.viewManager.isAdManifestSent = false
                invokeHandler({handler: "adManifest"})
            end if
            invokeHandler({ handler: "adBreakStart", params: adBreakParams })
        else if data.type = "PodComplete"
            adBreakParams["breakNumber"] = m.adBreakNumber
            invokeHandler({ handler: "adBreakStop", params: adBreakParams })
            if m.viewManager.isFinished = true or adBreakParams["position"] = "post"
                invokeHandler({ handler: "stop" })
            end if
        else if data.type = "Impression"
            m.lastAdPlayhead = 0
            m.adNumberInBreak = m.adNumberInBreak + 1
            try
                if m.adLastPosition = invalid or m.adLastPosition <> adParams["position"]
                    m.adLastPosition = adParams["position"]
                    m.adNumber = 0
                end if
            catch e
                YouboraLog("Exception checking adNumber: " + e.message, "YBPluginGeneric")
            end try
            'Increment adNumber and override the adParams
            m.adNumber = m.adNumber + 1
            adParams["adNumber"] = m.adNumber
            eventHandler("seeked")
            eventHandler("buffered")
            invokeHandler({ handler: "adPlay", params: adParams })
        else if data.type = "Start"
            invokeHandler({ handler: "adJoin", params: adParams })
        else if data.type = "FirstQuartile"
            adParams["quartile"] = "1"
            invokeHandler({ handler: "adQuartile", params: adParams })
        else if data.type = "Midpoint"
            adParams["quartile"] = "2"
            invokeHandler({ handler: "adQuartile", params: adParams })
        else if data.type = "ThirdQuartile"
            adParams["quartile"] = "3"
            invokeHandler({ handler: "adQuartile", params: adParams })
        else if data.type = "Complete"
            invokeHandler({ handler: "adStop", params: adParams })
            m.lastAdPlayhead = 0
        else if data.type = "Skip"
            adParams.skipped = "true"
            m.lastAdPlayhead = 0
            invokeHandler({ handler: "adStop", params: adParams })
        else if data.type = "Error" and data.errMsg <> invalid
            if data.errMsg <> invalid
                adParams.msg = data.errMsg
            end if
            if data.errcode <> invalid
                adParams["errorCode"] = data.errcode
            end if
            invokeHandler({ handler: "adError", params: adParams })
        else if data.type = "Pause"
            invokeHandler({ handler: "adPause", params: adParams })
        else if data.type = "Resume"
            invokeHandler({ handler: "adResume", params: adParams })
        else if data.type = "Close"
            invokeHandler({ handler: "adStop", params: adParams })
            adBreakParams["breakNumber"] = m.adBreakNumber
            invokeHandler({ handler: "adBreakStop", params: adBreakParams })
        end if
    end if

end sub

sub pingTimerTick()
    m.viewManager.pingCallback()
end sub

sub requestData(args = invalid)

    if args = invalid
        args = {}
    end if

    args.Delete("code")

    if args.DoesExist("outputformat") = false then args["outputformat"] = "jsonp"
    args["timemark"] = currentMillis().ToStr()

    m.dataRequest = Request(m.port)

    if m.infoManager.options["httpSecure"] = true
        protocol = "https://"
    else
        protocol = "http://"
    end if

    m.dataRequest.host = protocol + "a-fds.youborafds01.com"
    m.dataRequest.service = "/data"
    m.dataRequest.args = args

    m.dataRequest.send()
end sub

sub receiveData(response as string)
    if response = invalid or response = ""
        YouboraLog("FastData empty response", "YBPluginGeneric")
        return
    end if

    'Convert jsonp to json
    responseJson = mid(response, 8, Len(response) - 8)
    YouboraLog("responseJson: " + responseJson, "YBPluginGeneric")
    outerJson = ParseJSON(responseJson)

    if outerJson <> invalid
        if outerJson.q <> invalid
            innerJson = outerJson.q

            host = ""
            code = ""
            pt = ""
            yid = ""

            if innerJson.h <> invalid
                host = innerJson.h
            end if
            if innerJson.c <> invalid
                code = innerJson.c
            end if
            if innerJson.pt <> invalid
                pt = innerJson.pt
            end if
            if innerJson.f <> invalid
                yid = innerJson.f.yid
            end if


            if Len(host) > 0 and Len(code) > 0 and Len(pt) > 0
                firstCode = code
                pingTime = pt

                updateFields = {}
                updateFields["code"] = firstCode
                updateFields["requestHost"] = host
                updateFields["pingTime"] = pingTime
                updateFields["youboraId"] = yid

                m.viewManager.com.setFields(updateFields)
                'update ping time
                m.pingTimer.duration = pt
                'update the copy we have with the ping timer
                m.viewManager.pingTime = pt
                YouboraLog("FastData " + code + " is ready.", "YBPluginGeneric")

                m.viewManager.com.removePreloader = "FastData"
            end if

        end if

    end if

    m.dataRequest = invalid

end sub

sub setOptions(options = invalid)
    if options <> invalid
        m.infoManager.options = options
    end if
end sub

function isExtraMetadataReady()
    options = m.infoManager.options

    if options["pendingMetadata"] <> invalid and options["waitForMetadata"] = "true" then
        pendingParams = options["pendingMetadata"]
        for i = 0 to pendingParams.count() - 1
            if options[pendingParams[i]] = invalid then
                return false
            end if
        end for
    end if
    return true
end function

function isPlayheadJumpEnabled()
    try
        options = m.infoManager.options

        if options["playheadJumpEnabled"] <> invalid and type(options["playheadJumpEnabled"]) = "roString" then
            return LCase(options["playheadJumpEnabled"]) = true
        else if options["playheadJumpEnabled"] <> invalid
            return options["playheadJumpEnabled"]
        end if
    catch e
        YouboraLog("Exception on isPlayheadJumpEnabled function: " + e.message, "YBPluginGeneric")
    end try

    return true
end function

function isSeekEventEnabled()
    try
        options = m.infoManager.options

        if options["seekEventEnabled"] <> invalid and type(options["seekEventEnabled"]) = "roString" then
            return LCase(options["seekEventEnabled"]) = true
        else if options["seekEventEnabled"] <> invalid
            return options["seekEventEnabled"]
        end if
    catch e
        YouboraLog("Exception on isSeekEventEnabled function: " + e.message, "YBPluginGeneric")
    end try

    return true
end function

sub onSessionEvent(sessionEvent as object)
    try
        if type(sessionEvent) = "roAssociativeArray"
            event = sessionEvent.ev
            params = {}
            if type(event) = "roString"
                if event = "start"
                    event = "sessionStart"
                    params = { screeName: sessionEvent.sc, dimensions: sessionEvent.dim }
                else if event = "stop"
                    event = "sessionStop"
                else if event = "error"
                    event = "sessionError"
                    if sessionEvent.doesExist("code")
                        params["errorCode"] = sessionEvent.code
                    end if
                    if sessionEvent.doesExist("msg")
                        params["errorMsg"] = sessionEvent.msg
                    end if
                    if sessionEvent.doesExist("mt")
                        params["errorMetadata"] = sessionEvent.mt
                    end if
                    if sessionEvent.doesExist("typ")
                        params["errorType"] = sessionEvent.typ
                    end if
                    if sessionEvent.doesExist("cat")
                        params["errorCategory"] = sessionEvent.cat
                    end if
                else if event = "event"
                    event = "sessionEvent"
                    displayName = sessionEvent.displayName
                    if displayName = invalid then displayName = "event"
                    params = { dimensions: sessionEvent.dim, values: sessionEvent.vals, name: displayName }
                end if
                m.eventHandler(event, params)
            end if
        end if
    catch e
        YouboraLog("Exception on onSessionEvent: " + e.message, "YBPluginGeneric")
    end try
end sub
