''''''''''''''''''''
' Simple main to launch the unit tests if mode is "test".
' Otherwise, exit immediately.
'
Function Main()
  settings = getSettings()

  if settings.mode = "test" then
    BrsTestMain()
  endif

End Function
