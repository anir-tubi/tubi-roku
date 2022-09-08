Function init()
  m.maxRetries = 5
  m.initialBackoff = 1
  m.backoffFactor = 1.5

  m.retryCount = 0

  m.constants = getConstants()

  m.controllerContainer = m.top.findNode("controllerContainer")
  m.starterComponentLibrary = m.top.findNode("starterComponentLibrary")
  m.remoteComponentLibrary = m.top.findNode("remoteComponentLibrary")
  m.busySpinner = m.top.findNode("busySpinner")
  m.fallbackPoster = m.top.findNode("fallbackPoster")
  m.fallbackPosterTimer = m.top.findNode("fallbackPosterTimer")
  m.retryTimer = m.top.findNode("retryTimer")

  poster = m.busySpinner.poster
  poster.width = 66
  poster.height = 66
  m.busySpinner.uri = "pkg:/images/spinner.png"
  m.busySpinner.control = "start"

  m.starterComponentLibrary.observeFieldScoped("loadStatus", "onStarterComponentLibraryLoadStatusChange")
  m.starterComponentLibrary.uri = m.constants.settings.starterComponentsUrl

  m.fallbackPosterTimer.observeFieldScoped("fire", "onFallbackPosterTimerFire")
  m.retryTimer.observeFieldScoped("fire", "onRetryTimerFire")
End Function


Function onStarterComponentLibraryLoadStatusChange(msg)
  loadStatus = msg.getData()
  if loadStatus = "ready" then
    m.starterController = m.top.createChild("TubiStarterLibrary:StarterController")
    if m.starterController <> invalid then
      ' Reset retry logic for the potentially being used on remote component library
      m.retryCount = 0
      m.retryTimer.duration = m.initialBackoff

      m.starterController.id = "StarterController"
      m.starterController.observeFieldScoped("remoteComponentsUrl", "onStarterControllerRemoteComponentsUrlChange")
      m.starterController.getUrl = true
    end if
  else if loadStatus = "failed" then
    m.retryCount++
    if m.retryCount <= m.maxRetries then
      tubiLog(msg.getRoSGNode().id + " failed to load due to API error, attempting retry #" + m.retryCount.toStr())
      m.retryTimer.duration = m.retryTimer.duration * m.backoffFactor
      m.retryTimer.control = "start"
    else
      tubiLog(msg.getRoSGNode().id + " failed to load due to API error. No retries left, switching to backup")
      fallbackToBuiltInScreenSaver()
    end if
  end if
End Function


Function onStarterControllerRemoteComponentsUrlChange(msg)
  ' Setup global constants with our new constants from the starter component library
    ' NOTE must be called after the url is set as that is also when the constants has been updated with experiment info
    m.global.update({
      constants: m.starterController.newBuildConstants
    }, true)

  m.remoteComponentLibrary.observeFieldScoped("loadStatus", "onRemoteComponentLibraryLoadStatusChange")
  m.remoteComponentLibrary.uri = msg.getData()
End Function


Function onRemoteComponentLibraryLoadStatusChange(msg)
  loadStatus = msg.getData()
  if loadStatus = "ready" then
    controller = m.controllerContainer.createChild("TubiRemoteLibrary:ScreenSaverController")
    controller.startupArgs = m.top.startupArgs
    controller.observeFieldScoped("loadStatus", "onScreenSaverControllerLoadStatusChange")
  else if loadStatus = "failed" then
    m.retryCount++
    if m.retryCount <= m.maxRetries then
      tubiLog(msg.getRoSGNode().id + " failed to load due to API error, attempting retry #" + m.retryCount.toStr())
      m.retryTimer.duration = m.retryTimer.duration * m.backoffFactor
      m.retryTimer.control = "start"
    else
      tubiLog(msg.getRoSGNode().id + " failed to load due to API error. No retries left, switching to backup")
      fallbackToBuiltInScreenSaver()
    end if
  end if
End Function


Function fallbackToBuiltInScreenSaver()
  onFallbackPosterTimerFire()
  m.fallbackPoster.visible = true
  removeBusySpinner()
End Function


Function onScreenSaverControllerLoadStatusChange(msg)
  loadStatus = msg.getData()
  if loadStatus = "ready" then
    removeBusySpinner()
  else if loadStatus = "failed" then
    fallbackToBuiltInScreenSaver()
  end if
End Function


Function onRetryTimerFire()
  ' Figure out which component library we need to retry
  if m.starterComponentLibrary.loadStatus = "ready" then
    resetComponentLibrary(m.remoteComponentLibrary, "onRemoteComponentLibraryLoadStatusChange")
  else
    resetComponentLibrary(m.starterComponentLibrary, "onStarterComponentLibraryLoadStatusChange")
  end if
End Function

' @componentLibrary roSGNode - component library that we're resetting
' @callback string - callback function we want called on loadStatus change
Function resetComponentLibrary(componentLibrary, callback)
  componentId = componentLibrary.id
  componentUri = componentLibrary.uri
  m.top.removeChild(componentLibrary)

  newComponentLibrary = m.top.createChild("ComponentLibrary")
  newComponentLibrary.observeFieldScoped("loadStatus", callback)
  newComponentLibrary.id = componentId
  newComponentLibrary.uri = componentUri
  m[componentId] = newComponentLibrary
End Function


Function onFallbackPosterTimerFire()
  m.fallbackPoster.translation = generateNextPosterPosition()
  m.fallbackPosterTimer.control = "start"
End Function


Function generateNextPosterPosition()
  ' Trying to generate a random position that doesn't go offscreen
  currentPosition = m.fallbackPoster.translation
  horizontalOffset = rnd(960) * .8
  if horizontalOffset < 200 then
    horizontalOffset = rnd(960) * .8
  end if
  verticalOffset = rnd(540) * .8
  if horizontalOffset < 150 then
    horizontalOffset = rnd(540) * .8
  end if

  nextPosition = []
  if currentPosition[0] < 960 then
    nextPosition[0] = currentPosition[0] + horizontalOffset
  else
    nextPosition[0] = currentPosition[0] - horizontalOffset
  end if

  if currentPosition[1] < 540 then
    nextPosition[1] = currentPosition[1] + verticalOffset
  else
    nextPosition[1] = currentPosition[1] - verticalOffset
  end if
  return nextPosition
End Function


Function removeBusySpinner()
  m.top.removeChild(m.busySpinner)
  m.delete("busySpinner")
End Function
