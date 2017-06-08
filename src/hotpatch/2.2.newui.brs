print "Hot Patch 2.2.newui"

m.global.utils.constants.settings.allowAfterHours = false

' m.global.utils.constants.idsToLog = {
'   "YY00G1976937": true
' }

'correct the client version sent to the active tracking event when using remote components
if m.global.utils.constants.externalConfig.info.remote_components = 1
  m.global.utils.constants.deviceInfo.clientVersion = m.global.utils.constants.deviceInfo.clientVersion.Replace("local", "remote")
end if

'determine the appropriate remote components to use if server remote config says to allow On Now
print "hotpatch roku_onnow config = "; m.global.utils.constants.externalConfig.info.roku_onnow

' Set the most current remote components URL.  These should only increment build number.  Minor or major version number differences indicate
' incompatible architectural changes.
m.global.utils.constants.settings.remoteComponentsUrl = "http://cdn.adrise.com/hotpatches/roku/components/tubitv_remote_components_2_2_12.pkg"

