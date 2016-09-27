Function init()
  tubiLog("FBApplicationDetectionTask.init")
  m.top.functionName = "execFBDetect"
End Function

Function execFBDetect()
  tubiLog("FBApplicationDetectionTask.execFBDetect")
  port = CreateObject("roMessagePort")
  fbdetect = FBApplicationDetectionInit(m.global.constants.fban4tvtoken, true, port, false, onError)

  while true
    msg = wait(0, port)
    tubiLog("FBApplicationDetectionTask received message type " + type(msg))
    handled = fbdetect.HandleEvent(msg)
    if handled then tubiLog("FBApplicationDetectionTask successfully handled message")
  end while
End Function

Function onError(error)
  tubiLog("FBApplicationDetectionTask.onError: " + error)
end Function
