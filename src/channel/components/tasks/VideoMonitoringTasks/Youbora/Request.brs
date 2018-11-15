' ********** Copyright 2016 Nice People At Work.  All Rights Reserved. **********

'Request.brs

function Request(messagePort) As Object

	YouboraLog("Created Request")
    this = CreateObject("roAssociativeArray")

    'Methods
    this.getUrl = Request_getUrl
    this.getQuery = Request_getQuery
    this.send = Request_send

    'Fields
    this.host = ""
    this.service = ""
    this.args = {}

	this.request = CreateObject("roUrlTransfer")
	this.request.SetMessagePort(messagePort)

    return this
end Function

function Request_send() as Boolean
	
	url = m.getUrl()
    m.request.SetUrl(url)
    YouboraLog("XHR Req: " + url)
    
    'We need a little setup if the request is https
    if url.Left(5) = "https"
    	m.request.SetCertificatesFile("common:/certs/ca-bundle.crt")
        m.request.AddHeader("X-Roku-Reserved-Dev-Id", "")
        m.request.InitClientCertificates()
    endif

	'Send
    return m.request.AsyncGetToString()
end function


function Request_getUrl() as String
	return m.host + m.service + m.getQuery()
end function

function Request_getQuery() as String

	if m.args <> Invalid and m.args.IsEmpty() = false
		query$ = "?"

		for each paramKey in m.args

			paramValue = m.args[paramKey]

			if paramValue <> invalid
				if type(paramValue) = "roArray" or type(paramValue) = "roAssociativeArray"
					query$ = query$ + m.request.Escape(paramKey) + "=" + m.request.Escape(FormatJson(paramValue)) + "&"
				else if paramValue.ToStr() <> ""
					query$ = query$ + m.request.Escape(paramKey) + "=" + m.request.Escape(paramValue.ToStr()) + "&"
				endif
			endif
		end for

		'Remove last ampersand
		query$ = Left(query$, Len(query$) - 1)

		return query$
	endif

	return ""
end function