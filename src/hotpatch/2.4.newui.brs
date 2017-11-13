print "Hot Patch 2.4.newui {{profile}}"

'''''''''''''''''''''''''''''''
'settings.version must be updated manually in the new ui hotpatch file
'when a new remote components version is released
m.global.utils.constants.settings.version = "{{versionUnderscored}}"
' Set the most current remote components URL.  These should only increment build number.  Minor or major version number differences indicate
' incompatible architectural changes.
' m.global.utils.constants.settings.remoteComponentsUrl = "http://cdn.adrise.com/hotpatches/roku/components/tubitv_remote_components_" + m.global.utils.constants.settings.version + ".pkg"
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



'Fix issue on tracking
m.global.utils.tracking.getUserTrackingRequest = Function(trackData as Object)
  trackUrl = m.constants.urls.datascience.event

  options = {
    method: m.constants.reqTypes.post
    body: FormatJson(trackData)
    headers: {"Content-Type": "application/json"}
  }

  userRequest = m.request.createAsync(trackUrl, "track" + trackData.key, options)

  return userRequest
End Function