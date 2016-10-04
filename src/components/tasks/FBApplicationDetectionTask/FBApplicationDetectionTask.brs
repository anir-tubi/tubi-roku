Function init()
  tubiLog("FBApplicationDetectionTask.init")
  m.top.functionName = "execFBDetect"
End Function

Function execFBDetect()
  tubiLog("FBApplicationDetectionTask.execFBDetect")
  port = CreateObject("roMessagePort")
  fbdetect = FBApplicationDetectionInit(m.global.constants.fban4tvtoken, true, port, false, onError)

  while true
    ' HandleEvent internally will refresh the token from FB service once a timer threshold 
    ' is reached.  If we wait(0, port), it won't ever get the chance to refresh.
    msg = wait(10000, port)
    tubiLog("FBApplicationDetectionTask received message type " + type(msg))
    handled = fbdetect.HandleEvent(msg)
    if handled then tubiLog("FBApplicationDetectionTask successfully handled message")
  end while
End Function

Function onError(error)
  tubiLog("FBApplicationDetectionTask.onError: " + error)
end Function
