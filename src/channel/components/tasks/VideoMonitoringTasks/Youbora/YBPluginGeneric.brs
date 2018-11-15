' ********** Copyright 2016 Nice People At Work.  All Rights Reserved. **********

sub init()

    m.global.addFields({YouboraLogActive: true})
    YouboraLog("YBPluginGeneric.brs - init")
    m.top.functionName = "_run"

    m.port = createObject("roMessagePort")
    m.top.observeField("event", m.port)
    m.top.ObserveField("adevent", m.port)
    m.top.observeField("options", m.port)

    'Public methods
    m._requestData = requestData
    m._startPingTimer = startPingTimer
    m._stopPingTimer = stopPingTimer

    m.getResource = getResource
    m.getPlayhead = getPlayhead
    m.getMediaDuration = getMediaDuration
    m.getTitle = getTitle
    m.getIsLive = getIsLive
    m.getRendition = getRendition
    m.getThroughput = getThroughput
    m.getBitrate = getBitrate
    m.getPluginName = getPluginName
    m.getPluginVersion = getPluginVersion
    m.getPlayerVersion = getPlayerVersion

    'Ads
    m.getAdPosition = getAdPosition
    m.getAdNumber = getAdNumber
    m.getAdPlayhead = getAdPlayhead
    m.getAdDuration = getAdDuration

    m.lastAdPlayhead = 0

    m.adNumber = 0
    m.adPosition = "unknown"
    m.adTitle = invalid

    m.eventHandler = eventHandler

    'Fields

end sub

sub _run()

    YouboraLog("YBPluginGeneric.brs - run")

    m.pluginName = "Generic"
    m.pluginVersion = "6.0.4-" + m.pluginName

    m.infoManager = InfoManager(m)
    setOptions(m.top.options)

    'The ViewManager sends the /data call through the _requestData() method
    m.viewManager = ViewManager(m.infoManager, m)
    startMonitoring()

    'Create timer for pings
    m.pingTimer = CreateObject("roSGNode", "Timer")
    m.pingTimer.duration = 5
    m.pingTimer.repeat = true
    m.pingTimer.ObserveField("fire", m.port)

    'Endless loop to listen for events
    while true

        msg = wait(0, m.port)

        'Delegate call to the specific plugin.
        'The plugin will have to override this method in order
        'to get the events from the player.
        processMessage(msg, m.port)

        mt = type(msg)

        if mt = "roSGNodeEvent"
            if msg.getField() = "event"         'Process event from outside
                invokeHandler(msg.getData())
            else if msg.getField() = "fire"     'Timer callback
                m.viewManager.pingCallback()
            else if msg.getField() = "options"
                opt = msg.getData()
                setOptions(opt)
            else if msg.getField() = "logging"
                logEnabled = msg.getData()
                GetGlobalAA().YouboraLogActive = logEnabled
            else if msg.getField() = "adevent"
                 invokeAdHandler(msg.getData())
            endif

        else if (mt = "roUrlEvent") '/data response
            code = msg.GetResponseCode()
            if (code = 200)
                response = msg.GetString()
                receiveData(response)
                m.dataRequest = invalid
            else
                YouboraLog("Invalid data response, code: " + code.ToStr() + ", reason: " + msg.GetFailureReason())
            endif
        endif

    end while

end sub

sub _stop()

    stopMonitoring()

end sub

'This method should be overriden in the specific plugin in order to process
'the player events
sub processMessage(msg, port)
    YouboraLog("Youbora.brs -  processMessage")
end sub

'Info methods
function getResource()
    return "unknown"
end function

function getMediaDuration()
    return 0
end function

function getPlayhead()
    return 0
end function

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

function getAdPosition()
    return invalid
end function

function getAdPlayhead()
    return m.lastAdPlayhead
end function

function getAdNumber()
    return invalid
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
    m.pingTimer.control = "start"
end sub

sub stopPingTimer()
    m.pingTimer.control = "stop"
end sub

sub startMonitoring()

end sub

sub stoptMonitoring()
    eventHandler("stop")
end sub

sub eventHandler(event as String, params = Invalid)

    if event = "play"
        m.viewManager.sendRequest("start", params)
    else if event = "join"
        m.viewManager.sendRequest("join", params)
    else if event = "pause"
        m.viewManager.sendRequest("pause", params)
    else if event = "resume"
        m.viewManager.sendRequest("resume", params)
    else if event = "stop"
        m.viewManager.sendRequest("stop", params)
    else if event = "error"
        'Brightscript transforms the keys of params to lowercase
        'This is bad for the error, as the code should be sent as errorCode
        params2 = {}
        if params.DoesExist("msg")
            params2["msg"] = params["msg"]
        endif

        if params.DoesExist("errorCode")
            params2["errorCode"] = params["errorCode"]
        endif

        m.viewManager.sendRequest("error", params2)
    else if event = "buffering"
        m.viewManager.sendRequest("bufferStart", params)
    else if event = "buffered"
        m.viewManager.sendRequest("bufferEnd", params)
    else if event = "seeking"
        m.viewManager.sendRequest("seekStart", params)
    else if event = "seeked"
        m.viewManager.sendRequest("seekEnd", params)
    else if event = "adPlay"
        m.viewManager.sendRequest("adStart", params)
    else if event = "adJoin"
        m.viewManager.sendRequest("adJoin", params)
    else if event = "adPlayJoin"
        m.viewManager.sendRequest("adStart", params)
        m.viewManager.sendRequest("adJoin", params)
    else if event = "adStop"
        m.viewManager.sendRequest("adStop", params)
    else if event = "adError"
        m.viewManager.sendRequest("adError", params)
        if m.viewManager.isShowingAds = true
            m.viewManager.sendRequest("adStop", params)
        endif
    else if event = "adPause"
        m.viewManager.sendRequest("adPause", params)
    else if event = "adResume"
        m.viewManager.sendRequest("adResume", params)
    endif

end sub

sub invokeHandler(data as Object)
    if type(data) = "roAssociativeArray"
        handler = data.handler
        params = data.params
        if type(handler) = "roString"
            m.eventHandler(handler, params)
        endif
    endif

end sub

sub invokeAdHandler(data as Object)
    adParams = {}

    if data.adindex <> invalid = true
        adParams["adNumber"] = data.adindex
    end if
    if data.ad <> invalid = true and data.ad.adtitle <> invalid = true
        adParams["adTitle"] = data.ad.adtitle
    end if
    if data.time <> invalid
         m.lastAdPlayhead = data.time
    end if

    if data.duration <> invalid
         adParams["adDuration"] = data.duration
    end if

    if m.viewManager.isStartSent = true AND m.viewManager.isJoinSent = false
        adParams["adPosition"] = "pre"
    else if m.viewManager.isJoinSent = true
        if m.viewManager.isFinished = true
            adParams["adPosition"] = "post"
        else
            adParams["adPosition"] = "mid"
        end if
    end if

    if type(data) = "roAssociativeArray"
        if data.type = "PodStart"
            if m.viewManager.isStartSent = false
                invokeHandler({handler: "play"})
            end if
        else if data.type = "PodComplete"
            if m.viewManager.isFinished = true
                invokeHandler({handler: "stop"})
            end if
        else if data.type = "Impression"
            m.lastAdPlayhead = 0
            eventHandler("seeked")
            eventHandler("buffered")
            adParams["adnalyzerVersion"] = "6.0.3 Roku Adnalyzer"
            invokeHandler({handler: "adPlayJoin", params: adParams})
        else if data.type = "Complete"
            invokeHandler({handler: "adStop", params: adParams})
        else if data.type = "Skip"
            adParams.skipped = "true"
            invokeHandler({handler: "adStop", params: adParams})
        else if data.type = "Error" AND data.errMsg <> invalid
            if data.errMsg <> invalid
                adParams.msg = data.errMsg
            end if
            if data.errcode <> invalid
                adParams["errorCode"] = data.errcode
            end if
            invokeHandler({handler: "adError", params:adParams})
        else if data.type = "Pause"
            invokeHandler({handler: "adPause", params:adParams})
        else if data.type = "Resume"
            invokeHandler({handler: "adResume", params:adParams})
        else if data.type = "Close"
            invokeHandler({handler: "adStop", params: adParams})
        end if
    endif

end sub

sub pingTimerTick()
    m.viewManager.pingCallback()
end sub

sub requestData(args = Invalid)

    if args = Invalid
        args = {}
    endif

    args.Delete("code")

    if args.DoesExist("outputformat") = false then args["outputformat"] = "jsonp"
    args["timemark"] = currentMillis().ToStr()

    m.dataRequest = Request(m.port)

    if m.infoManager.options["httpSecure"] = true
        protocol = "https://"
    else
        protocol = "http://"
    endif

    m.dataRequest.host = protocol + "nqs.nice264.com"
    m.dataRequest.service = "/data"
    m.dataRequest.args = args

    m.dataRequest.send()
end sub

sub receiveData(response as string)
    if response = invalid or response = ""
        YouboraLog("FastData empty response")
        return
    endif

    'Convert jsonp to json
    responseJson = mid(response, 8, Len(response) - 8)
    YouboraLog("responseJson: " + responseJson)
    outerJson = ParseJSON(responseJson)

    if outerJson.q <> invalid
        innerJson = outerJson.q

        host = ""
        code = ""
        pt = ""
        balancer = ""

        if innerJson.h <> invalid
            host = innerJson.h
        endif
        if innerJson.c <> invalid
            code = innerJson.c
        endif
        if innerJson.pt <> invalid
            pt = innerJson.pt
        endif
        if innerJson.b <> invalid
            balancer = innerJson.b
        endif


        if Len(host) > 0 and Len(code) > 0 and Len(pt) > 0 and Len(balancer) > 0
            prefix = Left(code, 1)
            firstCode = Right(code, Len(code) - 1)
            pingTime = pt
            balancerEnabled = balancer

            m.viewManager.com.prefix = prefix
            m.viewManager.com.code = firstCode
            m.viewManager.com.requestHost = host
            m.viewManager.com.pingTime = pingTime
            m.viewManager.com.balancerEnabled = balancerEnabled
            'update ping time
            m.pingTimer.duration = pt

            YouboraLog("FastData " + code + " is ready.")

            m.viewManager.com.removePreloader = "FastData"
        endif

    endif

    m.dataRequest = Invalid

end sub

sub setOptions(options = Invalid)
    if options <> Invalid
        m.infoManager.options = options
    endif
end sub
