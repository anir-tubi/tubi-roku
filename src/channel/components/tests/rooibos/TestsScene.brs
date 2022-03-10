Function init()
  m.constants = m.global.constants

  unitTestNotifier = m.top.createChild("UnitTestNotifier")
  unitTestNotifier.id = "UnitTestNotifier"
  m.top.allowBackgroundTask = true

End Function

' customSuspend is the callback for suspendhandler customization tag, 
' will be triggered when home key button is pressed (home key is pressed when unit tests are completed)
Function customSuspend(args)

  unitTestNotifier = m.top.findNode("UnitTestNotifier") 
  if unitTestNotifier <> invalid
    unitTestNotifier.customSuspendUnitTest = args
  end if

End Function
