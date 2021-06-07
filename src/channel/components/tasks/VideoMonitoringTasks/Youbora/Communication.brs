sub init()
	YouboraLog("Created Communication")

    'Fields
    m.port = createObject("roMessagePort")
    m.preloaders = CreateObject("roList")
    m.preloaders.AddTail("FastData")
	m.requests = {} 

	m.requestHost = "a-fds.youborafds01.com"
	m.view = -1

	m.startedRequests = CreateObject("roList")

    m.top.observeField("request", m.port)
    m.top.observeField("addPreloader", m.port)
    m.top.observeField("removePreloader", m.port)
    m.top.observeField("requestHost", m.port)
    m.top.observeField("nextView", m.port)

    'Init ourselves
	m.top.functionName = "_run"
	m.top.control = "RUN"

	m.sessionStarted = false

end sub


sub _run()
	m.httpSecure = m.top.httpSecure
	'Endless loop to listen for events
    while true

        msg = wait(0, m.port)
        mt = type(msg)
        
        if mt = "roSGNodeEvent"
            if msg.getField() = "request"
                reqInfo = msg.getData()
                service = reqInfo.service
                args = reqInfo.args
                sendRequest(service, args)
            else if msg.getField() = "addPreloader"
                preloader = msg.getData()
                addPreloader(preloader)
            else if msg.getField() = "removePreloader"
                preloader = msg.getData()
                removePreloader(preloader)
            else if msg.getField() = "requestHost"
				' This will get executed before removing the preloader, so we make sure of saving the host just in case
				m.requestHost = m.top.requestHost
            	setHost(m.requestHost)
            else if msg.getField() = "nextView"
            	dict = msg.getData()
            	_nextView(dict.live)
            endif   

        else if mt = "roUrlEvent" 'request response
            code = msg.GetResponseCode()
            if code = 200
                YouboraLog("Request ok")
            else
                YouboraLog("Invalid request response, code: " + code.ToStr() + ", reason: " + msg.GetFailureReason())
            endif

            responseSourceIdentity = msg.GetSourceIdentity()

            length = m.startedRequests.Count()
            index = length - 1

            requestsAux = CreateObject("roList")

            while index >= 0
            	req = m.startedRequests[index]				
				if responseSourceIdentity <> req.GetIdentity()
					'Save the other requests
					requestsAux.Push(req)
				endif
            	index = index - 1
           	end while

           	m.startedRequests = requestsAux

        endif

    end while
end sub


function getHost() as String
	return addProtocol(m.host, m.httpSecure)
end function

sub addPreloader(preloader as String)
	m.preloaders.AddTail(preloader)
end sub

sub removePreloader(preloader as String)
	length = m.preloaders.Count()
	index = length - 1
	preloadersAux = CreateObject("roList")

	while index >= 0
		pre = m.preloaders[index]				
		if pre <> preloader
			preloadersAux.Push(pre)
		endif
		index = index - 1
	end while

	m.preloaders = preloadersAux

	if preloader = "FastData"
		'Move requests from 'nocode' to the proper queue
		nocodeRequests = m.requests["nocode"]
		'Save the updated data

		topFields = m.top.getFields()

		m.code = topFields["code"]
		m.prefix = topFields["prefix"]
		m.requestHost = topFields["requestHost"]
		m.pingTime = topFields["pingTime"]
		m.balancerEnabled = topFields["balancerEnabled"]
		m.youboraId = topFields["youboraId"]

		if nocodeRequests <> Invalid and nocodeRequests.Count() > 0
		    m.requests[getViewCode()] = nocodeRequests
		    m.requests["nocode"] = []
		endif

	endif

	if m.preloaders = Invalid or m.preloaders.Count() = 0
		processRequests()
	endif

end sub

sub sendRequest(service, args = Invalid)
	if args = Invalid
		args = {}
	endif
	YouboraLog("Service: " + service)
	'Remove code
	args.delete("code")
	
	req = Request(m.port)
	req.service = service
	req.args = args
	
	registerRequest(req)

end sub

sub registerRequest(req)
	viewCode = getViewCode()
	reqs = m.requests
	if reqs.DoesExist(viewCode) = false
		m.requests[viewCode] = []
	endif

	req.args.timemark = currentMillis().ToStr()

	m.requests[viewCode].Push(req)
	processRequests()

end sub

sub processRequests()

	if m.preloaders.IsEmpty() = true and  m.requests.IsEmpty() = false
		for each viewCode in m.requests 'This iterates over requests's keys, ie. the view codes
			requestsForCode = m.requests[viewCode]

			for each req in requestsForCode 'For each pending request for that view code

				req.args.code = viewCode
				req.args["sessionRoot"] = getSessionRoot()
				if req.host = Invalid or req.host = ""
					req.host = getHost()
				endif

				if req.service = "/start" OR req.service = "/init"
					req.args["youboraId"] = m.youboraId
				endif

				if req.service = "/start" OR req.service = "/init" OR req.service = "/ping" OR req.service = "/error"
					req.args["sessionParent"] = getSessionRoot() 'Since we won't have parent we use the same code as root
				endif

				if req.service = "/start" OR req.service = "/init" OR req.service = "/error"
					req.args["parentId"] = req.args["sessionRoot"]
				endif

				if (req.service = "/infinity/session/start" OR req.service = "/infinity/session/stop" OR req.service = "/infinity/session/nav" OR req.service = "/infinity/session/event" OR req.service = "/infinity/session/beat")
					req.args.Delete("code")
					req.args["sessionId"] = getSessionRoot()

					if req.service = "/infinity/session/start"
						m.sessionStarted = true
					endif

					if req.service = "/infinity/session/stop"
						m.sessionStarted = false
					endif
				end if

				req.send()

				m.startedRequests.Push(req.request)
			end for
		end for

		m.requests.Clear() 'Once sent, clear requests lists
	endif
end sub

function _nextView(liveOrPrefix) as String

	prefix = "U"

	'We don't check boolean type as it may be boxed (roBoolean) or unboxed (Boolean)
	' if liveOrPrefix = true
	' 	prefix = "L"
	' else if liveOrPrefix = false
	' 	prefix = "V"
	' else if type(liveOrPrefix) = "string"
	' 	prefix = liveOrPrefix
	' endif

	m.view = m.view + 1
	m.prefix = prefix

	vcode = getViewCode()
	return vcode

end function

function getViewCode() as String
	if m.code = Invalid or m.code = ""
		return "nocode"
	else
		return m.prefix + m.code + "_" + m.view.ToStr()
	endif
end function

function getSessionRoot() as String
	if m.code = Invalid or m.code = ""
		return "noSessionRoot"
	end if
		return m.prefix + m.code
end function

sub setHost(host as String)
	m.host = removeProtocol(host)
end sub

'Static
function removeProtocol(host as String) as String

	index = Instr(1, host, "//")

	if index > 0
		return Right(host, Len(host) - (index + 2))
	endif

	return host
end function

function addProtocol(host as String, httpSecure as Boolean) as String

	if httpSecure = true
		proto = "https://"
	else
		proto = "http://"
	endif

	return proto + host

end function
