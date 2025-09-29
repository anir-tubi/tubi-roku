Function init()
  m.internalComponentLibrary = m.top.findNode("internalComponentLibrary")
  m.retryDelayDurationTimer = m.top.findNode("retryDelayDurationTimer")
  m.timeoutDurationTimer = m.top.findNode("timeoutDurationTimer")

  m.top.observeField("uri", "onUriChange")

  m.internalComponentLibrary.observeField("loadStatus", "onInternalComponentLibraryLoadStatusChange")

  m.retryDelayDurationTimer.observeFieldScoped("fire", "onRetryDelayDurationTimerFire")
  m.timeoutDurationTimer.observeFieldScoped("fire", "onTimeoutDurationTimerFire")

  m.retriesAttempted = 0
End Function


Function onUriChange(msg)
  uri = msg.getData()

  m.timeoutDurationTimer.control = "start"
  m.top.loadStatus = "loading"
  m.internalComponentLibrary.uri = uri
End Function


Function onInternalComponentLibraryLoadStatusChange(msg)
  loadStatus = msg.getData()

  if loadStatus = "failed" then
    m.timeoutDurationTimer.control = "stop"

    if m.top.retryCount > m.retriesAttempted then
      print "RetryableComponentLibrary: Component library " + m.top.id + " load failed"
      m.retryDelayDurationTimer.control = "start" ' Start the retry delay timer
    else
      m.top.loadStatus = "failed"
      m.internalComponentLibrary.uri = "" ' Clear the URI to prevent further attempts
    end if
  else if loadStatus = "ready" then
    m.timeoutDurationTimer.control = "stop"

    m.top.loadStatus = "ready"
  end if
End Function


Function onRetryDelayDurationTimerFire()
  retryComponentLibrary()
End Function

Function onTimeoutDurationTimerFire()
  if m.top.retryCount > m.retriesAttempted then
    print "RetryableComponentLibrary: Component library" + m.top.id + " timed out"
    retryComponentLibrary()
  else
    m.top.loadStatus = "failed"
    m.internalComponentLibrary.uri = "" ' Clear the URI to prevent further attempts
  end if
End Function


Function retryComponentLibrary()
  m.retriesAttempted = m.retriesAttempted + 1

  previousUri = m.internalComponentLibrary.uri

  compLibType = "pkg"
  if previousUri.instr(".zip") then
    compLibType = "zip"
  end if

  ' Cut off the query params
  newUri = previousUri.split("?")[0] + "?retry=" + m.retriesAttempted.toStr() + "&type=." + compLibType ' need to add correct compLibType on the end of the url or else it won't work right

  m.internalComponentLibrary.uri = newUri
End Function
