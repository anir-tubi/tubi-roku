Function TubiRequestQueue()
  return {
    create: createHTTPRequestQueue
    pushRequest: tubiq_pushRequest
    handleEvent: tubiq_handleEvent
    count: tubiq_count
    clear: tubiq_clear
    cancelRequest: tubiq_cancelRequest
    wrapRequest: tubiq_wrapRequest_
    advanceQueue: tubiq_advanceQueue_
    findRequestById: tubiq_findRequestById_
    findRequestByUuid: tubiq_findRequestByUuid_
  }
End Function



'''''''''''''''''
' createHTTPRequestQueue - create and initialize a request queue
'
' port - the message port used by the caller's main loop, where roUrlTransfer objects will send events
' maxSize - the maximum depth of queue, or 0 if no limit
' timeout - seconds before expiring the request, default 30
'
Function createHTTPRequestQueue(port as Object, maxSize = 0 as Integer, timeout = 30 as Integer) as Object
  return {
    'public
    pushRequest: m.pushRequest
    handleEvent: m.handleEvent
    count: m.count
    clear: m.clear
    cancelRequest: m.cancelRequest
    ' private
    wrapRequest_: m.wrapRequest
    advanceQueue_: m.advanceQueue
    findRequestById_: m.findRequestById
    findRequestByUuid_: m.findRequestByUuid
    queue: []
    maxSize: maxSize
    timeout: timeout
    port: port
  }
End Function


''''''''''''''''
' pushRequest - add a request to the queue and start the request
'
' request - a request created by createAsyncHTTPRequest
'
Function tubiq_pushRequest(request as Object) as Object
  ' make room first
  m.advanceQueue_()

  if request = invalid OR request["klass"] <> "TubiAsyncHTTPRequest"
    tubiLog("Invalid object attempted to push to request queue")
    return invalid
  else
    ' push to queue only if there is room
    if m.maxSize = 0 OR m.queue.Count() < m.maxSize then
      m.queue.Push(m.WrapRequest_(request))
      m.AdvanceQueue_()
      return request
    end if
  end if
  return invalid
End Function


'''''''''''''''''
' handleEvent - Handle a roUrlEvent received by the message port, returns the request id which had changed.
'
' event - an event received on the message port assigned to this queue; events besides roUrlEvent will
'         be ignored
'
Function tubiq_handleEvent(event as Object) as Object
  if type(event) <> "roUrlEvent" then return invalid
  id = event.GetSourceIdentity()
  index = m.findRequestById_(id)
  result = invalid
  if index <> -1 then
    entry = m.queue[index]
    response = entry.request.handleEvent(event)
    if response <> invalid then
      result = response
      m.queue.Delete(index)
    end if
  end if
  m.AdvanceQueue_()
  return result
End Function


''''''''''''''''''
' cancelRequest
'
' Cancel a request and remove it from the queue.  We have to add this here because
' a Request object that is cancelled does not emit an event on which handleEvent could
' clean up the queue.
Function tubiq_cancelRequest(request as Object)
  if request <> invalid AND request.uuid <> invalid then
    i = m.findRequestByUuid_(request.uuid)
    if i <> -1 then
      m.queue[i].request.cancel()
      m.queue.Delete(i)
    end if
  end if
End Function

'''''''''''''''''
' count - Return the number of requests currently in the queue
'
Function tubiq_count()
  m.AdvanceQueue_()
  return m.queue.Count()
End Function


'''''''''''''''''
' clear - Cancel all outstanding requests
'
Function tubiq_clear()
  for each entry in m.queue
    if entry.urltransfer <> invalid then
      entry.urltransfer.AsyncCancel()
    end if
  end for
  m.queue.Clear()
End Function


' Make our own object out of the initial request
Function tubiq_wrapRequest_(request as Object) as Object
  datetime = CreateObject("roDateTime")
  now = datetime.AsSeconds()
  return {
    request: request
    urltransfer: invalid
    startTime: now
  }
End Function


'Start any queued requests if there is room in the active queue
Function tubiq_advanceQueue_()
  datetime = CreateObject("roDateTime")
  now = datetime.AsSeconds()

  ' Expire any active requests.  These may still be in transit or be complete
  ' but response not processed
  i = 0
  while i < m.queue.Count()
    entry = m.queue[i]
    if m.timeout <> invalid AND m.timeout <> 0 then
      if now - entry.startTime > m.timeout then
        entry.request.cancel()
        m.queue.Delete(i)
        i = i - 1 'to account for shift
      end if
    end if
    i = i + 1
  end while

  ' Start requests
  ' TODO(chris): incorporate an 'max active' to control a pool of roUrltransfer objects
  for i = 0 to m.queue.Count() - 1
    entry = m.queue[i]
    if entry.urltransfer = invalid
      entry.urltransfer = CreateObject("roUrlTransfer")
      entry.urltransfer.SetPort(m.port)
      entry.request.start(entry.urltransfer)
    end if
  end for
End Function

' Find a request in the queue by its urltransfer id. This is a helper for handleRequest().
'
' returns the index in the queue
Function tubiq_findRequestById_(id as Integer) as Integer
  for i = 0 to m.queue.Count() - 1
    entry = m.queue[i]
    if entry.urltransfer <> invalid AND entry.urltransfer.GetIdentity() = id then return i
  end for
  return -1
End Function

Function tubiq_findRequestByUuid_(uuid as String) as Integer
  for i = 0 to m.queue.Count() - 1
    entry = m.queue[i]
    if entry.request.uuid <> invalid AND entry.request.uuid = uuid then return i
  end for
  return -1
End Function
