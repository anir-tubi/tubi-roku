print "Hot Patch 2.5.newui {{profile}}"

'''''''''''''''''''''''''''''''
'settings.version must be updated manually in the new ui hotpatch file
'when a new remote components version is released
m.global.utils.constants.settings.version = "{{versionUnderscored}}"
' Set the most current remote components URL.  These should only increment build number.  Minor or major version number differences indicate
' incompatible architectural changes.
m.global.utils.constants.settings.remoteComponentsUrl = "{{remoteComponentsLocation}}"


'''''''''''''''''''''''''''''''
' Turn features on/off
m.global.utils.constants.ui.signIn.skipContinueScreen = true
m.global.utils.constants.ui.signIn.backExitsSignIn = true
m.global.utils.constants.ui.onNow.disableOnNow = false



'''''''''''''''''''''''''''''''
' Log specific device output
' m.global.utils.constants.idsToLog = {
'   "YY00G1976937": true
' }


'correct the client version sent to the active tracking event when using remote components
if m.global.utils.constants.externalConfig.info.remote_components = 1
  m.global.utils.constants.deviceInfo.clientVersion = m.global.utils.constants.deviceInfo.clientVersion.Replace("local", "remote")
end if
