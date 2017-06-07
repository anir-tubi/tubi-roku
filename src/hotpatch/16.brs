print "Hot Patch 16"

m.global.utils.constants.settings.allowAfterHours = false

' m.global.utils.constants.idsToLog = {
'   "YY00G1976937": true
' }

'correct the client version sent to the active tracking event when using remote components
if m.global.utils.constants.externalConfig.info.remote_components = 1
  m.global.utils.constants.deviceInfo.clientVersion = m.global.utils.constants.deviceInfo.clientVersion.Replace("local", "remote")
end if
