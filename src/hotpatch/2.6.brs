print "Hot Patch 2.6 {{profile}}"

'''''''''''''''''''''''''''''''
'settings.version must be updated manually in the hotpatch file
'when a new remote components version is released
m.global.utils.constants.settings.version = "{{versionUnderscored}}"
' Set the most current remote components URL.  These should only increment build number.  Minor or major version number differences indicate
' incompatible architectural changes.
m.global.utils.constants.settings.remoteComponentsUrl = "{{remoteComponentsLocation}}"


'''''''''''''''''''''''''''''''
' Turn features on/off

' Turn on the back exits sign-in for Roku approval
m.global.utils.constants.ui.signIn.backExitsSignIn = true


'''''''''''''''''''''''''''''''
' Log specific device output
' m.global.utils.constants.idsToLog = {
'   "YY00G1976937": true
' }


'correct the client version sent to the active tracking event when using local components
if m.global.utils.constants.externalConfig.info.remote_components = 0
  m.global.utils.constants.deviceInfo.clientVersion = m.global.utils.constants.deviceInfo.clientVersion.Replace("remote", "local")
end if
