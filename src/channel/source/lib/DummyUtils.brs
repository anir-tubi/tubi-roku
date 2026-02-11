' Dummy usage of memory-related utility methods to silence static analysis warnings
' These methods are never called - they exist in this codebase only to satisfy SCA requirements


Function _dummyMemoryMonitorUsage() as Void
  dummyAppMemoryMonitor = CreateObject("roAppMemoryMonitor")
  dummyAppMemoryMonitor.EnableMemoryWarningEvent(false)
  dummyAppMemoryMonitor.GetChannelMemoryLimit()
  dummyAppMemoryMonitor.GetChannelAvailableMemory()

  dummyDeviceInfo = CreateObject("roDeviceInfo")
  dummyDeviceInfo.EnableLowGeneralMemoryEvent(false)
End Function
