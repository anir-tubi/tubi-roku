function ViewManager(_infoManager as Object, plugin) As Object

	YouboraLog("Created ViewManager")
    this = CreateObject("roAssociativeArray")

    'Methods
    this.pingCallback = ViewManager_pingCallback
	this.sendRequest = ViewManager_sendRequest

    'Fields
    this.isStartSent = false
	this.isJoinSent = false
	this.isPaused = false
	this.isSeeking = false
	this.isBuffering = false
	this.isShowingAds = false
	this.isErrorSent = false
	this.isAdPaused = false
	this.isAdJoinSent = false

	this.isFinished = false

    this.chronoSeek = Chrono()
    this.chronoPause = Chrono()
    this.chronoJoinTime = Chrono()
    this.chronoBuffer = Chrono()
	this.chronoPing = Chrono()

	'Ad chronos
	this.chronoGenericAd = Chrono()
	this.chronoAdJoin = Chrono()
	this.chronoAdPause = Chrono()
	this.chronoTotalAds = Chrono()


    if _infoManager <> Invalid

    	this.infoManager = _infoManager

    	this.com = CreateObject("roSGNode", "Communication")
    	this.com.requestHost = "nqs.nice264.com"
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
	m.sendRequest("ping")
	m.chronoPing.start()
end sub


sub ViewManager_sendRequest(req as String, params = Invalid)

  if req  = "ping"
		params = m.infoManager.getRequestParams("ping", params)

		if m.isShowingAds = false
		  m.lastPlayhead = params.playhead
		else
		  m.lastPlayhead = -1
		endif
  endif

	if req = "start"

		if m.isStartSent = false
			params = m.infoManager.getRequestParams("start", params)

			m.isStartSent = true

			'Start chronos
			m.infoManager.plugin._startPingTimer()
			m.chronoPing.start()
	        m.chronoJoinTime.start() 'Start timing join time

			m.com.nextView = {live:false} 'Live = true
			m.com.request = {service: "/start", args:params}
			YouboraLog("Request: NQS /start " + params["mediaResource"])
		endif

	else if req = "join"

		if m.isStartSent = true and m.isJoinSent = false
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

	if m.isStartSent

		pauseDuration = -1

		if m.isPaused
			pauseDuration = m.chronoPause.getDeltaTime(false)
		end if

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
			'm.chronoPause.getDeltaTime()

			params = m.infoManager.getRequestParams("resume", params)

			if params.DoesExist("pauseDuration") = false then params["pauseDuration"] = m.chronoPause.getDeltaTime()

			m.com.request = {service: "/resume", args:params}

			YouboraLog("Request: NQS /resume")
		endif

	else if req = "ping"

		params = m.infoManager.getRequestParams("ping", params)

		rendition = m.infoManager.getRendition()

		changedEntities = {}

		if rendition <> Invalid and rendition <> m.lastRendition
			m.lastRendition = rendition
			changedEntities["rendition"] = m.lastRendition
		endif

		if params.DoesExist("pingTime") = false then params["pingTime"] = m.com.pingTime

		if m.isBuffering
			if params.DoesExist("bufferDuration") = false then params["bufferDuration"] = m.chronoBuffer.getDeltaTime(false)
		else if m.isSeeking
			if params.DoesExist("seekDuration") = false then params["seekDuration"] = m.chronoSeek.getDeltaTime(false)
		endif

		if m.isPaused
			if params.DoesExist("pauseDuration") = false then params["pauseDuration"] = m.chronoPause.getDeltaTime(false)
		end if

		if changedEntities.Count() = 1
			key = changedEntities.Keys()[0]
			value = changedEntities[key]
			params["entityType"] = key
			params["entityValue"] = value
		else if changedEntities.Count() > 1
			if params.DoesExist("entityValue") = false
				params["entityValue"] = changedEntities
			endif
		endif

		if m.isShowingAds = true
		  params["adPlayhead"] = m.infoManager.getAdPlayhead()
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

			if params.DoesExist("duration") = false then params["duration"] = m.chronoBuffer.getDeltaTime()
			if params.DoesExist("time") = false then params["time"] = m.infoManager.getPlayhead()

			m.com.request = {service: "/bufferUnderrun", args:params}

			YouboraLog("Request: NQS /bufferUnderrun " + params["duration"].ToStr() + " ms")

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
			if params.DoesExist("duration") = false then params["duration"] = m.chronoSeek.getDeltaTime()

			m.com.request = {service: "/seek", args:params}

			YouboraLog("Request: NQS /seek " + params["duration"].ToStr() + " ms")

		endif

	else if req = "error"

		m.infoManager.plugin._stopPingTimer()

		params = m.infoManager.getRequestParams("error", params)

		m.com.request = {service: "/error", args:params}

		YouboraLog("Request: NQS /error " + params.msg)

	else if req = "adStart"
        if m.isStartSent = true and m.isShowingAds = false
            m.isShowingAds = true
            if m.chronoTotalAds.getDeltaTime() = -1
            	m.chronoTotalAds.start()
            end if
            m.chronoGenericAd.start()
            m.chronoAdJoin.start()
            params = m.infoManager.getRequestParams("adStart", params)

            m.com.request = {service: "/adStart", args:params}
            YouboraLog("Request: NQS /adStart")

         end if

     else if req = "adJoin"
        if m.isStartSent = true and m.isShowingAds = true and m.isAdJoinSent = false
            m.isAdJoinSent = true
            m.chronoAdJoin.stop()
            if params.DoesExist("adJoinDuration") = false then params["adJoinDuration"] = m.chronoAdJoin.getDeltaTime()

            params = m.infoManager.getRequestParams("adJoin", params)

            m.com.request = {service: "/adJoin", args:params}
            YouboraLog("Request: NQS /adJoin " + params.playhead.toStr() + " ms")

         end if

     else if req = "adPause"
        if m.isStartSent = true and m.isShowingAds = true and m.isAdPaused = false
            m.isAdPaused = true
            params = m.infoManager.getRequestParams("adPause", params)

            m.com.request = {service: "/adPause", args:params}
            YouboraLog("Request: NQS /adPause")

         end if

     else if req = "adResume"
        if m.isStartSent = true and m.isShowingAds = true and m.isAdPaused = true
            m.isAdPaused = false
            params = m.infoManager.getRequestParams("adResume", params)

            m.com.request = {service: "/adResume", args:params}
            YouboraLog("Request: NQS /adResume")

         end if

     else if req = "adStop"
        if m.isStartSent = true and m.isShowingAds = true
            m.chronoGenericAd.stop()

            if m.isShowingAds = true
                m.isAdPaused = false
                m.isAdJoinSent = false
            m.isShowingAds = false
            end if

            params["adTotalDuration"] = m.chronoGenericAd.getDeltaTime()

            params = m.infoManager.getRequestParams("adStop", params)

            m.com.request = {service: "/adStop", args:params}
            YouboraLog("Request: NQS /adStop")

         end if

     else if req = "adError"
     	params = m.infoManager.getRequestParams("adError", params)

        m.com.request = {service: "/adError", args:params}
        YouboraLog("Request: NQS /adError")
    endif
end sub

