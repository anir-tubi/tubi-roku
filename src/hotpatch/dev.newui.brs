print "Hot Patch dev.newui"
' This hotpatch is for local developer use

'correct the client version sent to the active tracking event when using remote components
if m.global.utils.constants.externalConfig.info.remote_components = 1
  m.global.utils.constants.deviceInfo.clientVersion = m.global.utils.constants.deviceInfo.clientVersion.Replace("local", "remote")
end if

