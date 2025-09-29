' Placeholder file to make bsc happy while developing since this file is created at build time
Function getSettings()
  print "this should never get called"
  stop 'bs:disable-line LINT3016
End Function
