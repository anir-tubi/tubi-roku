function ViewManager(_infoManager as Object, plugin) As Object

	YouboraLog("Created ViewManager")
    this = CreateObject("roAssociativeArray")

    'Methods
    this.pingCallback = ViewManager_pingCallback
    this.beatCallback = ViewManager_beatCallback
		this.sendRequest = ViewManager_sendRequest
		this.getDiff = ViewManager_getDiff

    'Fields
		this.isInitiated = false
    this.isStartSent = false
		this.isJoinSent = false
		this.isPaused = false
		this.isSeeking = false
		this.isBuffering = false
		this.isShowingAds = false
		this.isErrorSent = false
		this.isAdPaused = false
		this.isAdJoinSent = false
		this.isAdInitiated = false
		this.isAdBreakStarted = false
		this.isAdManifestSent = false

		this.isFinished = false

    this.chronoSeek = Chrono()
    this.chronoPause = Chrono()
    this.chronoJoinTime = Chrono()
    this.chronoBuffer = Chrono()
		this.chronoPing = Chrono()
		this.chronoBeat = Chrono()

		'Ad chronos
		this.chronoGenericAd = Chrono()
		this.chronoAdJoin = Chrono()
		this.chronoAdPause = Chrono()
		this.chronoTotalAds = Chrono()

		'Ping time, even though we could get it from the communication class for performance sake we save a copy here
		this.pingTime = 5

    if _infoManager <> Invalid

    	this.infoManager = _infoManager

    	this.com = CreateObject("roSGNode", "Communication")
    	'this.com.requestHost = "nqs.nice264.com"
		if (_infoManager.options["httpSecure"] = true)
			this.com.httpSecure = true
		else
			this.com.httpSecure = false
		endif

    endif

    plugin._requestData(m.infoManager.getRequestParams("data"))

    return this
end Function

'This method is called from the plugin periodically
sub ViewManager_pingCallback()
	diffvalue = 0
	if m.chronoPing.startTime <> invalid
		diffvalue = m.chronoPing.currentMillis() - m.chronoPing.startTime 
	end if
	m.sendRequest("ping", {"diffTime": diffvalue})
	m.chronoPing.start()
	'We "use" the ping time to check if any metadata was missing too
	if m.infoManager.options["waitForMetadata"] = "true" then m.infoManager.plugin.eventHandler("play")
end sub

sub ViewManager_beatCallback()
	m.sendRequest("sessionBeat")
	m.chronoBeat.start()
end sub

function ViewManager_getDiff(current as object, previous as object) as object
	ret = {}
	if previous = invalid
		previous = {}
	end if
	for each prop in current
		if current[prop] <> invalid and current[prop] <> previous[prop]
			ret[prop] = current[prop]
		end if
	end for
	return ret
end function

sub ViewManager_sendRequest(req as String, params = Invalid)

  if req  = "ping"
		params = m.infoManager.getRequestParams("ping", params)

		if m.isShowingAds = false
		  m.lastPlayhead = params.playhead
		else
		  m.lastPlayhead = -1
		endif
  endif

	if req = "init"
		if m.isInitiated = false and m.isStartSent = false then
			params = m.infoManager.getRequestParams("start", params)

			m.isInitiated = true

			'Start chronos
			m.infoManager.plugin._startPingTimer()
			m.chronoPing.start()
	    m.chronoJoinTime.start() 'Start timing join time

			m.com.nextView = {live:"U"} 'Live = true
			m.com.request = {service: "/init", args:params}
			YouboraLog("Request: NQS /init " + params["mediaResource"])
		end if
	else if req = "start"

		if m.isStartSent = false
			params = m.infoManager.getRequestParams("start", params)
			m.lastEntities = m.infoManager.getEntities()

			m.isStartSent = true

			'Start chronos
			m.infoManager.plugin._startPingTimer()
			m.chronoPing.start()
			if m.isInitiated = false
				if (m.chronoJoinTime.getDeltaTime() = -1) then
					m.chronoJoinTime.start() 'Start timing join time
				end if
				
				m.com.nextView = {live:"U"} 'Live = true
			end if 

			m.com.request = {service: "/start", args:params}
			YouboraLog("Request: NQS /start " + params["mediaResource"])
		endif

	else if req = "join"

		if (m.isStartSent = true OR m.isInitiated) and m.isJoinSent = false
			m.isJoinSent = true

			params = m.infoManager.getRequestParams("join", params)

			'Add jointime from chrono
			if m.chronoTotalAds.startTime <> Invalid
			     m.chronoJoinTime.setStartTime(m.chronoJoinTime.getStartTime() + m.chronoTotalAds.getDeltaTime())
			end if
			if params.DoesExist("joinDuration") = false then params["joinDuration"] = m.chronoJoinTime.getDeltaTime()

			'Check duration to only send it once
			mediaDuration = params.mediaDuration
			if mediaDuration <> Invalid and mediaDuration = m.lastDuration
				params.delete("mediaDuration")
			endif

			'joinTime cannot be less than 1ms
			playhead = params.playhead
			if playhead <> Invalid and playhead <= 0
				params.playhead = 1
			endif

			'params.playhead = params.playhead.ToStr()

			m.com.request = {service: "/joinTime", args:params}
			YouboraLog("Request: NQS /joinTime " + params["joinDuration"].ToStr())

		endif

	else if req = "stop"

	if m.isStartSent OR m.isInitiated

		pauseDuration = -1

		if m.isPaused
			pauseDuration = m.chronoPause.getDeltaTime(false)
		end if

		m.isInitiated = false
		m.isStartSent = false
		m.isPaused = false
		m.isJoinSent = false
		m.isSeeking = false
		m.isBuffering = false
		'Stop timers
		m.infoManager.plugin._stopPingTimer()

		params = m.infoManager.getRequestParams("stop", params)

		if params.DoesExist("diffTime") = false then params["diffTime"] = m.chronoPing.getDeltaTime()

		if pauseDuration <> -1
			if params.DoesExist("pauseDuration") = false then params["pauseDuration"] = pauseDuration
		end if

		m.chronoSeek.reset()
		m.chronoPause.reset()
		m.chronoJoinTime.reset()
		m.chronoBuffer.reset()

		'Ad Chronos
		m.chronoGenericAd.reset()
		m.chronoAdJoin.reset()
		m.chronoAdPause.reset()
		m.chronoTotalAds.reset()

		m.com.request = {service: "/stop", args:params}

        YouboraLog("Request: NQS /stop")

	endif

	else if req = "pause"

		if m.isJoinSent = true and m.isPaused = false
			m.isPaused = true

			m.chronoPause.start()

			params = m.infoManager.getRequestParams("pause", params)

			m.com.request = {service: "/pause", args:params}

			YouboraLog("Request: NQS /pause")
		endif

	else if req = "resume"

		if m.isJoinSent = true and m.isPaused = true
			m.isPaused = false

			params = m.infoManager.getRequestParams("resume", params)

			if params.DoesExist("pauseDuration") = false then params["pauseDuration"] = m.chronoPause.getDeltaTime()

			m.com.request = {service: "/resume", args:params}

			YouboraLog("Request: NQS /resume")
		endif

	else if req = "ping"

		params = m.infoManager.getRequestParams("ping", params)
		entities = m.infoManager.getEntities()
		diffEntities = m.getDiff(entities, m.lastEntities)
		m.lastEntities = entities
		if diffEntities.Count() > 0
			params["entities"] = diffEntities
		end if

		if params.DoesExist("pingTime") = false then params["pingTime"] = m.pingTime

		if m.isBuffering
			if params.DoesExist("bufferDuration") = false then params["bufferDuration"] = m.chronoBuffer.getDeltaTime(false)
		else if m.isSeeking
			if params.DoesExist("seekDuration") = false then params["seekDuration"] = m.chronoSeek.getDeltaTime(false)
		endif

		if m.isPaused
			if params.DoesExist("pauseDuration") = false then params["pauseDuration"] = m.chronoPause.getDeltaTime(false)
		end if

		if m.isShowingAds = true
		  params["adPlayhead"] = m.infoManager.getAdPlayhead()

			if m.isAdPaused = true
				params["adPauseDuration"] = m.chronoAdPause.getDeltaTime(false)
			end if

		end if

		m.com.request = {service: "/ping", args:params}

	else if req = "bufferStart"

		if m.isJoinSent = true and m.isBuffering = false
			m.isBuffering = true
			m.chronoBuffer.start()

			YouboraLog("Method: /bufferStart")
		endif

	else if req = "bufferEnd"

		if m.isJoinSent = true and m.isBuffering = true
			m.isBuffering = false

			params = m.infoManager.getRequestParams("bufferEnd", params)

			if params.DoesExist("bufferDuration") = false then params["bufferDuration"] = m.chronoBuffer.getDeltaTime()
			if params.DoesExist("playhead") = false then params["playhead"] = m.infoManager.getPlayhead()

			m.com.request = {service: "/bufferUnderrun", args:params}

			YouboraLog("Request: NQS /bufferUnderrun " + params["bufferDuration"].ToStr() + " ms")

		endif

	else if req = "seekStart"

		if m.isJoinSent = true and m.isSeeking = false
			m.isSeeking = true
			m.chronoSeek.start()

			YouboraLog("Method /seekStart")
		endif

	else if req = "seekEnd"

		if m.isJoinSent = true and m.isSeeking = true
			m.isSeeking = false

			params = m.infoManager.getRequestParams("seekEnd", params)
			if params.DoesExist("seekDuration") = false then params["seekDuration"] = m.chronoSeek.getDeltaTime()

			m.com.request = {service: "/seek", args:params}

			YouboraLog("Request: NQS /seek " + params["seekDuration"].ToStr() + " ms")

		endif

	else if req = "error"

		m.infoManager.plugin._stopPingTimer()

		params = m.infoManager.getRequestParams("error", params)

		m.com.request = {service: "/error", args:params}

		YouboraLog("Request: NQS /error " + params.msg)

	else if req = "videoEvent"

		params = m.infoManager.getRequestParams("videoEvent", params)
		m.com.request = {service: "/infinity/video/event", args:params}
		YouboraLog("Request: NQS /infinity/video/event " + params.name)

	else if req = "adInit"

		if (m.isAdInitiated = false)
			if m.chronoTotalAds.getDeltaTime() = -1
            	m.chronoTotalAds.start()
            end if
			m.chronoGenericAd.start()
            m.chronoAdJoin.start()

			params = m.infoManager.getRequestParams("adInit", params)
			m.isAdInitiated = true
            m.com.request = {service: "/adInit", args:params}
            YouboraLog("Request: NQS /adInit")
		end if

	else if req = "adStart"
        if (m.isStartSent = true OR m.isInitiated) and m.isShowingAds = false
            m.isShowingAds = true
			if (m.isAdInitiated = false)
				if m.chronoTotalAds.getDeltaTime() = -1
					m.chronoTotalAds.start()
				end if
				m.chronoGenericAd.start()
				m.chronoAdJoin.start()
			end if
            params = m.infoManager.getRequestParams("adStart", params)

            m.com.request = {service: "/adStart", args:params}
            YouboraLog("Request: NQS /adStart")

         end if
     else if req = "adJoin"
        if (m.isStartSent = true OR m.isInitiated) and m.isShowingAds = true and m.isAdJoinSent = false
            m.isAdJoinSent = true
            m.chronoAdJoin.stop()
            if params.DoesExist("adJoinDuration") = false then params["adJoinDuration"] = m.chronoAdJoin.getDeltaTime()

            params = m.infoManager.getRequestParams("adJoin", params)

            m.com.request = {service: "/adJoin", args:params}
            YouboraLog("Request: NQS /adJoin " + Str(params["adJoinDuration"]) + " ms")

         end if

     else if req = "adPause"
        if (m.isStartSent = true OR m.isInitiated) and m.isShowingAds = true and m.isAdPaused = false
            m.isAdPaused = true
			m.chronoAdPause.start()
            params = m.infoManager.getRequestParams("adPause", params)

            m.com.request = {service: "/adPause", args:params}
            YouboraLog("Request: NQS /adPause")

         end if

     else if req = "adResume"
        if (m.isStartSent = true OR m.isInitiated) and m.isShowingAds = true and m.isAdPaused = true
            m.isAdPaused = false
            params = m.infoManager.getRequestParams("adResume", params)

			if params.DoesExist("adPauseDuration") = false then params["adPauseDuration"] = m.chronoAdPause.getDeltaTime()

            m.com.request = {service: "/adResume", args:params}
            YouboraLog("Request: NQS /adResume")

         end if

     else if req = "adStop"
        if (m.isStartSent = true OR m.isInitiated) and m.isShowingAds = true
            if m.isShowingAds = true
                m.isAdPaused = false
                m.isAdJoinSent = false
            	m.isShowingAds = false
            end if
			m.isAdInitiated = false
            params["adTotalDuration"] = m.chronoGenericAd.getDeltaTime()

            params = m.infoManager.getRequestParams("adStop", params)

            m.com.request = {service: "/adStop", args:params}
            YouboraLog("Request: NQS /adStop")

         end if

     else if req = "adError"
     	params = m.infoManager.getRequestParams("adError", params)

        m.com.request = {service: "/adError", args:params}
        YouboraLog("Request: NQS /adError")
  else if req = "adManifest" AND m.isAdManifestSent = false
		m.isAdManifestSent = true
		params = m.infoManager.getRequestParams("adManifest", params)
		m.com.request = {service: "/adManifest", args:params}
		YouboraLog("Request: NQS /adManifest")

	else if req = "adBreakStart" AND m.isAdBreakStarted = false
		m.isAdBreakStarted = true
		params = m.infoManager.getRequestParams("adBreakStart", params)
		if m.chronoTotalAds.getDeltaTime() = -1
			m.chronoTotalAds.start()
		end if

		m.com.request = {service: "/adBreakStart", args:params}
		YouboraLog("Request: NQS /adBreakStart")

	else if req = "adQuartile" AND m.isAdJoinSent = true
		params = m.infoManager.getRequestParams("adQuartile", params)
		m.com.request = {service: "/adQuartile", args:params}
        YouboraLog("Request: NQS /adQuartile")

	else if req = "adBreakStop" AND m.isAdBreakStarted = true
			m.isAdBreakStarted = false

			m.chronoTotalAds.stop()

			params = m.infoManager.getRequestParams("adBreakStop", params)

            m.com.request = {service: "/adBreakStop", args:params}
            YouboraLog("Request: NQS /adBreakStop")

	else if req = "sessionStart"
		m.infoManager.plugin._startBeatTimer()
		params = m.infoManager.getRequestParams("sessionStart", params)
		m.com.request = {service: "/infinity/session/start", args: params}
		YouboraLog("Request: NQS /infinity/session/start")

	else if req = "sessionStop"
		m.infoManager.plugin._stopBeatTimer()
		params = m.infoManager.getRequestParams("sessionStop", params)
		m.com.request = {service: "/infinity/session/stop", args: params}
		YouboraLog("Request: NQS /infinity/session/stop")	

	else if req = "sessionEvent"
		params = m.infoManager.getRequestParams("sessionEvent", params)
		m.com.request = {service: "/infinity/session/event", args: params}
		YouboraLog("Request: NQS /infinity/session/event")	

	else if req = "sessionNav"
		params = m.infoManager.getRequestParams("sessionNav", params)
		m.com.request = {service: "/infinity/session/nav", args: params}
		YouboraLog("Request: NQS /infinity/session/nav")

	else if req = "sessionBeat"
		params = m.infoManager.getRequestParams("sessionBeat", params)
		m.com.request = {service: "/infinity/session/beat", args: params}
		YouboraLog("Request: NQS /infinity/session/beat")

	else if req = "videoEvent"
		if m.isStartSent = true
			params = m.infoManager.getRequestParams("videoEvent", params)
			m.com.request = {service: "/infinity/video/event", args: params}
			YouboraLog("Request: NQS /infinity/video/event")
		end if

    endif
end sub

