' ********** Copyright 2023 Nice People At Work.  All Rights Reserved. **********

'Request.brs

Function Request(messagePort) as Object

  YouboraLog("Created Request", "Request")
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
End Function

Function Request_send() as Boolean

  url = m.getUrl()
  m.request.SetUrl(url)
  YouboraLog("XHR Req: " + url, "Request")

  'We need a little setup if the request is https
  if url.Left(5) = "https"
    m.request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    m.request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    m.request.InitClientCertificates()
  end if

  'Send
  return m.request.AsyncGetToString()
End Function


Function Request_getUrl() as String
  return m.host + m.service + m.getQuery()
End Function

Function Request_getQuery() as String

  if m.args <> invalid AND m.args.IsEmpty() = false
    query$ = "?"

    for each paramKey in m.args

      paramValue = m.args[paramKey]

      if paramValue <> invalid
        if type(paramValue) = "roArray" OR type(paramValue) = "roAssociativeArray"
          query$ = query$ + m.request.Escape(paramKey) + "=" + m.request.Escape(FormatJson(paramValue)) + "&"
        else if paramValue.ToStr() <> ""
          query$ = query$ + m.request.Escape(paramKey) + "=" + m.request.Escape(paramValue.ToStr()) + "&"
        end if
      end if
    end for

    'Remove last ampersand
    query$ = Left(query$, Len(query$) - 1)

    return query$
  end if

  return ""
End Function