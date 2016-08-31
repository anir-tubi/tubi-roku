''''''''''''''''''''
' tubiLog
'
' Wrapper for logging.  By default prints to console
Function tubiLog(what As String) As Void
  print what
End Function


''''''''''''''''''''
' testLog
'
' Logging specifically targeted at automated tests.  These log
' statements should not be reformatted without also changing
' the black box tests which rely upon them.
Function testLog(what As String) As Void
  print "TEST: " + what
End Function